#!/opt/homebrew/bin/bash
# Sanbrain: harvest-recordings
# Transcribes iPhone voice memos from iCloud Meetings/ folder using OpenAI
# Whisper API, then delivers frontmattered markdown to raw/ for nightly ingest.
#
# Capture-fidelity rules (no silent drops, no compression at capture):
#   - Files >25MB are CHUNKED with ffmpeg and transcribed per-chunk
#     (previously skipped silently — the longest meetings were the ones lost).
#   - Delivery is tracked in a state file, not by checking raw/ (which broke
#     once ingest archived the file — transcripts re-delivered forever).
#   - No date window: anything transcribed and never delivered gets delivered,
#     even if the Mac was off for a week.
#   - Apple's AI summary .txt files are delivered with `fidelity: apple-summary`
#     so downstream skills treat the framing as unverified. Verbatim Whisper
#     transcripts are the primary record.
#   - Each newly delivered voice memo sends a Telegram confirmation ping
#     («title» — transcrito, N palabras) — parity with the ⌘⇧R hotkey path,
#     which already confirms every recording in the moment. Phone memos used to
#     be transcribed silently; now Santiago gets the same "recibido y
#     transcrito" feedback for them. Apple summaries (not voice memos) and
#     silent-audio hallucinations don't ping.
#
# Called by nightly.sh before the 4-skill chain.

source "$(dirname "$0")/lib.sh"
MEETINGS="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Meetings"
# Second source: the ⌘⇧R voice-memo hotkey (scripts/voice-memo) records here.
# It transcribes + delivers immediately; this nightly pass is the safety net
# for anything that failed mid-pipeline (no API key, whisper error, >25MB).
# The shared transcript naming + delivered-list make re-delivery impossible.
HOTKEY_RECORDINGS="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Recordings"
TRANSCRIPTS="$HOME/transcripts"
TODAY=$(date +%Y-%m-%d)
LOG="$SANBRAIN/logs/recordings.log"
MAX_SIZE=$((25 * 1024 * 1024))  # 25MB Whisper API limit
DELIVERED_LIST="$STATE_DIR/delivered-recordings.list"

TRANSCRIBED=0
DELIVERED=0
FAILED=0

# ── Pre-flight ──────────────────────────────────────────────────
mkdir -p "$TRANSCRIPTS"
touch "$DELIVERED_LIST"

if [ -z "$OPENAI_API_KEY" ]; then
  log "=== Recordings harvest SKIPPED: OPENAI_API_KEY not set (put it in ~/.sanbrain.env) ==="
  echo "Recordings harvest: SKIPPED (no API key)"
  heartbeat harvest-recordings skip "OPENAI_API_KEY not set"
  exit 0
fi

if ! ls "$MEETINGS" >/dev/null 2>&1; then
  log "=== Recordings harvest SKIPPED: cannot access Meetings folder ==="
  echo "Recordings harvest: SKIPPED (no access to Meetings/)"
  heartbeat harvest-recordings skip "no access to Meetings/"
  exit 0
fi

log "=== Recordings harvest started ==="

# ── Helper: derive transcript filename from .m4a filename ───────
# "Audio Recording 2026-05-28 at 8.46.53.m4a" → "memo-2026-05-28-0846.txt"
transcript_name() {
  local base="$1"
  local date_part time_part
  if [[ "$base" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2})\ at\ ([0-9]+)\.([0-9]{2})\.[0-9]{2} ]]; then
    date_part="${BASH_REMATCH[1]}"
    local hour="${BASH_REMATCH[2]}"
    local min="${BASH_REMATCH[3]}"
    time_part=$(printf "%02d%s" "$hour" "$min")
    echo "memo-${date_part}-${time_part}.txt"
  else
    echo "${base%.*}.txt" | tr ' ' '-' | tr '[:upper:]' '[:lower:]'
  fi
}

# ── Helper: extract date from filename ──────────────────────────
extract_date() {
  local base="$1"
  if [[ "$base" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo "$TODAY"
  fi
}

# ── Helper: one-line "what was this about" for the confirmation ping ─────
# Mirrors the ⌘⇧R hotkey path (scripts/voice-memo): claude best-effort, in the
# memo's own language; falls back to the first words verbatim if claude is
# unavailable or times out. Only the first 4KB feeds the prompt — meeting
# transcripts can be long and a title needs only the opening.
gen_title() {
  local tf="$1" title="" snippet
  snippet=$(head -c 4000 "$tf")
  if [ -x "$CLAUDE" ]; then
    title=$(timeout 60 "$CLAUDE" -p "Below is a voice memo transcript (Spanish/English mix, may have transcription errors). Reply with ONLY a title for it: 3-8 words, in the memo's own language, describing what it's about. No quotes, no trailing punctuation, nothing but the title.

$snippet" 2>>"$LOG" | grep -m1 . | tr -d '"' | cut -c1-80)
  fi
  if [ -z "$title" ]; then
    title=$(tr '\n' ' ' < "$tf" | awk '{for(i=1;i<=8&&i<=NF;i++)printf "%s ",$i}' | sed 's/ *$/…/')
  fi
  printf '%s' "$title"
}

# Transcription: whisper_file from lib.sh (stdout = transcript, errors → $LOG)

# ── Helper: transcribe with chunking for >25MB files ────────────
transcribe_file() { # audio_path out_txt
  local f="$1" out="$2"
  local fsize
  fsize=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f" 2>/dev/null)

  if [ "${fsize:-0}" -le "$MAX_SIZE" ]; then
    whisper_file "$f" > "$out"
    [ -s "$out" ] && return 0
    rm -f "$out"; return 1
  fi

  # Chunk path
  if ! command -v ffmpeg >/dev/null 2>&1; then
    log "GAP: $(basename "$f") is >25MB and ffmpeg is not installed — cannot chunk. brew install ffmpeg"
    return 2
  fi
  local tmpdir
  tmpdir=$(mktemp -d)
  log "Chunking $(basename "$f") ($(( fsize / 1048576 ))MB) for transcription"
  if ! ffmpeg -hide_banner -loglevel error -i "$f" -f segment -segment_time 600 -c copy "$tmpdir/chunk-%03d.m4a" 2>>"$LOG"; then
    log "FAIL: ffmpeg chunking failed for $(basename "$f")"
    rm -rf "$tmpdir"; return 1
  fi
  : > "$out.tmp"
  local chunk ok=true
  for chunk in "$tmpdir"/chunk-*.m4a; do
    [ -e "$chunk" ] || continue
    if ! whisper_file "$chunk" >> "$out.tmp"; then
      ok=false; break
    fi
    printf '\n' >> "$out.tmp"
  done
  rm -rf "$tmpdir"
  if [ "$ok" = true ] && [ -s "$out.tmp" ]; then
    mv "$out.tmp" "$out"; return 0
  fi
  rm -f "$out.tmp"; return 1
}

# ── Phase 1: Transcribe new .m4a files (chunked when needed) ────
# Sanity cap: a runaway recording once hit 3.7GB (3 days of mic). Chunking
# that would burn ~$25 of Whisper on room noise — skip and flag instead.
SANITY_MAX=$((300 * 1024 * 1024))

while IFS= read -r -d '' f; do
  base=$(basename "$f")
  txt_name=$(transcript_name "$base")
  [ -f "$TRANSCRIPTS/$txt_name" ] && continue

  fsize=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f" 2>/dev/null)
  if [ "${fsize:-0}" -gt "$SANITY_MAX" ]; then
    log "GAP: $base is $(( fsize / 1048576 ))MB (>300MB sanity cap) — runaway recording? Skipping; transcribe manually if it matters."
    continue
  fi

  log "Transcribing: $base → $txt_name"
  transcribe_file "$f" "$TRANSCRIPTS/$txt_name"
  rc=$?
  if [ $rc -eq 0 ]; then
    TRANSCRIBED=$((TRANSCRIBED + 1))
    log "OK: $txt_name ($(wc -c < "$TRANSCRIPTS/$txt_name") bytes)"
  else
    FAILED=$((FAILED + 1))
    log "FAIL: $base (rc=$rc)"
  fi
done < <(find "$MEETINGS" "$HOTKEY_RECORDINGS" -maxdepth 1 -name "*.m4a" -type f -print0 2>/dev/null)

# ── Phase 2: Copy Apple summary .txt files (marked as summaries) ─
# These are AI-generated summaries, NOT verbatim transcripts. They are kept
# because they may cover recordings we never got audio for, but they carry a
# fidelity marker so ingest treats the framing as unverified.
while IFS= read -r -d '' f; do
  base=$(basename "$f")
  safe_name=$(echo "$base" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
  if [ ! -f "$TRANSCRIPTS/apple-summary-$safe_name" ]; then
    cp "$f" "$TRANSCRIPTS/apple-summary-$safe_name"
    log "Apple summary copied: $base → apple-summary-$safe_name"
  fi
done < <(find "$MEETINGS" -maxdepth 1 -name "*.txt" -type f -print0 2>/dev/null)

# ── Phase 3: Deliver undelivered transcripts to raw/ ────────────
# State-file tracked. No date window — undelivered means deliver.
while IFS= read -r -d '' txt; do
  txt_base=$(basename "$txt")
  slug="${txt_base%.txt}"

  # Already delivered? (state file is the source of truth)
  grep -qxF "$slug" "$DELIVERED_LIST" && continue

  raw_target="$VAULT/raw/voice-${slug}.md"
  [ -f "$raw_target" ] && { echo "$slug" >> "$DELIVERED_LIST"; continue; }

  file_date=$(extract_date "$txt_base")
  file_time=""
  if [[ "$txt_base" =~ ^memo-([0-9]{4}-[0-9]{2}-[0-9]{2})-([0-9]{2})([0-9]{2}) ]]; then
    file_date="${BASH_REMATCH[1]}"
    file_time="${BASH_REMATCH[2]}:${BASH_REMATCH[3]}"
  fi

  content=$(cat "$txt")
  [ -z "$content" ] && continue

  fidelity="verbatim-whisper"
  header="Voice Memo"
  if [[ "$txt_base" == apple-summary-* ]]; then
    fidelity="apple-summary"
    header="Recording Summary (Apple AI — framing unverified)"
  fi
  if [ -n "$file_time" ]; then
    header="$header — ${file_date} ${file_time}"
  else
    header="$header — ${file_date}"
  fi

  {
    echo "---"
    echo "type: voice-memo"
    echo "date: $file_date"
    echo "source: harvest-recordings"
    echo "fidelity: $fidelity"
    echo "auto_process: true"
    echo "---"
    echo ""
    echo "# $header"
    echo ""
    echo "$content"
  } > "$raw_target"

  echo "$slug" >> "$DELIVERED_LIST"
  DELIVERED=$((DELIVERED + 1))
  log "Delivered: $txt_base → $(basename "$raw_target") (fidelity: $fidelity)"

  # ── Confirmation ping (parity with the ⌘⇧R hotkey) ──────────────────
  # Hotkey memos pinged at record time are already in DELIVERED_LIST, so the
  # dedup above means they never reach here — no double-ping. What reaches
  # here is a phone memo (Meetings/) or a hotkey memo that failed its instant
  # ping and got recovered tonight. Apple summaries aren't voice memos → no
  # ping. Whisper's silent-audio hallucinations ("thank you for watching")
  # are noise → still delivered as before, just no ping.
  if [ "$fidelity" = "verbatim-whisper" ]; then
    if printf '%s' "$content" | grep -qiE "thank you (so much )?for watching|thanks for watching|gracias por ver|subt[ií]tulos|^you$|시청|감사합니다|ご視聴|ありがとうございました|구독"; then
      log "No ping: $slug looks like silent-audio hallucination"
    else
      words=$(printf '%s' "$content" | wc -w | tr -d ' ')
      title=$(gen_title "$txt")
      if [[ "$slug" == voice-memo-* ]]; then
        notify "🎙️ «${title}» — recuperado por el harvest y transcrito (${words} palabras), entregado a raw/."
      else
        notify "📱 «${title}» — voice memo del teléfono, transcrito (${words} palabras) y entregado a raw/."
      fi
    fi
  fi

done < <(find "$TRANSCRIPTS" -maxdepth 1 -name "*.txt" -type f -print0 2>/dev/null)

# ── Summary ─────────────────────────────────────────────────────
echo "Recordings harvest: $TRANSCRIBED transcribed, $DELIVERED delivered to raw/"
[ $FAILED -gt 0 ] && echo "  ($FAILED files FAILED — see logs/recordings.log)"
log "=== Complete: $TRANSCRIBED transcribed, $DELIVERED delivered, $FAILED failed ==="
if [ $FAILED -gt 0 ]; then
  heartbeat harvest-recordings warn "$TRANSCRIBED transcribed, $DELIVERED delivered, $FAILED FAILED"
else
  heartbeat harvest-recordings ok "$TRANSCRIBED transcribed, $DELIVERED delivered"
fi

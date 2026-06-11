#!/bin/bash
# Sanbrain: transcribe voice recordings embedded in today's brief.
#
# TCC REALITY (tested 2026-06-10 with one-shot launchd jobs): under launchd,
# /bin/bash and python3 get "Operation not permitted" reading vault CONTENT
# (stat/metadata works), while the claude binary and its CHILDREN are allowed.
# So this helper must run as a child of claude (the feedback run's first step)
# or manually from a terminal — never directly from the launchd wrapper.
#
# Modes:
#   (no args)         transcribe new recordings embedded in today's brief and
#                     print the transcripts to stdout as markdown sections
#   --mark-processed  mark every cached recording in the brief as processed —
#                     claude calls this AFTER propagating, so a crashed run
#                     re-feeds the cached transcript instead of losing it
#   --status          one-line state summary (used by brief-status.sh)
#
# State (under ~/sanbrain/.state — readable in every context):
#   brief-audio/<file>.txt        transcript cache (never re-pay Whisper)
#   brief-audio/<file>.attempts   failure counter — caps at 4, then gives up LOUDLY
#   brief-audio-processed.list    recordings fully propagated to the vault
#
# Every state transition is visible: transcription success pings Telegram
# immediately ("got it, processing"), give-ups ping with the reason.

source "$(dirname "$0")/lib.sh"
LOG="$SANBRAIN/logs/brief-feedback.log"
TODAY=$(date +%Y-%m-%d)
BRIEF="${BRIEF_OVERRIDE:-$VAULT/wiki/daily/${TODAY}-brief.md}"
CACHE="$STATE_DIR/brief-audio"
PROCESSED="$STATE_DIR/brief-audio-processed.list"
QUEUE_DIR="$STATE_DIR/brief-voice-queue"
MAX_SIZE=$((25 * 1024 * 1024))  # 25MB Whisper API limit
MAX_ATTEMPTS=4

mkdir -p "$CACHE" "$QUEUE_DIR"
touch "$PROCESSED"

# All audio embeds referenced by the brief: `![[Recording 2026... .webm]]`,
# optionally with a path prefix, |alias or #subpath.
embeds() {
  grep -oE '!\[\[[^]]*\.(webm|m4a|mp3|wav|ogg|flac)[^]]*\]\]' "$BRIEF" 2>/dev/null \
    | sed -E 's/^!\[\[//; s/\]\]$//; s/[|#].*$//' | sort -u
}

attempts_of() { cat "$CACHE/$1.attempts" 2>/dev/null || echo 0; }
bump_attempts() {
  local n
  n=$(attempts_of "$1")
  echo $((n + 1)) > "$CACHE/$1.attempts"
}

# ── --status ────────────────────────────────────────────────────
if [ "$1" = "--status" ]; then
  total=0; done_n=0; pending=""
  while IFS= read -r e; do
    [ -n "$e" ] || continue
    f=$(basename "$e")
    total=$((total + 1))
    if grep -qxF "$f" "$PROCESSED"; then
      done_n=$((done_n + 1))
    else
      pending="$pending $f(attempts:$(attempts_of "$f"))"
    fi
  done < <(embeds)
  qn=$(ls "$QUEUE_DIR" 2>/dev/null | wc -l | tr -d ' ')
  echo "recordings in today's brief: $total, processed: $done_n, pending:${pending:- none}; voice-memo queue: $qn"
  exit 0
fi

[ -f "$BRIEF" ] || { echo "[no brief today]"; exit 0; }
if ! head -c1 "$BRIEF" >/dev/null 2>&1; then
  echo "[ERROR: cannot read brief content — TCC denied in this context. Run me as a child of claude or from a terminal.]"
  log "transcribe-brief-audio: TCC denied reading $BRIEF"
  exit 1
fi

# ── --mark-processed ────────────────────────────────────────────
if [ "$1" = "--mark-processed" ]; then
  marked=0
  while IFS= read -r e; do
    [ -n "$e" ] || continue
    f=$(basename "$e")
    [ -s "$CACHE/$f.txt" ] || continue
    grep -qxF "$f" "$PROCESSED" && continue
    echo "$f" >> "$PROCESSED"
    marked=$((marked + 1))
    log "transcribe-brief-audio: marked processed: $f"
  done < <(embeds)
  # Consume the voice-memo queue (transcripts already live in raw/ — the
  # queue copy only existed to get them in front of the brief processor)
  for q in "$QUEUE_DIR"/*.txt; do
    [ -e "$q" ] || continue
    rm -f "$q"
    marked=$((marked + 1))
    log "transcribe-brief-audio: consumed queued memo: $(basename "$q")"
  done
  echo "marked $marked recording(s) as processed"
  exit 0
fi

# ── Default mode: transcribe new recordings, print transcripts ──
FOUND=0
while IFS= read -r e; do
  [ -n "$e" ] || continue
  fname=$(basename "$e")
  grep -qxF "$fname" "$PROCESSED" && continue
  cache_file="$CACHE/$fname.txt"

  if [ ! -s "$cache_file" ]; then
    if [ -z "$OPENAI_API_KEY" ]; then
      log "GAP: voice embed '$fname' but OPENAI_API_KEY not set (~/.sanbrain.env)"
      notify_once no-openai-key "sanbrain: hay una grabación en el brief pero OPENAI_API_KEY no está en ~/.sanbrain.env — no puedo transcribir."
      continue
    fi

    audio_path=$(find "$VAULT" -name "$fname" -not -path "*/.trash/*" -type f 2>/dev/null | head -1)
    fsize=0
    [ -n "$audio_path" ] && fsize=$(stat -f%z "$audio_path" 2>/dev/null || stat -c%s "$audio_path" 2>/dev/null)

    if [ -z "$audio_path" ] || [ "${fsize:-0}" -eq 0 ]; then
      bump_attempts "$fname"
      if [ "$(attempts_of "$fname")" -ge "$MAX_ATTEMPTS" ]; then
        echo "$fname" >> "$PROCESSED"
        log "GIVE UP: audio '$fname' never appeared on disk after $MAX_ATTEMPTS attempts"
        notify "⚠️ sanbrain: no encontré el audio '$fname' del brief después de $MAX_ATTEMPTS intentos. Si la grabación importa, dímelo por aquí o vuelve a grabar."
      else
        log "WAIT: audio '$fname' not on disk yet (attempt $(attempts_of "$fname")/$MAX_ATTEMPTS)"
      fi
      continue
    fi

    if [ "$fsize" -gt "$MAX_SIZE" ]; then
      echo "$fname" >> "$PROCESSED"
      log "GIVE UP: '$fname' is >25MB — beyond Whisper limit for brief feedback"
      notify "⚠️ sanbrain: la grabación '$fname' pasa de 25MB y no puedo transcribirla. Graba feedback en tomas más cortas."
      continue
    fi

    log "Transcribing voice feedback: $fname ($(( fsize / 1024 ))KB)"
    whisper_file "$audio_path" > "$cache_file"
    if [ ! -s "$cache_file" ]; then
      rm -f "$cache_file"
      bump_attempts "$fname"
      if [ "$(attempts_of "$fname")" -ge "$MAX_ATTEMPTS" ]; then
        echo "$fname" >> "$PROCESSED"
        log "GIVE UP: whisper failed $MAX_ATTEMPTS times on '$fname'"
        notify "⚠️ sanbrain: no pude transcribir '$fname' ($MAX_ATTEMPTS intentos — ¿grabación vacía o muy corta?). Vuelve a grabar si importaba."
      else
        log "FAIL: whisper empty for '$fname' (attempt $(attempts_of "$fname")/$MAX_ATTEMPTS)"
      fi
      continue
    fi
    words=$(wc -w < "$cache_file" | tr -d ' ')
    log "Transcribed: $fname ($words words)"
    notify "🎙️ sanbrain: grabación recibida y transcrita ($words palabras). Procesando — respuestas en el brief en unos minutos."
  fi

  printf '\n### Recording: %s\n%s\n' "$fname" "$(cat "$cache_file")"
  FOUND=$((FOUND + 1))
done < <(embeds)

# Queued voice-memo transcripts (global ⌘⇧R recordings, already transcribed
# and delivered to raw/ by scripts/voice-memo). May or may not be about the
# brief — the caller (claude) routes by content.
for q in "$QUEUE_DIR"/*.txt; do
  [ -e "$q" ] || continue
  printf '\n### Voice memo (global recording): %s\n%s\n' "$(basename "$q" .txt)" "$(cat "$q")"
  FOUND=$((FOUND + 1))
done

[ "$FOUND" -eq 0 ] && echo "[no new recordings]"
exit 0

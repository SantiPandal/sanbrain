#!/opt/homebrew/bin/bash
# Sanbrain: harvest-recordings
# Transcribes iPhone voice memos from iCloud Meetings/ folder using OpenAI
# Whisper API, then delivers frontmattered markdown to raw/ for nightly ingest.
#
# Flow:
#   1. Scan Meetings/ for .m4a files not yet transcribed
#   2. Transcribe via Whisper API → ~/transcripts/
#   3. Copy Apple summary .txt files to ~/transcripts/
#   4. Deliver today's new transcripts to $VAULT/raw/ with frontmatter
#
# Called by nightly.sh before the 4-skill chain.

export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
SANBRAIN="$HOME/sanbrain"
VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT"
MEETINGS="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Meetings"
TRANSCRIPTS="$HOME/transcripts"
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d "yesterday" +%Y-%m-%d)
LOG="$SANBRAIN/logs/recordings.log"
MAX_SIZE=$((25 * 1024 * 1024))  # 25MB Whisper API limit

TRANSCRIBED=0
DELIVERED=0
SKIPPED=0

log() { echo "$(date +%Y-%m-%dT%H:%M:%S) $1" >> "$LOG"; }

# ── Pre-flight ──────────────────────────────────────────────────
mkdir -p "$TRANSCRIPTS"
mkdir -p "$SANBRAIN/logs"

if [ -z "$OPENAI_API_KEY" ]; then
  # Try sourcing from .zshrc
  source "$HOME/.zshrc" 2>/dev/null
fi

if [ -z "$OPENAI_API_KEY" ]; then
  log "=== Recordings harvest SKIPPED: OPENAI_API_KEY not set ==="
  echo "Recordings harvest: SKIPPED (no API key)"
  exit 0
fi

if ! ls "$MEETINGS" >/dev/null 2>&1; then
  log "=== Recordings harvest SKIPPED: cannot access Meetings folder ==="
  echo "Recordings harvest: SKIPPED (no access to Meetings/)"
  exit 0
fi

log "=== Recordings harvest started ==="

# ── Helper: derive transcript filename from .m4a filename ───────
# "Audio Recording 2026-05-28 at 8.46.53.m4a" → "memo-2026-05-28-0846.txt"
transcript_name() {
  local base="$1"
  # Extract date and time from filename
  local date_part time_part
  if [[ "$base" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2})\ at\ ([0-9]+)\.([0-9]{2})\.[0-9]{2} ]]; then
    date_part="${BASH_REMATCH[1]}"
    # Zero-pad hour and combine with minutes (drop seconds)
    local hour="${BASH_REMATCH[2]}"
    local min="${BASH_REMATCH[3]}"
    time_part=$(printf "%02d%s" "$hour" "$min")
    echo "memo-${date_part}-${time_part}.txt"
  else
    # Fallback: sanitize the whole name
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

# ── Helper: extract time from filename for display ──────────────
extract_time() {
  local base="$1"
  if [[ "$base" =~ at\ ([0-9]+)\.([0-9]{2})\.([0-9]{2}) ]]; then
    printf "%02d:%s:%s" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
  else
    echo ""
  fi
}

# ── Phase 1: Transcribe new .m4a files ──────────────────────────
while IFS= read -r -d '' f; do
  base=$(basename "$f")

  # Derive transcript name and check if already done
  txt_name=$(transcript_name "$base")
  if [ -f "$TRANSCRIPTS/$txt_name" ]; then
    continue
  fi

  # Check file size
  fsize=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f" 2>/dev/null)
  if [ "${fsize:-0}" -gt "$MAX_SIZE" ]; then
    log "SKIP (>25MB): $base ($(( fsize / 1048576 ))MB)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  log "Transcribing: $base → $txt_name"

  # Call Whisper API via OpenAI SDK (same as /transcribe skill)
  python3 -c "
from openai import OpenAI
import sys
client = OpenAI()
with open(sys.argv[1], 'rb') as f:
    text = client.audio.transcriptions.create(model='whisper-1', file=f, response_format='text')
print(text, end='')
" "$f" > "$TRANSCRIPTS/$txt_name" 2>>"$LOG"

  if [ $? -eq 0 ] && [ -s "$TRANSCRIPTS/$txt_name" ]; then
    TRANSCRIBED=$((TRANSCRIBED + 1))
    log "OK: $txt_name ($(wc -c < "$TRANSCRIPTS/$txt_name") bytes)"
  else
    rm -f "$TRANSCRIPTS/$txt_name"
    log "FAIL: $base"
  fi

done < <(find "$MEETINGS" -maxdepth 1 -name "*.m4a" -type f -print0 2>/dev/null)

# ── Phase 2: Copy Apple summary .txt files ──────────────────────
while IFS= read -r -d '' f; do
  base=$(basename "$f")
  # Sanitize name for transcript store
  safe_name=$(echo "$base" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
  if [ ! -f "$TRANSCRIPTS/$safe_name" ]; then
    cp "$f" "$TRANSCRIPTS/$safe_name"
    log "Apple summary copied: $base → $safe_name"
  fi
done < <(find "$MEETINGS" -maxdepth 1 -name "*.txt" -type f -print0 2>/dev/null)

# ── Phase 3: Deliver new transcripts to raw/ ────────────────────
# Deliver transcripts modified today or yesterday (nightly harvest window)
while IFS= read -r -d '' txt; do
  txt_base=$(basename "$txt")
  slug="${txt_base%.txt}"
  raw_target="$VAULT/raw/voice-${slug}.md"

  # Skip if already delivered
  if [ -f "$raw_target" ]; then
    continue
  fi

  # Extract date from filename, or use file modification date
  file_date=$(extract_date "$txt_base")
  file_time=""
  # Try to get time from original memo naming
  if [[ "$txt_base" =~ ^memo-([0-9]{4}-[0-9]{2}-[0-9]{2})-([0-9]{2})([0-9]{2}) ]]; then
    file_date="${BASH_REMATCH[1]}"
    file_time="${BASH_REMATCH[2]}:${BASH_REMATCH[3]}"
  fi

  # Only deliver files from today or yesterday
  if [[ "$file_date" != "$TODAY" && "$file_date" != "$YESTERDAY" ]]; then
    # Also check file modification time as fallback
    mod_date=$(stat -f "%Sm" -t "%Y-%m-%d" "$txt" 2>/dev/null || stat -c "%y" "$txt" 2>/dev/null | cut -d' ' -f1)
    if [[ "$mod_date" != "$TODAY" && "$mod_date" != "$YESTERDAY" ]]; then
      continue
    fi
  fi

  # Read transcript content
  content=$(cat "$txt")
  if [ -z "$content" ]; then
    continue
  fi

  # Build display header
  header="Voice Memo"
  if [ -n "$file_time" ]; then
    header="Voice Memo — ${file_date} ${file_time}"
  else
    header="Voice Memo — ${file_date}"
  fi

  # Write frontmattered markdown to raw/
  {
    echo "---"
    echo "type: voice-memo"
    echo "date: $file_date"
    echo "source: harvest-recordings"
    echo "auto_process: true"
    echo "---"
    echo ""
    echo "# $header"
    echo ""
    echo "$content"
  } > "$raw_target"

  DELIVERED=$((DELIVERED + 1))
  log "Delivered: $txt_base → $(basename "$raw_target")"

done < <(find "$TRANSCRIPTS" -maxdepth 1 -name "*.txt" -type f -print0 2>/dev/null)

# ── Summary ─────────────────────────────────────────────────────
echo "Recordings harvest: $TRANSCRIBED transcribed, $DELIVERED delivered to raw/"
[ $SKIPPED -gt 0 ] && echo "  ($SKIPPED files skipped: >25MB)"
log "=== Complete: $TRANSCRIBED transcribed, $DELIVERED delivered, $SKIPPED skipped ==="

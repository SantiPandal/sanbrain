#!/opt/homebrew/bin/bash
# Sanbrain: harvest-downloads
# Treats ~/Downloads as a WORKING DIRECTORY — Santiago saves, downloads, and
# processes; the residue is cleared automatically and reversibly.
#
# The actual lifecycle (trash/promote/age) is owned by process-downloads.py,
# which runs in Phase 1 BEFORE this scan. This script's remaining jobs:
#   NOISE   — .DS_Store, .localized, .part, .crdownload → auto-delete (invisible junk)
#   HARVEST — text files (.md, .txt) → copy to raw/ for ingest, keep original
#             (the original is verified-saved next run and trashed then)
#   REPORT  — write a READ-ONLY manifest: what process-downloads did last night
#             + what's still on the desk. No approval checkboxes anymore.
#
# Philosophy: idle & already-saved files move to macOS Trash on their own
# (recoverable ~30d); one-way doors (fiscal/legal) are saved to the vault first;
# crypto keys are never touched. The full audit trail is the in-vault ledger
# wiki/logs/downloads-trash-YYYY-MM.md.
#
# Called by nightly.sh before the 4-skill chain.

source "$(dirname "$0")/lib.sh"
DOWNLOADS="$HOME/Downloads"
TODAY=$(date +%Y-%m-%d)
MANIFEST="$VAULT/raw/downloads-manifest-${TODAY}.md"
LOG="$SANBRAIN/logs/downloads.log"

HARVESTED=()
DESK_ITEMS=()
CLEANED=()

# ── Pre-flight: verify Downloads access ──────────────────────────
if ! ls "$DOWNLOADS" >/dev/null 2>&1; then
  log "=== Downloads harvest SKIPPED: cannot access $DOWNLOADS (FDA not granted) ==="
  echo "Downloads harvest: SKIPPED (no access)"
  heartbeat harvest-downloads skip "no Downloads access (FDA not granted)"
  exit 0
fi

# ── Classification functions ─────────────────────────────────────

is_sacred() {
  local f="$1"
  local base=$(basename "$f")
  # Fiscal certificates, private keys, crypto credentials
  [[ "$base" == *.cer ]] && return 0
  [[ "$base" == *.key ]] && return 0
  [[ "$base" == *.p12 ]] && return 0
  # SAT fiscal documents
  [[ "$base" == Acuse* ]] && return 0
  [[ "$base" == factura* ]] && return 0
  [[ "$base" == CFDI* ]] && return 0
  return 1
}

is_noise() {
  local f="$1"
  local base=$(basename "$f")
  # Only truly invisible system junk — auto-clean silently
  [[ "$base" == .DS_Store ]] && return 0
  [[ "$base" == .localized ]] && return 0
  [[ "$base" == *.part ]] && return 0
  [[ "$base" == *.crdownload ]] && return 0
  return 1
}

is_harvestable() {
  local f="$1"
  local base=$(basename "$f")
  # Text files the ingest pipeline can process directly
  [[ "$base" == *.md ]] && return 0
  [[ "$base" == *.txt ]] && return 0
  return 1
}

get_file_category() {
  local f="$1"
  local base=$(basename "$f")
  local ext="${base##*.}"
  ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

  case "$ext" in
    pdf)  echo "document" ;;
    doc|docx|pages|rtf) echo "document" ;;
    xls|xlsx|csv|numbers) echo "data" ;;
    ppt|pptx|key) echo "presentation" ;;
    jpg|jpeg|png|heic|webp) echo "image" ;;
    m4a|mp3|wav|ogg|aac) echo "audio" ;;
    mp4|mov|m4v) echo "video" ;;
    epub|mobi) echo "book" ;;
    zip|tar|gz|rar|7z) echo "archive" ;;
    *) echo "other" ;;
  esac
}

human_size() {
  local bytes=$1
  if [ "$bytes" -gt 1073741824 ]; then
    echo "$(echo "scale=1; $bytes/1073741824" | bc)G"
  elif [ "$bytes" -gt 1048576 ]; then
    echo "$(echo "scale=1; $bytes/1048576" | bc)M"
  elif [ "$bytes" -gt 1024 ]; then
    echo "$(echo "scale=0; $bytes/1024" | bc)K"
  else
    echo "${bytes}B"
  fi
}

# ── Main scan ────────────────────────────────────────────────────

log "=== Downloads harvest started ==="

# Process files (not hidden, not directories initially)
while IFS= read -r -d '' f; do
  base=$(basename "$f")

  # Skip hidden files (except noise check below)
  [[ "$base" == .* ]] && {
    # Silently clean invisible noise
    is_noise "$f" && rm -f "$f" 2>/dev/null && CLEANED+=("$base")
    continue
  }

  # ── SACRED: never touch, never list
  if is_sacred "$f"; then
    log "SACRED: $base"
    continue
  fi

  # ── NOISE: auto-clean (broken downloads, etc.)
  if is_noise "$f"; then
    rm -f "$f" 2>/dev/null && CLEANED+=("$base") && log "NOISE cleaned: $base"
    continue
  fi

  # ── HARVESTABLE: copy to raw/ for ingest, keep original on desk.
  # Record provenance so process-downloads.py recognizes the original as SAVED
  # (by content hash) and trashes it once idle — no vault read needed.
  if is_harvestable "$f"; then
    if cp "$f" "$VAULT/raw/$base" 2>/dev/null; then
      record_download_provenance "$f" "raw/$base"
    fi
    HARVESTED+=("$base")
    log "HARVESTED: $base → raw/ (original stays on desk until verified-saved)"
  fi

  # ── DESK: log everything (including harvested) in manifest for the brief
  local_size=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f" 2>/dev/null)
  local_date=$(stat -f "%Sm" -t "%Y-%m-%d" "$f" 2>/dev/null || stat -c "%y" "$f" 2>/dev/null | cut -d' ' -f1)
  category=$(get_file_category "$f")
  h_size=$(human_size "${local_size:-0}")

  DESK_ITEMS+=("$category|$base|$h_size|$local_date")
  log "DESK: $base ($category, $h_size)"

done < <(find "$DOWNLOADS" -maxdepth 1 -type f -print0 2>/dev/null)

# ── Process directories (shallow scan) ───────────────────────────
while IFS= read -r -d '' d; do
  dir_base=$(basename "$d")
  [[ "$dir_base" == .* ]] && continue
  dir_size=$(timeout 30 du -sh "$d" 2>/dev/null | cut -f1)
  [ -z "$dir_size" ] && dir_size="??"
  file_count=$(timeout 30 find "$d" -type f 2>/dev/null | wc -l | tr -d ' ')
  DESK_ITEMS+=("folder|$dir_base/|$dir_size (${file_count} files)|$(stat -f "%Sm" -t "%Y-%m-%d" "$d" 2>/dev/null)")
  log "DESK folder: $dir_base/ ($dir_size, $file_count files)"
done < <(find "$DOWNLOADS" -maxdepth 1 -type d -not -path "$DOWNLOADS" -print0 2>/dev/null)

# ── Write manifest for the morning brief (READ-ONLY report) ──────
# No approval checkboxes: process-downloads.py already acted (Phase 1). We just
# report its summary + what's still on the desk. The audit trail is the in-vault
# ledger wiki/logs/downloads-trash-YYYY-MM.md.
ACTION_JSON="$STATE_DIR/downloads-last-action.json"
if [ ${#DESK_ITEMS[@]} -gt 0 ] || [ -f "$ACTION_JSON" ]; then
  {
    echo "---"
    echo "type: downloads-manifest"
    echo "date: $TODAY"
    echo "source: harvest-downloads"
    echo "auto_process: true"
    echo "---"
    echo ""
    echo "# Your Desk — $TODAY"
    echo ""
    echo "Downloads is a working directory. Idle and already-saved files move to"
    echo "Trash automatically (recoverable ~30d); fiscal/legal one-way doors are"
    echo "saved to the vault first. Full record: [[wiki/logs/downloads-trash-$(date +%Y-%m)]]."
    echo ""

    # Last night's automatic actions, rendered from the engine's state summary.
    if [ -f "$ACTION_JSON" ]; then
      python3 - "$ACTION_JSON" <<'PY'
import json, sys
try:
    s = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(0)
def sec(title, items, fmt):
    if not items: return
    print(f"## {title}")
    for it in items:
        print(fmt(it))
    print()
sec("Trashed last night (recoverable ~30d)", s.get("trashed", []),
    lambda it: f"- **{it['name']}** — {it.get('reason') or it.get('kind','')}")
sec("Saved to vault & cleared (one-way doors)", s.get("promoted", []),
    lambda it: f"- **{it['name']}** → {it['copy_path']}")
sec("Needs your hand (not auto-handled)", s.get("flagged", []),
    lambda it: f"- **{it['name']}** — {it['reason']}")
aging = s.get("aging", [])
if aging:
    print("## Aging out soon")
    for it in sorted(aging, key=lambda x: x.get("days_left", 99)):
        print(f"- **{it['name']}** — {it['days_left']}d until Trash (idle {it['idle_days']}d)")
    print()
PY
    fi

    if [ ${#DESK_ITEMS[@]} -gt 0 ]; then
      echo "## On the desk now"
      echo ""
      declare -A CATEGORIES
      for entry in "${DESK_ITEMS[@]}"; do
        IFS='|' read -r cat name size date <<< "$entry"
        CATEGORIES["$cat"]+="- $name ($size, $date)\n"
      done
      for cat in document data image audio video book archive folder presentation other; do
        if [ -n "${CATEGORIES[$cat]}" ]; then
          echo "### ${cat^}"
          echo -e "${CATEGORIES[$cat]}"
        fi
      done
    fi
  } > "$MANIFEST"
  log "Manifest written: $MANIFEST"
fi

# ── Summary ──────────────────────────────────────────────────────
echo "Downloads harvest: ${#HARVESTED[@]} harvested, ${#DESK_ITEMS[@]} items on desk, ${#CLEANED[@]} noise cleaned"
log "=== Complete: ${#HARVESTED[@]} harvested, ${#DESK_ITEMS[@]} on desk, ${#CLEANED[@]} noise ==="
heartbeat harvest-downloads ok "${#HARVESTED[@]} harvested, ${#DESK_ITEMS[@]} on desk"

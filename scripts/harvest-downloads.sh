#!/opt/homebrew/bin/bash
# Sanbrain: harvest-downloads
# Treats ~/Downloads as a sensor. Classifies every file, extracts knowledge,
# flags one-way-door files for Santiago's approval before deletion.
#
# Classification:
#   SACRED  — fiscal certs, keys → never touch
#   JUNK    — installers, temp → auto-delete now
#   HARVEST — text files → copy to raw/, auto-delete
#   ONE-WAY — unique docs, photos, audio → log in manifest, ask before deleting
#
# Called by nightly.sh before the 4-skill chain.

export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
SANBRAIN="$HOME/sanbrain"
VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT"
DOWNLOADS="$HOME/Downloads"
TODAY=$(date +%Y-%m-%d)
MANIFEST="$VAULT/raw/downloads-manifest-${TODAY}.md"
LOG="$SANBRAIN/logs/downloads.log"

HARVESTED=()
ONE_WAY_DOORS=()
DELETED=()

log() { echo "$(date +%Y-%m-%dT%H:%M:%S) $1" >> "$LOG"; }

# ── Pre-flight: verify Downloads access ──────────────────────────
if ! ls "$DOWNLOADS" >/dev/null 2>&1; then
  log "=== Downloads harvest SKIPPED: cannot access $DOWNLOADS (FDA not granted) ==="
  echo "Downloads harvest: SKIPPED (no access)"
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

is_junk() {
  local f="$1"
  local base=$(basename "$f")
  # Installers and temp files
  [[ "$base" == *.dmg ]] && return 0
  [[ "$base" == *.pkg ]] && return 0
  [[ "$base" == *.part ]] && return 0
  [[ "$base" == *.crdownload ]] && return 0
  # AI-generated images (ephemeral, re-generable)
  [[ "$base" == Gemini_Generated_Image* ]] && return 0
  [[ "$base" == DALL* ]] && return 0
  # macOS junk
  [[ "$base" == .DS_Store ]] && return 0
  [[ "$base" == .localized ]] && return 0
  return 1
}

is_junk_dir() {
  local d="$1"
  local base=$(basename "$d")
  # Telegram cache (re-downloads from cloud)
  [[ "$base" == "Telegram Desktop" ]] && return 0
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

  # Skip hidden files
  [[ "$base" == .* ]] && continue

  # ── SACRED: never touch
  if is_sacred "$f"; then
    log "SACRED: $base"
    continue
  fi

  # ── JUNK: auto-delete
  if is_junk "$f"; then
    rm -f "$f" 2>/dev/null && DELETED+=("$base") && log "JUNK deleted: $base"
    continue
  fi

  # ── HARVESTABLE: copy to raw/, queue for deletion
  if is_harvestable "$f"; then
    cp "$f" "$VAULT/raw/$base" 2>/dev/null
    HARVESTED+=("$f")
    log "HARVESTED: $base → raw/"
    continue
  fi

  # ── ONE-WAY DOOR: everything else — log in manifest, keep until approved
  local_size=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f" 2>/dev/null)
  local_date=$(stat -f "%Sm" -t "%Y-%m-%d" "$f" 2>/dev/null || stat -c "%y" "$f" 2>/dev/null | cut -d' ' -f1)
  category=$(get_file_category "$f")
  h_size=$(human_size "${local_size:-0}")

  ONE_WAY_DOORS+=("$category|$base|$h_size|$local_date")
  log "ONE-WAY: $base ($category, $h_size)"

done < <(find "$DOWNLOADS" -maxdepth 1 -type f -print0 2>/dev/null)

# ── Process directories (shallow scan) ───────────────────────────
while IFS= read -r -d '' d; do
  dir_base=$(basename "$d")
  [[ "$dir_base" == .* ]] && continue
  # Junk directories
  if is_junk_dir "$d"; then
    rm -rf "$d" 2>/dev/null && DELETED+=("$dir_base/") && log "JUNK dir deleted: $dir_base/"
    continue
  fi
  dir_size=$(timeout 30 du -sh "$d" 2>/dev/null | cut -f1)
  [ -z "$dir_size" ] && dir_size="??"
  file_count=$(timeout 30 find "$d" -type f 2>/dev/null | wc -l | tr -d ' ')
  ONE_WAY_DOORS+=("folder|$dir_base/|$dir_size (${file_count} files)|$(stat -f "%Sm" -t "%Y-%m-%d" "$d" 2>/dev/null)")
  log "ONE-WAY folder: $dir_base/ ($dir_size, $file_count files)"
done < <(find "$DOWNLOADS" -maxdepth 1 -type d -not -path "$DOWNLOADS" -print0 2>/dev/null)

# ── Delete harvested text files ──────────────────────────────────
for f in "${HARVESTED[@]}"; do
  [ -f "$f" ] && rm "$f" && log "Cleaned harvested: $(basename "$f")"
done

# ── Write manifest for the morning brief ─────────────────────────
if [ ${#ONE_WAY_DOORS[@]} -gt 0 ] || [ ${#HARVESTED[@]} -gt 0 ] || [ ${#DELETED[@]} -gt 0 ]; then
  {
    echo "---"
    echo "type: downloads-manifest"
    echo "date: $TODAY"
    echo "source: harvest-downloads"
    echo "auto_process: true"
    echo "---"
    echo ""
    echo "# Downloads Harvest — $TODAY"
    echo ""

    if [ ${#DELETED[@]} -gt 0 ]; then
      echo "## Auto-Deleted (junk)"
      for item in "${DELETED[@]}"; do
        echo "- $item"
      done
      echo ""
    fi

    if [ ${#HARVESTED[@]} -gt 0 ]; then
      echo "## Harvested to raw/ (auto-deleted)"
      for f in "${HARVESTED[@]}"; do
        echo "- $(basename "$f")"
      done
      echo ""
    fi

    if [ ${#ONE_WAY_DOORS[@]} -gt 0 ]; then
      echo "## One-Way Doors (pending approval)"
      echo ""
      echo "These files contain potentially unique data. They stay in Downloads"
      echo "until Santiago confirms they can be deleted. Check items to approve deletion."
      echo ""

      # Group by category
      declare -A CATEGORIES
      for entry in "${ONE_WAY_DOORS[@]}"; do
        IFS='|' read -r cat name size date <<< "$entry"
        CATEGORIES["$cat"]+="- [ ] **$name** ($size, $date)\n"
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
echo "Downloads harvest: ${#DELETED[@]} junk deleted, ${#HARVESTED[@]} harvested, ${#ONE_WAY_DOORS[@]} one-way doors flagged"
log "=== Complete: ${#DELETED[@]} deleted, ${#HARVESTED[@]} harvested, ${#ONE_WAY_DOORS[@]} flagged ==="

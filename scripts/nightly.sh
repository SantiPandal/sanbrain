#!/bin/bash
# Sanbrain: nightly batch
# Runs all 4 processing skills in one claude -p call.
# Single context window means each skill sees what the previous one did.
# Schedule: 10:00 PM daily

export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
CLAUDE="$HOME/.local/bin/claude"
SANBRAIN="$HOME/sanbrain"
VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT"

# Pre-flight: check claude is authenticated
if ! "$CLAUDE" auth status 2>&1 | grep -q '"loggedIn": true'; then
  echo "ERROR: claude not logged in. Run: claude login" >&2
  exit 1
fi

# ── Phase 0: Harvest Downloads ──────────────────────────────────
# Move written content to raw/ for ingest. Then clean junk.
DOWNLOADS="$HOME/Downloads"
HARVESTED=()

# Harvest .md and .txt (knowledge, notes, summaries, research)
for f in "$DOWNLOADS"/*.md "$DOWNLOADS"/*.txt; do
  [ -f "$f" ] || continue
  base=$(basename "$f")
  cp "$f" "$VAULT/raw/$base"
  HARVESTED+=("$f")
  echo "Harvested: $base"
done

# ── Phase 1: Harvest GitHub PRs ──────────────────────────────────
"$SANBRAIN/scripts/harvest-github.sh" >> "$SANBRAIN/logs/nightly.log" 2>&1

# ── Read skill files ────────────────────────────────────────────
CONTEXT=$(cat "$SANBRAIN/CONTEXT.md")
SKILL_INGEST=$(cat "$SANBRAIN/skills/ingest/SKILL.md")
SKILL_EXTRACT=$(cat "$SANBRAIN/skills/claude-extract/SKILL.md")
SKILL_ENTITY=$(cat "$SANBRAIN/skills/entity-update/SKILL.md")
SKILL_CONTEXT=$(cat "$SANBRAIN/skills/context-maintain/SKILL.md")

"$CLAUDE" -p "You are an autonomous skill runner for Santiago's second brain.
The Obsidian vault is at: $VAULT
Read CRITICAL_FACTS.md and SOUL.md from the vault root before starting.
Log all actions to $VAULT/log.md.

# Project Context
$CONTEXT

---

You will execute 4 skills in sequence. Each skill builds on the previous.
Do them in order. Do not skip any.

# SKILL 1: INGEST
$SKILL_INGEST

# SKILL 2: CLAUDE EXTRACT
$SKILL_EXTRACT

# SKILL 3: ENTITY UPDATE
$SKILL_ENTITY

# SKILL 4: CONTEXT MAINTAIN
$SKILL_CONTEXT

---

Execute all 4 skills now, in order: ingest -> claude-extract -> entity-update -> context-maintain.
After each skill, log the completion to log.md before starting the next.
If a skill has nothing to process (e.g., raw/ is empty), log that and move to the next."

# ── Phase 5: Clean Downloads ────────────────────────────────────
# Delete harvested .md/.txt (now in raw/archive/ via ingest)
for f in "${HARVESTED[@]}"; do
  [ -f "$f" ] && rm "$f" && echo "Cleaned: $(basename "$f")"
done

# Delete obvious junk (installers, temp files, generated images)
rm -f "$DOWNLOADS"/*.dmg "$DOWNLOADS"/*.pkg "$DOWNLOADS"/*.part 2>/dev/null

# Delete images older than 3 days (screenshots, generated, etc.)
find "$DOWNLOADS" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.webp" \) -mtime +3 -delete 2>/dev/null

# Delete old PDFs that are NOT fiscal (Acuse*, factura*) — older than 14 days
find "$DOWNLOADS" -maxdepth 1 -type f -name "*.pdf" -mtime +14 \
  ! -name "Acuse*" ! -name "factura*" ! -name "CFDI*" -delete 2>/dev/null

# Delete old zip files older than 14 days
find "$DOWNLOADS" -maxdepth 1 -type f -name "*.zip" -mtime +14 -delete 2>/dev/null

# NEVER touch: .cer, .key, .csv, .p12 (fiscal/crypto credentials)

echo "Downloads cleanup complete: $(ls "$DOWNLOADS" | wc -l | tr -d ' ') files remaining"

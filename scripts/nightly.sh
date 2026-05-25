#!/bin/bash
# Sanbrain: nightly batch
# Runs all 4 processing skills in one claude -p call.
# Single context window means each skill sees what the previous one did.
# Schedule: 10:00 PM daily

export PATH="$HOME/.nvm/versions/node/v23.3.0/bin:$HOME/.local/bin:/opt/homebrew/bin:$PATH"
CLAUDE="$HOME/.local/bin/claude"
SANBRAIN="$HOME/sanbrain"
VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT"

# Pre-flight: check claude is authenticated
if ! "$CLAUDE" auth status 2>&1 | grep -q '"loggedIn": true'; then
  echo "ERROR: claude not logged in. Run: claude login" >&2
  exit 1
fi

# ── Phase 0: Harvest Downloads (sensor) ──────────────────────────
# Classifies files, harvests text to raw/, flags one-way doors for brief
"$SANBRAIN/scripts/harvest-downloads.sh" >> "$SANBRAIN/logs/nightly.log" 2>&1

# ── Phase 1: Harvest GitHub PRs ──────────────────────────────────
"$SANBRAIN/scripts/harvest-github.sh" >> "$SANBRAIN/logs/nightly.log" 2>&1

# ── Phase 2: Process approved deletions from brief ───────────────
# Santiago checks [x] items in the brief to approve Downloads deletion.
# The format is: - [x] **filename** (size, date)
# Only delete if the file actually exists in Downloads (safety check).
DOWNLOADS="$HOME/Downloads"
LATEST_BRIEF=$(ls "$VAULT/wiki/daily/"*-brief.md 2>/dev/null | sort | tail -1)
if [ -n "$LATEST_BRIEF" ]; then
  while IFS= read -r line; do
    # Extract filename between ** markers
    fname=$(echo "$line" | sed -n 's/.*\*\*\([^*]*\)\*\*.*/\1/p')
    if [ -n "$fname" ]; then
      target="$DOWNLOADS/$fname"
      if [ -e "$target" ]; then
        rm -rf "$target" 2>/dev/null
        echo "$(date +%Y-%m-%dT%H:%M:%S) Approved deletion: $fname" >> "$SANBRAIN/logs/downloads.log"
      fi
    fi
  done < <(grep '^\- \[x\] \*\*' "$LATEST_BRIEF" 2>/dev/null)
fi

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
If a skill has nothing to process (e.g., raw/ is empty), log that and move to the next." >> "$SANBRAIN/logs/nightly.log" 2>&1

echo "$(date +%Y-%m-%dT%H:%M:%S) Nightly complete" >> "$SANBRAIN/logs/nightly.log"

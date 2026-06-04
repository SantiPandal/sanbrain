#!/bin/bash
# Sanbrain: nightly batch
# Runs all 4 processing skills in one claude -p call.
# Single context window means each skill sees what the previous one did.
# Schedule: 10:00 PM daily

export PATH="$HOME/.nvm/versions/node/v23.3.0/bin:$HOME/.local/bin:/opt/homebrew/bin:$PATH"
CLAUDE="$HOME/.local/bin/claude"
SANBRAIN="$HOME/sanbrain"
VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT"
LOG="$SANBRAIN/logs/nightly.log"
LOCKFILE="$SANBRAIN/logs/.nightly.lock"
SENTINEL="$SANBRAIN/logs/.nightly-last-success"

ts() { date +%Y-%m-%dT%H:%M:%S; }

# ── Prevent concurrent runs ─────────────────────────────────────
if [ -f "$LOCKFILE" ]; then
  old_pid=$(cat "$LOCKFILE" 2>/dev/null)
  if kill -0 "$old_pid" 2>/dev/null; then
    echo "$(ts) SKIP: nightly already running (PID $old_pid)" >> "$LOG"
    exit 0
  fi
  rm -f "$LOCKFILE"
fi
echo $$ > "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT

# ── Prevent system sleep during run ──────────────────────────────
caffeinate -i -w $$ &

echo "$(ts) ── Nightly started ──" >> "$LOG"

# Pre-flight: check claude is authenticated
if ! "$CLAUDE" auth status 2>&1 | grep -q '"loggedIn": true'; then
  echo "$(ts) ERROR: claude not logged in" >> "$LOG"
  exit 1
fi

# ── Phase 0: Harvest Downloads (sensor) ──────────────────────────
timeout 300 "$SANBRAIN/scripts/harvest-downloads.sh" >> "$LOG" 2>&1
[ $? -eq 124 ] && echo "$(ts) WARN: harvest-downloads timed out (5m)" >> "$LOG"

# ── Phase 1: Harvest GitHub PRs ──────────────────────────────────
timeout 300 "$SANBRAIN/scripts/harvest-github.sh" >> "$LOG" 2>&1
[ $? -eq 124 ] && echo "$(ts) WARN: harvest-github timed out (5m)" >> "$LOG"

# ── Phase 1b: Harvest Voice Recordings ───────────────────────────
timeout 600 "$SANBRAIN/scripts/harvest-recordings.sh" >> "$LOG" 2>&1
[ $? -eq 124 ] && echo "$(ts) WARN: harvest-recordings timed out (10m)" >> "$LOG"

# ── Phase 1c: Harvest OpenClaw Summaries ─────────────────────────
timeout 300 "$SANBRAIN/scripts/harvest-openclaw.sh" >> "$LOG" 2>&1
[ $? -eq 124 ] && echo "$(ts) WARN: harvest-openclaw timed out (5m)" >> "$LOG"

# ── Phase 2: Process approved deletions from brief ───────────────
DOWNLOADS="$HOME/Downloads"
LATEST_BRIEF=$(ls "$VAULT/wiki/daily/"*-brief.md 2>/dev/null | sort | tail -1)
if [ -n "$LATEST_BRIEF" ]; then
  while IFS= read -r line; do
    fname=$(echo "$line" | sed -n 's/.*\*\*\([^*]*\)\*\*.*/\1/p')
    if [ -n "$fname" ]; then
      target="$DOWNLOADS/$fname"
      if [ -e "$target" ]; then
        rm -rf "$target" 2>/dev/null
        echo "$(ts) Approved deletion: $fname" >> "$SANBRAIN/logs/downloads.log"
      fi
    fi
  done < <(grep '^\- \[x\] \*\*' "$LATEST_BRIEF" 2>/dev/null)
fi

# ── Phase 3: 4-skill chain (the big one — 45m timeout) ──────────
CONTEXT=$(cat "$SANBRAIN/CONTEXT.md")
SKILL_INGEST=$(cat "$SANBRAIN/skills/ingest/SKILL.md")
SKILL_EXTRACT=$(cat "$SANBRAIN/skills/claude-extract/SKILL.md")
SKILL_ENTITY=$(cat "$SANBRAIN/skills/entity-update/SKILL.md")
SKILL_CONTEXT=$(cat "$SANBRAIN/skills/context-maintain/SKILL.md")

timeout 2700 "$CLAUDE" -p "You are an autonomous skill runner for Santiago's second brain.
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
If a skill has nothing to process (e.g., raw/ is empty), log that and move to the next." >> "$LOG" 2>&1

CLAUDE_EXIT=$?
if [ $CLAUDE_EXIT -eq 124 ]; then
  echo "$(ts) WARN: 4-skill chain timed out (45m)" >> "$LOG"
elif [ $CLAUDE_EXIT -ne 0 ]; then
  echo "$(ts) WARN: 4-skill chain exited with code $CLAUDE_EXIT" >> "$LOG"
fi

# ── Write completion sentinel ────────────────────────────────────
echo "$(ts)" > "$SENTINEL"
echo "$(ts) ── Nightly complete ──" >> "$LOG"

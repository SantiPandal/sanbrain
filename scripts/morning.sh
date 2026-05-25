#!/bin/bash
# Sanbrain: morning brief
# Creates the daily deliverable Santiago reads every morning.
# Schedule: 7:00 AM daily

export PATH="$HOME/.nvm/versions/node/v23.3.0/bin:$HOME/.local/bin:/opt/homebrew/bin:$PATH"
CLAUDE="$HOME/.local/bin/claude"
SANBRAIN="$HOME/sanbrain"
VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT"
TODAY=$(date +%Y-%m-%d)
BRIEF_FILE="wiki/daily/${TODAY}-brief.md"

# Pre-flight: check claude is authenticated
if ! "$CLAUDE" auth status 2>&1 | grep -q '"loggedIn": true'; then
  echo "ERROR: claude not logged in. Run: claude login" >&2
  exit 1
fi

# ── Phase A: Get today's calendar events ─────────────────────────
TODAY_EVENTS=$("$SANBRAIN/scripts/schedule-reminders.sh" 2>/dev/null)
CALENDAR_CONTEXT=""
if [ -n "$TODAY_EVENTS" ]; then
  CALENDAR_CONTEXT="
# Today's Calendar
The following events are on Santiago's calendar today ($TODAY). Use these
to generate questions in the Questions section (ask about agenda, goals,
or what he needs from each meeting). Telegram reminders have already been
scheduled 10 min before each.

$TODAY_EVENTS"
fi

CONTEXT=$(cat "$SANBRAIN/CONTEXT.md")
SKILL=$(cat "$SANBRAIN/skills/morning-brief/SKILL.md")

"$CLAUDE" -p "You are an autonomous skill runner for Santiago's second brain.
The Obsidian vault is at: $VAULT
Read CRITICAL_FACTS.md and SOUL.md from the vault root before starting.
Log all actions to $VAULT/log.md.

# Project Context
$CONTEXT
$CALENDAR_CONTEXT

---

# Skill to Execute
$SKILL

---

Execute this skill now.
Read SOUL.md for connection synthesis. Read all wiki/context/ files for active threads.
Check log.md for all changes since the last brief.
Write the brief to $VAULT/$BRIEF_FILE." >> "$SANBRAIN/logs/morning.log" 2>&1

# Open the brief in Obsidian after generation
if [ -f "$VAULT/$BRIEF_FILE" ]; then
  open "obsidian://open?vault=VAULT&file=${BRIEF_FILE}"
fi

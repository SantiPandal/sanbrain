#!/bin/bash
# Sanbrain: morning brief
# Creates the daily deliverable Santiago reads every morning.
# New in staged pipeline: lockfile, vault-doctor runs first (mechanical
# health report fed into the brief), vault-git checkpoint after the brief.
# Schedule: 7:00 AM daily

source "$(dirname "$0")/lib.sh"
LOG="$SANBRAIN/logs/morning.log"
LOCKFILE="$SANBRAIN/logs/.morning.lock"
SENTINEL="$SANBRAIN/logs/.nightly-last-success"
TODAY=$(date +%Y-%m-%d)
BRIEF_FILE="wiki/daily/${TODAY}-brief.md"

# ── Prevent concurrent runs ─────────────────────────────────────
if [ -f "$LOCKFILE" ]; then
  old_pid=$(cat "$LOCKFILE" 2>/dev/null)
  if kill -0 "$old_pid" 2>/dev/null; then
    echo "$(ts) SKIP: morning already running (PID $old_pid)" >> "$LOG"
    exit 0
  fi
  rm -f "$LOCKFILE"
fi
echo $$ > "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT

# Prevent system sleep during run
caffeinate -i -w $$ &

# Pre-flight: check claude is authenticated
if ! claude_ok; then
  echo "$(ts) ERROR: claude not logged in" >> "$LOG"
  heartbeat morning error "claude not logged in"
  notify "sanbrain morning brief ABORTED: claude CLI not authenticated."
  exit 1
fi

# ── Recover missed nightly ──────────────────────────────────────
YESTERDAY=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d "yesterday" +%Y-%m-%d)
NIGHTLY_RAN=false
if [ -f "$SENTINEL" ]; then
  last_success=$(cut -dT -f1 "$SENTINEL")
  [ "$last_success" = "$YESTERDAY" ] || [ "$last_success" = "$TODAY" ] && NIGHTLY_RAN=true
fi
if [ "$NIGHTLY_RAN" = false ]; then
  echo "$(ts) Nightly missed — running recovery before brief" >> "$LOG"
  "$SANBRAIN/scripts/nightly.sh"
  echo "$(ts) Nightly recovery complete" >> "$LOG"
fi

# ── Phase A: today's calendar events (also schedules reminders) ──
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

# ── Phase B: vault-doctor (mechanical health, fed into the brief) ──
DOCTOR_SUMMARY=$(python3 "$SANBRAIN/scripts/vault-doctor.py" 2>>"$LOG")
echo "$(ts) $DOCTOR_SUMMARY" >> "$LOG"
DOCTOR_REPORT_FILE="$VAULT/wiki/logs/doctor-${TODAY}.md"
DOCTOR_CONTEXT=""
if [ -f "$DOCTOR_REPORT_FILE" ]; then
  DOCTOR_CONTEXT="
# Vault Doctor Report (mechanical — use these numbers, do not recompute)
$(cat "$DOCTOR_REPORT_FILE")"
fi
heartbeat vault-doctor ok "$DOCTOR_SUMMARY"

CONTEXT=$(cat "$SANBRAIN/CONTEXT.md")
SKILL=$(cat "$SANBRAIN/skills/morning-brief/SKILL.md")

"$CLAUDE" -p "You are an autonomous skill runner for Santiago's second brain.
The Obsidian vault is at: $VAULT
Read CRITICAL_FACTS.md and SOUL.md from the vault root before starting.
Log all actions to $VAULT/log.md.

# Project Context
$CONTEXT
$CALENDAR_CONTEXT
$DOCTOR_CONTEXT

---

# Skill to Execute
$SKILL

---

Execute this skill now.
Read SOUL.md for connection synthesis. Read all wiki/context/ files for active threads.
Check log.md for all changes since the last brief.
Write the brief to $VAULT/$BRIEF_FILE." >> "$LOG" 2>&1

BRIEF_RC=$?
if [ -f "$VAULT/$BRIEF_FILE" ]; then
  heartbeat morning ok "brief written ($BRIEF_FILE)"
else
  heartbeat morning error "brief missing after run (rc=$BRIEF_RC)"
  notify "sanbrain: morning brief FAILED to generate (rc=$BRIEF_RC). See logs/morning.log."
fi

"$SANBRAIN/scripts/vault-git.sh" checkpoint "post-morning-brief" >> "$LOG" 2>&1

# Open the brief in Obsidian after generation
if [ -f "$VAULT/$BRIEF_FILE" ]; then
  open "obsidian://open?vault=VAULT&file=${BRIEF_FILE}"
fi

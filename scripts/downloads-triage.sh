#!/bin/bash
# Sanbrain: downloads-triage
# Runs the downloads-triage skill via `claude -p` to produce an ADVISORY
# proposal classifying ~/Downloads. It writes ONLY the proposal file; it never
# touches Downloads. The deterministic executor (process-downloads.py, nightly
# Phase 1) consumes the proposal, clamps it (crypto/legal can't be downgraded,
# nothing is permanently deleted), and is the only thing that acts.
#
# Why claude and not bash/python here: under launchd, only claude's process tree
# can read the iCloud vault — so the model can answer "is this already captured
# in the vault?" in a way the executor's hash check can't.
#
# Schedule: own launchd job, before the 22:00 nightly. Also runnable by hand.

source "$(dirname "$0")/lib.sh"
LOG="$SANBRAIN/logs/downloads-triage.log"
LOCKFILE="$SANBRAIN/logs/.downloads-triage.lock"
PROPOSAL="$STATE_DIR/downloads-proposal.json"

# ── Prevent concurrent runs ─────────────────────────────────────
if [ -f "$LOCKFILE" ]; then
  old_pid=$(cat "$LOCKFILE" 2>/dev/null)
  if kill -0 "$old_pid" 2>/dev/null; then
    echo "$(ts) SKIP: downloads-triage already running (PID $old_pid)" >> "$LOG"
    exit 0
  fi
  rm -f "$LOCKFILE"
fi
echo $$ > "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT
caffeinate -i -w $$ &

echo "$(ts) ── downloads-triage started ──" >> "$LOG"

# Pre-flight: claude must be authenticated. If not, leave no proposal — the
# nightly executor then runs purely deterministically (safe).
if ! claude_ok; then
  echo "$(ts) SKIP: claude not logged in — executor will run deterministically" >> "$LOG"
  heartbeat downloads-triage skip "claude not logged in"
  exit 0
fi

CONTEXT=$(cat "$SANBRAIN/CONTEXT.md")
SKILL=$(cat "$SANBRAIN/skills/downloads-triage/SKILL.md")

timeout 600 "$CLAUDE" -p "You are an autonomous skill runner for Santiago's second brain.
The Obsidian vault is at: $VAULT
Downloads is at: $HOME/Downloads
PROPOSAL_PATH (write your proposal JSON here, and nowhere else): $PROPOSAL

# Project Context
$CONTEXT

---

# Skill to Execute
$SKILL

---

Execute this skill now. You are an ADVISOR: read ~/Downloads and the vault and
write the proposal JSON to PROPOSAL_PATH. Do NOT move, delete, trash, rename, or
copy any file. The only file you may write is PROPOSAL_PATH." >> "$LOG" 2>&1
rc=$?

if [ $rc -eq 0 ] && [ -f "$PROPOSAL" ]; then
  n=$(python3 -c "import json,sys; print(len(json.load(open('$PROPOSAL')).get('files',[])))" 2>/dev/null || echo "?")
  echo "$(ts) ── proposal written: $n files ──" >> "$LOG"
  heartbeat downloads-triage ok "$n files classified"
  echo "downloads-triage: proposal written ($n files)"
else
  echo "$(ts) WARN: triage run rc=$rc, proposal $( [ -f "$PROPOSAL" ] && echo exists || echo missing )" >> "$LOG"
  heartbeat downloads-triage warn "rc=$rc — executor will fall back to deterministic"
  echo "downloads-triage: no proposal (rc=$rc) — executor runs deterministically"
fi

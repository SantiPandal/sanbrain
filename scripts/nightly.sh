#!/bin/bash
# Sanbrain: nightly batch — STAGED.
# Each skill runs as its own thin `claude -p` call ("read the skill, run it"),
# with a machine-written state checkpoint, a JSON handoff for the next stage,
# and a vault-git checkpoint after every stage. A stage failing loudly no
# longer takes the whole night with it.
#
# Order:
#   0. vault-git checkpoint (pre-run undo point)
#   1. approved deletions (strict parse, before harvest rewrites the manifest)
#   2. sensors: downloads, github, recordings, openclaw (each heartbeats)
#   3. skill stages: ingest -> claude-extract -> entity-update -> context-maintain
#   4. housekeeping: archive stale system files, sentinel, alert on failures
#
# Schedule: 10:00 PM daily

source "$(dirname "$0")/lib.sh"
LOG="$SANBRAIN/logs/nightly.log"
LOCKFILE="$SANBRAIN/logs/.nightly.lock"
SENTINEL="$SANBRAIN/logs/.nightly-last-success"
HANDOFF_DIR="$STATE_DIR/handoffs"
TODAY=$(date +%Y-%m-%d)
mkdir -p "$HANDOFF_DIR"

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
if ! claude_ok; then
  echo "$(ts) ERROR: claude not logged in" >> "$LOG"
  heartbeat nightly error "claude not logged in"
  notify "sanbrain nightly ABORTED: claude CLI not authenticated on the Mac mini."
  exit 1
fi

FAILURES=""

# ── Phase 0: vault-git undo point ────────────────────────────────
"$SANBRAIN/scripts/vault-git.sh" checkpoint "pre-nightly" >> "$LOG" 2>&1 \
  || FAILURES="$FAILURES vault-git"

# ── Phase 1: approved deletions (uses yesterday's manifest + brief,
#     so it must run BEFORE harvest-downloads writes today's manifest) ──
python3 "$SANBRAIN/scripts/process-approved-deletions.py" >> "$LOG" 2>&1 \
  || echo "$(ts) WARN: approved-deletions failed" >> "$LOG"

# ── Phase 2: sensors ─────────────────────────────────────────────
run_sensor() { # name script timeout_s
  local name="$1" script="$2" t="$3"
  timeout "$t" "$SANBRAIN/scripts/$script" >> "$LOG" 2>&1
  local rc=$?
  if [ $rc -eq 124 ]; then
    echo "$(ts) WARN: $name timed out (${t}s)" >> "$LOG"
    heartbeat "$name" error "timed out after ${t}s"
    FAILURES="$FAILURES $name"
  elif [ $rc -ne 0 ]; then
    echo "$(ts) WARN: $name exited $rc" >> "$LOG"
    heartbeat "$name" error "exit code $rc"
    FAILURES="$FAILURES $name"
  fi
  # On success the sensor scripts write their own ok/skip heartbeat.
}

run_sensor harvest-downloads  harvest-downloads.sh  300
run_sensor harvest-github     harvest-github.sh     300
run_sensor harvest-recordings harvest-recordings.sh 1200
run_sensor harvest-openclaw   harvest-openclaw.sh   300

"$SANBRAIN/scripts/vault-git.sh" checkpoint "post-sensors" >> "$LOG" 2>&1

# ── Phase 3: staged skill chain ──────────────────────────────────
CONTEXT=$(cat "$SANBRAIN/CONTEXT.md")

# run_skill <name> <timeout_s> <extra_handoffs_to_pass...>
# Builds a thin prompt: project context + ONE skill + handoffs from earlier
# stages, asks the model to write its own handoff JSON, then checkpoints.
# Retries once on fast failures (<300s — auth/network), never after long runs.
run_skill() {
  local name="$1" t="$2"; shift 2
  local skill_file="$SANBRAIN/skills/$name/SKILL.md"
  local handoff_out="$HANDOFF_DIR/$name.json"
  rm -f "$handoff_out"

  local handoffs=""
  local h
  for h in "$@"; do
    if [ -f "$HANDOFF_DIR/$h.json" ]; then
      handoffs="$handoffs

## Handoff from $h (previous stage tonight)
$(cat "$HANDOFF_DIR/$h.json")"
    else
      handoffs="$handoffs

## Handoff from $h: MISSING (stage may have failed — fall back to the skill's own discovery)"
    fi
  done

  local last_run
  last_run=$(state_get "$name.last")

  local prompt="You are an autonomous skill runner for Santiago's second brain.
The Obsidian vault is at: $VAULT
Read CRITICAL_FACTS.md and SOUL.md from the vault root before starting.
Log all actions to $VAULT/log.md.

# Project Context
$CONTEXT

# State
Last successful $name run (machine-recorded): ${last_run:-never}
$handoffs

---

# Skill to Execute
$(cat "$skill_file")

---

Execute this ONE skill now. Do not execute any other skill — downstream
skills run as separate stages after you and will read your handoff.

When finished, write a handoff file at $handoff_out containing ONLY valid JSON:
{
  \"skill\": \"$name\",
  \"completed_at\": \"ISO timestamp\",
  \"status\": \"ok | partial | nothing-to-do\",
  \"entities_touched\": [\"slug\", ...],
  \"pages_written\": [\"wiki/...\", ...],
  \"context_flags\": [\"business-slug\", ...],
  \"notes\": \"one line on what happened\"
}"

  local attempt start dur rc
  for attempt in 1 2; do
    start=$(date +%s)
    echo "$(ts) [stage:$name] attempt $attempt starting" >> "$LOG"
    timeout "$t" "$CLAUDE" -p "$prompt" >> "$LOG" 2>&1
    rc=$?
    dur=$(( $(date +%s) - start ))
    if [ $rc -eq 0 ]; then
      state_set "$name.last"
      heartbeat "skill-$name" ok "${dur}s, attempt $attempt"
      echo "$(ts) [stage:$name] OK in ${dur}s" >> "$LOG"
      "$SANBRAIN/scripts/vault-git.sh" checkpoint "post-$name" >> "$LOG" 2>&1
      return 0
    fi
    echo "$(ts) [stage:$name] FAILED rc=$rc after ${dur}s (attempt $attempt)" >> "$LOG"
    # Retry only fast failures; a 20-minute run that died is not retryable tonight.
    if [ $rc -eq 124 ] || [ $dur -ge 300 ]; then break; fi
    sleep 30
  done
  heartbeat "skill-$name" error "rc=$rc after ${dur}s"
  FAILURES="$FAILURES $name"
  # Still checkpoint whatever partial writes happened, so they're inspectable.
  "$SANBRAIN/scripts/vault-git.sh" checkpoint "post-$name-FAILED" >> "$LOG" 2>&1
  return 1
}

# Mechanical fast-paths: skip stages with provably nothing to do.
# System files (manifests/reminders) are script-owned and don't count as work.
raw_count=$(find "$VAULT/raw" -maxdepth 1 -type f ! -name ".*" \
  ! -name 'downloads-manifest-*' ! -name 'today-reminders-*' 2>/dev/null | wc -l | tr -d ' ')
RAN_UPSTREAM=false

if [ "$raw_count" -gt 0 ]; then
  RAN_UPSTREAM=true
  run_skill ingest 1500
else
  echo "$(ts) [stage:ingest] skipped — raw/ is empty" >> "$LOG"
  printf '{"skill":"ingest","status":"nothing-to-do","notes":"raw/ empty, skipped mechanically"}\n' \
    > "$HANDOFF_DIR/ingest.json"
  heartbeat skill-ingest skip "raw/ empty"
fi

extract_state="$STATE_DIR/claude-extract.last"
if [ ! -f "$extract_state" ] || [ -n "$(find "$HOME/.claude/projects" -newer "$extract_state" -name '*.jsonl' -print -quit 2>/dev/null)" ]; then
  RAN_UPSTREAM=true
  run_skill claude-extract 1200
else
  echo "$(ts) [stage:claude-extract] skipped — no new sessions since last run" >> "$LOG"
  printf '{"skill":"claude-extract","status":"nothing-to-do","notes":"no sessions modified since last run"}\n' \
    > "$HANDOFF_DIR/claude-extract.json"
  heartbeat skill-claude-extract skip "no new sessions"
fi

# Run downstream stages if any upstream stage actually ran (even a failed
# upstream stage may have written pages — downstream skills have their own
# discovery fallbacks and the handoff tells them what state things are in).
if [ "$RAN_UPSTREAM" = true ]; then
  run_skill entity-update 1200 ingest claude-extract
  run_skill context-maintain 900 ingest claude-extract entity-update
else
  echo "$(ts) [stage:entity-update,context-maintain] skipped — nothing new tonight" >> "$LOG"
  heartbeat skill-entity-update skip "no upstream changes"
  heartbeat skill-context-maintain skip "no upstream changes"
fi

# ── Phase 4: housekeeping ────────────────────────────────────────
# System files (manifests, reminders) are script-owned: ingest never touches
# them; we archive yesterday's mechanically.
for f in "$VAULT/raw/"downloads-manifest-*.md "$VAULT/raw/"today-reminders-*.md; do
  [ -e "$f" ] || continue
  case "$(basename "$f")" in
    *"$TODAY"*) ;; # keep today's
    *) mv "$f" "$VAULT/raw/archive/$(date +%Y%m%d-%H%M%S)-$(basename "$f")" 2>/dev/null \
         && echo "$(ts) Archived system file: $(basename "$f")" >> "$LOG" ;;
  esac
done

"$SANBRAIN/scripts/vault-git.sh" checkpoint "post-nightly" >> "$LOG" 2>&1

if [ -n "$FAILURES" ]; then
  heartbeat nightly warn "failures:$FAILURES"
  notify "sanbrain nightly finished WITH FAILURES:$FAILURES — see logs/nightly.log. Vault checkpoints exist for every stage (scripts/vault-git.sh log)."
else
  heartbeat nightly ok "all stages clean"
fi

echo "$(ts)" > "$SENTINEL"
echo "$(ts) ── Nightly complete (failures:${FAILURES:- none}) ──" >> "$LOG"

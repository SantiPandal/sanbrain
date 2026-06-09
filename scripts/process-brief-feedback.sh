#!/bin/bash
# Sanbrain: process brief feedback
# Runs via cron (midday + evening) or fswatch. Only spends an LLM call when
# the brief actually changed since the last processing — the mtime gate makes
# polling free, so no fswatch daemon is required.
# Lightweight — reads edits, propagates to entities/context. Not the full chain.

source "$(dirname "$0")/lib.sh"
LOG="$SANBRAIN/logs/brief-feedback.log"
TODAY=$(date +%Y-%m-%d)
BRIEF="$VAULT/wiki/daily/${TODAY}-brief.md"

# Only run if today's brief exists
[ -f "$BRIEF" ] || exit 0

# Change gate: skip unless the brief was modified since we last processed it.
brief_mtime=$(stat -f %m "$BRIEF" 2>/dev/null || stat -c %Y "$BRIEF" 2>/dev/null)
last_processed=$(state_get brief-feedback.mtime)
if [ -n "$last_processed" ] && [ "$brief_mtime" = "$last_processed" ]; then
  exit 0
fi

# Debounce: skip if we processed in the last 5 minutes (rapid edit bursts)
LOCK="$SANBRAIN/logs/.brief-feedback-lock"
if [ -f "$LOCK" ]; then
  last=$(stat -f %m "$LOCK" 2>/dev/null || stat -c %Y "$LOCK" 2>/dev/null)
  now=$(date +%s)
  diff=$((now - last))
  [ "$diff" -lt 300 ] && exit 0
fi
touch "$LOCK"

# Pre-flight: check claude is authenticated
if ! claude_ok; then
  echo "ERROR: claude not logged in" >&2
  heartbeat brief-feedback error "claude not logged in"
  exit 1
fi

CONTEXT=$(cat "$SANBRAIN/CONTEXT.md")
BRIEF_CONTENT=$(cat "$BRIEF")

"$CLAUDE" -p "You are processing Santiago's feedback on today's morning brief.
The Obsidian vault is at: $VAULT

# Project Context
$CONTEXT

---

# Today's Brief (with Santiago's edits)
$BRIEF_CONTENT

---

## Your Task

Santiago has edited today's brief. Process his feedback:

1. **Checked items** (\`- [x]\`): These are resolved. Update the relevant entity or context page if the resolution changes compiled truth. For example, if he confirmed a status change, update the entity.

2. **Added comments/text**: Treat as new information. If it contains decisions, entity updates, or context, propagate to the appropriate wiki page.

3. **Answers to questions**: Extract the information and update relevant context files.

4. **Today's Plan entries**: If Santiago wrote what he's doing today, create appropriate timeline entries in entity pages.

## Rules
- Log all changes to $VAULT/log.md with format: \`- YYYY-MM-DDTHH:MM:SS [brief-feedback] action\`
- Use [[wikilinks]] for all entity/concept/project references
- Only update pages where Santiago's input provides NEW information
- Do not rewrite context files (that's context-maintain's job) — only update entity timelines and compiled truth
- Be surgical: small targeted updates, not rewrites" >> "$SANBRAIN/logs/brief-feedback.log" 2>&1

state_set brief-feedback.mtime "$brief_mtime"
"$SANBRAIN/scripts/vault-git.sh" checkpoint "post-brief-feedback" >> "$LOG" 2>&1
heartbeat brief-feedback ok "processed edits to $(basename "$BRIEF")"
echo "$(date +%Y-%m-%dT%H:%M:%S) Brief feedback processed" >> "$SANBRAIN/logs/brief-feedback.log"

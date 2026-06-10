#!/bin/bash
# Sanbrain: evening-debrief
# Nightly elicitation directed at the AI AGENTS, not Santiago — he doesn't
# answer at 9:30 PM (his elicitation point is the morning brief's Questions).
#
# Each OpenClaw agent gets one "Daily Signal" question in its own topic,
# asking for what the verbatim conversation capture CANNOT contain: the xai
# agent's feed distillation (captured nowhere else), judge's verdicts and
# concerns, cross-domain observations, memory-file notes. Re-summarizing
# logged conversations is forbidden (AGENTS.md workflow 4) — that would
# duplicate the verbatim harvest.
#
# Agent replies land in their session logs within minutes and are captured
# by harvest-openclaw at 10 PM (window covers late evening).
# Schedule: 9:30 PM daily (30 min before nightly).

source "$(dirname "$0")/lib.sh"
LOG="$SANBRAIN/logs/reminders.log"
TODAY=$(date +%Y-%m-%d)

SENT=0
FAILS=0

ask() { # thread_id vantage_prompt
  if notify_topic "$1" "Daily Signal $TODAY — reply in this topic with bullets under the heading '## Daily Signal — [your agent name] — $TODAY'.

$2

Rules: NEW signal only — do NOT re-summarize logged conversations (they are captured verbatim every night). Max 10 bullets, specifics with sources beat vibes. If nothing new: reply exactly 'No new signal today.'"
  then SENT=$((SENT + 1)); else FAILS=$((FAILS + 1)); fi
}

ask "$TELEGRAM_THREAD_OPENCLAW" "Your vantage: the whole board. Cross-domain patterns, loose threads, and observations about Santiago's projects or thinking that emerged today but are not explicit in any single conversation."

ask "$TELEGRAM_THREAD_JUDGE" "Your vantage: truth-seeking. Verdicts you rendered today, risks or contradictions you noticed, anything Santiago appears to be fooling himself about."

ask "$TELEGRAM_SANBRAIN_THREAD" "Your vantage: the vault. Anything Santiago asked you to remember today, vault-health observations, and items that should reach tomorrow's morning brief."

ask "$TELEGRAM_THREAD_XAI" "Your vantage: the feed. The 1-3 insights from today's X / SV-thinkers feed worth filing permanently — specific, with source links. The feed is captured nowhere else; your reply is its only path into the brain."

if [ "$FAILS" -gt 0 ]; then
  heartbeat evening-debrief warn "$SENT sent, $FAILS failed"
else
  heartbeat evening-debrief ok "$SENT agent debriefs sent"
fi
log "Evening debrief: $SENT sent, $FAILS failed"

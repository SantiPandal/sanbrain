#!/bin/bash
# Sanbrain: schedule-reminders
# Runs after morning.sh generates the brief. Two jobs:
# 1. Output today's events (stdout) for the brief's Questions section
# 2. Write a reminders file that the sanbrain-admin OpenClaw agent picks up
#
# Reminder delivery: sanbrain-admin reads reminders.md → creates Telegram messages
# at the right times. This avoids the CLI scope-approval requirement.

export PATH="$HOME/.nvm/versions/node/v23.3.0/bin:$HOME/.local/bin:/opt/homebrew/bin:$PATH"
SANBRAIN="$HOME/sanbrain"
VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT"
LOG="$SANBRAIN/logs/reminders.log"
TODAY=$(date +%Y-%m-%d)
CALENDARS='{"Work", "Calendar", "Calendario", "Dansan"}'

log() { echo "$(date +%Y-%m-%dT%H:%M:%S) $1" >> "$LOG"; }

# ── Get today's events via AppleScript ───────────────────────────
EVENTS=$(osascript -e "
set today to current date
set hours of today to 0
set minutes of today to 0
set seconds of today to 0
set tomorrow to today + (1 * days)
set nowDate to current date
set output to \"\"
tell application \"Calendar\"
  repeat with cal in calendars
    set calName to name of cal
    if calName is in $CALENDARS then
      set evts to (every event of cal whose start date ≥ today and start date < tomorrow)
      repeat with e in evts
        set evtName to summary of e
        set evtStart to start date of e
        if evtStart > (nowDate - 30 * minutes) then
          set y to year of evtStart as string
          set m to text -2 thru -1 of (\"0\" & ((month of evtStart) as integer))
          set d to text -2 thru -1 of (\"0\" & (day of evtStart))
          set h to text -2 thru -1 of (\"0\" & (hours of evtStart))
          set mn to text -2 thru -1 of (\"0\" & (minutes of evtStart))
          set s to text -2 thru -1 of (\"0\" & (seconds of evtStart))
          set isoDate to y & \"-\" & m & \"-\" & d & \"T\" & h & \":\" & mn & \":\" & s
          set output to output & isoDate & \"|\" & evtName & \"|\" & calName & linefeed
        end if
      end repeat
    end if
  end repeat
end tell
return output
" 2>/dev/null)

if [ -z "$EVENTS" ]; then
  log "No events today"
  echo ""
  exit 0
fi

log "Found events: $(echo "$EVENTS" | wc -l | tr -d ' ')"

# ── Write reminders file for OpenClaw sanbrain-admin ─────────────
REMINDERS_FILE="$VAULT/raw/today-reminders-${TODAY}.md"
{
  echo "---"
  echo "type: calendar-reminders"
  echo "date: $TODAY"
  echo "generated: $(date +%Y-%m-%dT%H:%M:%S)"
  echo "auto_process: true"
  echo "---"
  echo ""
  echo "# Calendar Reminders for $TODAY"
  echo ""
  echo "Send these as Telegram reminders 10 min before each event."
  echo "Include: event name, time, and prompt to hit record."
  echo ""
} > "$REMINDERS_FILE"

# ── Build brief output + reminders file ──────────────────────────
EVENTS_FOR_BRIEF=""
while IFS='|' read -r iso_time event_name cal_name; do
  [ -z "$iso_time" ] && continue

  time_short=$(echo "$iso_time" | cut -dT -f2 | cut -c1-5)
  EVENTS_FOR_BRIEF="${EVENTS_FOR_BRIEF}- ${time_short} ${event_name}\n"

  # Calculate reminder time (event - 10 min)
  if [[ "$OSTYPE" == "darwin"* ]]; then
    event_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$iso_time" "+%s" 2>/dev/null)
  else
    event_epoch=$(date -d "$iso_time" "+%s" 2>/dev/null)
  fi
  [ -z "$event_epoch" ] && continue

  reminder_epoch=$((event_epoch - 600))
  now_epoch=$(date +%s)

  if [ "$reminder_epoch" -le "$now_epoch" ]; then
    log "Skipped (past): $event_name at $iso_time"
    continue
  fi

  if [[ "$OSTYPE" == "darwin"* ]]; then
    reminder_iso=$(date -j -f "%s" "$reminder_epoch" "+%Y-%m-%dT%H:%M:%S" 2>/dev/null)
  else
    reminder_iso=$(date -d "@$reminder_epoch" "+%Y-%m-%dT%H:%M:%S" 2>/dev/null)
  fi

  echo "- **$time_short $event_name** → remind at $reminder_iso" >> "$REMINDERS_FILE"
  log "Queued reminder: $event_name at $reminder_iso"

done <<< "$EVENTS"

echo "" >> "$REMINDERS_FILE"

# ── Try openclaw cron (may fail if scope not approved) ───────────
OPENCLAW=$(which openclaw 2>/dev/null)
if [ -n "$OPENCLAW" ]; then
  # Clean old sanbrain-remind jobs
  for job_id in $("$OPENCLAW" cron list 2>/dev/null | grep "sanbrain-remind:" | awk '{print $1}'); do
    "$OPENCLAW" cron rm "$job_id" 2>/dev/null && log "Cleaned old: $job_id"
  done

  while IFS='|' read -r iso_time event_name cal_name; do
    [ -z "$iso_time" ] && continue
    if [[ "$OSTYPE" == "darwin"* ]]; then
      event_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$iso_time" "+%s" 2>/dev/null)
    else
      event_epoch=$(date -d "$iso_time" "+%s" 2>/dev/null)
    fi
    [ -z "$event_epoch" ] && continue
    reminder_epoch=$((event_epoch - 600))
    [ "$reminder_epoch" -le "$(date +%s)" ] && continue
    if [[ "$OSTYPE" == "darwin"* ]]; then
      reminder_iso=$(date -j -f "%s" "$reminder_epoch" "+%Y-%m-%dT%H:%M:%S" 2>/dev/null)
    else
      reminder_iso=$(date -d "@$reminder_epoch" "+%Y-%m-%dT%H:%M:%S" 2>/dev/null)
    fi

    "$OPENCLAW" cron add \
      --name "sanbrain-remind: $event_name" \
      --at "$reminder_iso" \
      --tz "America/Mexico_City" \
      --agent sanbrain-admin \
      --session isolated \
      --message "Send a short Telegram reminder: '$event_name' in 10 min. Prompt to record." \
      --announce \
      --channel telegram \
      --delete-after-run \
      --timeout 15000 \
      2>/dev/null && log "Cron created: $event_name" || log "Cron failed (scope?): $event_name — fallback to reminders file"
  done <<< "$EVENTS"
fi

# ── Output events for morning.sh ─────────────────────────────────
echo -e "$EVENTS_FOR_BRIEF"

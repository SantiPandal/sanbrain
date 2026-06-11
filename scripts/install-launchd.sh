#!/bin/bash
# Sanbrain: install/refresh the launchd jobs. Idempotent — safe to re-run
# after every deploy. This is the single source of truth for scheduling
# (the plists in ~/Library/LaunchAgents are generated, never hand-edited).
#
# Why launchd and not cron:
#   - WatchPaths fires the feedback processor within seconds of a brief edit
#     (cron polling would add up to 15 min of latency)
#   - StartCalendarInterval fires missed jobs on wake (cron silently skips
#     when the Mac was asleep)
#
# Jobs:
#   com.sanbrain.morning        07:00 daily  → morning.sh
#   com.sanbrain.nightly        22:00 daily  → nightly.sh
#   com.sanbrain.brief-watcher  on wiki/daily/ change (+30-min backstop)
#                                            → process-brief-feedback.sh

source "$(dirname "$0")/lib.sh"
AGENTS="$HOME/Library/LaunchAgents"
DAILY_DIR="$VAULT/wiki/daily"
UID_N=$(id -u)
PLIST_PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
mkdir -p "$AGENTS"

# write_plist <label> <body-xml>
install_job() {
  local label="$1" body="$2" plist="$AGENTS/$1.plist"
  cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$label</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>$HOME</string>
        <key>USER</key>
        <string>$USER</string>
        <key>LOGNAME</key>
        <string>$USER</string>
        <key>PATH</key>
        <string>$PLIST_PATH</string>
    </dict>
    <key>StandardOutPath</key>
    <string>$SANBRAIN/logs/launchd-$label.log</string>
    <key>StandardErrorPath</key>
    <string>$SANBRAIN/logs/launchd-$label.log</string>
$body
</dict>
</plist>
EOF
  launchctl bootout "gui/$UID_N/$label" 2>/dev/null
  if launchctl bootstrap "gui/$UID_N" "$plist"; then
    echo "installed: $label"
  else
    echo "FAILED to bootstrap: $label" >&2
    return 1
  fi
}

install_job com.sanbrain.morning "    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$SANBRAIN/scripts/morning.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>7</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>"

install_job com.sanbrain.nightly "    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$SANBRAIN/scripts/nightly.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>22</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>"

# Watcher: WatchPaths = instant reaction to edits/recordings; StartInterval =
# backstop for missed events (fires concurrently are collapsed by the PID lock
# + pending flag inside the script). ThrottleInterval keeps Obsidian autosave
# bursts from respawning the job more than once per 2 min.
install_job com.sanbrain.brief-watcher "    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$SANBRAIN/scripts/process-brief-feedback.sh</string>
    </array>
    <key>WatchPaths</key>
    <array>
        <string>$DAILY_DIR</string>
    </array>
    <key>StartInterval</key>
    <integer>1800</integer>
    <key>ThrottleInterval</key>
    <integer>120</integer>
    <key>RunAtLoad</key>
    <false/>"

echo
launchctl list | grep com.sanbrain | awk '{printf "  %s (last exit: %s)\n", $3, $2}'
echo "Done. Verify with: bash $SANBRAIN/scripts/brief-status.sh"

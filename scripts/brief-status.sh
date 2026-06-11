#!/bin/bash
# Sanbrain: brief-status — answer "is the feedback loop working?" in one command.
# Run from a terminal: bash ~/sanbrain/scripts/brief-status.sh
# Read-only. Checks scheduling, permissions, state, recordings, and recent runs.

source "$(dirname "$0")/lib.sh"
TODAY=$(date +%Y-%m-%d)
BRIEF="$VAULT/wiki/daily/${TODAY}-brief.md"

ok()   { printf '  ✅ %s\n' "$1"; }
warn() { printf '  ⚠️  %s\n' "$1"; }
bad()  { printf '  ❌ %s\n' "$1"; }

echo "── sanbrain brief-status — $(date +%Y-%m-%dT%H:%M:%S) ──"

echo "Scheduling (launchd):"
for job in com.sanbrain.morning com.sanbrain.nightly com.sanbrain.brief-watcher; do
  line=$(launchctl list 2>/dev/null | grep "$job")
  if [ -n "$line" ]; then
    rc=$(echo "$line" | awk '{print $2}')
    if [ "$rc" = "0" ] || [ "$rc" = "-" ]; then
      ok "$job loaded (last exit: $rc)"
    else
      bad "$job loaded but last exit code = $rc (check logs)"
    fi
  else
    bad "$job NOT loaded — run scripts/install-launchd.sh"
  fi
done

echo "Secrets:"
if [ -f "$HOME/.sanbrain.env" ]; then
  if [ -n "$OPENAI_API_KEY" ]; then
    ok "~/.sanbrain.env present, OPENAI_API_KEY loaded (Whisper available)"
  else
    bad "~/.sanbrain.env present but OPENAI_API_KEY empty — voice transcription DOWN"
  fi
else
  bad "~/.sanbrain.env missing — voice transcription DOWN"
fi
if claude_ok; then ok "claude CLI authenticated"; else bad "claude CLI NOT authenticated — run 'claude login'"; fi

echo "Permissions (TCC):"
n=$(grep -c "Operation not permitted" "$SANBRAIN/logs/brief-feedback.log" 2>/dev/null); n=${n:-0}
nw=$(grep -c "Operation not permitted" "$SANBRAIN/logs/brief-watcher.log" 2>/dev/null); nw=${nw:-0}
if [ "$((n + nw))" -gt 0 ]; then
  warn "$((n + nw)) 'Operation not permitted' entries in feedback/watcher logs — expected for bash under launchd; content work is routed through claude. Optional fix: System Settings → Privacy & Security → Full Disk Access → add /bin/bash"
else
  ok "no permission errors logged"
fi

echo "Today's brief:"
if [ -f "$BRIEF" ]; then
  bm=$(stat -f %m "$BRIEF" 2>/dev/null || stat -c %Y "$BRIEF" 2>/dev/null)
  lp=$(state_get brief-feedback.mtime)
  ok "exists ($(basename "$BRIEF"), mtime $(date -r "$bm" +%H:%M:%S 2>/dev/null))"
  if [ -z "$lp" ]; then
    warn "never processed yet today"
  elif [ "$bm" = "$lp" ]; then
    ok "fully processed (no edits since last run)"
  else
    warn "has UNPROCESSED changes (edited $(date -r "$bm" +%H:%M:%S 2>/dev/null), last processed state $lp) — watcher should fire shortly"
  fi
  [ -f "$STATE_DIR/brief-feedback.pending" ] && warn "pending flag set (a fire arrived mid-run)"
  if [ -f "$SANBRAIN/logs/.brief-feedback.pid" ]; then
    pid=$(cat "$SANBRAIN/logs/.brief-feedback.pid" 2>/dev/null)
    kill -0 "$pid" 2>/dev/null && warn "a feedback run is in progress RIGHT NOW (PID $pid)" || warn "stale lockfile (PID $pid dead) — next run clears it"
  fi
else
  warn "no brief for today (morning.sh runs at 07:00)"
fi

echo "Voice recordings:"
if [ -x "$SANBRAIN/scripts/transcribe-brief-audio.sh" ]; then
  echo "  $("$SANBRAIN/scripts/transcribe-brief-audio.sh" --status 2>/dev/null)"
else
  warn "transcribe-brief-audio.sh missing"
fi

echo "Voice-memo hotkey (⌘⇧R):"
if grep -q "voice-memo toggle-finish" "$HOME/.config/skhd/skhdrc" 2>/dev/null || grep -q "voice-memo toggle-finish" "$HOME/.skhdrc" 2>/dev/null; then
  pgrep -x skhd >/dev/null && ok "skhd running with ⌘⇧R → voice-memo binding" || bad "binding present but skhd NOT running"
else
  bad "no skhd binding — run scripts/install-voice-memo.sh"
fi
if launchctl list 2>/dev/null | grep -q com.santiago.voice-memo-hotkey; then
  warn "legacy voice-memo-hotkey agent still loaded (crash-loops on Accessibility) — install-voice-memo.sh retires it"
else
  ok "legacy event-tap listener retired"
fi
vm_state=$(cat "$HOME/.voice-memo/state" 2>/dev/null)
if [ -n "$vm_state" ]; then
  vm_pid=$(cat "$HOME/.voice-memo/ffmpeg.pid" 2>/dev/null)
  if [ -n "$vm_pid" ] && kill -0 "$vm_pid" 2>/dev/null; then
    warn "recording IN PROGRESS right now ($vm_state, since $(stat -f %Sm "$HOME/.voice-memo/state" 2>/dev/null))"
  else
    warn "stale voice-memo state ('$vm_state', ffmpeg dead) — next ⌘⇧R press self-heals and processes the orphan"
  fi
else
  ok "recorder idle"
fi
echo "  last voice-memo log lines:"
tail -3 "$HOME/.voice-memo/voice-memo.log" 2>/dev/null | sed 's/^/  | /'

echo "Heartbeat:"
hb="$HEARTBEAT_DIR/brief-feedback.json"
if [ -f "$hb" ]; then
  echo "  $(cat "$hb")"
else
  warn "no heartbeat yet — the new watcher hasn't run (or isn't deployed)"
fi

echo "Last summary sent to Telegram:"
if [ -s "$STATE_DIR/brief-feedback-summary.txt" ]; then
  sed 's/^/  | /' "$STATE_DIR/brief-feedback-summary.txt"
else
  echo "  (none yet)"
fi

echo "Last 5 log lines ($SANBRAIN/logs/brief-feedback.log):"
tail -5 "$SANBRAIN/logs/brief-feedback.log" 2>/dev/null | sed 's/^/  | /'

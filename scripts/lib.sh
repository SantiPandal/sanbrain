# Sanbrain: shared shell library
# Sourced by all scripts. Must stay bash-3.2 compatible (macOS /bin/bash).
#
# Provides: paths, env loading, ts/log, heartbeat, notify, claude_ok.
# Scripts move bytes. This file is where the byte-moving conventions live.

SANBRAIN="${SANBRAIN:-$HOME/sanbrain}"
VAULT="${VAULT:-$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT}"
STATE_DIR="${STATE_DIR:-$SANBRAIN/.state}"
HEARTBEAT_DIR="$STATE_DIR/heartbeats"
CLAUDE="${CLAUDE:-$HOME/.local/bin/claude}"

# Telegram routing (San group, sanbrain topic) — override in ~/.sanbrain.env
TELEGRAM_GROUP="${TELEGRAM_GROUP:--1003637114912}"
TELEGRAM_SANBRAIN_THREAD="${TELEGRAM_SANBRAIN_THREAD:-34}"

# Secrets and machine-specific overrides live in ~/.sanbrain.env (chmod 600),
# NOT in .zshrc — cron shells don't reliably read interactive rc files.
[ -f "$HOME/.sanbrain.env" ] && . "$HOME/.sanbrain.env"

# PATH: homebrew, local bins, plus any nvm node (no pinned version)
PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
for _nvm_bin in "$HOME/.nvm/versions/node"/*/bin; do
  [ -d "$_nvm_bin" ] && PATH="$_nvm_bin:$PATH"
done
export PATH

mkdir -p "$SANBRAIN/logs" "$STATE_DIR" "$HEARTBEAT_DIR"

ts() { date +%Y-%m-%dT%H:%M:%S; }

# log "message" — appends to $LOG (caller sets LOG, falls back to sanbrain.log)
log() { echo "$(ts) $1" >> "${LOG:-$SANBRAIN/logs/sanbrain.log}"; }

# heartbeat <name> <ok|warn|error|skip> [detail]
# Single-line JSON per sensor/job. vault-doctor reads these to surface
# sensor health in the morning brief. A sensor that never beats is the
# failure mode this exists to catch.
heartbeat() {
  local name="$1" status="$2" detail="${3:-}"
  local now last_success=""
  now=$(ts)
  if [ "$status" = "ok" ]; then
    last_success="$now"
  else
    last_success=$(sed -n 's/.*"last_success":"\([^"]*\)".*/\1/p' \
      "$HEARTBEAT_DIR/$name.json" 2>/dev/null | head -1)
  fi
  detail=$(printf '%s' "$detail" | tr '"' "'" | tr '\n' ' ' | cut -c1-300)
  printf '{"sensor":"%s","last_run":"%s","last_success":"%s","status":"%s","detail":"%s"}\n' \
    "$name" "$now" "$last_success" "$status" "$detail" > "$HEARTBEAT_DIR/$name.json"
}

# notify "message" — best-effort push to Santiago (Telegram via openclaw).
# Loud on failure, silent on success. Never blocks the pipeline.
notify() {
  local msg="$1" oc
  oc=$(command -v openclaw 2>/dev/null) || { log "NOTIFY (openclaw unavailable): $msg"; return 0; }
  timeout 20 "$oc" message send --channel telegram \
    --target "$TELEGRAM_GROUP" --thread-id "$TELEGRAM_SANBRAIN_THREAD" \
    --message "$msg" >/dev/null 2>&1 || log "NOTIFY failed: $msg"
}

# claude_ok — pre-flight auth check
claude_ok() {
  "$CLAUDE" auth status 2>&1 | grep -q '"loggedIn": true'
}

# state_get/state_set <key> — machine-written checkpoints (ISO timestamps).
# Skills read these instead of grepping prose out of log.md.
state_get() { cat "$STATE_DIR/$1" 2>/dev/null; }
state_set() { printf '%s\n' "${2:-$(ts)}" > "$STATE_DIR/$1"; }

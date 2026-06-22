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
# SANBRAIN_NO_NOTIFY=1 suppresses sends (tests/dry runs) — message goes to log.
# Empty TELEGRAM_SANBRAIN_THREAD = DM target (no topic threads in DMs).
# Errors are captured to the log — "failed silently" is not a thing here.
notify() {
  local msg="$1" oc
  [ -n "$SANBRAIN_NO_NOTIFY" ] && { log "NOTIFY (suppressed): $msg"; return 0; }
  oc=$(command -v openclaw 2>/dev/null) || { log "NOTIFY (openclaw unavailable): $msg"; return 0; }
  local args=(message send --channel telegram --target "$TELEGRAM_GROUP" --message "$msg")
  [ -n "$TELEGRAM_SANBRAIN_THREAD" ] && args+=(--thread-id "$TELEGRAM_SANBRAIN_THREAD")
  timeout 20 "$oc" "${args[@]}" >/dev/null 2>>"${LOG:-$SANBRAIN/logs/sanbrain.log}" \
    || log "NOTIFY failed: $msg"
}

# notify_once <key> <message> — like notify, but at most once per day per key.
# For persistent error conditions checked on every poll (missing API key,
# broken permissions): alert daily, don't spam every few minutes.
notify_once() {
  local key="$1" msg="$2" marker
  marker="$STATE_DIR/notified-$key"
  [ "$(cat "$marker" 2>/dev/null)" = "$(date +%Y-%m-%d)" ] && return 0
  date +%Y-%m-%d > "$marker"
  notify "$msg"
}

# claude_ok — pre-flight auth check
claude_ok() {
  "$CLAUDE" auth status 2>&1 | grep -q '"loggedIn": true'
}

# whisper_file <audio_path> — transcribe via OpenAI Whisper, transcript on
# stdout. Requires OPENAI_API_KEY (from ~/.sanbrain.env). Empty stdout means
# failure; errors land in $LOG. Caller handles the 25MB API limit (chunking
# lives in harvest-recordings.sh, the only place long recordings arrive).
whisper_file() {
  python3 -c "
from openai import OpenAI
import sys
client = OpenAI()
with open(sys.argv[1], 'rb') as f:
    text = client.audio.transcriptions.create(model='whisper-1', file=f, response_format='text')
print(text, end='')
" "$1" 2>>"${LOG:-$SANBRAIN/logs/sanbrain.log}"
}

# state_get/state_set <key> — machine-written checkpoints (ISO timestamps).
# Skills read these instead of grepping prose out of log.md.
state_get() { cat "$STATE_DIR/$1" 2>/dev/null; }
state_set() { printf '%s\n' "${2:-$(ts)}" > "$STATE_DIR/$1"; }

# record_download_provenance <source_abs> <copy_rel> — note that a Downloads
# file's content is now durably copied into the vault, so process-downloads.py
# can recognize it as SAVED (keyed by sha256) and trash the desk original once
# idle — even under launchd, where it can't read the iCloud vault to verify.
# Local-only write (~/sanbrain/.state); python does robust hashing + JSON.
record_download_provenance() {
  python3 - "$1" "$2" "$STATE_DIR/downloads-provenance.jsonl" <<'PY' 2>/dev/null
import datetime, hashlib, json, os, sys
src, copy_rel, ledger = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    h = hashlib.sha256()
    with open(src, "rb") as f:
        for c in iter(lambda: f.read(1 << 20), b""):
            h.update(c)
    sha = h.hexdigest()
    if sha == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855":
        sys.exit(0)  # empty file is never proof of a save
    os.makedirs(os.path.dirname(ledger), exist_ok=True)
    rec = {"ts": datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S"),
           "source_name": os.path.basename(src), "source_sha256": sha,
           "size": os.path.getsize(src), "copy_path": copy_rel,
           "copy_sha256": sha, "origin": "harvest"}
    with open(ledger, "a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")
except Exception:
    sys.exit(0)
PY
}

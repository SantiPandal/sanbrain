#!/bin/bash
# Sanbrain: install brief report style + voice recording into the vault's
# Obsidian config. Idempotent — called best-effort by morning.sh each run,
# so a CSS change in the repo reaches the vault the next morning.
#
# Does two things, each only if needed:
#   1. Copies templates/brief.css → .obsidian/snippets/sanbrain-brief.css
#   2. Enables the snippet (appearance.json) and the audio-recorder core
#      plugin (core-plugins.json — handles both list and dict formats)
#
# NOTE: ⌘⇧R is deliberately NOT bound inside Obsidian — it's the GLOBAL
# voice-memo hotkey (skhd → scripts/voice-memo, see install-voice-memo.sh),
# which skhd intercepts before Obsidian would ever see it. The Obsidian
# audio recorder stays enabled for embed-in-note recording via the command
# palette. This installer also removes the ⌘⇧R binding an earlier version
# added, to keep one gesture = one meaning.
#
# Caveat: Obsidian rewrites these JSON files when its settings UI is used,
# so a manual change in-app wins until the next morning run.

source "$(dirname "$0")/lib.sh"
LOG="${LOG:-$SANBRAIN/logs/morning.log}"

OBSIDIAN_DIR="$VAULT/.obsidian"
SRC="$SANBRAIN/templates/brief.css"
DEST="$OBSIDIAN_DIR/snippets/sanbrain-brief.css"

if [ ! -d "$OBSIDIAN_DIR" ]; then
  log "install-brief-style: SKIPPED — $OBSIDIAN_DIR not found"
  exit 0
fi
if [ ! -f "$SRC" ]; then
  log "install-brief-style: SKIPPED — $SRC not found"
  exit 0
fi

mkdir -p "$OBSIDIAN_DIR/snippets"
if ! cmp -s "$SRC" "$DEST"; then
  cp "$SRC" "$DEST"
  log "install-brief-style: snippet updated ($DEST)"
fi

python3 - "$OBSIDIAN_DIR" <<'PY' 2>>"$LOG"
import json, os, sys

cfg = sys.argv[1]

def edit(name, fn, default):
    path = os.path.join(cfg, name)
    data = default
    if os.path.exists(path):
        try:
            with open(path) as f:
                data = json.load(f)
        except ValueError:
            return  # malformed — leave it alone
    out = fn(data)
    if out is not None:
        with open(path, "w") as f:
            json.dump(out, f, indent=2)
        print(f"install-brief-style: updated {name}")

def appearance(d):
    snips = d.get("enabledCssSnippets", [])
    if "sanbrain-brief" in snips:
        return None
    d["enabledCssSnippets"] = snips + ["sanbrain-brief"]
    return d

def core_plugins(d):
    # Newer Obsidian: {"plugin-id": bool}; older: ["plugin-id", ...]
    if isinstance(d, list):
        if "audio-recorder" in d:
            return None
        return d + ["audio-recorder"]
    if d.get("audio-recorder") is True:
        return None
    d["audio-recorder"] = True
    return d

def hotkeys(d):
    # Remove the ⌘⇧R audio-recorder binding an earlier installer added:
    # ⌘⇧R is the GLOBAL voice-memo hotkey now (skhd), and a shadowed
    # in-app binding is a surprise waiting for the day skhd is off.
    binding = [{"modifiers": ["Mod", "Shift"], "key": "R"}]
    changed = False
    for cmd in ("audio-recorder:start", "audio-recorder:stop"):
        if d.get(cmd) == binding:
            del d[cmd]
            changed = True
    return d if changed else None

edit("appearance.json", appearance, {})
edit("core-plugins.json", core_plugins, {})
edit("hotkeys.json", hotkeys, {})
PY

exit 0

#!/bin/bash
# Sanbrain: install/refresh the voice-memo hotkey system. Idempotent —
# called by morning.sh each run, so script updates deploy themselves.
#
# 1. Copies scripts/voice-memo → ~/.local/bin/voice-memo (stable path,
#    independent of ~/sanbrain deploy state; old version backed up once)
# 2. Ensures the skhd binding: ⌘⇧R → voice-memo toggle-finish.
#    skhd already runs with Accessibility permission — no custom event-tap
#    binary, no separate TCC grant to lose.
# 3. Decommissions the legacy com.santiago.voice-memo-hotkey launchd agent
#    (a compiled F14 listener that lost Accessibility and crash-looped).

source "$(dirname "$0")/lib.sh"
LOG="${LOG:-$SANBRAIN/logs/morning.log}"

SRC="$SANBRAIN/scripts/voice-memo"
DEST="$HOME/.local/bin/voice-memo"
SKHDRC="$HOME/.config/skhd/skhdrc"
[ -f "$SKHDRC" ] || SKHDRC="$HOME/.skhdrc"
BINDING='cmd + shift - r : /bin/bash $HOME/.local/bin/voice-memo toggle-finish'

[ -f "$SRC" ] || { log "install-voice-memo: SKIPPED — $SRC not found"; exit 0; }

# 1. Install the script
mkdir -p "$HOME/.local/bin"
if [ -f "$DEST" ] && [ ! -f "$DEST.pre-sanbrain" ] && ! cmp -s "$SRC" "$DEST"; then
  cp "$DEST" "$DEST.pre-sanbrain"   # one-time backup of the original
fi
if ! cmp -s "$SRC" "$DEST"; then
  cp "$SRC" "$DEST" && chmod +x "$DEST"
  log "install-voice-memo: script updated ($DEST)"
fi

# 1b. Compile the menu bar indicator (🔴 m:ss while recording) when the
# Swift source is newer than the installed binary. Needs Xcode CLT swiftc;
# without it the recorder still works, just with banner-only feedback.
MB_SRC="$SANBRAIN/scripts/voice-memo-menubar.swift"
MB_BIN="$HOME/.local/bin/voice-memo-menubar"
if [ -f "$MB_SRC" ] && command -v swiftc >/dev/null 2>&1; then
  if [ ! -x "$MB_BIN" ] || [ "$MB_SRC" -nt "$MB_BIN" ]; then
    if swiftc -O -o "$MB_BIN" "$MB_SRC" 2>>"$LOG"; then
      log "install-voice-memo: menu bar indicator compiled ($MB_BIN)"
    else
      log "install-voice-memo: GAP — swiftc failed for menu bar indicator (see log)"
    fi
  fi
fi

# 2. skhd binding (append once; skhd expands $HOME via sh)
if [ -f "$SKHDRC" ]; then
  if ! grep -q "voice-memo toggle-finish" "$SKHDRC"; then
    {
      echo ""
      echo "# Voice memo: press to record, press to finish (sanbrain install-voice-memo.sh)"
      echo "$BINDING"
    } >> "$SKHDRC"
    log "install-voice-memo: skhd binding added (cmd+shift-r)"
  fi
  pgrep -x skhd >/dev/null && skhd --reload 2>/dev/null
else
  log "install-voice-memo: GAP — no skhd config found; hotkey not bound"
fi

# 3. Retire the legacy crash-looping listener
LEGACY="$HOME/Library/LaunchAgents/com.santiago.voice-memo-hotkey.plist"
if [ -f "$LEGACY" ]; then
  launchctl bootout "gui/$(id -u)/com.santiago.voice-memo-hotkey" 2>/dev/null
  mv "$LEGACY" "$LEGACY.disabled"
  log "install-voice-memo: legacy voice-memo-hotkey agent unloaded and disabled"
fi

exit 0

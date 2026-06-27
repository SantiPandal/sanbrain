#!/bin/bash
# Install/update the wa-capture daemon as a launchd job.
#
# Nothing else to install: sanbrain ingests raw/ via its nightly job, and
# taxbrain ingests ~/Downloads via its existing com.taxfreebrain.watch.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
RUNTIME="${WA_CAPTURE_RUNTIME:-$HOME/wa-capture}"
LA="$HOME/Library/LaunchAgents"

mkdir -p "$RUNTIME" "$RUNTIME/launchd" "$LA"
cp "$SRC/daemon.mjs" "$RUNTIME/daemon.mjs"
cp "$SRC/package.json" "$RUNTIME/package.json"
cp "$SRC/package-lock.json" "$RUNTIME/package-lock.json"
cp "$SRC/README.md" "$RUNTIME/README.md"
cp "$SRC/.gitignore" "$RUNTIME/.gitignore"
cp "$SRC/install-launchd.sh" "$RUNTIME/install-launchd.sh"
cp "$SRC/launchd/com.wacapture.daemon.plist" "$RUNTIME/launchd/com.wacapture.daemon.plist"
chmod +x "$RUNTIME/install-launchd.sh"

cd "$RUNTIME"
npm install

mkdir -p "$LA"
cp "$RUNTIME/launchd/com.wacapture.daemon.plist" "$LA/com.wacapture.daemon.plist"
launchctl unload "$LA/com.wacapture.daemon.plist" 2>/dev/null || true
launchctl load -w "$LA/com.wacapture.daemon.plist"
echo "loaded com.wacapture.daemon"
launchctl list | grep wacapture || echo "(not listed yet — check run/daemon.err.log)"

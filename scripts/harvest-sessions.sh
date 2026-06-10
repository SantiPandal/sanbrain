#!/bin/bash
# Sanbrain: harvest-sessions
# Delivers self-filed summaries from remote Claude Code sessions (sessions/
# in this repo) to VAULT/raw/ for ingest. Remote web/mobile sessions push
# summaries to claude/* branches per the CLAUDE.md contract; this reads
# sessions/ across ALL remote branches via git plumbing — no merge needed,
# no working-tree mutation, no mid-run code changes.
#
# Called by nightly.sh before the skill chain.

source "$(dirname "$0")/lib.sh"
LOG="$SANBRAIN/logs/sessions.log"
DELIVERED_LIST="$STATE_DIR/delivered-sessions.list"
touch "$DELIVERED_LIST"

if ! git -C "$SANBRAIN" rev-parse --git-dir >/dev/null 2>&1; then
  log "=== Sessions harvest SKIPPED: $SANBRAIN is not a git repo ==="
  echo "Sessions harvest: SKIPPED (not a git repo)"
  heartbeat harvest-sessions skip "sanbrain not a git repo"
  exit 0
fi

if ! git -C "$SANBRAIN" fetch origin '+refs/heads/*:refs/remotes/origin/*' --quiet 2>>"$LOG"; then
  log "=== Sessions harvest: git fetch failed (offline?) — using last known refs ==="
  heartbeat harvest-sessions warn "git fetch failed; used cached refs"
fi

DELIVERED=0
SEEN=" "

# master first so its version of a file wins over branch copies
REFS="refs/remotes/origin/master"
for r in $(git -C "$SANBRAIN" for-each-ref 'refs/remotes/origin/claude/*' --format='%(refname)' 2>/dev/null); do
  REFS="$REFS $r"
done

for ref in $REFS; do
  git -C "$SANBRAIN" rev-parse --verify "$ref" >/dev/null 2>&1 || continue
  for path in $(git -C "$SANBRAIN" ls-tree -r --name-only "$ref" -- sessions/ 2>/dev/null); do
    case "$path" in
      *.md) ;;
      *) continue ;;
    esac
    base=$(basename "$path")
    [ "$base" = "README.md" ] && continue
    # Contract: kebab-case, no spaces. Skip anything weird rather than mangle it.
    case "$base" in
      *" "*) log "SKIP (space in filename, violates contract): $path"; continue ;;
    esac
    case "$SEEN" in *" $base "*) continue ;; esac
    SEEN="$SEEN$base "
    grep -qxF "$base" "$DELIVERED_LIST" && continue

    target="$VAULT/raw/session-$base"
    if git -C "$SANBRAIN" show "$ref:$path" > "$target" 2>>"$LOG" && [ -s "$target" ]; then
      echo "$base" >> "$DELIVERED_LIST"
      DELIVERED=$((DELIVERED + 1))
      log "Delivered: $path (from ${ref#refs/remotes/}) → raw/session-$base"
    else
      rm -f "$target"
      log "FAIL extracting $ref:$path"
    fi
  done
done

echo "Sessions harvest: $DELIVERED delivered to raw/"
log "=== Complete: $DELIVERED delivered ==="
heartbeat harvest-sessions ok "$DELIVERED delivered"

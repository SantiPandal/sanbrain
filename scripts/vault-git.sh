#!/bin/bash
# Sanbrain: vault-git
# Versions the Obsidian vault so every LLM write session is one revert away
# from undo. The git dir lives OUTSIDE iCloud (~/.sanbrain-vault.git) so no
# git internals sync to the cloud and nothing is added inside the vault —
# excludes live in $GITDIR/info/exclude, not in a .gitignore in the vault.
#
# Usage:
#   vault-git.sh init                  # idempotent setup
#   vault-git.sh checkpoint <label>    # commit current vault state (if changed)
#   vault-git.sh log [n]               # recent checkpoints
#
# Safety: checkpoint refuses to commit mass deletions (>20% of tracked files
# gone) — that pattern means iCloud eviction or sync damage, not real edits.

source "$(dirname "$0")/lib.sh"
LOG="$SANBRAIN/logs/vault-git.log"
GITDIR="${VAULT_GIT_DIR:-$HOME/.sanbrain-vault.git}"

GIT() { git --git-dir="$GITDIR" --work-tree="$VAULT" "$@"; }

cmd_init() {
  if [ ! -d "$VAULT" ]; then
    log "ERROR: vault not found at $VAULT"
    echo "vault-git: vault not found" >&2
    return 1
  fi
  if [ ! -d "$GITDIR" ]; then
    git --git-dir="$GITDIR" init -q
    log "Initialized $GITDIR"
  fi
  GIT config core.worktree "$VAULT"
  GIT config user.name "sanbrain"
  GIT config user.email "sanbrain@localhost"
  GIT config commit.gpgsign false
  # Noise + things that must never enter history. PDFs stay out per the
  # wiki-books policy; .icloud placeholders are evicted-file stubs.
  cat > "$GITDIR/info/exclude" <<'EOF'
.DS_Store
.obsidian/
.trash/
*.icloud
books-pdf/
EOF
  # First commit if the repo is empty
  if ! GIT rev-parse HEAD >/dev/null 2>&1; then
    GIT add -A
    GIT commit -qm "vault-git: initial snapshot @ $(ts)" || true
    log "Initial snapshot committed"
  fi
}

cmd_checkpoint() {
  local label="${1:-checkpoint}"
  cmd_init || return 1

  # Eviction guard: a wave of deletions is almost never real editing.
  local tracked deleted
  tracked=$(GIT ls-files | wc -l | tr -d ' ')
  deleted=$(GIT status --porcelain | grep -c '^.D\|^D')
  if [ "$tracked" -gt 50 ] && [ $((deleted * 5)) -gt "$tracked" ]; then
    log "ERROR: checkpoint '$label' refused — $deleted of $tracked tracked files deleted (iCloud eviction?)"
    heartbeat vault-git error "checkpoint refused: $deleted/$tracked files deleted"
    echo "vault-git: REFUSED checkpoint '$label' — $deleted/$tracked files deleted" >&2
    return 2
  fi

  GIT add -A
  if GIT diff --cached --quiet; then
    log "checkpoint '$label': no changes"
    heartbeat vault-git ok "no changes ($label)"
    return 0
  fi
  GIT commit -qm "$label @ $(ts)"
  local changed
  changed=$(GIT show --stat --oneline HEAD | tail -1)
  log "checkpoint '$label': $changed"
  heartbeat vault-git ok "$label: $changed"
}

cmd_log() {
  GIT log --oneline -"${1:-15}"
}

case "${1:-}" in
  init)       cmd_init ;;
  checkpoint) cmd_checkpoint "${2:-checkpoint}" ;;
  log)        cmd_log "${2:-15}" ;;
  *) echo "usage: vault-git.sh init | checkpoint <label> | log [n]" >&2; exit 1 ;;
esac

#!/usr/bin/env bash
# install-claw.sh — wire the claw CLI into every LLM harness on this machine.
#
# Idempotent. Creates:
#   ~/.local/bin/claw                 -> scripts/claw            (any shell / any harness)
#   ~/.claude/skills/claw             -> .claude/skills/claw     (Claude Code, global)
#   ~/.codex/skills/claw              -> .claude/skills/claw     (Codex CLI, if installed)
#   ~/.claude/CLAUDE.md               += marker-guarded claw block (guaranteed injection
#                                        every Claude session — skill descriptions can be
#                                        dropped when the skill-listing budget overflows)
#
# Run from the canonical clone (~/sanbrain). Conductor workspaces are ephemeral, so
# installing from one is refused unless you pass --force.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "$REPO" == */conductor/workspaces/* && "${1:-}" != "--force" ]]; then
  echo "Refusing: $REPO is a Conductor workspace (ephemeral — symlinks would break when it's archived)." >&2
  echo "Run from ~/sanbrain after merging, or pass --force to install from here anyway." >&2
  exit 1
fi

mkdir -p "$HOME/.local/bin"
ln -sfn "$REPO/scripts/claw" "$HOME/.local/bin/claw"
echo "✓ $HOME/.local/bin/claw -> $REPO/scripts/claw"

link_skill() {
  local dst="$1"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    local bak="${dst}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dst" "$bak"
    echo "  (existing $dst moved to $bak)"
  fi
  ln -sfn "$REPO/.claude/skills/claw" "$dst"
  echo "✓ $dst -> $REPO/.claude/skills/claw"
}

link_skill "$HOME/.claude/skills/claw"
[ -d "$HOME/.codex" ] && link_skill "$HOME/.codex/skills/claw"

python3 - "$HOME/.claude/CLAUDE.md" <<'PY'
import pathlib, re, sys

p = pathlib.Path(sys.argv[1])
p.parent.mkdir(parents=True, exist_ok=True)
block = """<!-- claw:start -->
## Consult the claws (OpenClaw agents) — standing rule
Four always-on brain agents with their own memory + vault access are one shell call away: `claw <judge|xai|sanbrain|openclaw|all> "<question>"` (30–120s per turn — set long command timeouts; `claw --list` for routing, `--tg` to mirror to Telegram). judge = verdicts/reality checks, xai = product/eng/leverage, sanbrain = vault/people/history, openclaw = dot-connecting.
Before forming a strong opinion, recommendation, or go/no-go about a person, business, deal, project, or architecture: check whether a claw holds context you don't. If a named person/project is involved, run `claw sanbrain "qué sabemos de X"` first; before a high-stakes verdict, run `claw judge`. Never guess what's in the vault — ask it. Skip only for trivial or purely mechanical tasks.
<!-- claw:end -->"""
text = p.read_text() if p.exists() else ""
if "<!-- claw:start -->" in text:
    text = re.sub(r"<!-- claw:start -->.*?<!-- claw:end -->", block, text, flags=re.S)
else:
    text = (text.rstrip() + "\n\n" if text.strip() else "") + block + "\n"
p.write_text(text)
print(f"✓ claw block in {p}")
PY

echo
echo "Smoke test:"
"$HOME/.local/bin/claw" --doctor

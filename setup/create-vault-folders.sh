#!/bin/bash
# Create Sanbrain folder structure in an existing Obsidian vault.
# Usage: ./create-vault-folders.sh /path/to/your/vault

VAULT_PATH="${1:?Usage: $0 /path/to/your/obsidian/vault}"

if [ ! -d "$VAULT_PATH" ]; then
  echo "Error: $VAULT_PATH does not exist"
  exit 1
fi

echo "Creating Sanbrain folders in: $VAULT_PATH"

mkdir -p "$VAULT_PATH/raw/archive"
mkdir -p "$VAULT_PATH/wiki/entities"
mkdir -p "$VAULT_PATH/wiki/concepts"
mkdir -p "$VAULT_PATH/wiki/projects"
mkdir -p "$VAULT_PATH/wiki/context"
mkdir -p "$VAULT_PATH/wiki/daily"
mkdir -p "$VAULT_PATH/wiki/logs"
mkdir -p "$VAULT_PATH/wiki/reviews"
mkdir -p "$VAULT_PATH/boards"
mkdir -p "$VAULT_PATH/templates"

echo "Done. Folders created:"
echo "  raw/              — drop zone for new material"
echo "  raw/archive/      — processed originals (timestamped)"
echo "  wiki/entities/    — people + businesses (compiled truth + timeline)"
echo "  wiki/concepts/    — mental models, frameworks, ideas"
echo "  wiki/projects/    — active project tracking"
echo "  wiki/context/     — living 'what's true now' per business"
echo "  wiki/daily/       — daily briefs + ingestion logs"
echo "  wiki/logs/        — skill run logs"
echo "  wiki/reviews/     — periodic reviews"
echo "  boards/           — kanban boards"
echo "  templates/        — page templates"
echo ""
echo "Next steps:"
echo "  1. Ensure SOUL.md and personality.md exist in vault root"
echo "  2. Write _CLAUDE.md, CRITICAL_FACTS.md, index.md, log.md"
echo "  3. Install crontab: crontab ~/sanbrain/crontab.example"

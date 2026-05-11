#!/bin/bash
# Create Sanbrain folder structure in an existing Obsidian vault.
# Usage: ./create-vault-folders.sh /path/to/your/vault

VAULT_PATH="${1:?Usage: $0 /path/to/your/obsidian/vault}"

if [ ! -d "$VAULT_PATH" ]; then
  echo "Error: $VAULT_PATH does not exist"
  exit 1
fi

echo "Creating Sanbrain folders in: $VAULT_PATH"

mkdir -p "$VAULT_PATH/People"
mkdir -p "$VAULT_PATH/Businesses"
mkdir -p "$VAULT_PATH/Meetings"
mkdir -p "$VAULT_PATH/Mirrors"
mkdir -p "$VAULT_PATH/Daily"

echo "Done. Folders created:"
echo "  People/      — one page per person (compiled truth + timeline)"
echo "  Businesses/  — one page per business (thesis + state + decisions)"
echo "  Meetings/    — structured meeting summaries with entity propagation"
echo "  Mirrors/     — book mirrors (author's ideas mapped to your life)"
echo "  Daily/       — daily compilation/digest pages"
echo ""
echo "Next steps:"
echo "  1. Write your soul.md and personality.md (see setup/seed-identity.md)"
echo "  2. Configure your crontab (see crontab.example)"
echo "  3. Point your harness at the skills/ directory"

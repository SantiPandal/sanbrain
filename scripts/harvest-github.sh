#!/bin/bash
# Sanbrain: harvest-github
# Pulls today's PR activity across tracked repos → writes to raw/ for ingest.
# Called by nightly.sh before the 4-skill chain.

source "$(dirname "$0")/lib.sh"
LOG="$SANBRAIN/logs/github.log"
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d "yesterday" +%Y-%m-%d)
OUTPUT="$VAULT/raw/github-prs-${TODAY}.md"

# ── Tracked repos ───────────────────────────────────────────────
# Add repos here. Format: owner/repo
REPOS=(
  "SantiPandal/taxfree-ai-bot"
  "SantiPandal/sanbrain"
)

# ── Check gh auth ────────────────────────────────────────────────
if ! gh auth status 2>&1 | grep -q "Logged in"; then
  echo "gh not authenticated, skipping GitHub harvest" >&2
  heartbeat harvest-github skip "gh not authenticated"
  exit 0
fi

has_activity=false
CONTENT="---
type: github-digest
date: $TODAY
source: harvest-github
auto_process: true
---

# GitHub Activity — $TODAY

Daily digest of PR activity across Santiago's repositories.
"

for repo in "${REPOS[@]}"; do
  repo_short=$(echo "$repo" | cut -d/ -f2)

  # ── Merged PRs (since yesterday) ──────────────────────────────
  merged=$(gh pr list --repo "$repo" --state merged --search "merged:>=$YESTERDAY" \
    --json number,title,mergedAt,body,additions,deletions,changedFiles,author \
    --jq '.[] | "- **#\(.number) \(.title)** (merged \(.mergedAt[:10]))\n  \(.additions)+/\(.deletions)- across \(.changedFiles) files. By \(.author.login).\n  \(.body // "" | split("\n") | first | if length > 200 then .[:200] + "…" else . end)"' \
    2>/dev/null)

  # ── Open PRs ──────────────────────────────────────────────────
  open_prs=$(gh pr list --repo "$repo" --state open \
    --json number,title,createdAt,body,additions,deletions,changedFiles,author,reviewDecision \
    --jq '.[] | "- **#\(.number) \(.title)** (opened \(.createdAt[:10]), \(.reviewDecision // "no review"))\n  \(.additions)+/\(.deletions)- across \(.changedFiles) files. By \(.author.login).\n  \(.body // "" | split("\n") | first | if length > 200 then .[:200] + "…" else . end)"' \
    2>/dev/null)

  # ── Recent commits on default branch (last 24h) ───────────────
  commits=$(gh api "repos/$repo/commits?since=${YESTERDAY}T00:00:00Z&per_page=10" \
    --jq '.[] | "- \(.sha[:7]) \(.commit.message | split("\n") | first) — \(.commit.author.name) (\(.commit.author.date[:10]))"' \
    2>/dev/null)

  # Only write section if there's any activity
  if [ -n "$merged" ] || [ -n "$open_prs" ] || [ -n "$commits" ]; then
    has_activity=true
    CONTENT+="
## [[${repo_short}]]
"
    if [ -n "$merged" ]; then
      CONTENT+="
### Merged
$merged
"
    fi

    if [ -n "$open_prs" ]; then
      CONTENT+="
### Open PRs
$open_prs
"
    fi

    if [ -n "$commits" ]; then
      CONTENT+="
### Commits
$commits
"
    fi
  fi
done

# Only write file if there was activity
if [ "$has_activity" = true ]; then
  echo "$CONTENT" > "$OUTPUT"
  echo "GitHub harvest: wrote $OUTPUT"
  heartbeat harvest-github ok "activity written for ${#REPOS[@]} repos"
else
  echo "GitHub harvest: no activity since $YESTERDAY"
  heartbeat harvest-github ok "no activity since $YESTERDAY"
fi

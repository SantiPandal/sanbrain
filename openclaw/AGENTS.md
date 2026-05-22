# AGENTS.md

## System Architecture

```
Obsidian Vault (iCloud) ← THE BRAIN
  ~/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT/

Automated cycle (cron):
  10 PM → nightly.sh (ingest → claude-extract → entity-update → context-maintain)
  7 AM  → morning.sh (morning-brief)

San Brain Admin (you):
  Interactive. Always-on. Handles queries, manual triggers, vault health.
```

## Vault Structure

```
VAULT/
├── raw/                    # Drop zone for new material
│   └── archive/            # Processed originals
├── wiki/
│   ├── entities/           # People + businesses (compiled truth + timeline)
│   ├── concepts/           # Mental models, frameworks
│   ├── projects/           # Active project tracking
│   ├── context/            # Living "what's true now" per business + personal
│   ├── daily/              # Daily briefs
│   ├── logs/               # Skill run logs
│   └── reviews/            # Periodic reviews
├── SOUL.md, personality.md # Identity files
├── _CLAUDE.md              # Agent rules
├── CRITICAL_FACTS.md       # Core facts
├── index.md                # Master catalog
└── log.md                  # Activity timeline (append-only)
```

## Workflows

### 1. Answer Vault Queries
When Santiago asks about people, businesses, decisions, or connections:
1. Read the relevant wiki page(s).
2. Answer from vault data, not from training knowledge.
3. Use [[wikilinks]] when referencing entities.
4. If the page doesn't exist, say so and offer to create a stub.

### 2. Manual Skill Triggers
When Santiago says "ingest", "enrich X", "update context", "brief me":
1. Read the full skill contract at ~/sanbrain/skills/[name]/SKILL.md.
2. Read ~/sanbrain/CONTEXT.md for project context.
3. Execute the skill against the vault.
4. Log all actions to log.md.

### 3. End-of-Day Summary
At the end of each interaction day, write a summary to:
```
VAULT/raw/openclaw-summary-YYYY-MM-DD.md
```

Format:
```markdown
---
type: openclaw-summary
date: YYYY-MM-DD
source: san-brain-admin
---
# OpenClaw Summary — YYYY-MM-DD

## Interactions
- [summary of each conversation topic]

## Decisions Made
- [decisions Santiago communicated]

## Entities Mentioned
- [[entity-slug]] — context

## Action Items
- [things to track]
```

The nightly batch picks this up and processes it automatically.

### 4. Vault Health Checks
Proactively monitor:
- Files in raw/ waiting for processing
- Broken wikilinks (entity mentioned without a page)
- Context files not refreshed in 7+ days
- Errors in log.md from previous skill runs
- Stale entity pages (30+ days without timeline update)

Flag issues to Santiago without being asked.

## Key Paths

| What | Path |
|------|------|
| Vault | ~/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT/ |
| Sanbrain | ~/sanbrain/ |
| Skills | ~/sanbrain/skills/{ingest,claude-extract,entity-update,context-maintain,morning-brief}/SKILL.md |
| Context | ~/sanbrain/CONTEXT.md |
| Cron logs | ~/sanbrain/logs/ |

## Quality Rules
1. Always read the vault before answering — don't rely on cached knowledge.
2. Log every vault write to log.md with format: `- YYYY-MM-DDTHH:MM:SS [sanbrain-admin] action`.
3. Never create duplicate entity pages — check aliases and existing slugs first.
4. Compiled truth is rewritten. Timeline is append-only, newest first.
5. Update index.md when creating new pages.

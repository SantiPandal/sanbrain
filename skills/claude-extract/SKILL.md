---
name: claude-extract
version: 1.0.0
description: |
  Extract decisions, entities, and insights from Claude Code sessions and
  Claude.ai memory files. Write updates to people pages, business pages,
  and decision logs in the vault.
triggers:
  - "extract from claude"
  - "pull claude sessions"
  - "what did I discuss in claude"
  - "sync claude to vault"
tools:
  - exec
  - read
  - write
mutating: true
---

# Claude Extract

## Contract

Given access to Claude.ai memory files and Claude Code session data, this skill:
1. Extracts all entities (people, businesses) mentioned
2. Extracts decisions made, insights generated, and action items
3. Writes/updates relevant vault pages
4. Triggers entity-propagate for all affected pages

## Phases

### Phase 1: Read Sources

Read Claude.ai memory files from their location on disk.
Read recent Claude Code session transcripts if available.

For each source, extract:
- **Entities**: people and businesses mentioned
- **Decisions**: conclusions reached, choices made
- **Insights**: non-obvious observations, frameworks applied
- **Action items**: tasks assigned or committed to
- **Context**: what problem was being worked on

### Phase 2: Deduplicate

Check the vault for existing entries:
- Has this decision already been logged? (check dates + content)
- Has this interaction already been captured? (check timeline entries)
- Skip anything already in the vault.

### Phase 3: Write to Vault

For each extracted item:

**Decisions** → Append to relevant `Businesses/` page Decisions Log:
```
- YYYY-MM-DD: [decision] — reasoning: [why]. (Claude session, YYYY-MM-DD)
```

**Insights** → Create or update relevant page (could be business, concept, or person):
```
- YYYY-MM-DD: [insight] (Claude session, YYYY-MM-DD)
```

**Action items** → Append to relevant page's Open Threads section.

### Phase 4: Propagate

Run `entity-propagate` on every page written or updated.

## Output Format

Report to user:
```
Extracted from [N] Claude sessions:
- [N] decisions logged
- [N] entities updated
- [N] insights captured
- [N] new entity stubs created
```

## Cron

Every 30 minutes. Idempotent — safe to run repeatedly.

## Dependencies

- `entity-propagate` (post-write)
- Read access to Claude.ai memory files on disk
- Read access to Claude Code session data (if available)

---
name: enrich
version: 1.0.0
description: |
  Upgrade a person or business page based on mention frequency.
  Tier 3 (stub) -> Tier 2 (basic) -> Tier 1 (full).
triggers:
  - "enrich"
  - "who is"
  - "tell me about"
  - "upgrade this page"
tools:
  - exec
  - read
  - write
mutating: true
---

# Enrich

## Contract

Given a person or business slug, upgrade their page to the appropriate tier:
1. Tier 3 → Tier 2: Add relationship context, state, open threads from vault mentions
2. Tier 2 → Tier 1: Add web research, full compiled truth, career arc, cross-references

## Phases

### Phase 1: Assess Current State

Read the entity's current page. Determine current tier from frontmatter.
Count mentions across all vault pages.

### Phase 2: Gather Context from Vault

Search the entire vault for mentions of this entity:
- Meeting pages where they attended
- Business pages where they're referenced
- Daily compilations mentioning them
- Source material referencing them
- Claude session extracts mentioning them

Compile all context chronologically.

### Phase 3: Tier 2 Upgrade (from vault data only)

Rewrite the page with:

```markdown
---
type: person
tier: 2
---
# [Name]

Context: [expanded — how Santiago knows them, their role, why they matter]
State: [what's currently true about the relationship/interaction]

## Open Threads
- [pending items, extracted from meeting action items and vault mentions]

## Timeline
- [all interactions, compiled from vault, newest first]
```

For businesses, include thesis, current metrics, key people, decisions log.

### Phase 4: Tier 1 Upgrade (vault + external research)

Everything from Tier 2, PLUS:
- Web research on the person/company (background, career, public statements)
- Cross-references to Santiago's thinkers and mental models where relevant
- Relationship dynamics (what Santiago has said about them, patterns in interactions)
- Full compiled truth synthesis

**Fact-check**: Every claim must cite its source. Web claims cite URLs. Vault claims cite pages.

### Phase 5: Update Frontmatter

Set `tier: 2` or `tier: 1` in frontmatter.

## Output Format

```
Enriched: [[entity-name]]
- Tier: [old] → [new]
- Sources consulted: [N] vault pages, [N] web sources
- Compiled truth: [word count]
- Timeline entries: [N]
```

## Dependencies

- Read: entire vault (for mention gathering)
- External: web search (for Tier 1 only)

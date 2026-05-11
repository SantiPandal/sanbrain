---
name: entity-propagate
version: 1.0.0
description: |
  After any page is written or updated, walk through all mentioned
  entities and update their pages. Create stubs for first-time mentions.
  This is the nervous system of the vault.
triggers:
  - auto-fires after any skill writes a page
tools:
  - read
  - write
mutating: true
---

# Entity Propagate

## Contract

Given a newly written or updated vault page, this skill:
1. Detects all entities (people, businesses) mentioned
2. For each entity WITH an existing page: adds a timeline entry back-linking to the source
3. For each entity WITHOUT a page: creates a Tier 3 stub
4. Checks mention counts and flags tier upgrades

This skill is the most important in the system. Without it, knowledge stays siloed. With it, every write enriches the entire vault.

## Phases

### Phase 1: Detect Entities

Scan the source page for:
1. **Wikilinks**: `[[Person Name]]`, `[[Business Name]]`
2. **Frontmatter**: `attendees:` field in meeting pages
3. **Inline mentions**: Names that match existing people/business pages

Build a list of all detected entities with their type (person/business) and context (the sentence/section where they appear).

### Phase 2: Check Existing Pages

For each detected entity:
- Does `People/[name].md` or `Businesses/[name].md` exist?
- If yes → Phase 3 (update)
- If no → Phase 4 (create stub)

### Phase 3: Update Existing Pages

For each entity with an existing page, append to their Timeline section:

```markdown
- YYYY-MM-DD: Referenced in [[source-page-title]] — [one-line context of how they were mentioned]
```

**Dedup check**: If a timeline entry for this source page on this date already exists, skip. This ensures idempotency.

### Phase 4: Create Stubs

For each entity WITHOUT an existing page, apply the notability gate (see `conventions/quality.md`):
- Will Santiago interact with them again?
- Are they relevant to a business or goal?

If yes, create a Tier 3 stub:

```markdown
---
type: person
tier: 3
---
# [Name]

Context: [one line — extracted from the source page]

## Timeline
- YYYY-MM-DD: First mentioned in [[source-page-title]] — [context]
```

### Phase 5: Check Tier Upgrades

Count how many distinct pages mention each entity:
- **3+ pages** → Flag for Tier 2 upgrade (run `enrich` skill)
- **8+ pages or meeting attendance** → Flag for Tier 1 upgrade

Report flagged entities so the next cron cycle picks them up.

## Output Format

```
Propagated from [[source-page]]:
- [N] existing pages updated with timeline entries
- [N] new stubs created
- [N] entities flagged for tier upgrade
```

## Rules

1. **Never modify compiled truth** of entity pages. Only append to Timeline.
2. **Never create duplicate timeline entries.** Check date + source page before appending.
3. **Newest entries first** in Timeline sections.
4. **One-line context** in timeline entries. Enough to understand why without reading the source.

## Dependencies

- Read: `People/`, `Businesses/`
- May trigger: `enrich` (when tier threshold crossed)

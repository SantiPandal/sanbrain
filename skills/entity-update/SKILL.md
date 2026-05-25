---
name: entity-update
version: 1.0.0
description: |
  The nervous system of the vault. After any page is written or updated,
  detects all entities mentioned, updates their pages with back-link timeline
  entries, creates stubs for new notable entities, enriches frequently
  mentioned entities, and merges duplicates. Replaces entity-propagate.
triggers:
  - auto-fires after any skill writes a page
  - "update entities"
  - "propagate entities"
  - "entity update"
tools:
  - read
  - write
mutating: true
---

# Entity Update

## Contract

Given a newly written or updated vault page (or a list of entity names from a triggering skill), this skill:

1. Detects all entities (people, businesses) mentioned in the source page(s)
2. For existing entities: adds a timeline back-link entry (deduped, newest first)
3. For new entities passing the notability gate: creates a stub page in `wiki/entities/`
4. For frequently mentioned entities: auto-enriches with vault context (Tier 2) or web research (Tier 3 -> deep enrichment on manual trigger)
5. Detects and merges duplicate entities (e.g., "Alfonso" and "Alfonso Rojas")
6. Logs every change to `log.md`

This is the most important skill in the system. Without it, knowledge stays siloed in individual pages. With it, every write enriches the entire vault.

## Constants

```
VAULT_PATH="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT"
ENTITIES_DIR="$VAULT_PATH/wiki/entities"
LOG_FILE="$VAULT_PATH/log.md"
INDEX_FILE="$VAULT_PATH/index.md"
SOUL_FILE="$VAULT_PATH/SOUL.md"
```

## Entity Page Format

Every entity page in `wiki/entities/` follows this format:

```markdown
---
type: person|business
aliases: [alternative names, nicknames, abbreviations]
first_seen: YYYY-MM-DD
confidence: high|medium|low
---
## For future Claude
[One-line: who this is and why they matter to Santiago]

# [Full Name]

[Compiled truth -- current best understanding of this entity. This section is REWRITTEN
when new evidence changes the picture. It should always reflect the most current, accurate
understanding. Include: who they are, how Santiago knows them, their role, current state
of the relationship or business, and any important context.]

## Open Threads
- [pending items, follow-ups, unresolved questions]

## Timeline
- YYYY-MM-DD: [event -- append-only, newest first]
- YYYY-MM-DD: [event]
```

## Enrichment Tiers

These tiers are internal logic that determines how much effort to put into an entity page. They are NOT exposed in frontmatter (no `tier:` field).

| Tier | Trigger | Content Level |
|---|---|---|
| Stub | First mention passing notability gate | Name, one-line context, source, single timeline entry |
| Vault-enriched | 3+ mentions across different pages | Compiled truth from vault context, relationship state, open threads, all timeline entries |
| Deep enrichment | 8+ mentions OR meeting attendance OR manual trigger | Full compiled truth with web research (if available), comprehensive relationship context, all open threads |

The skill checks mention counts on every run and upgrades entities that cross thresholds.

## Phases

### Phase 0: Determine Input

The skill can be triggered in two ways:

**A. Post-write trigger**: A specific source page was just written or updated. The skill receives the page path.
1. Read the source page.
2. Proceed to Phase 1 to detect entities in that page.

**B. Entity list trigger**: A triggering skill (ingest, claude-extract) passes a list of entity names and their source pages.
1. Use the provided list directly.
2. Skip to Phase 2 (entities already detected).

### Phase 1: Detect Entities

Scan the source page for entity mentions using these methods (in order of reliability):

1. **Wikilinks**: `[[Person Name]]` or `[[Business Name]]` — highest confidence.
2. **Frontmatter fields**: `attendees:`, `key_people:`, or any field listing names.
3. **Inline mentions**: Names that match existing entity pages in `wiki/entities/`. Check against all filenames and all `aliases` in frontmatter.
4. **Contextual detection**: Names that appear in decision contexts, meeting notes, or action items even if they don't match existing pages. Use surrounding context to determine if it's a person or business.

For each detected entity, capture:
```
{
  name: string (canonical name — use existing page title if matched),
  type: person|business,
  context: string (the sentence or section where they appear),
  source_page: string (path of the page where detected),
  confidence: high|medium|low (wikilink = high, frontmatter = high, inline match = medium, contextual = low)
}
```

### Phase 2: Check Existing Pages

For each detected entity:

1. Normalize the name to a slug: lowercase, hyphens for spaces, remove special characters.
2. Check if `wiki/entities/[slug].md` exists.
3. Also check aliases: read all entity pages' frontmatter `aliases` fields. If the detected name matches an alias, use the canonical page.
4. Categorize:
   - **Existing page found** -> Phase 3 (update)
   - **No page found** -> Phase 4 (notability gate + create)

### Phase 3: Update Existing Entity Pages

For each entity with an existing page:

#### 3a: Add Timeline Entry

Construct the timeline entry:
```
- YYYY-MM-DD: Referenced in [[source-page-title]] — [one-line context extracted from Phase 1]. (Source: [triggering skill or page])
```

**Dedup check**: Read the existing `## Timeline` section. Skip if an entry with the same date AND the same source page already exists. This ensures idempotency.

Prepend the new entry at the top of `## Timeline` (newest first).

#### 3b: Check for Compiled Truth Updates

Determine if the source page contains information that changes the compiled truth:
- Role change ("X is now the CTO" vs existing "X is the lead developer")
- Relationship change (new business partnership, ended collaboration)
- Status change (business pivoted, person left the company)
- Decision that affects the entity

If yes:
1. Read the current compiled truth section.
2. Rewrite it to incorporate the new information. Preserve everything that is still true. Only change what the new evidence contradicts or extends.
3. Log the change:
   ```
   - YYYY-MM-DDTHH:MM:SS [entity-update] Compiled truth updated for [[entity]]: [summary of what changed]. Source: [[source-page]].
   ```

If no: leave compiled truth unchanged. Only the timeline entry is added.

#### 3c: Update Open Threads

If the source page contains action items or follow-ups involving this entity:
- Add new items to `## Open Threads`.
- If an existing thread is resolved by the source page, mark it as done: `- ~~[item]~~ (resolved YYYY-MM-DD, [[source-page]])`.

#### 3d: Check Enrichment Threshold

Count distinct pages that reference this entity (count unique source pages in `## Timeline`):
- **3+ distinct pages** AND current content is stub-level -> trigger vault enrichment (Phase 5).
- **8+ distinct pages** OR entity appears in meeting attendees -> flag for deep enrichment (Phase 6).

### Phase 4: Create New Entity Stubs

For each entity without an existing page:

#### 4a: Notability Gate

Apply these criteria. The entity passes if ANY of the following are true:
- Entity is an attendee in a meeting note.
- Entity is mentioned in a decision or action item.
- Entity is mentioned in 2+ different source pages in the current batch.
- Entity is a business (all businesses pass).
- Entity is explicitly named with context suggesting ongoing relevance (partner, client, team member, investor).

If the entity fails the notability gate:
```
- YYYY-MM-DDTHH:MM:SS [entity-update] Skipped stub for "[name]" — below notability threshold. Source: [[source-page]].
```
Continue to next entity.

#### 4b: Create Stub Page

```markdown
---
type: [person|business]
aliases: []
first_seen: YYYY-MM-DD
confidence: [confidence from Phase 1 detection]
---
## For future Claude
[One-line: who this is and why they matter to Santiago, inferred from the source context]

# [Full Name]

[Context extracted from the source page. Keep it factual. Do not fabricate information
not present in the source.]

## Open Threads
- [any action items involving this entity from the source page, if applicable]

## Timeline
- YYYY-MM-DD: First seen in [[source-page-title]] — [context]. (Source: [triggering skill])
```

Log:
```
- YYYY-MM-DDTHH:MM:SS [entity-update] Created stub for [[entity-slug]]. Type: [person|business]. Source: [[source-page]].
```

Update `index.md` with the new page entry.

### Phase 5: Vault Enrichment (3+ mentions)

When an entity crosses the 3-mention threshold:

1. Read ALL vault pages that mention this entity (search through `## Timeline` entries and full-text search of wiki/).
2. Read `SOUL.md` for Santiago's context and how this entity fits into his world.
3. Synthesize a compiled truth section from all available vault information:
   - Who is this person/business?
   - How does Santiago know them?
   - What is the current state of the relationship/engagement?
   - What patterns emerge from the timeline? (e.g., frequent collaborator, one-time meeting, recurring blocker)
4. Populate `## Open Threads` from all unresolved action items across the vault involving this entity.
5. Rewrite the page with the enriched compiled truth. Preserve ALL existing timeline entries.
6. Set `confidence: medium` in frontmatter.

Log:
```
- YYYY-MM-DDTHH:MM:SS [entity-update] Vault-enriched [[entity-slug]]. Mentions: [N] across [N] pages. Compiled truth rewritten.
```

### Phase 6: Deep Enrichment (8+ mentions / meeting / manual)

When an entity crosses the 8-mention threshold, appears as a meeting attendee, or is manually triggered:

1. Perform everything in Phase 5 first (vault enrichment).
2. If web research tools are available: search for public information about the entity (LinkedIn, company website, news). Add factual findings to the compiled truth, clearly marked with source.
3. If web research is not available: note in the compiled truth that deep enrichment was triggered but web research was unavailable. The compiled truth is vault-only.
4. Ensure the `## For future Claude` preamble is comprehensive: future agents should immediately understand who this entity is and why they matter.
5. Set `confidence: high` in frontmatter.

Log:
```
- YYYY-MM-DDTHH:MM:SS [entity-update] Deep-enriched [[entity-slug]]. Mentions: [N]. Web research: [available|unavailable]. Compiled truth rewritten.
```

### Phase 7: Duplicate Detection and Merge

After all updates and creations, scan for potential duplicates:

1. Compare all entity names and aliases. Flag pairs where:
   - One name is a substring of another (e.g., "Alfonso" and "Alfonso Rojas")
   - Names differ only by formatting (e.g., "CargoClaro" and "Cargo Claro")
   - Aliases overlap between two entity pages

2. For each potential duplicate pair:
   - Read both pages.
   - Determine if they refer to the same entity (same context, same timeline events, same relationships).
   - If confirmed duplicate:
     a. Choose the more complete page as the canonical page.
     b. Merge timeline entries from the secondary page into the canonical page (dedup by date + content).
     c. Merge open threads.
     d. Update compiled truth to include information from both pages.
     e. Add all names/aliases from the secondary page to the canonical page's `aliases` field.
     f. Replace the secondary page with a redirect note:
        ```markdown
        ---
        type: redirect
        target: [[canonical-page-slug]]
        ---
        ## For future Claude
        This entity was merged into [[canonical-page-slug]].
        ```
     g. Log:
        ```
        - YYYY-MM-DDTHH:MM:SS [entity-update] Merged [[secondary-slug]] into [[canonical-slug]]. Reason: [duplicate detection method].
        ```

3. If unsure whether two entities are duplicates, do NOT merge. Instead, log:
   ```
   - YYYY-MM-DDTHH:MM:SS [entity-update] [ATTENTION] Possible duplicate: [[entity-a]] and [[entity-b]]. Review recommended.
   ```

### Phase 8: Final Log

```
- YYYY-MM-DDTHH:MM:SS [entity-update] Run complete. Source: [source page or triggering skill]. Entities processed: [N]. Timeline entries added: [N]. Stubs created: [N]. Vault-enriched: [N]. Deep-enriched: [N]. Duplicates merged: [N]. Duplicates flagged: [N].
```

## Output Format

Report to user:
```
Entity update complete:
- Source: [[source-page]] (or: [N] entities from [triggering skill])
- Existing pages updated: [N] (timeline entries added)
- New stubs created: [N]
- Notability gate rejections: [N]
- Vault enrichments triggered: [N]
- Deep enrichments triggered: [N]
- Compiled truths rewritten: [N]
- Duplicates merged: [N]
- Possible duplicates flagged: [N] (review in log.md)
```

## Rules

1. **Never fabricate information.** If the source page says "Alfonso was at the meeting," the timeline entry says exactly that. Do not infer what was discussed unless the source page provides it.
2. **Never create duplicate timeline entries.** Check date + source page before appending.
3. **Newest entries first** in Timeline sections.
4. **One-line context** in timeline entries. Enough to understand why without reading the source.
5. **Compiled truth is rewritten, not appended.** When evidence changes the picture, rewrite the section. The timeline is the append-only record; compiled truth is the living summary.
6. **Back-links are mandatory.** Every entity mention in any wiki page should use wikilink syntax `[[entity-slug]]`.
7. **Respect the notability gate.** Do not create stub pages for one-off mentions of people unlikely to appear again.
8. **Log everything.** Every page creation, update, merge, and skip goes to `log.md`.

## Idempotency

Running twice on the same source page produces the same result because:
1. Timeline entries are deduped by date + source page.
2. Stub creation checks for existing pages (including aliases).
3. Enrichment thresholds only trigger upgrades (never downgrades).
4. Duplicate merges produce a redirect that prevents re-merging.

## Dependencies

- Reads: source page (or entity list), all `wiki/entities/` pages, `SOUL.md`, `index.md`
- Writes: `wiki/entities/`, `log.md`, `index.md`
- Triggered by: `ingest`, `claude-extract`, or any skill that writes to the vault
- May trigger: nothing downstream (entity-update is a terminal skill)

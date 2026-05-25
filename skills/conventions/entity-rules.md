# Entity Rules Convention

People and businesses are enriched in tiers based on mention frequency.

## Location

All entity pages live in `wiki/entities/`. Filename: lowercase, hyphens for spaces.

## Tiers

| Tier | Trigger | What the page contains |
|------|---------|----------------------|
| **Stub** | First mention passing notability gate | Name, one-line context, how Santiago knows them |
| **Vault-enriched** | 3+ mentions across different pages | Compiled truth from vault data, relationship state, open threads, all timeline entries |
| **Deep** | Meeting attendance OR 8+ mentions | Full compiled truth with web research (if available), comprehensive relationship context |

## Rules

1. **Auto-create stubs.** When entity-update encounters a notable person/business for the first time, create a stub in `wiki/entities/`.
2. **Count mentions.** Track how many distinct pages mention each entity. When threshold crossed, enrich.
3. **Never downgrade.** A deep-enriched page stays deep even if mentions slow down.
4. **Merge duplicates.** If the same entity appears under different names (e.g., "Alfonso" and "Alfonso Rojas"), merge into one page with aliases in frontmatter.

## Entity Detection

Entities are detected by:
1. Explicit wikilinks: `[[person-slug]]`
2. Names in meeting attendees frontmatter
3. Names matching existing entity page filenames or aliases
4. Contextual detection in decisions, action items, meeting notes

## Notability Gate

An entity passes if ANY of:
- Is an attendee in a meeting
- Is mentioned in a decision or action item
- Is mentioned in 2+ source pages in the same batch
- Is a business (all businesses pass)
- Is clearly a partner, client, team member, or investor

## Post-Write Flow

After any page write, `entity-update` walks through all detected entities and:
1. Creates stubs for new notable entities
2. Adds timeline entries to existing entity pages (deduped by date + source)
3. Checks mention count and enriches if threshold crossed
4. Detects and merges duplicates

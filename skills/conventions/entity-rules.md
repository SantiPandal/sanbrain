# Entity Rules Convention

People and businesses are enriched in tiers based on mention frequency.

## Tiers

| Tier | Trigger | What the page contains |
|------|---------|----------------------|
| **3 (stub)** | First mention in any page | Name, one-line context, how Santiago knows them |
| **2 (basic)** | 3+ mentions across different pages | Context, relationship state, open threads, timeline of interactions |
| **1 (full)** | Meeting OR 8+ mentions | Full compiled truth, web research, career arc, relationship history, cross-references |

## Rules

1. **Auto-create stubs.** When entity-propagate encounters a person/business mentioned for the first time, create a Tier 3 stub in `People/` or `Businesses/`.
2. **Count mentions.** Track how many distinct pages mention each entity. When threshold crossed, flag for enrichment.
3. **Never downgrade.** A Tier 1 page stays Tier 1 even if mentions slow down.
4. **Merge duplicates.** If the same person appears under different names (e.g., "Alfonso" and "Alfonso Rojas"), merge into one page with aliases noted.

## Entity Detection

Entities are detected by:
1. Explicit wikilinks: `[[Alfonso Rojas]]`
2. Names mentioned in meeting attendees frontmatter
3. Names appearing in timeline entries
4. Skill-specific extraction (e.g., book-mirror detecting people referenced in mirrors)

## Propagation

After any page write, `entity-propagate` walks through all detected entities and:
1. Creates stub pages for new entities (Tier 3)
2. Adds a timeline entry in existing entity pages: `- YYYY-MM-DD: Referenced in [[source-page]] — [context]`
3. Checks mention count and flags for tier upgrade if threshold crossed

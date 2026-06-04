# Entity Rules Convention

People, businesses, and books are enriched in tiers based on mention frequency.

## Location

All entity pages live in `wiki/entities/`. Filename: lowercase, hyphens for spaces.

## Entity Types

| Type | Description | Example |
|------|-------------|---------|
| `person` | People Santiago interacts with or learns from | [[alfonso-rojas]], [[brad-jacobs]] |
| `business` | Companies, ventures, organizations | [[pala-padel]], [[cargo-claro]] |
| `book` | Books in Santiago's library — static knowledge, dynamic interpretations | [[100m-offers]], [[the-selfish-gene]] |

Books are entities like people, but more static. The compiled truth captures what the book teaches. The timeline captures when and how Santiago applies its ideas. The `## For future Claude` section is the retrieval hint — it tells the brain when to reach for this book.

### Book-Specific Fields

Books use additional frontmatter beyond the standard entity fields:
- `author`: Author name(s)
- `publisher`: Publisher
- `status`: `read` | `reading` | `unread` | `reference`
- `domains`: Topic tags for retrieval (e.g., `[consolidation, M&A, leadership]`)

### Book ↔ Entity Cross-Linking

- Book pages reference authors via wikilinks: `[[author-slug]]`
- When Santiago applies a book idea to a business, both the book entity and the business entity get timeline entries
- Concepts extracted from books link to `wiki/concepts/` with back-links to the book entity
- The mirror template (`templates/mirror.md`) is deep enrichment for books — the T1 treatment

## Tiers

| Tier | Trigger | What the page contains |
|------|---------|----------------------|
| **Stub** | First mention passing notability gate | Name, one-line context, how Santiago knows them |
| **Vault-enriched** | 3+ mentions across different pages | Compiled truth from vault data, relationship state, open threads, all timeline entries |
| **Deep** | Meeting attendance OR 8+ mentions | Full compiled truth with web research (if available), comprehensive relationship context |

## Rules

1. **Auto-create stubs.** When entity-update encounters a notable person/business/book for the first time, create a stub in `wiki/entities/`.
2. **Count mentions.** Track how many distinct pages mention each entity. When threshold crossed, enrich.
3. **Never downgrade.** A deep-enriched page stays deep even if mentions slow down.
4. **Merge duplicates.** If the same entity appears under different names (e.g., "Alfonso" and "Alfonso Rojas"), merge into one page with aliases in frontmatter.
5. **Books are always notable.** All books bypass the notability gate — they are curated knowledge sources by definition.

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
- Is a book (all books pass — curated knowledge sources)
- Is clearly a partner, client, team member, or investor

## Post-Write Flow

After any page write, `entity-update` walks through all detected entities and:
1. Creates stubs for new notable entities
2. Adds timeline entries to existing entity pages (deduped by date + source)
3. Checks mention count and enriches if threshold crossed
4. Detects and merges duplicates

# Book distillation agent contract

You are distilling ONE book into Santiago's Obsidian wiki. Books are **entities** (`type: book`) in `wiki/entities/[slug].md`.

## Paths
- Vault: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT`
- Entity page: `VAULT/wiki/entities/[slug].md`
- Gold standard example: `VAULT/wiki/entities/100m-leads.md` and `100m-offers.md`
- Context pack (wikilink targets): `conductor/workspaces/sanbrain/calgary/.context/context-pack.md`
- Full text (local, never iCloud): `conductor/workspaces/sanbrain/calgary/.context/book-text/[slug].txt`
- Job metadata: `conductor/workspaces/sanbrain/calgary/.context/book-jobs.json`

## Rules
1. **Read** the entity page (create from `templates/book.md` if missing), context-pack, and book text.
2. For texts >600k chars: read first 200k + last 80k; skim mid via chapter/section headers (`rg '^[A-Z]'` or `^Chapter`).
3. **Write** the entity page in place. Preserve valid frontmatter; set `confidence: low` → `medium` when done.
4. **Do NOT** copy PDFs into iCloud. In `## PDF`, note local path from job `pdf` field + extracted text path. Never sync PDF to vault.
5. **Semantic work only you can do**: Core Thesis (first principles), 4–8 Key Frameworks as `- **Name** — explanation`, Santiago's Applications with real `[[wikilinks]]` to businesses/concepts from context-pack, `## Related` (5–8 links to other books/concepts).
6. Only link slugs that exist in context-pack or vault — verify with `ls wiki/entities` / `ls wiki/concepts` if unsure.
7. Append timeline entry: `YYYY-MM-DD: Enriched from full-text extraction — [one line]. (Source: Phase 2 book ingestion)`
8. Log to `VAULT/log.md`: `- YYYY-MM-DDTHH:MM:SS [book-ingest] Enriched [[slug]]`

## Output quality bar (match 100m-leads)
- `## For future Claude`: when to reach for this book (retrieval hint)
- Frameworks are **actionable names**, not generic summaries
- Santiago's Applications tie to **Pala**, **Tax Free**, or his operating patterns — skip generic filler
- Cross-book links where real (Hormozi stack, Dawkins↔Ridley, Meadows↔systems books, etc.)

## Forbidden
- Placeholder text ("To be extracted", "To be connected")
- Inventing wiki pages that don't exist
- Putting raw book text in the vault
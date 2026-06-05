---
name: wiki-books
version: 1.0.0
description: |
  Wiki a book into the vault as a type:book entity. Mechanical extract (pdftotext) +
  semantic distill (frameworks, Santiago applications, cross-links). PDFs stay local;
  only distillate syncs via iCloud. Use when a new PDF lands in Downloads, "wiki this
  book", "ingest book", or nightly harvest finds a book PDF.
triggers:
  - "wiki book"
  - "ingest book"
  - "new book"
  - "book entity"
  - "distill book"
tools:
  - exec
  - read
  - write
mutating: true
---

# Wiki Books

Books are **entities** (`wiki/entities/[slug].md`, `type: book`). The graph value is semantic linking, not storage.

## Pipeline (every book)

| Step | Layer | Tool | Output |
|------|-------|------|--------|
| 1. Match | Mechanical | `python3 scripts/prep-books.py` (or single-slug path) | `.context/book-jobs.json` entry |
| 2. Extract | Mechanical | `pdftotext` → `.context/book-text/[slug].txt` | Local cache (not iCloud) |
| 3. Distill + link | Semantic | 1 agent per book (fan-out 10 parallel) | Enriched entity page |
| 4. Register | Mechanical | `log.md` + timeline entry | Audit trail |

**Rule:** Scripts move bytes. Agents make meaning. Never skip step 3 for bulk backfill.

## Single new book (marginal cost → zero)

1. Drop PDF in `~/Downloads` (or `oceanofpdf_bulk/`).
2. Run `python3 scripts/prep-books.py` — adds job if slug matches entity or `NEW` block.
3. If `new: true`, create entity from `templates/book.md` first.
4. Run distill agent (see `.context/distill-agent-prompt.md`) on that slug only.
5. Optional: promote `type: mirror` page later for deep-read books (~10 max).

## Bulk backfill

```bash
# How many left
python3 scripts/run-book-batch.py 10 0   # batch 0 slugs (stderr shows counts)

# Fan-out: launch 10 generalPurpose agents, each with distill-agent-prompt + one slug
# Repeat batch N until pending = 0
```

Agent contract: `skills/wiki-books/distill-agent-prompt.md`  
Cross-link targets: `.context/context-pack.md`  
Gold standard pages: `wiki/entities/100m-leads.md`, `100m-offers.md`

## PDF policy

- **Never** copy PDF into iCloud vault.
- `## PDF` section: local path + `.context/book-text/[slug].txt` reference.
- Deep-dive: open local PDF or re-run pdftotext.

## Ingest skill integration (Phase 2a)

When `ingest` sees a PDF matching `wiki/entities/*` with `type: book`:

1. Run mechanical steps 1–2 above.
2. Trigger wiki-books distill for that slug (do not generic-extract into a new page).
3. Skip archiving if PDF was harvested from Downloads by `harvest-downloads` — books stay in local library.

## Fan-out defaults

- Backfill: **10 agents** per wave until `run-book-batch.py` reports 0 pending.
- Single new book: 1 agent.
- Huge texts (>600k chars): agent reads head + tail + section scan (see distill prompt).

## Quality bar

- No placeholders in Key Frameworks / Santiago's Applications.
- `confidence: medium` after distill.
- Timeline: `Enriched from full-text extraction (Source: Phase 2 book ingestion)`.
- Log: `[book-ingest] Enriched [[slug]]`.

## Dependencies

- `scripts/prep-books.py`, `scripts/match-books.py`, `scripts/run-book-batch.py`
- `.context/book-jobs.json`, `.context/context-pack.md`
- `skills/wiki-books/distill-agent-prompt.md`
- `templates/book.md`, `skills/conventions/entity-rules.md`
- Vault: `SOUL.md` optional for personal lens

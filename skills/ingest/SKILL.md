---
name: ingest
version: 1.0.0
description: |
  Unified ingestion pipeline. Scans the raw/ folder in the vault, detects file
  type (PDF, audio transcript, meeting notes, research, articles, URLs, plain
  notes), extracts content, and distributes updates across wiki/. Moves
  processed originals to raw/archive/ with a timestamp prefix. This is the
  primary entry point for all new material entering the vault.
triggers:
  - "ingest"
  - "process raw"
  - "scan raw folder"
  - "what's new in raw"
  - "process new files"
tools:
  - exec
  - read
  - write
mutating: true
---

# Ingest

## Contract

Given files in `raw/` inside the vault, this skill:

1. Scans `raw/` for unprocessed files (ignores `raw/archive/`)
2. Detects each file's type from extension + content heuristics
3. Extracts structured content appropriate to the file type
4. Distributes extracted knowledge across `wiki/` subdirectories
5. Creates wikilinks for every detected entity
6. Resolves contradictions against existing compiled truth
7. Logs every action to `log.md` at vault root
8. Moves each processed original to `raw/archive/` with timestamp prefix
9. Triggers `entity-update` for all entities mentioned across all processed files

Idempotent: if a file has already been archived with the same content hash, skip it.

## Constants

```
VAULT_PATH="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT"
RAW_DIR="$VAULT_PATH/raw"
ARCHIVE_DIR="$VAULT_PATH/raw/archive"
WIKI_DIR="$VAULT_PATH/wiki"
LOG_FILE="$VAULT_PATH/log.md"
INDEX_FILE="$VAULT_PATH/index.md"
SOUL_FILE="$VAULT_PATH/SOUL.md"
CRITICAL_FACTS="$VAULT_PATH/CRITICAL_FACTS.md"
```

## Phases

### Phase 0: Pre-flight

1. Verify `raw/` exists. If empty, log "ingest: nothing to process" to `log.md` and exit.
2. Ensure `raw/archive/` exists (create if missing).
3. Ensure all target directories exist under `wiki/` (entities, concepts, ideas, projects, context, daily, logs, reviews). Create any that are missing.
4. Read `SOUL.md` — needed for personal-lens elaboration in Phase 3.
5. Read `CRITICAL_FACTS.md` — needed for contradiction detection.
6. Read `index.md` — needed to check what pages already exist.

### Phase 1: Scan and Classify

List all files in `raw/` (non-recursive, exclude `archive/` subdirectory).

For each file, classify by type using this decision tree:

| Extension / Signal | Type | Handler |
|---|---|---|
| `.pdf` | `pdf` | Phase 2a |
| `.mp3`, `.m4a`, `.wav`, `.ogg` | `audio-transcript` | Phase 2b |
| `.md` or `.txt` with `attendees:` in frontmatter or "Meeting" in first 5 lines | `meeting-notes` | Phase 2c |
| `.md` or `.txt` with a URL on the first line | `article-url` | Phase 2d |
| `.md` or `.txt` with `type: research` in frontmatter | `research` | Phase 2e |
| `.md` or `.txt` (default) | `plain-note` | Phase 2f |
| `.json`, `.jsonl` | `structured-data` | Phase 2g |
| Any image (`.png`, `.jpg`, `.jpeg`, `.webp`) | `image` | Phase 2h |
| Unknown extension | `unknown` | Log warning, skip, do NOT archive |

Build a manifest: `[ { path, filename, type, size, detected_at } ]`

Log to `log.md`:
```
- YYYY-MM-DDTHH:MM:SS [ingest] Scan complete. Found N files: N pdf, N meeting-notes, N plain-note, ...
```

### Phase 2: Extract Content

Process each file according to its type. Every handler produces a uniform extraction object:

```
{
  source_file: string,
  type: string,
  title: string,
  summary: string (3-5 sentences),
  entities: [ { name, type: person|business, context } ],
  concepts: [ { name, description } ],
  projects: [ { name, relevance } ],
  decisions: [ { decision, reasoning, date } ],
  action_items: [ { item, owner, deadline? } ],
  key_insight: string (one sentence, the non-obvious takeaway),
  raw_text: string (full extracted text for reference),
  personal_elaboration: string (how this connects to Santiago's life, using SOUL.md lens),
  contradictions: [ { claim, conflicts_with: { page, existing_claim }, resolution } ],
  tags: [ string ]
}
```

#### Phase 2a: PDF

1. Extract text from the PDF (use available PDF extraction tools or `pdftotext`).
2. Summarize: what is this document about?
3. Extract entities, concepts, decisions.
4. Generate personal elaboration: read `SOUL.md` and map the document's key ideas to Santiago's businesses, frameworks, or growth edges.

#### Phase 2b: Audio Transcript

1. If the file is raw audio, note that transcription is required first. Log a warning and skip if no transcript is available. If a `.txt` or `.md` companion file exists with the same name, use that as the transcript.
2. Parse the transcript for speakers, topics, decisions.
3. Extract attendees (treat as meeting if 2+ speakers detected).
4. Pull action items and key insight.

#### Phase 2c: Meeting Notes

1. Parse frontmatter for date, attendees.
2. Extract discussion points, decisions made, action items with owners.
3. Identify the single key insight from the meeting.
4. For each attendee, note their role and context from the transcript.

#### Phase 2d: Article / URL

1. If the file contains a URL on the first line, note the URL as the source.
2. Read any body text below the URL as the user's notes or the article content.
3. Summarize the article's key ideas.
4. Generate personal elaboration through `SOUL.md` lens.
5. Extract any entities or concepts worth tracking.

#### Phase 2e: Research

1. Parse structured research notes.
2. Extract thesis, evidence, counter-arguments.
3. Map to existing concepts in `wiki/concepts/`.
4. Generate personal elaboration.

#### Phase 2f: Plain Note

1. Read the full text.
2. Detect intent — classify as one of:
   - **idea**: Something Santiago might build, try, or implement later. Could be a product feature, a business experiment, a personal project, a process change. The key signal: it's forward-looking and not yet committed to. Examples: "add ELO rankings to Pala," "try cold plunge routine," "what if Tax Free integrated with X." If `type: idea` appears in frontmatter, always classify as idea.
   - **thought**: A reflection, observation, or journal entry — backward-looking or present-tense.
   - **to-do list**: Explicit action items with owners or deadlines.
   - **decision log**: A choice that was made, with reasoning.
   - **other**: Anything that doesn't fit above.
3. Extract any entities, concepts, or project references.
4. If classified as **idea**: extract the idea summary (2-4 sentences preserving Santiago's original intent), determine the domain (`pala-padel`, `tax-free`, `personal`, or `general`), and identify wikilink targets (entities, concepts, projects the idea connects to). Add to the extraction object:
   ```
   idea: {
     title: string (short label for the idea),
     summary: string (2-4 sentences — the idea as Santiago thought it),
     domain: string (pala-padel|tax-free|personal|general),
     links: [ { target: string (entity/concept/project slug), why: string } ]
   }
   ```
5. If it contains a decision or insight, capture it.

#### Phase 2g: Structured Data (JSON/JSONL)

1. Parse the JSON structure.
2. Detect if it's Claude session data (defer to `claude-extract`), export data, or other structured input.
3. If Claude session data, log "Detected Claude session data — defer to claude-extract skill" and skip.
4. Otherwise, extract entities and key data points.

#### Phase 2h: Image

1. Log the image filename and any metadata.
2. If OCR is available, extract text.
3. Otherwise, create a stub reference note with the image embedded.

### Phase 3: Distribute to Wiki

For each extraction object, write to the appropriate wiki locations. All notes must include:
- Frontmatter with `type`, source, date
- `## For future Claude` preamble
- Wikilinks for every entity mention

#### 3a: Entities -> wiki/entities/

For each entity in the extraction:

1. Check if `wiki/entities/[slug].md` exists (slug = lowercase, hyphens for spaces).
2. If exists: append a timeline entry under `## Timeline`:
   ```
   - YYYY-MM-DD: Mentioned in [[source-page-title]] — [context from extraction]. (Source: [source_file])
   ```
   Dedup: skip if an entry with the same date and source page already exists.
   If the extraction contains new compiled truth (decisions, role changes, relationship changes), update the compiled truth section and log the change.
3. If does not exist: apply notability gate.
   - Pass: entity is mentioned in a decision, is an attendee, is referenced in 2+ extractions in this batch, or is explicitly flagged as important.
   - Fail: log "Skipped entity stub for [name] — below notability threshold" and continue.
   - If passes, create stub:
     ```markdown
     ---
     type: person|business
     aliases: []
     first_seen: YYYY-MM-DD
     confidence: low
     ---
     ## For future Claude
     [One-line: who this is and why they matter to Santiago, based on extraction context]

     # [Name]

     [Initial context from the extraction.]

     ## Open Threads
     - [any action items involving this entity]

     ## Timeline
     - YYYY-MM-DD: First seen in [[source-page-title]] — [context]. (Source: [source_file])
     ```

#### 3b: Concepts -> wiki/concepts/

For each concept in the extraction:

1. Check if `wiki/concepts/[slug].md` exists.
2. If exists: check if the new information adds to or contradicts the existing page. If it adds, append under a `## References` section. If it contradicts, flag in `log.md` and update compiled truth.
3. If does not exist: create:
   ```markdown
   ---
   type: concept
   first_seen: YYYY-MM-DD
   sources: ["source_file"]
   ---
   ## For future Claude
   [One-line: what this concept is and why it matters in Santiago's knowledge system]

   # [Concept Name]

   [Description from extraction + personal elaboration from SOUL.md lens]

   ## References
   - YYYY-MM-DD: [[source-page-title]] — [how this concept appeared]. (Source: [source_file])

   ## Connections
   - [wikilinks to related concepts, entities, projects already in the vault]
   ```

#### 3c: Projects -> wiki/projects/

For each project reference in the extraction:

1. Check if `wiki/projects/[slug].md` exists.
2. If exists: append relevant decisions, action items, and insights under the appropriate sections. Update `## Current State` if the extraction contains state-changing information.
3. If does not exist: create a stub project page:
   ```markdown
   ---
   type: project
   status: active
   first_seen: YYYY-MM-DD
   ---
   ## For future Claude
   [One-line: what this project is]

   # [Project Name]

   ## Current State
   [What's known from the extraction]

   ## Decisions
   - YYYY-MM-DD: [decision + reasoning]. (Source: [source_file])

   ## Action Items
   - [ ] [item] — [[owner]]

   ## Timeline
   - YYYY-MM-DD: Project first referenced in [[source-page-title]]. (Source: [source_file])
   ```

#### 3d: Ideas -> wiki/ideas/

For each extraction where `idea` is present (from Phase 2f or any other handler that detects an idea):

1. Generate slug from the idea title: lowercase, hyphens for spaces.
2. Check if `wiki/ideas/[slug].md` exists.
3. If exists: append a new timeline entry. If the new extraction adds context or refines the idea, update the Summary section.
4. If does not exist: create:
   ```markdown
   ---
   type: idea
   status: parked
   domain: [domain from extraction]
   first_seen: YYYY-MM-DD
   source: [source_file]
   ---
   ## For future Claude
   [One-line: what this idea is about and which domain it belongs to]

   # [Idea Title]

   ## Summary
   [2-4 sentences from extraction — preserve Santiago's original intent and nuance]

   ## Links
   - [[link-target]] — [why this connects]

   ## Timeline
   - YYYY-MM-DD: Captured from [[source-page-title]]. (Source: [source_file])
   ```

Ideas are NEVER promoted to projects automatically. Santiago decides when to act on an idea. The `status` field only changes via manual edit or morning brief feedback:
- `parked` — default, sitting in the idea bank
- `exploring` — Santiago is actively thinking about it
- `decided` — committed, a project page should exist
- `dropped` — decided against

#### 3e: Daily -> wiki/daily/

Append a summary of what was ingested to today's daily note at `wiki/daily/YYYY-MM-DD.md`. Create the daily note if it does not exist.

Add under `## Ingested Today`:
```
- [HH:MM] Processed [filename] ([type]): [one-line summary]. Entities: [[entity1]], [[entity2]]. Key insight: [key_insight].
```

#### 3f: Context Files -> wiki/context/

If any extraction contains business-relevant information (references a known business entity, contains decisions tagged to a business, or updates project state), flag the relevant context file for update:

```
Log to log.md:
- YYYY-MM-DDTHH:MM:SS [ingest] Business-relevant content detected for [business]. Flagging context-maintain.
```

The actual context file update is handled by `context-maintain` — ingest only flags it.

### Phase 4: Contradiction Resolution

For each contradiction detected in Phase 2:

1. Read the existing page that contains the conflicting claim.
2. Compare dates: newer information wins by default, unless the existing claim has higher-confidence sourcing.
3. Update the compiled truth section of the existing page with the newer information.
4. Add a log entry:
   ```
   - YYYY-MM-DDTHH:MM:SS [ingest] Contradiction resolved on [[page]]: "[old claim]" replaced with "[new claim]". Source: [source_file]. Reason: [newer date | higher confidence source].
   ```
5. Add the contradiction to the next morning brief's "Attention Required" section by appending to `log.md` with a `[ATTENTION]` tag:
   ```
   - YYYY-MM-DDTHH:MM:SS [ingest] [ATTENTION] Contradiction resolved: [summary]. Review recommended.
   ```

### Phase 5: Archive Originals

For each successfully processed file:

1. Generate timestamp prefix: `YYYYMMDD-HHMMSS`
2. Move file: `raw/[filename]` -> `raw/archive/[timestamp]-[filename]`
3. Log:
   ```
   - YYYY-MM-DDTHH:MM:SS [ingest] Archived raw/[filename] -> raw/archive/[timestamp]-[filename]
   ```

For files that failed processing or were skipped (unknown type), do NOT move them. Log a warning instead.

### Phase 6: Update Index

Update `index.md` with any newly created pages:

For each new page created in this run, add an entry under the appropriate section of the index:
```
- [[wiki/entities/person-name]] — [one-line description]
- [[wiki/concepts/concept-name]] — [one-line description]
- [[wiki/ideas/idea-name]] — [one-line description]
- [[wiki/projects/project-name]] — [one-line description]
```

Dedup: do not add entries that already exist in the index.

### Phase 7: Trigger Downstream Skills

1. Collect all entity names mentioned across all extractions in this run.
2. Trigger `entity-update` with the list of affected entities and source pages.
3. If any business-relevant content was detected, trigger `context-maintain` for the affected businesses.
4. Log:
   ```
   - YYYY-MM-DDTHH:MM:SS [ingest] Triggered entity-update for N entities. Triggered context-maintain for: [business1, business2].
   ```

### Phase 8: Final Log

Write a summary entry to `log.md`:
```
- YYYY-MM-DDTHH:MM:SS [ingest] Run complete. Processed N files. Created: N entity pages, N concept pages, N project stubs. Updated: N existing pages. Contradictions resolved: N. Archived: N files. Skipped: N files.
```

## Output Format

Report to user:
```
Ingest complete:
- Scanned: [N] files in raw/
- Processed: [N] ([breakdown by type])
- Skipped: [N] ([reasons])
- Pages created: [N] (entities: [N], concepts: [N], projects: [N])
- Pages updated: [N]
- Contradictions resolved: [N] (review recommended: [Y/N])
- Archived: [N] files to raw/archive/
- Downstream triggers: entity-update ([N] entities), context-maintain ([list])
```

## Idempotency

Running ingest twice produces the same result because:
1. Files already in `raw/archive/` are never re-processed.
2. Timeline entries are deduped by date + source page.
3. Page creation checks for existing pages before creating.
4. Index entries are deduped.
5. If a file in `raw/` has an identical content hash to a file already in `raw/archive/` (ignoring the timestamp prefix), it is skipped and logged as a duplicate.

## Error Handling

- If a single file fails to process, log the error, skip it, and continue with the remaining files. Do not halt the entire run.
- If writing to a wiki page fails, log the error and continue. The file remains in `raw/` (not archived) so it will be retried on the next run.
- If `entity-update` or `context-maintain` triggers fail, log the failure but consider the ingest run itself successful.

## Cron

Nightly at 10 PM + manual trigger via "ingest" or "process raw".

## Dependencies

- Reads: `SOUL.md`, `CRITICAL_FACTS.md`, `index.md`, all `wiki/` pages (for dedup and contradiction detection)
- Writes: `wiki/entities/`, `wiki/concepts/`, `wiki/ideas/`, `wiki/projects/`, `wiki/daily/`, `log.md`, `index.md`
- Moves: `raw/*` -> `raw/archive/*`
- Triggers: `entity-update` (post-processing), `context-maintain` (when business-relevant content detected)

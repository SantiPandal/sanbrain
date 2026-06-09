---
name: morning-brief
version: 1.1.0
description: |
  The daily deliverable. Creates a single, concise file that Santiago reads
  every morning to know what happened overnight, what needs attention, and
  what connections emerged. Replaces daily-compile as the primary output skill.
triggers:
  - "morning brief"
  - "daily brief"
  - "what happened overnight"
  - "brief me"
tools:
  - exec
  - read
  - write
mutating: true
---

# Morning Brief

## Contract

Every morning, this skill produces a single file that gives Santiago complete awareness of:
1. What changed in the vault since the last brief
2. New connections between recent inputs and existing knowledge
3. Items requiring his review or decision
4. The health of the vault itself

Guarantees:
- One file per day: `wiki/daily/YYYY-MM-DD-brief.md`
- Every change since the last brief is accounted for
- Connections are non-obvious (not just "X was mentioned in Y" — actual insight)
- Review prompts are actionable
- Vault health metrics are accurate
- Running twice on the same day updates the existing brief (idempotent)

## Constants

```
VAULT_PATH="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT"
WIKI_DIR="$VAULT_PATH/wiki"
DAILY_DIR="$VAULT_PATH/wiki/daily"
ENTITIES_DIR="$VAULT_PATH/wiki/entities"
CONCEPTS_DIR="$VAULT_PATH/wiki/concepts"
IDEAS_DIR="$VAULT_PATH/wiki/ideas"
PROJECTS_DIR="$VAULT_PATH/wiki/projects"
CONTEXT_DIR="$VAULT_PATH/wiki/context"
LOGS_DIR="$VAULT_PATH/wiki/logs"
LOG_FILE="$VAULT_PATH/log.md"
INDEX_FILE="$VAULT_PATH/index.md"
SOUL_FILE="$VAULT_PATH/SOUL.md"
CRITICAL_FACTS="$VAULT_PATH/CRITICAL_FACTS.md"
```

## Output Format

The brief is written to `wiki/daily/YYYY-MM-DD-brief.md`:

```markdown
---
type: daily-brief
date: YYYY-MM-DD
generated: YYYY-MM-DDTHH:MM:SS
previous_brief: YYYY-MM-DD
changes_since: YYYY-MM-DDTHH:MM:SS
---
## For future Claude
Daily brief for Santiago. Contains all vault changes since the last brief,
new connections surfaced by the system, and items requiring human review.
Read this to understand the current state of the knowledge system.

# [Day of week], [Month DD, YYYY] -- Morning Brief

## What Changed Overnight
[Bullet list of every page created or updated since last brief, grouped by category]

### New Pages
- [[wiki/entities/person-name]] -- [one-line: who and why created]
- [[wiki/concepts/concept-name]] -- [one-line: what it captures]

### New Ideas Captured
- [[wiki/ideas/idea-slug]] -- [one-line summary, domain]

### Updated Pages
- [[wiki/entities/person-name]] -- [what changed: new timeline entry, compiled truth rewrite, enrichment]
- [[wiki/projects/project-name]] -- [what changed: new decision, status update]
- [[wiki/context/business.md]] -- context rewritten

### Context Files Rewritten
- [[wiki/context/pala-padel.md]] -- [key change summary]

### Ingested Files
- [filename] ([type]) -- processed and archived. Key output: [summary]

## New Connections
[Non-obvious links between recent inputs and existing knowledge. These should
be genuine insights, not mechanical "X was mentioned in Y" observations.]

- [connection 1: explain the link and why it matters]
- [connection 2]

## Attention Required
- [ ] [item needing Santiago's review or decision -- be specific about what action is needed]
- [ ] [contradiction flagged during ingest: "[old claim]" vs "[new claim]" on [[page]] -- confirm which is correct]
- [ ] [proposed entity merge: [[entity-a]] and [[entity-b]] may be duplicates -- confirm or reject]
- [ ] [stale context: [[page]] has not been updated in N days -- still accurate?]

## Active Threads Across All Businesses
[Aggregated from context files -- the top open items across all of Santiago's work]

### Pala Padel
- [most important active thread]

### Tax Free
- [most important active thread]

### Personal
- [most important personal thread]

## Idea Bank
[Surface parked ideas when they connect to today's context — a recent decision,
a new connection, or an active thread that an idea could solve. Do NOT list all
parked ideas every day. Only surface an idea when there's a reason to recall it.]

- [[wiki/ideas/idea-slug]] -- [why it's relevant today: connects to active thread X, related to yesterday's decision about Y]

[If no ideas are relevant today, omit this section entirely.]

## Questions for Santiago
[3-5 questions the brief is asking Santiago to answer. These prompt him to provide
context that feeds back into the system via Phase 0.5. Each question should be
specific, not generic — derived from real gaps in the vault.]

- [ ] [question about an open thread where the vault lacks a recent status update]
- [ ] [question about an entity whose compiled truth has an unresolved ambiguity]
- [ ] [question about today's calendar — "You have [meeting] at [time]. What's the goal / what do you need from it?" One per meeting, max 2.]
- [ ] [question about a stale attention item that's been carried 2+ briefs]
- [ ] [forward-looking question: "What are you working on today?" — the answer becomes tomorrow's context]

## Review
Edit this file directly in Obsidian:
- Check `[x]` any resolved attention items or answered questions
- Add inline comments below any item that needs context
- Write free text anywhere — the system reads every edit

## Vault Health
- Total pages: [N]
- Entities: [N] people, [N] businesses
- Concepts: [N]
- Ideas: [N] parked, [N] exploring
- Projects: [N]
- Pages created since last brief: [N]
- Pages updated since last brief: [N]
- Stale pages (30+ days untouched): [N] [list top 5 if any]
- Orphan pages (no inbound wikilinks): [N] [list all if <10, top 5 if more]
- Context files: [N], last full refresh: [date]
```

## Phases

### Phase 0: Determine Time Window

1. Find the most recent previous brief by scanning `wiki/daily/` for files matching `*-brief.md`, sorted by date descending.
2. If a previous brief exists: read its `generated:` timestamp. The time window is from that timestamp to now.
3. If no previous brief exists: use the last 48 hours as the window. Log:
   ```
   - YYYY-MM-DDTHH:MM:SS [morning-brief] No previous brief found. Using 48-hour window.
   ```
4. Store the window boundaries: `since_timestamp` and `now_timestamp`.

### Phase 0.5: Read Previous Brief Feedback

If a previous brief exists, read it fully and scan the `## Attention Required` section:

1. **Checked items** (`- [x]`): Santiago resolved these. Do NOT carry them forward. If the item has an inline comment or a line below it, treat that as Santiago's decision — propagate it to the relevant entity/context page if it changes compiled truth (e.g., "CONFIRMED ARCHIVED" should update the entity's status).
2. **Unchecked items** (`- [ ]`) with added comments: Santiago acknowledged but hasn't resolved. Carry forward WITH his comment as context.
3. **Unchecked items with no comment**: Still unresolved. Carry forward as-is. If carried for 3+ briefs, escalate to top of attention list with "STALE — open since [date]".
4. **Any free-text Santiago added** anywhere in the brief (below sections, inline notes): Treat as input. If it contains a decision, entity update, or new information, flag it for context-maintain or entity-update propagation.

This is Santiago's primary feedback mechanism. The brief is a living document he edits in Obsidian — respect every edit.

### Phase 1: Inventory Changes

Read `log.md` and extract all entries within the time window. Categorize:

| Category | How to detect |
|---|---|
| Pages created | `[ingest] Created`, `[entity-update] Created stub`, `[claude-extract]` with "created" |
| Pages updated | `[entity-update] Compiled truth updated`, `[entity-update] Vault-enriched`, timeline entries added |
| Context rewrites | `[context-maintain] Rewrote` |
| Files ingested | `[ingest] Archived` |
| Contradictions | `[ATTENTION]` tag entries |
| Proposed merges | `[entity-update] [ATTENTION] Possible duplicate` |
| Errors | Any `[ERROR]` or `[WARNING]` entries |

Additionally, use filesystem modification times to catch any vault changes not captured in `log.md`:
- Scan all files under `wiki/` modified since `since_timestamp`.
- Cross-reference with log entries. Any modified file NOT in the log gets flagged:
  ```
  - [[page]] -- modified at [timestamp] but no log entry found (manual edit?)
  ```

### Phase 2: Read Context

1. Read `SOUL.md` — needed for connection synthesis (Santiago's frameworks, thinkers, growth edges).
2. Read `CRITICAL_FACTS.md` — for grounding.
3. Read all `wiki/context/` files — for active threads aggregation.
4. Read the changed pages identified in Phase 1 — needed to understand WHAT changed, not just THAT it changed.

### Phase 3: Surface Connections

This is the highest-value phase. Analyze the changed pages through Santiago's lens (from `SOUL.md`) and look for:

1. **Cross-domain links**: Does a concept from a book or article apply to a current business problem? Does a pattern from one business appear in another?

2. **Thinker connections**: Would Munger's inversion illuminate a recent decision? Does a Deutsch hard-to-vary explanation apply? Would Hormozi's offer lens change how a business thread is approached?

3. **Pattern recognition**: Are multiple recent inputs pointing to the same underlying theme? (e.g., three different conversations all touching on pricing strategy)

4. **Blind spot alerts**: Does any recent activity trigger one of Santiago's known blind spots from `SOUL.md`? (e.g., optimizing relationships like systems, reflexive rejection of feedback, treating everything as an achievement problem)

5. **Temporal connections**: Has something that was an open question 2+ weeks ago been answered by recent inputs? Has a prediction been confirmed or falsified?

Rules for connections:
- Quality over quantity. One genuine insight > five forced connections.
- Each connection must explain WHY it matters, not just THAT a link exists.
- If no non-obvious connections exist today, write "No significant new connections today." Do not fabricate.
- Maximum 5 connections per brief. If more exist, pick the most actionable.

### Phase 3.5: Surface Relevant Ideas

Read all `wiki/ideas/` pages with `status: parked` or `status: exploring`.

For each idea, check if it connects to today's context:
1. Does the idea's `domain` match a business with an active thread that the idea could address?
2. Does the idea link to an entity or concept that appeared in overnight changes?
3. Was the idea mentioned or related to a recent decision?
4. Has the idea been parked for 30+ days without being surfaced? (Periodic reminder.)

If any connections exist, include the idea in the brief's `## Idea Bank` section with a one-line explanation of WHY it's relevant today.

Rules:
- Maximum 3 ideas per brief. Pick the most relevant.
- If no ideas connect to today's context, omit the section entirely.
- Never nag about the same idea on consecutive days. Track which ideas were surfaced in the previous brief (from Phase 0.5) and skip them unless new context emerged.

### Phase 4: Compile Attention Items

Aggregate all items requiring Santiago's review or decision:

1. **Contradictions** from `[ATTENTION]` log entries: present the conflict clearly and ask for confirmation.
2. **Proposed merges** from entity-update duplicate detection.
3. **Stale pages**: entity pages where compiled truth references facts older than 30 days with no recent confirmation. Context files not refreshed in 7+ days.
4. **Unresolved open threads**: action items from entity or project pages that have been open for 14+ days.
5. **Failed skill runs**: any errors logged by other skills since the last brief.
6. **Downloads one-way doors**: If `raw/downloads-manifest-*.md` exists for today or yesterday (manifests are system files — ingest never archives them; nightly.sh rotates them mechanically), read the newest one and copy its `## One-Way Doors` section verbatim as a sub-section of Attention Required. Present the checkboxes EXACTLY as written in the manifest — `- [ ] **name** (size, date)` — do not rephrase the bolded filenames; the deletion script validates checked names against the manifest, so altered names will never be deleted. Group header: "### Downloads — pending deletion approval".

Each attention item must be actionable: state what Santiago needs to DO, not just what happened.

### Phase 5: Aggregate Active Threads

Read all `wiki/context/` files. For each business and personal context:
1. Pull the `## Active Threads` section.
2. Select the single most important thread per subject.
3. If a context file is stale (not rewritten in 7+ days), note it.

This gives Santiago a one-screen view of what's in motion across his entire world.

### Phase 5.5: Generate Questions

Generate 3-5 specific questions for Santiago. These are the brief's self-solving mechanism — his answers become tomorrow's input via Phase 0.5.

Sources for questions (in priority order):

1. **Carried attention items** (2+ briefs old): Ask for a status update or decision. e.g., "Launchers has been open for 4 days — archive or activate?"
2. **Entity gaps**: Entities with `confidence: low` or missing key fields. e.g., "What's [[person]]'s role at [[company]]?"
3. **Today's calendar**: If the morning.sh script passed calendar context (via `$TODAY_EVENTS`), generate a question for each meeting: "You have [meeting] at [time]. What's the agenda / what do you need from it?" These prime Santiago to record and capture context.
4. **Stale active threads**: Context file threads with no log activity in 7+ days. e.g., "Is the Tax Free term-sheet negotiation still active?"
5. **Forward-looking**: Always end with "What are you working on today?" — the answer becomes the next brief's context and triggers calendar-based reminders.

Rules for questions:
- Checkbox format (`- [ ]`) so Santiago can answer inline
- Specific, not generic. "How's business?" is worthless. "Did the Mario meeting happen?" is useful.
- Maximum 5 questions. If more exist, pick the most time-sensitive.
- One question per attention item max — don't duplicate the attention section.

### Phase 6: Compute Vault Health

**If a Vault Doctor report was provided in your prompt (or exists at
`wiki/logs/doctor-YYYY-MM-DD.md` for today): use its numbers directly — do NOT
recompute counts, orphans, or staleness yourself.** The doctor is mechanical and
exhaustive; your job is only to (a) copy its metrics into the Vault Health
section, (b) turn its Findings into Attention Required items where action is
needed (broken links, unpropagated attendees, sensors failing 48h+, raw/
backlog), and (c) link the report.

Only if no doctor report exists, fall back to scanning the vault yourself:

1. **Total pages**: count all `.md` files under `wiki/`.
2. **Entities**: count files in `wiki/entities/`. Separate by `type: person` and `type: business` from frontmatter.
3. **Concepts**: count files in `wiki/concepts/`.
4. **Ideas**: count files in `wiki/ideas/`. Separate by `status: parked` and `status: exploring` from frontmatter.
5. **Projects**: count files in `wiki/projects/`.
6. **Created since last brief**: count from Phase 1 inventory.
7. **Updated since last brief**: count from Phase 1 inventory.
8. **Stale pages**: files in `wiki/` not modified in 30+ days. List top 5 by staleness.
9. **Orphan pages**: pages with zero inbound wikilinks from other pages. To compute:
   - Build a set of all wikilink targets across all vault pages.
   - Any page NOT in that set is an orphan.
   - Exclude `_CLAUDE.md`, `index.md`, `log.md`, `SOUL.md`, `CRITICAL_FACTS.md` (root-level files are not expected to have inbound links).
10. **Context files**: count, plus date of the oldest `last_updated` across all context files.

### Phase 7: Write the Brief

1. Check if `wiki/daily/YYYY-MM-DD-brief.md` already exists for today.
   - If yes: this is a re-run. Overwrite the file entirely (idempotent).
   - If no: create the file.
2. Populate every section of the output format using data from Phases 1-6.
3. Set frontmatter fields: `date`, `generated` (current timestamp), `previous_brief` (date of the last brief), `changes_since` (the `since_timestamp` from Phase 0).

### Phase 8: Log

```
- YYYY-MM-DDTHH:MM:SS [morning-brief] Brief written: [[wiki/daily/YYYY-MM-DD-brief.md]]. Window: [since_timestamp] to [now_timestamp]. Changes: [N] created, [N] updated. Connections: [N]. Attention items: [N]. Vault: [N] total pages.
```

## Idempotency

Running twice on the same day produces the same result because:
1. The brief file is fully overwritten (not appended).
2. The time window is determined by the PREVIOUS brief, not the current one being written.
3. All data is re-read fresh from source pages and logs.
4. Vault health metrics are recomputed each time.

## Edge Cases

- **First brief ever**: No previous brief exists. Use 48-hour window. Note in the brief: "This is the first morning brief. Prior vault activity may not be fully captured."
- **No changes since last brief**: Write a brief anyway with "No changes since last brief" in the changes section. Still compute vault health and active threads — Santiago should still see the overview.
- **Very large number of changes**: If 50+ pages were created/updated, group by category and summarize instead of listing each one. "Entity update processed 47 entities from ingest run — [top 5 listed], plus 42 others."
- **Missing SOUL.md**: Skip connection synthesis. Note in the brief: "SOUL.md not found — connection synthesis unavailable."
- **Missing context files**: Skip active threads aggregation for that business. Note it as an attention item: "No context file for [business]. Run context-maintain."
- **Brief requested mid-day**: The skill works the same regardless of time — it always looks at changes since the last brief. A mid-day run captures morning activity; the next morning run captures the rest.

## Cron

Daily at 7 AM + manual trigger via "morning brief" or "brief me".

## Dependencies

- Reads: `log.md`, `SOUL.md`, `CRITICAL_FACTS.md`, `wiki/context/`, `wiki/entities/`, `wiki/concepts/`, `wiki/ideas/`, `wiki/projects/`, `wiki/daily/` (previous briefs), `index.md`, all recently modified vault pages
- Writes: `wiki/daily/YYYY-MM-DD-brief.md`, `log.md`
- Triggered by: 7 AM cron, manual trigger
- Triggers: nothing downstream (morning-brief is a terminal, read-heavy skill)

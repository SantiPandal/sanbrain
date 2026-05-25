---
name: claude-extract
version: 2.0.0
description: |
  Extract decisions, entities, insights, and action items from Claude Code
  sessions. This captures Santiago's highest-volume data source — his AI
  conversations — and distributes the knowledge across the vault's wiki/
  structure. Only reads Claude Code local sessions (not Claude.ai cloud data).
triggers:
  - "extract from claude"
  - "pull claude sessions"
  - "what did I discuss in claude"
  - "sync claude to vault"
tools:
  - exec
  - read
  - write
mutating: true
---

# Claude Extract

## Contract

Given access to Claude Code session data, this skill:

1. Reads recent Claude Code session transcripts and memory files from `~/.claude/projects/`
2. Extracts all entities (people, businesses) mentioned
3. Extracts decisions made, insights generated, frameworks applied, and action items
4. Determines the problem context for each session (what was being worked on)
5. Writes/updates relevant pages in `wiki/` (entities, projects, context)
6. Deduplicates against existing vault content before writing
7. Logs every action to `log.md`
8. Triggers `entity-update` for all affected entities

Idempotent: uses date + content hash to prevent duplicate entries. Safe to run hourly.

## Constants

```
VAULT_PATH="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT"
WIKI_DIR="$VAULT_PATH/wiki"
LOG_FILE="$VAULT_PATH/log.md"
INDEX_FILE="$VAULT_PATH/index.md"
SOUL_FILE="$VAULT_PATH/SOUL.md"

# Claude Code paths (only source — Claude.ai data is cloud-only)
CLAUDE_CODE_PROJECTS="$HOME/.claude/projects"
CLAUDE_CODE_SESSIONS="$HOME/.claude/projects/*/sessions"
```

## Phases

### Phase 0: Locate Sources

1. Scan `$CLAUDE_CODE_PROJECTS` for project directories. Each project dir may contain:
   - `*.jsonl` files (session transcripts)
   - `memory/` subdirectory (persistent memory files, including `MEMORY.md`)

2. Determine the "last extraction" timestamp. Check `log.md` for the most recent `[claude-extract] Run complete` entry. Only process sessions and memory files modified after that timestamp. If no previous run found, process the last 7 days of data.

3. Log:
   ```
   - YYYY-MM-DDTHH:MM:SS [claude-extract] Sources located. Claude Code projects: [N]. Processing since: [timestamp].
   ```

### Phase 1: Read Claude Code Sessions

For each project directory under `$CLAUDE_CODE_PROJECTS`:

1. List `*.jsonl` files modified since last extraction.
2. For each session file, read the JSONL entries. Each line is a JSON object representing a message in the conversation.
3. Extract from the conversation:

   **Session metadata:**
   - Project name (from directory name)
   - Session date (from file modification time or first message timestamp)
   - Duration estimate (from first to last message timestamp)

   **Content extraction:**
   - **Problem context**: What was Santiago trying to solve? Look at the first few user messages to determine the task.
   - **Decisions made**: Any explicit choices ("let's go with X", "I decided to", "we should use", architectural choices, technology selections).
   - **Entities mentioned**: People names (not generic pronouns), business names, product names. Cross-reference against known entities in `wiki/entities/`.
   - **Insights**: Non-obvious observations, "aha" moments, framework applications. Look for messages where Santiago or Claude articulated something that changed understanding.
   - **Action items**: Tasks committed to ("I need to", "next step is", "TODO", "let's do X tomorrow").
   - **Frameworks applied**: References to Santiago's thinkers (Munger, Naval, Deutsch, Hormozi, etc.) or specific mental models.
   - **Technical decisions**: Architecture choices, library selections, design patterns chosen, trade-offs discussed.

4. Build an extraction object per session:
   ```
   {
     source: "claude-code",
     project: string,
     session_file: string,
     date: YYYY-MM-DD,
     problem_context: string,
     decisions: [ { decision, reasoning, category: business|technical|personal } ],
     entities: [ { name, type: person|business, context } ],
     insights: [ { insight, domain, connected_thinker? } ],
     action_items: [ { item, status: open|done, deadline? } ],
     frameworks: [ { name, how_applied } ],
     content_hash: string (hash of key extracted fields for dedup)
   }
   ```

### Phase 2: Read Claude Code Memory Files

For each project directory under `$CLAUDE_CODE_PROJECTS`:

1. Check for `memory/MEMORY.md` and any other files in `memory/`.
2. Memory files contain persistent facts, preferences, and patterns the agent learned about Santiago.
3. Extract:
   - **Stated preferences**: coding style, tool choices, workflow patterns.
   - **Learned facts**: about Santiago, his businesses, his people.
   - **Decisions recorded**: choices that were persisted as memory.
4. These are lower-frequency but higher-signal than session transcripts.

### Phase 3: Deduplicate

Before writing anything to the vault:

1. For each extraction, compute a content hash from: `date + decision_text` (for decisions), `date + entity_name + context` (for entity mentions), `date + insight_text` (for insights).
2. Read existing timeline entries in target wiki pages.
3. Skip any extraction where:
   - A timeline entry with the same date and matching content hash already exists.
   - The decision text is semantically identical to an existing entry (same date, >90% similar wording).
4. Log skipped duplicates:
   ```
   - YYYY-MM-DDTHH:MM:SS [claude-extract] Skipped duplicate: [type] "[summary]" on [date] — already in [[page]].
   ```

### Phase 4: Write to Vault

For each non-duplicate extraction, write to the appropriate wiki locations.

#### 5a: Entities -> wiki/entities/

For each entity mentioned in sessions:

1. Check if `wiki/entities/[slug].md` exists.
2. If exists: append timeline entry under `## Timeline` (newest first):
   ```
   - YYYY-MM-DD: Discussed in Claude Code session ([project]) — [context of mention]. (Source: claude-code/[session_file])
   ```
   If the session revealed new information about the entity (role change, new relationship context, decision involving them), update the compiled truth section.
3. If does not exist: apply notability gate.
   - Pass if: entity is involved in a decision, is mentioned in 2+ sessions, or is clearly relevant to a business.
   - Create stub:
     ```markdown
     ---
     type: person|business
     aliases: []
     first_seen: YYYY-MM-DD
     confidence: medium
     ---
     ## For future Claude
     [One-line: who this is and why they appeared in Santiago's Claude sessions]

     # [Name]

     [Context from Claude sessions.]

     ## Open Threads
     - [any action items involving this entity]

     ## Timeline
     - YYYY-MM-DD: First mentioned in Claude Code session ([project]) — [context]. (Source: claude-code/[session_file])
     ```

#### 5b: Projects -> wiki/projects/

For each session that was working on a recognizable project:

1. Check if a project page exists in `wiki/projects/`.
2. If exists: append decisions under `## Decisions`, action items under `## Action Items`, and a timeline entry:
   ```
   - YYYY-MM-DD: Claude Code session — [problem_context]. [decisions made, if any]. (Source: claude-code/[session_file])
   ```
3. If does not exist and the session represents meaningful project work (not a one-off question): create a project stub.

#### 5c: Insights -> wiki/concepts/

For insights that articulate a reusable framework, mental model, or cross-domain connection:

1. Check if a relevant concept page exists in `wiki/concepts/`.
2. If exists: add a reference entry linking the insight to its source session.
3. If the insight is novel enough to warrant its own concept page (new framework, new synthesis): create it.
4. Most insights should be appended to existing entity or project pages rather than creating new concept pages. Only create concept pages for genuinely reusable ideas.

#### 5d: Context flagging

If any extraction contains information relevant to a known business (Pala Padel, Tax Free):

1. Log with `[CONTEXT]` tag:
   ```
   - YYYY-MM-DDTHH:MM:SS [claude-extract] [CONTEXT] Business-relevant content for [business]: [summary]. Flagging context-maintain.
   ```
2. The `context-maintain` skill reads these flags on its next run.

### Phase 5: Log and Report

Write to `log.md`:
```
- YYYY-MM-DDTHH:MM:SS [claude-extract] Run complete. Sessions processed: [N]. Memory files read: [N]. Decisions: [N] new, [N] duplicate. Entities: [N] updated, [N] created. Insights: [N]. Action items: [N]. Context flags: [N].
```

### Phase 6: Trigger Downstream

1. Collect all entity names from this run's extractions.
2. Trigger `entity-update` with the list of affected entities and their source pages.
3. If business-relevant content was flagged, trigger `context-maintain` for those businesses.

## Output Format

Report to user:
```
Claude extraction complete:
- Sources: [N] Claude Code sessions, [N] memory files
- Period: [start_date] to [end_date]
- Decisions logged: [N] ([N] business, [N] technical, [N] personal)
- Entities: [N] updated, [N] new stubs created
- Insights captured: [N]
- Action items: [N] open, [N] completed
- Context flags: [list of businesses flagged]
- Duplicates skipped: [N]
- Downstream: entity-update triggered for [N] entities
```

## Idempotency

Running twice produces the same result because:
1. The "last extraction" timestamp ensures already-processed sessions are skipped.
2. Content hashes prevent duplicate timeline entries.
3. Entity stubs are not recreated if the page already exists.
4. As a fallback, even without the timestamp check, the per-entry dedup in Phase 3 catches duplicates.

## Edge Cases

- **Very long sessions** (1000+ messages): Focus extraction on the last 200 messages + the first 20 (which establish context). Log that the session was truncated.
- **Sessions with no extractable content** (e.g., pure debugging with no decisions): Log "No extractable content in [session_file]" and skip.
- **Corrupted JSONL**: If a line fails to parse, skip it and log a warning. Do not halt the entire session.

## Cron

Daily + manual trigger. Can safely run every few hours if more frequent extraction is desired.

## Dependencies

- Reads: `~/.claude/projects/` (Claude Code sessions + memory), `SOUL.md`, `wiki/` pages (for dedup)
- Writes: `wiki/entities/`, `wiki/projects/`, `wiki/concepts/`, `log.md`, `index.md`
- Triggers: `entity-update` (post-write), `context-maintain` (when business-relevant)

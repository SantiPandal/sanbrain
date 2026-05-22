---
name: context-maintain
version: 1.0.0
description: |
  Maintains living context files in wiki/context/. One file per business plus
  one personal. These files are the "what's true RIGHT NOW" snapshot that any
  agent or human reads for instant situational awareness. The entire context
  file is rewritten on each run (not appended) to ensure it always reflects
  current state.
triggers:
  - "update context"
  - "refresh context"
  - "what's current"
  - auto-fires when ingest or claude-extract flags business-relevant content
tools:
  - read
  - write
mutating: true
---

# Context Maintain

## Contract

This skill maintains a set of living context files that answer the question: "What is true RIGHT NOW about [subject]?" For any agent (OpenClaw, Claude Code, Claude.ai) or for Santiago himself, reading a context file gives instant, complete situational awareness without needing to search the vault.

Guarantees:
1. One context file per tracked business + one personal context file
2. Each file is fully rewritten on every run (not appended) — always current
3. All claims in context files are sourced from vault pages (traceable)
4. Context files contain zero stale information — anything not confirmed by recent vault data is dropped
5. Every rewrite is logged to `log.md`
6. Wikilinks connect context files to all referenced entity and project pages

## Constants

```
VAULT_PATH="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT"
CONTEXT_DIR="$VAULT_PATH/wiki/context"
ENTITIES_DIR="$VAULT_PATH/wiki/entities"
PROJECTS_DIR="$VAULT_PATH/wiki/projects"
DAILY_DIR="$VAULT_PATH/wiki/daily"
LOG_FILE="$VAULT_PATH/log.md"
SOUL_FILE="$VAULT_PATH/SOUL.md"
CRITICAL_FACTS="$VAULT_PATH/CRITICAL_FACTS.md"
```

## Context Files

The skill maintains these files:

| File | Subject | Key Sources |
|---|---|---|
| `wiki/context/pala-padel.md` | Pala Padel — Tournament/league platform | Entity pages for Fer, León, Rafa; project pages; user metrics |
| `wiki/context/tax-free.md` | Tax Free — AI automation for tourist VAT refund processing | Entity pages for Mario Pasquel; project pages; SAT integration |
| `wiki/context/personal.md` | Santiago's personal context | SOUL.md; personal goals; fitness; relationships; skills; daily notes |

If a new business emerges in the vault (detected by entity pages with `type: business` not covered by an existing context file), the skill creates a new context file for it and logs the creation.

## Context File Format

Every context file follows this exact structure:

```markdown
---
type: context
subject: [business-slug|personal]
last_updated: YYYY-MM-DD
updated_by: context-maintain
sources: [list of key pages read to produce this file]
---
## For future Claude
This is the living context file for [subject]. Read this for instant situational
awareness. Rewritten automatically by context-maintain. Every claim here is sourced
from vault pages listed in the frontmatter. If something is missing, it means the
vault does not yet have that information.

# [Subject] -- Context

## Current State
[What's true right now. For businesses: stage, revenue/ARR, users, team size,
current sprint/focus, primary blocker. For personal: current priorities, energy
state, active life threads. Keep this to 3-8 bullet points. Hard facts only.]

## Key People
- [[person-slug]] -- role, current state of relationship, last interaction date
- [[person-slug]] -- role, current state of relationship, last interaction date

## Recent Decisions
- YYYY-MM-DD: [decision + one-line reasoning]. (Source: [[page]])
- YYYY-MM-DD: [decision + one-line reasoning]. (Source: [[page]])

## Open Questions
- [unresolved strategic question — things Santiago is still thinking about]
- [unresolved strategic question]

## Active Threads
- [thing in motion: waiting on X, deadline Y, next step Z]
- [thing in motion]

## Last 7 Days
- YYYY-MM-DD: [summary of that day's relevant activity]
- YYYY-MM-DD: [summary]
- ...
```

## Phases

### Phase 0: Determine Scope

The skill can be triggered in two ways:

**A. Targeted trigger**: Another skill (ingest, claude-extract) flagged specific businesses as having new relevant content. The `[CONTEXT]` entries in `log.md` indicate which businesses need updating.
1. Read recent `[CONTEXT]` entries from `log.md`.
2. Only rewrite the context files for the flagged businesses.

**B. Full refresh**: Manual trigger or scheduled run.
1. Rewrite ALL context files (all businesses + personal).

In both cases, read `SOUL.md` and `CRITICAL_FACTS.md` first — they inform all context files.

### Phase 1: Gather Sources (per subject)

For each context file being rewritten, gather ALL relevant vault pages. Read them fully.

#### For business context files:

1. **Entity pages**: Read all `wiki/entities/` pages where the entity is:
   - The business itself (e.g., `wiki/entities/cargo-claro.md`)
   - A person linked to the business (check compiled truth and timeline for business mentions)
   - Search entity pages for wikilinks to or mentions of the business name

2. **Project pages**: Read all `wiki/projects/` pages related to the business. Detect by:
   - Explicit business tag in frontmatter
   - Business name in the project title or compiled truth
   - Wikilinks between project and business entity pages

3. **Daily notes**: Read the last 7 days of `wiki/daily/` entries. Extract any mentions of the business.

4. **Log entries**: Read `log.md` for recent `[CONTEXT]` flags and other entries mentioning the business.

5. **The existing context file**: Read the current version of the context file being rewritten. This helps preserve information that hasn't changed — but the skill should NOT blindly copy sections. Every claim must be re-verified against source pages.

#### For personal context file:

1. **SOUL.md**: Read fully — this is the foundation of personal context.
2. **CRITICAL_FACTS.md**: Read fully.
3. **Daily notes**: Last 7 days from `wiki/daily/`.
4. **Personal entity pages**: Any entity pages about Santiago or his personal relationships (non-business).
5. **Personal project pages**: Projects not tied to a specific business.
6. **Log entries**: Recent `log.md` entries for personal items.

### Phase 2: Synthesize Current State

For each context file, synthesize the gathered sources into the context file format.

#### Current State section:
- Extract ONLY facts that are currently true. If a source page says "revenue is $50K ARR" but a newer source says "revenue is $80K ARR," use the newer figure.
- If a fact's recency is uncertain, note it: "Revenue: ~$50K ARR (as of YYYY-MM-DD)".
- For businesses: stage, revenue, users, team, current focus, primary blocker.
- For personal: current priorities, fitness routine, active learning, relationship state, energy level.

#### Key People section:
- List all people actively involved with the subject.
- For each person, pull from their entity page: role, relationship state, date of last timeline entry.
- Use wikilinks: `[[person-slug]]`.
- Do NOT list people who haven't been mentioned in the last 30 days unless they hold a permanent role (co-founder, partner).

#### Recent Decisions section:
- Pull decisions from entity timeline entries, project pages, and daily notes.
- Only include decisions from the last 30 days.
- Include the reasoning (not just the decision) and the source page.
- Newest first. Maximum 10 entries.

#### Open Questions section:
- Pull from entity pages' `## Open Threads`, project pages' unresolved items, and any `[ATTENTION]` log entries.
- These are strategic questions, not action items. "Should we pivot pricing?" not "Send the invoice."

#### Active Threads section:
- Things currently in motion: pending responses, upcoming deadlines, work in progress.
- Include the next concrete step for each thread.
- Pull from action items across all source pages.

#### Last 7 Days section:
- One line per day, summarizing the most relevant activity for this subject.
- If nothing happened on a given day, omit that day (don't write "no activity").
- Source from daily notes and timeline entries.

### Phase 3: Write Context File

1. Construct the full context file following the format specification exactly.
2. Populate the `sources:` field in frontmatter with the paths of all pages read during Phase 1.
3. Set `last_updated:` to today's date.
4. Write the file, completely replacing the previous version.

This is a FULL REWRITE. The old file is entirely replaced. This prevents information drift and ensures the context file is always a clean, current snapshot.

### Phase 4: Verify Quality

After writing, perform these checks:

1. **No orphan claims**: Every factual claim in the context file should be traceable to a source page listed in `sources:`. If a claim has no source, remove it or mark it as unverified.
2. **No stale information**: If a fact hasn't been confirmed by a source modified in the last 60 days, add a staleness marker: "(last confirmed: YYYY-MM-DD)".
3. **All wikilinks resolve**: Every `[[entity-slug]]` in the file should correspond to an actual page in `wiki/entities/`. If not, either create a stub (defer to entity-update) or remove the wikilink and use plain text.
4. **Reasonable length**: Context files should be 50-200 lines. If longer, the Current State section is probably too verbose — compress it.

### Phase 5: Log

For each context file rewritten:
```
- YYYY-MM-DDTHH:MM:SS [context-maintain] Rewrote [[wiki/context/subject.md]]. Sources read: [N] pages. Key people: [N]. Recent decisions: [N]. Open questions: [N]. Active threads: [N].
```

If a new context file was created for a previously untracked business:
```
- YYYY-MM-DDTHH:MM:SS [context-maintain] Created new context file: [[wiki/context/new-business.md]]. Detected from entity pages.
```

## Output Format

Report to user:
```
Context maintenance complete:
- Files rewritten: [N]
  - pala-padel.md: [N] sources, [N] key people, [N] decisions, [N] threads
  - tax-free.md: [N] sources, [N] key people, [N] decisions, [N] threads
  - personal.md: [N] sources, [N] active priorities
- New context files created: [N]
- Stale markers added: [N]
- Orphan claims removed: [N]
```

## Idempotency

Running twice produces the same result because:
1. The context file is fully rewritten each time (not appended).
2. The same source pages produce the same synthesized output.
3. There is no cumulative state — each run reads sources fresh and writes a clean snapshot.

## Edge Cases

- **New business detected**: If a `type: business` entity page exists in `wiki/entities/` but has no corresponding context file, create one. Use whatever vault information exists. Log the creation.
- **Business becomes inactive**: If no source pages mention the business in the last 60 days, still maintain the context file but add a note at the top of Current State: "No vault activity in 60+ days. Context may be stale."
- **Conflicting information across sources**: Use the most recent source. Note the conflict in `## Open Questions`: "Conflicting information about [topic] — [[source-a]] says X, [[source-b]] says Y. Needs resolution."
- **SOUL.md or CRITICAL_FACTS.md missing**: Log a warning but continue. Personal context will be less informed.
- **Empty source data**: If no source pages contain relevant information for a business, write a minimal context file with just the business name and a note: "Insufficient vault data. Add information to wiki/entities/ and wiki/projects/ for this business."

## Cron

Runs after `ingest` or `claude-extract` when business-relevant content is detected (targeted trigger). Also runs as a full refresh daily at 9 PM.

## Dependencies

- Reads: `SOUL.md`, `CRITICAL_FACTS.md`, `wiki/entities/`, `wiki/projects/`, `wiki/daily/`, `log.md`, existing context files
- Writes: `wiki/context/`, `log.md`
- Triggered by: `ingest` (when `[CONTEXT]` flagged), `claude-extract` (when `[CONTEXT]` flagged), manual trigger, daily cron
- Triggers: nothing downstream (context-maintain is a terminal skill)

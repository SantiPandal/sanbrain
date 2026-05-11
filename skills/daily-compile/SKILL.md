---
name: daily-compile
version: 1.0.0
description: |
  Nightly dream cycle. Review all vault changes from the day, synthesize
  connections, update stale compiled truths, write daily digest.
triggers:
  - "daily compile"
  - "dream cycle"
  - "what connected today"
  - "compile today"
tools:
  - exec
  - read
  - write
mutating: true
---

# Daily Compile

## Contract

Run nightly. This skill:
1. Reviews all vault pages modified in the last 24 hours
2. Identifies connections between today's inputs and existing knowledge
3. Updates stale compiled truths on affected pages
4. Writes a daily digest page
5. Flags orphan pages and unresolved threads

This is the compounding engine. Without it, the vault accumulates pages but doesn't synthesize.

## Phases

### Phase 1: Inventory Today's Changes

Find all vault pages modified in the last 24 hours.
Categorize by type: meetings, people updates, business updates, source material, mirrors.

### Phase 2: Read Santiago's Context

Read `soul.md` for the lens — connections should be surfaced through Santiago's frameworks:
- His thinkers (Munger, Deutsch, Naval, etc.)
- His businesses (Cargo Claro, Pala Padel, Launchers, etc.)
- His growth edges (blind spots from personality.md)

### Phase 3: Synthesize Connections

For each modified page, check:
- Does this connect to something in a DIFFERENT domain? (e.g., a book idea that applies to a business problem)
- Does this contradict or reinforce something already in the vault?
- Does this reveal a pattern across multiple recent interactions?
- Does any thinker's framework illuminate this?

Write connections as they emerge. Quality > quantity. One genuine insight beats five forced connections.

### Phase 4: Update Stale Compiled Truths

For pages where new evidence changes the picture:
- Rewrite the compiled truth section to reflect current understanding
- Note what changed and why in the timeline

### Phase 5: Write Daily Page

Create `Daily/YYYY-MM-DD.md`:

```markdown
---
type: daily
date: YYYY-MM-DD
---
# YYYY-MM-DD

## What Happened
- [events, meetings, decisions, insights — sourced from modified pages]

## Pages Updated
- [[page]] — [what changed]

## Connections Surfaced
- [non-obvious links between today's inputs and existing knowledge]

## Stale Pages Updated
- [[page]] — [compiled truth rewritten because: reason]

## Open Threads
- [things that need follow-up, aggregated from all modified pages]

## Orphans
- [pages with no inbound links — may need connecting or archiving]
```

### Phase 6: Housekeeping

- Flag pages in `People/` with no timeline entries in 30+ days (relationship may need attention)
- Flag `Businesses/` pages whose "State" section is 14+ days old
- Count total vault pages, total people, total businesses (track growth)

## Output Format

```
Daily compilation: YYYY-MM-DD
- Pages modified today: [N]
- Connections surfaced: [N]
- Compiled truths updated: [N]
- Open threads: [N]
- Vault stats: [N] total pages, [N] people, [N] businesses
```

## Cron

Nightly at 11 PM. Idempotent — running twice on the same day updates the existing daily page.

## Dependencies

- Read: entire vault (modified files + context)
- Write: `Daily/`, any page with stale compiled truth

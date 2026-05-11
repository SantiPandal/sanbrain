---
name: book-mirror
version: 1.0.0
description: |
  Create a chapter-by-chapter personal mirror of a book. Left column:
  what the author says. Right column: how it maps to Santiago's specific
  life — his businesses, relationships, blind spots, thinkers, goals.
  Each mirror gets richer because the vault gets richer.
triggers:
  - "mirror this book"
  - "book mirror"
  - "read this through my life"
  - "map this book to me"
tools:
  - exec
  - read
  - write
mutating: true
---

# Book Mirror

## Contract

Given a book (PDF, chapter notes, or chapter-by-chapter input), this skill:
1. Summarizes each chapter's core ideas
2. Maps EVERY idea to Santiago's specific life using vault context
3. Cross-references with previous mirrors for compounding connections
4. Creates a mirror page in `Mirrors/`
5. Extracts entities and triggers propagation

The mirror is NOT a book summary. It's a two-column document where the right column uses Santiago's actual words, actual businesses, actual blind spots, and actual relationships.

## Phases

### Phase 1: Load Santiago's Full Context

Read these files from the vault — they are the lens for the right column:
- `soul.md` — who he is, how he thinks, blind spots, growth edges
- `personality.md` — psychological profile, attachment style, values
- All `Businesses/` pages — current state of each business
- All `People/` pages — key relationships
- All existing `Mirrors/` — previous book mirrors (for cross-book connections)
- `3 - Main Notes/` — his mental models and frameworks

This is the most important phase. The quality of the mirror depends entirely on how deeply the right column connects to Santiago's actual life.

### Phase 2: Process Each Chapter

For each chapter:

1. **Summarize** the author's key ideas (left column). Be faithful to the author's argument. Include the strongest formulations.

2. **Mirror** each idea to Santiago's life (right column). Be specific:
   - Name actual businesses (Cargo Claro, Pala Padel, Launchers)
   - Name actual people ([[Alfonso]], [[Eduardo]])
   - Reference actual blind spots (emotional flatness, narcissistic feedback filtering)
   - Connect to his thinkers (Munger would say..., Deutsch's criterion here is...)
   - Reference actual decisions or conversations if relevant
   - Connect to previous book mirrors if the idea echoes

3. **DO NOT** write generic advice. "This applies to leaders" is worthless. "This maps to how Santiago dismissed Eduardo's feedback on the Cargo Claro pricing model because Eduardo isn't in his competence hierarchy — but Eduardo has proximity data Santiago doesn't" is valuable.

### Phase 3: Write Mirror Page

Create `Mirrors/[book-title].md`:

```markdown
---
type: mirror
book: [Title]
author: [Author]
date_mirrored: YYYY-MM-DD
---
# [Title] — Mirror

## Chapter 1: [Chapter Title]

| What [Author] says | What this means for Santiago |
|---|---|
| [Key idea 1] | [Specific mapping to Santiago's life] |
| [Key idea 2] | [Specific mapping] |

## Chapter 2: [Chapter Title]
...

## Cross-Book Connections
- [Idea from this book] echoes [idea from [[previous-mirror]]] — [how they connect]

## The One Thing
[If Santiago remembers nothing else from this book, it should be this.]
```

### Phase 4: Propagate

Run `entity-propagate` for all people, businesses, and concepts referenced.

### Phase 5: Fact-Check

Verify all claims about Santiago's life against the vault:
- Did you reference the right people for the right businesses?
- Did you claim something about his history that's not in soul.md or personality.md?
- If uncertain about a fact, flag it: `[VERIFY: ...]`

This phase was added because early book mirrors in GBrain had factual errors about the user's family history. Every mirror must be checked.

## Output Format

```
Mirror complete: [Title] by [Author]
- [N] chapters mirrored
- [N] personal connections mapped
- [N] cross-book connections found
- [N] entities propagated
- The One Thing: [one line]
```

## Cost Estimate

~$6 for a 20-chapter book at Opus-tier pricing.

## Dependencies

- `entity-propagate` (post-write)
- Read: `soul.md`, `personality.md`, `Businesses/`, `People/`, `Mirrors/`, `3 - Main Notes/`

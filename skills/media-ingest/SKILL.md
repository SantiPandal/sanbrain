---
name: media-ingest
version: 1.0.0
description: |
  Process YouTube videos, X threads, articles, and podcasts into
  structured vault pages with entity extraction and personal elaboration.
triggers:
  - "ingest this"
  - "save this video"
  - "capture this thread"
  - "process this article"
tools:
  - exec
  - read
  - write
mutating: true
---

# Media Ingest

## Contract

Given a URL or content, this skill:
1. Fetches and processes the content (transcribe video, fetch article, parse thread)
2. Creates a source material page with structured summary
3. Adds personal elaboration — why this matters to Santiago
4. Extracts entities and triggers propagation

## Phases

### Phase 1: Detect Type and Fetch

| Input | Action |
|-------|--------|
| YouTube URL | Transcribe audio, extract key segments |
| X/Twitter thread | Fetch thread text, capture author |
| Article URL | Fetch and clean article text |
| Podcast URL/file | Transcribe audio |
| PDF | Extract text |

### Phase 2: Read Santiago's Context

Read `soul.md` and relevant `Businesses/` pages to understand WHY this content matters to Santiago. The personal elaboration in Phase 3 depends on this.

### Phase 3: Write Source Material Page

Create page in `1 - Source Material/[title].md`:

```markdown
---
type: source
media: [youtube|article|thread|podcast|pdf]
author: [name]
date: YYYY-MM-DD
url: [source URL]
---
# [Title]

## Summary
[3-5 lines: what this content says]

## Key Ideas
- [idea 1]
- [idea 2]

## Personal Elaboration
[Why this matters to Santiago. How it connects to his businesses,
thinkers, mental models, or current problems. Written in first person
as if Santiago is processing this himself.]

## Entities
- [[person]] — [context]
- [[business/concept]] — [context]

## Source
[URL or reference]
```

### Phase 4: Propagate

Run `entity-propagate` for all entities detected.
If the author is notable, create/update their people page.

## Output Format

```
Ingested: [title] ([type])
- Author: [name]
- [N] key ideas extracted
- [N] entities detected
- Personal elaboration: [one-line summary of connection to Santiago]
```

## Queue Pattern

For batch processing, maintain a queue file at vault root:
`to-process.md` — list of URLs to ingest. Cron picks up new entries.

## Dependencies

- `entity-propagate` (post-write)
- Read: `soul.md`, `Businesses/`, `People/` (for context)
- External: transcription API for audio/video

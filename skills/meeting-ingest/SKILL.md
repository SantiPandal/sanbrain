---
name: meeting-ingest
version: 1.0.0
description: |
  Process a meeting transcript into a structured vault page. Extract
  attendees, action items, key insights. Propagate to all people pages.
  The meeting page is not the end product — entity propagation is.
triggers:
  - "process this meeting"
  - "ingest meeting"
  - "meeting with"
  - "I just had a meeting"
tools:
  - exec
  - read
  - write
mutating: true
---

# Meeting Ingest

## Contract

Given a meeting transcript (text), this skill:
1. Creates a structured meeting page in `Meetings/`
2. Identifies all attendees and entities mentioned
3. Creates/updates people pages for all attendees
4. Extracts action items and assigns owners
5. Identifies the one key insight from the meeting

## Phases

### Phase 1: Parse Transcript

Read the transcript. Identify:
- **Date** of meeting
- **Attendees** (names, roles if mentioned)
- **Topics** discussed
- **Decisions** made
- **Action items** with owners
- **Key insight** — the one non-obvious thing

### Phase 2: Read Existing Context

For each attendee, check if a people page exists in `People/`.
If it exists, read it — the meeting page should reference prior context.
If not, it will be created as a Tier 3 stub in Phase 4.

For each business mentioned, check `Businesses/`.

### Phase 3: Write Meeting Page

Create `Meetings/YYYY-MM-DD-[topic-slug].md` using the meeting template:

```markdown
---
type: meeting
date: YYYY-MM-DD
attendees: [person1, person2]
---
# Meeting: [topic] — YYYY-MM-DD

Summary: [3 lines max]

## Attendees
- [[person-1]] — [role/context]
- [[person-2]] — [role/context]

## Key Discussion Points
- [point 1]
- [point 2]

## Decisions
- [decision + reasoning]

## Action Items
- [ ] [item] — [[owner]]

## Key Insight
[The one non-obvious thing from this meeting]
```

### Phase 4: Propagate

Run `entity-propagate` on the meeting page. This will:
- Create stub pages for new attendees
- Add timeline entries to existing attendee pages
- Update business pages if businesses were discussed

### Phase 5: Surface Connections

Check if any attendee has been mentioned in recent meetings or vault pages.
If connections exist, note them in the meeting page:
```
## Connections
- [[person]] was also discussed in [[other-page]] on YYYY-MM-DD
```

## Output Format

```
Meeting processed: [topic] — YYYY-MM-DD
- [N] attendees tracked
- [N] action items captured
- [N] entity pages updated
- Key insight: [one line]
```

## Input Sources

- Transcribed audio from iPhone → iCloud (transcribed via existing skill)
- Manual paste of meeting notes
- Calendar event with notes

## Dependencies

- `entity-propagate` (post-write)
- Read: `People/`, `Businesses/`, `soul.md` (for personal context in connections)

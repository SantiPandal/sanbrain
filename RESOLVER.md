# Sanbrain Skill Resolver

Route user intent to the right skill. The harness reads this file to dispatch.

## Always-On (post-write hook)

| Trigger | Skill |
|---------|-------|
| Any page written or updated | `skills/entity-propagate/SKILL.md` |

## Capture

| Trigger | Skill |
|---------|-------|
| "extract from claude", "pull claude sessions", "what did I discuss" | `skills/claude-extract/SKILL.md` |
| "process this meeting", "ingest meeting", "meeting with [person]" | `skills/meeting-ingest/SKILL.md` |
| "ingest this", "save this video", "capture this thread", [URL pasted] | `skills/media-ingest/SKILL.md` |
| "mirror this book", "book mirror", "read [book] through my life" | `skills/book-mirror/SKILL.md` |

## Processing

| Trigger | Skill |
|---------|-------|
| "enrich [person]", "who is [person]", "tell me about [person]" | `skills/enrich/SKILL.md` |
| Mention count crosses tier threshold (automatic) | `skills/enrich/SKILL.md` |

## Output

| Trigger | Skill |
|---------|-------|
| "daily compile", "dream cycle", "what connected today" | `skills/daily-compile/SKILL.md` |
| "prep my context", "update claude code context", "morning briefing" | `skills/context-for-claude-code/SKILL.md` |

## Disambiguation

When multiple skills match:
1. Check content type (URL → media-ingest, transcript → meeting-ingest)
2. Check explicit trigger phrase
3. Ask the user

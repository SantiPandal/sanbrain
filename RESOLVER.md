# Sanbrain Skill Resolver

Route user intent to the right skill. The harness reads this file to dispatch.

## Cron-Driven (autonomous, no user trigger)

| Trigger | Skill | Schedule |
|---------|-------|----------|
| Nightly ingest | `skills/ingest/SKILL.md` | 10:00 PM |
| Claude session extraction | `skills/claude-extract/SKILL.md` | 10:30 PM |
| Entity back-links and enrichment | `skills/entity-update/SKILL.md` | 11:00 PM |
| Context file refresh | `skills/context-maintain/SKILL.md` | 11:15 PM |
| Morning deliverable | `skills/morning-brief/SKILL.md` | 7:00 AM |

## Manual Triggers

| Trigger Phrase | Skill |
|----------------|-------|
| "ingest", "process raw", "scan raw folder" | `skills/ingest/SKILL.md` |
| "extract from claude", "pull claude sessions", "sync claude" | `skills/claude-extract/SKILL.md` |
| "update entities", "propagate entities" | `skills/entity-update/SKILL.md` |
| "update context", "refresh context", "what's current" | `skills/context-maintain/SKILL.md` |
| "morning brief", "daily brief", "brief me" | `skills/morning-brief/SKILL.md` |

## Disambiguation

When multiple skills match:
1. Check content type (files in raw/ -> ingest, Claude sessions -> claude-extract)
2. Check explicit trigger phrase
3. Ask the user

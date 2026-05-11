# Vault Schema Convention

Every page in the vault follows the **compiled truth + timeline** pattern.

## The Pattern

```markdown
---
type: [person|business|meeting|mirror|daily|concept]
---
# Title

[COMPILED TRUTH — current best understanding. Rewrite when evidence changes.
This is NOT a summary of the timeline. It's the synthesized picture.]

## Timeline
- YYYY-MM-DD: [event — append-only, newest first, never edited]
```

## Rules

1. **Compiled truth is rewritten, not appended.** When new evidence changes the picture, rewrite the top section. The timeline preserves the history.
2. **Timeline is append-only.** Never edit or delete timeline entries. Add new ones at the top (newest first).
3. **Frontmatter is minimal.** Type is required. Tags optional. No bloat.
4. **Wikilinks for connections.** Use `[[page-name]]` to link to other vault pages. This is how the knowledge graph forms.
5. **One idea per page** for concepts. People and business pages aggregate.

## Page Types

See `templates/` for the specific format of each type:
- `person.md` — people in Santiago's network
- `business.md` — businesses Santiago runs or evaluates
- `meeting.md` — structured meeting summaries
- `mirror.md` — book mirrors (author's ideas mapped to Santiago's life)
- `daily.md` — daily compilation/digest

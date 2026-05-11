# Quality Convention

Cross-cutting rules. Every skill that writes to the vault MUST follow these.

## 1. Back-Linking (mandatory)

Every mention of a person or business WITH a vault page MUST create a back-link FROM that entity's page TO the page mentioning them.

Format in the entity's Timeline section:
```
- YYYY-MM-DD: Referenced in [[page-title]] — [one-line context]
```

Unlinked mentions are structural damage. The knowledge graph breaks silently.

## 2. Citations

Every factual claim in a compiled truth section needs a source:
- User statement: `(Santiago, YYYY-MM-DD)`
- Meeting: `(Meeting with [[person]], YYYY-MM-DD)`
- Web source: `(source-name, URL, YYYY-MM-DD)`
- Book: `(Author, Title, Chapter N)`
- Claude session: `(Claude session, YYYY-MM-DD)`

## 3. Notability Gate

Before creating a new page, check:
- **People**: Will Santiago interact with them again? Relevant to a business or goal?
- **Businesses**: Relevant to Santiago's work, investments, or interests?
- **Concepts**: Reusable mental model? Future reference value?

When in doubt, DON'T create a page. A stub in an existing page is better than an orphan page that adds noise.

## 4. Idempotency

Every skill must be idempotent. Running it twice produces the same result:
- Check for existing pages before creating
- Check for existing timeline entries before appending
- Use dates as dedup keys

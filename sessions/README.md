# sessions/

Self-filed summaries from remote Claude Code sessions (web/mobile containers
the pipeline can't read). See the session summary contract in `CLAUDE.md`.

Lifecycle: `harvest-sessions.sh` fetches all remote branches nightly, extracts
new `sessions/*.md` files (no working-tree mutation, no merge required), and
delivers them to `VAULT/raw/` for ingest. Originals stay here as the versioned
record. Delivered filenames are tracked in `.state/delivered-sessions.list` —
files are write-once; edit nothing after pushing.

Naming: `YYYY-MM-DD-kebab-case-topic.md`. No spaces.

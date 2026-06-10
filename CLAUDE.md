# CLAUDE.md — sanbrain repo

Personal second-brain system: cron → staged `claude -p` calls → Obsidian vault.
Orientation: `CONTEXT.md` (system facts, injected into every run),
`docs/INPUTS.md` (capture registry), `crontab.md` (pipeline flow).
Conventions: scripts move bytes, agents make meaning; compiled truth is
rewritten, timelines are append-only; every entity mention is a `[[wikilink]]`.

## Session summary contract (REQUIRED for remote sessions)

Santiago does most of his thinking in AI chat windows. Local Mac sessions are
captured verbatim from `~/.claude/projects/` — but remote sessions (Claude
Code on the web/mobile, this container) are invisible to the pipeline unless
they file themselves.

**If you are running in a remote/cloud container:** before ending substantive
work (and again after any major additional work in long sessions), write a
session summary file and include it in your commit/push:

- Path: `sessions/YYYY-MM-DD-<kebab-case-topic>.md` — no spaces in filenames.
- Format: the LLM Session Summary block (see
  `setup/llm-session-summary-prompt.md`), first line:
  `## LLM Session Summary — claude-code-web — <topic>`
- Content: problem context, decisions WITH reasoning, entities mentioned,
  insights, action items, open questions. Factual only — summarize what
  actually happened in the session, nothing aspirational.
- Push it. `harvest-sessions.sh` reads `sessions/` across ALL remote branches
  nightly (no merge required) and delivers new files to the vault for ingest.

Local CLI sessions on the Mac: skip this — you're already captured, a summary
would be a duplicate.

## Other rules for sessions in this repo

- Shell must stay macOS bash-3.2 compatible (`/bin/bash`) except scripts with
  an explicit homebrew-bash shebang; Python is stdlib-only.
- New input sources get a row in `docs/INPUTS.md` and a heartbeat
  (`scripts/lib.sh`). A sensor that can't report failure doesn't exist.
- Skill contract changes bump the `version:` in the skill's frontmatter.

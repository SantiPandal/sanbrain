# AGENTS.md — sanbrain

Orientation for any coding agent (Codex, Gemini, Cursor, Claude Code via the CLAUDE.md shim, …) working in this repo.

## What this repo is

Santiago's second brain: cron-driven harvesters feed an Obsidian vault ("wikibrain"), a staged nightly pipeline distills raw captures into wiki pages, and four always-on OpenClaw agents sit on top of it. Read `README.md` for architecture, `CONTEXT.md` for the vault structure and Santiago's world, `crontab.md` for the schedule, `RESOLVER.md` for skill routing.

## Consult the brain agents — `claw`

Four real, always-on OpenClaw agents run on this machine (the Mac mini) with their own memory, vault access, and Telegram presence. Any LLM session can query them synchronously:

```bash
claw <agent> "<question>"      # agent ∈ judge | xai | sanbrain | openclaw | all
claw --list                    # roster + routing table
```

- `judge` — high-stakes verdicts, reality checks, go/no-go.
- `xai` — product/engineering tradeoffs, leverage analysis.
- `sanbrain` — "what do we know about X": vault data, entities, decisions, relationships.
- `openclaw` — broad dot-connecting, default catch-all.

A turn takes 30–120s — set long command timeouts. Not on PATH? `scripts/claw`. Consult proactively when a second opinion or Santiago-specific context would change your answer.

## Ground rules

- The live OpenClaw install (`~/.openclaw/`) belongs to the agents — never edit its config from here. `openclaw/` in this repo is the charter *source* (AGENTS.md, SOUL.md, IDENTITY.md for the bots), deployed deliberately.
- Secrets live in `~/.sanbrain.env` (chmod 600, never committed). The example is `setup/sanbrain.env.example`.
- The Obsidian vault is the production data store. Prefer the skills pipeline (`skills/`, run by `scripts/nightly.sh`) over ad-hoc vault writes.

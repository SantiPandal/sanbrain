# Sanbrain Cron Schedule

## Daily entry points

| When | Script | What |
|------|--------|------|
| 9:30 PM | `evening-debrief.sh` | "Daily Signal" question to each AI agent's topic — agents reply with new signal (feed, verdicts, observations) before the 10 PM harvest |
| 10 PM | `nightly.sh` | sensors → staged skill chain (4 separate `claude -p` calls) |
| 7 AM | `morning.sh` | vault-doctor → morning brief |
| 2 PM, 7 PM | `process-brief-feedback.sh` | propagate Santiago's brief edits (free if brief unchanged) |

## Installed (crontab -l)

```
SHELL=/bin/zsh
PATH=/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin
30 21 * * * $HOME/sanbrain/scripts/evening-debrief.sh >> $HOME/sanbrain/logs/reminders.log 2>&1
0 22 * * * $HOME/sanbrain/scripts/nightly.sh >> $HOME/sanbrain/logs/nightly.log 2>&1
0 7 * * * $HOME/sanbrain/scripts/morning.sh >> $HOME/sanbrain/logs/morning.log 2>&1
0 14,19 * * * $HOME/sanbrain/scripts/process-brief-feedback.sh >> $HOME/sanbrain/logs/brief-feedback.log 2>&1
```

## Prerequisites
- `claude login` must have been run in Terminal.app at least once (stores OAuth in macOS Keychain)
- Secrets in `~/.sanbrain.env` (chmod 600) — see `setup/sanbrain.env.example`. Cron does not read .zshrc.
- Scripts use absolute path `$HOME/.local/bin/claude` (not PATH-dependent)
- Pre-flight auth check in all entry scripts — log error, Telegram alert, and exit if not authenticated
- `ffmpeg` (brew install ffmpeg) for chunking voice recordings >25MB
- Morning brief auto-opens in Obsidian after generation

## Reliability machinery (Phase 1)

- **Vault versioning**: `scripts/vault-git.sh` keeps the vault in a git repo whose
  git dir lives OUTSIDE iCloud (`~/.sanbrain-vault.git`). Checkpoints: pre-nightly,
  post-sensors, after every skill stage, post-morning-brief, post-brief-feedback.
  Undo a bad night: `scripts/vault-git.sh log` then `git --git-dir=~/.sanbrain-vault.git revert <sha>`.
  Checkpoint refuses mass deletions (>20% tracked files) — the iCloud-eviction signature.
- **State checkpoints**: `~/sanbrain/.state/<skill>.last` — machine-written ISO
  timestamps. Skills read these; only wrapper scripts write them.
- **Handoffs**: each nightly stage writes `~/sanbrain/.state/handoffs/<skill>.json`;
  the next stage receives it in its prompt. Stages with provably nothing to do
  are skipped mechanically (empty raw/, no new Claude sessions).
- **Heartbeats**: every sensor and stage writes `~/sanbrain/.state/heartbeats/<name>.json`.
  `vault-doctor.py` surfaces any sensor with no success in 48h into the brief.
- **Alerts**: failures push to Telegram (San group, sanbrain topic) via openclaw.
  Silent when everything is clean.
- **vault-doctor**: `scripts/vault-doctor.py` runs before each brief — broken
  wikilinks, iCloud conflict/evicted files, schema violations, unpropagated
  meeting attendees, raw/ backlog, sensor health. Report: `wiki/logs/doctor-DATE.md`.

## Data Flow

```
Sensors (6 input channels):
  ~/Downloads/            → harvest-downloads.sh  → raw/downloads-manifest-*.md (system file)
  GitHub API (2 repos)    → harvest-github.sh     → raw/github-prs-*.md
  iCloud Meetings/ (.m4a) → harvest-recordings.sh → raw/voice-*.md (Whisper, chunked >25MB)
  OpenClaw conversations  → harvest-openclaw.sh   → raw/openclaw-conversations-*.md
  Claude Code (local CLI) → ~/.claude/projects/   (read directly by claude-extract)
  Claude Code (web/remote)→ harvest-sessions.sh   → sessions/ on any remote branch → raw/session-*.md
  Cloud LLM chats         → "wiki this" summary pasted to Telegram or raw/ (morning brief asks if missing)
  Agent vantage points    → evening-debrief.sh (9:30 PM) asks each agent for Daily Signal
                            (xai feed distillation, judge verdicts, observations) → replies
                            captured by openclaw harvest (window: 21:00 yesterday → midnight today)
  Santiago's head         → morning brief Questions section (he answers in the morning)
  Calendar.app (4 cals)   → schedule-reminders.sh → raw/today-reminders-*.md + Telegram agenda push

                        ↓
10 PM: nightly.sh
  Phase 0: vault-git checkpoint (undo point)
  Phase 1: process approved deletions (strict two-factor parse: checked in
           brief/manifest AND allow-listed in a harvest-written manifest)
  Phase 2: 4 harvest sensors (each heartbeats; failures alert, don't halt)
  Phase 3: staged skill chain — one claude -p call PER skill, with handoff
           JSON between stages and a vault-git checkpoint after each:
    1. ingest:           raw/ → wiki/ → raw/archive/   (skipped if raw/ empty)
    2. claude-extract:   ~/.claude/ → wiki/            (skipped if no new sessions)
    3. entity-update:    back-links, stubs, enrichment (reads handoffs 1+2)
    4. context-maintain: rewrite context files         (reads handoffs 1-3)
  Phase 4: archive stale system files, sentinel, Telegram alert if failures
                        ↓
7 AM: morning.sh
  5. schedule-reminders → calendar events + guaranteed agenda push to Telegram
  6. vault-doctor       → wiki/logs/doctor-DATE.md (mechanical health)
  7. morning-brief      → wiki/daily/YYYY-MM-DD-brief.md (uses doctor numbers)
                        ↓
Santiago reads the brief on iPhone via Obsidian, checks boxes / writes answers
                        ↓
2 PM / 7 PM: process-brief-feedback.sh propagates his edits (mtime-gated)
```

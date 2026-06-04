# Sanbrain Cron Schedule

## Two calls per day

| When | Script | What |
|------|--------|------|
| 10 PM | `nightly.sh` | 1 call → ingest → claude-extract → entity-update → context-maintain |
| 7 AM | `morning.sh` | 1 call → morning brief |

## Installed (crontab -l)

```
SHELL=/bin/zsh
PATH=/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin
0 22 * * * $HOME/sanbrain/scripts/nightly.sh >> $HOME/sanbrain/logs/nightly.log 2>&1
0 7 * * * $HOME/sanbrain/scripts/morning.sh >> $HOME/sanbrain/logs/morning.log 2>&1
```

## Prerequisites
- `claude login` must have been run in Terminal.app at least once (stores OAuth in macOS Keychain)
- Scripts use absolute path `$HOME/.local/bin/claude` (not PATH-dependent)
- Pre-flight auth check in both scripts — will log error and exit if not authenticated
- Morning brief auto-opens in Obsidian after generation

## Data Flow

```
Sensors (6 input channels):
  ~/Downloads/          → harvest-downloads.sh  → raw/downloads-manifest-*.md
  GitHub API (2 repos)  → harvest-github.sh     → raw/github-prs-*.md
  iCloud Meetings/ (.m4a) → harvest-recordings.sh → raw/voice-*.md (via Whisper API)
  OpenClaw conversations  → harvest-openclaw.sh   → raw/openclaw-summary-*.md
  Claude Code sessions    → ~/.claude/projects/   (read directly by claude-extract)
  Calendar.app (4 cals)   → schedule-reminders.sh → raw/today-reminders-*.md (morning only)

                        ↓
10 PM: nightly.sh
  Phase 0: Run 4 harvest sensors (downloads, github, recordings, openclaw)
  Phase 1: Process approved deletions from today's brief
  Phase 2: 4-skill chain (1 claude -p call):
    1. ingest:          raw/ → wiki/ → raw/archive/
    2. claude-extract:  ~/.claude/ → wiki/
    3. entity-update:   back-links, stubs, enrichment
    4. context-maintain: rewrite context files
                        ↓
7 AM: morning.sh
  5. schedule-reminders → calendar events
  6. morning-brief:     → wiki/daily/YYYY-MM-DD-brief.md
                        ↓
Santiago reads the brief on iPhone via Obsidian
```

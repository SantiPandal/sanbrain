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
OpenClaw summaries → raw/ (before 10 PM)
Research/reports   → raw/ (downloaded manually or via script)
Claude Code        → ~/.claude/projects/ (automatic)
                        ↓
10 PM: nightly.sh (1 claude -p call, 4 skills in sequence)
  1. ingest:          raw/ → wiki/ → raw/archive/
  2. claude-extract:  ~/.claude/ → wiki/
  3. entity-update:   back-links, stubs, enrichment
  4. context-maintain: rewrite context files
                        ↓
7 AM: morning.sh (1 claude -p call)
  5. morning-brief:   → wiki/daily/YYYY-MM-DD-brief.md
                        ↓
Santiago reads the brief on iPhone via Obsidian
```

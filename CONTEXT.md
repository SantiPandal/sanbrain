# Sanbrain -- Project Context

Read this file before executing any skill. It provides the context you need to operate.

---

## Santiago

Santiago Pandal. 24. Mexico City. Industrial engineer, builder, first-principles thinker.
Core value: freedom (optionality). Vehicle: business as truth-testing mechanism.
Active businesses: Pala Padel, Tax Free. Everything else is archived.

Thinkers (cite when the model fits):
- **Munger**: inversion, mental models, avoiding stupidity
- **Naval**: leverage, specific knowledge, wisdom
- **Deutsch**: hard-to-vary explanations, fallibilism, conjecture/refutation
- **Hormozi**: offers, sales, scaling, guarantees
- **Musk**: scale, vision, first-principles manufacturing
- **Tobi Lutke**: systems thinking, decision quality > outcomes

Blind spots (skills should watch for these):
1. Optimizing relationships like engineering problems
2. Reflexive rejection of feedback (criticism feels like identity attack)
3. Avoidant in hard conversations
4. Treating everything as an achievement problem

Communication: 1-4 lines default. No filler, no hedging. Action over discussion.

For deep context, read `SOUL.md` and `personality.md` in the vault root.

---

## Vault

**Location:** `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT/`
**Sync:** iCloud (accessible on iPhone via Obsidian mobile)

### Structure

```
VAULT/
├── raw/                    # Drop zone -- put new files here for processing
│   └── archive/            # Processed originals (timestamped, never re-processed)
├── wiki/
│   ├── entities/           # People + businesses (compiled truth + timeline)
│   ├── concepts/           # Mental models, frameworks, ideas
│   ├── ideas/              # Parked ideas and thoughts (brain dump captures)
│   ├── projects/           # Active project tracking
│   ├── context/            # Living "what's true now" files (rewritten each run)
│   ├── daily/              # Daily briefs + ingestion logs
│   ├── logs/               # Skill run logs
│   └── reviews/            # Periodic reviews
├── SOUL.md                 # Identity file -- who Santiago is
├── personality.md          # Psychological assessment (Big Five, attachment, etc.)
├── _CLAUDE.md              # Agent operating manual (conventions, rules)
├── CRITICAL_FACTS.md       # ~120 token core facts -- read first, always
├── index.md                # Master catalog of all wiki pages
├── log.md                  # Activity timeline (append-only, newest first)
└── [legacy folders]        # 0-Drafts, 1-Source Material, 3-Main Notes, Archive, etc.
```

Legacy folders are preserved (existing Zettelkasten notes, book summaries, essays). New content goes exclusively into `wiki/` and `raw/`.

### Core Pattern: Compiled Truth + Timeline

Every wiki page has two layers:
- **Compiled truth** (top): current best understanding. REWRITTEN when evidence changes.
- **Timeline** (bottom): append-only, newest first, never edited.

The compiled truth tells you what's true NOW. The timeline tells you HOW we got here.

### Entity Pages (wiki/entities/)

Filename: lowercase, hyphens for spaces (e.g., `mario-pasquel.md`).

```markdown
---
type: person|business
aliases: []
first_seen: YYYY-MM-DD
confidence: high|medium|low
---
## For future Claude
[One-line: who this is and why they matter to Santiago]

# [Full Name]

[Compiled truth -- rewritten when evidence changes]

## Open Threads
- [pending items, follow-ups]

## Timeline
- YYYY-MM-DD: [event -- append-only, newest first]
```

Enrichment tiers (internal, not in frontmatter):
- **Stub**: first mention, passes notability gate. Name + context.
- **Vault-enriched**: 3+ mentions across different pages. Full compiled truth.
- **Deep**: 8+ mentions or meeting attendance. Vault + web research.

### Wikilinks

EVERY entity mention uses `[[slug]]` syntax. This builds the Obsidian knowledge graph.

### Logging

Every skill action goes to `log.md`:
```
- YYYY-MM-DDTHH:MM:SS [skill-name] action description
```

Items needing human review get `[ATTENTION]` tag.
Business-relevant content gets `[CONTEXT]` tag (triggers context-maintain).

---

## Active Businesses

### Pala Padel
Padel tournament and league management platform.
- **Users:** 240+ historical
- **Ranking:** TrueSkill algorithm (categories: Primera, Segunda, Tercera, Cuarta)
- **Key people:** [[fer]], [[leon]], [[rafa]]
- **Model:** Tournament fees, sponsorships, foundation events

### Tax Free
AI automation for tourist VAT refund processing in Mexico.
- **Key people:** [[mario-pasquel]]
- **Focus:** SAT integration, automated refund workflows

### Personal
Santiago's non-business context.
- **Fitness:** Full-body Mon/Fri, cardio Tue/Wed/Fri, padel evenings
- **Skills:** Cliff diving (gainer, front flip, side flip)
- **Creative:** Fujifilm x100v photography, food reviews
- **Key people:** [[nicolas]], family

### Archived (DO NOT create context files for these)
Cargo Claro, Learning Temple, Vive Energia, Launchers, Pest Control, YUTE Shoes.
These exist in the vault Archive/ folder. Do not update or maintain.

---

## 5 Core Skills

| Skill | Purpose | Cron |
|-------|---------|------|
| **ingest** | Scan raw/, classify, extract, distribute to wiki/, archive | 10:00 PM |
| **claude-extract** | Pull decisions/entities/insights from ~/.claude/ sessions | 10:30 PM |
| **entity-update** | Back-links, stubs, enrichment, duplicate merge | 11:00 PM |
| **context-maintain** | Rewrite living context files per business + personal | 11:15 PM |
| **morning-brief** | Daily deliverable with changes, connections, review prompts | 7:00 AM |

### Skill Chain

```
ingest ──→ entity-update ──→ context-maintain (if business-relevant)
claude-extract ──→ entity-update ──→ context-maintain (if business-relevant)
morning-brief reads everything, writes only the brief
```

Each skill has a full contract at `~/sanbrain/skills/[name]/SKILL.md`.

### Conventions

Detailed conventions at `~/sanbrain/skills/conventions/`:
- `vault-schema.md` -- compiled truth + timeline pattern
- `entity-rules.md` -- enrichment tiers, detection, propagation
- `quality.md` -- skill quality checklist

### Templates

Page templates at `~/sanbrain/templates/`:
- `person.md`, `business.md`, `meeting.md`, `mirror.md`, `daily.md`

---

## Architecture

```
crontab (Mac mini, always-on)
  → shell scripts (~/sanbrain/scripts/)
    → claude -p (Claude Code CLI in prompt mode)
      → reads CONTEXT.md + SKILL.md
        → reads/writes Obsidian vault (iCloud)
          → syncs to iPhone
```

Claude Code sessions (manual, interactive) are separate from this system.
This system runs autonomously via cron. No human in the loop except morning review.

---

## Key Paths

| What | Path |
|------|------|
| Sanbrain repo | `~/sanbrain/` |
| Context (this file) | `~/sanbrain/CONTEXT.md` |
| Skills | `~/sanbrain/skills/{ingest,claude-extract,entity-update,context-maintain,morning-brief}/SKILL.md` |
| Conventions | `~/sanbrain/skills/conventions/{quality,vault-schema,entity-rules}.md` |
| Templates | `~/sanbrain/templates/{person,business,meeting,mirror,daily}.md` |
| Wrapper scripts | `~/sanbrain/scripts/{ingest,claude-extract,entity-update,context-maintain,morning-brief}.sh` |
| Crontab | `~/sanbrain/crontab.example` |
| Resolver | `~/sanbrain/RESOLVER.md` |
| Obsidian vault | `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT/` |
| Claude Code sessions | `~/.claude/projects/` |
| Claude Code memory | `~/.claude/projects/*/memory/` |

# Input Registry — every signal source, captured or not

The single source of truth for what flows into the brain. Dorsey's rule: the
world model is built by recording ALL decisions, discussions, plans, problems,
progress. Tan's rule: "If the user thinks out loud and the brain doesn't
capture it, the system is broken." This file is the audit of both.

**Maintenance rule:** any new input source gets a row here AND a heartbeat
(`scripts/lib.sh: heartbeat`). vault-doctor surfaces sensors that stop beating.
A source not in this file is a capture gap by definition.

Last full audit: 2026-06-09.

---

## The capture contract (landing zones)

| You have | Put it | What happens |
|---|---|---|
| Audio (any meeting/memo) | `iCloud Drive/Meetings/` | Whisper-transcribed nightly (chunked if >25MB) → raw/ → vault. **Constraint: only `.m4a` files at the folder root are picked up today** — `.wav`/`.mp3` or subfolders sit there silently (Gap Backlog #6). iOS Shortcuts and Voice Memos both produce .m4a, so phone capture is safe. |
| Text, ideas, notes | `VAULT/raw/` (Obsidian phone/desktop) | Ingested nightly, classified, distributed to wiki/ |
| A link or stray thought, on the go | Message a topic in the San Telegram group | harvest-openclaw captures the conversation nightly |
| Book PDF | `~/Downloads` | Matched to book entity, distilled (wiki-books) |
| Other docs (.md/.txt) | `~/Downloads` | Auto-copied to raw/ by harvest-downloads |

Anything that can't land in one of these zones needs its own sensor — see Gap
Backlog.

---

## Status matrix

✅ captured · 🟡 partial (capture exists, loses content) · ❌ not captured · ❓ unverified

### Self-capture (Santiago → brain)

| Source | Path | Status | Notes |
|---|---|---|---|
| Phone mic shortcut | iOS Shortcut → iCloud `Meetings/` | ✅ | Confirmed 2026-06-09. Transcribed nightly. |
| Desktop mic shortcut | destination UNKNOWN | ❓ | Run it once, then: `find ~/Downloads ~/Desktop ~/Documents ~/Library/Mobile\ Documents -name '*.m4a' -mmin -10 2>/dev/null`. If it lands outside `Meetings/`, point the shortcut's Save File action at `Meetings/` — zero code needed. If it's dictation-style (text, no file), the contract is: paste the text into a raw/ note or Telegram. |
| Manual notes | Obsidian → `VAULT/raw/` | ✅ | Works from phone + desktop. |
| Morning-brief edits | checkboxes/comments in the brief | ✅ | process-brief-feedback (2 PM / 7 PM, mtime-gated). |
| Telegram messages to the 4 agents | San group topics | ✅ | harvest-openclaw nightly, verbatim, window = yesterday 21:00 → today midnight (late-evening hole closed 2026-06-10). **Voice notes to bots are NOT captured** (text-only extraction) — speak to the Meetings/ folder instead, or type. |
| Nightly agent debrief (agents → vault) | 9:30 PM "Daily Signal" question in each agent topic | ✅ | evening-debrief.sh asks each agent for NEW signal from its vantage (xai feed distillation, judge verdicts, cross-domain observations, vault flags). Re-summarizing logged conversations forbidden — those are captured verbatim. Replies harvested at 10 PM. Santiago-directed elicitation lives in the morning brief's Questions instead — he answers in the morning, not at 9:30 PM (decision 2026-06-10). |

### AI conversations ("the main inputs of my brain to computer")

| Source | Path | Status | Notes |
|---|---|---|---|
| Claude Code — local CLI / Conductor | `~/.claude/projects/*.jsonl` | 🟡 | claude-extract nightly. Known compression: sessions >1000 msgs read first 20 + last 200 only. |
| Claude Code — web/mobile sessions | Anthropic cloud | ✅ | Self-filing contract (CLAUDE.md): every remote session writes `sessions/YYYY-MM-DD-topic.md` and pushes; harvest-sessions.sh extracts sessions/ across ALL remote branches nightly (no merge needed) → raw/. Transcripts stay unreachable; the summary + git artifacts are the record. Same pattern copyable to other repos (taxfree-ai-bot) by adding the CLAUDE.md contract there. |
| Claude.ai chats | Anthropic cloud | 🟡 | Verbatim is unreachable (no API). Capture path: session-end **"wiki this"** self-summary → paste to Telegram sanbrain topic or raw/ (`setup/llm-session-summary-prompt.md`, ingest Phase 2i, `self-summary` fidelity). Signal over exact data — accepted trade 2026-06-09. If a day had LLM activity but no summaries arrived, the morning brief asks once (Phase 5.5) — elicitation at the hour Santiago actually answers. Official data export remains the archival backstop. |
| ChatGPT | OpenAI cloud | 🟡 | Same self-summary path. One-time setup: add the prompt to custom instructions. |
| Grok | xAI cloud | 🟡 | Same self-summary path. |
| OpenClaw agent conversations | `~/.openclaw/agents/*/sessions/` | ✅ | Nightly digest, VERBATIM; >4000-char messages truncated but counted. Do not add bot-written daily summaries on top — second copy, lower fidelity (agent charter workflow 3 repurposed accordingly). |

### Consumption (world → brain)

| Source | Status | Notes |
|---|---|---|
| Books (PDF) | ✅ | wiki-books pipeline from Downloads. Physical-book notes: manual raw/ drop. |
| X — bookmarks/feed | 🟡 | High volume, high signal (confirmed). The xai agent's curated-feed distillation now flows in via the nightly agent debrief — but YOUR OWN bookmarks/reading remain uncaptured. Close via share-sheet → Telegram sanbrain topic habit now; media-queue sensor later (Gap Backlog #2). |
| YouTube | ❌ | Same: share link to Telegram now; transcript-fetch sensor later. |
| Articles/web | 🟡 | Works IF dropped as URL-note into raw/ (ingest Phase 2d). No frictionless path from phone browser yet — same media-queue fix. |
| Podcasts | ❌ | Lowest priority; no habit identified. |

### Communications

| Source | Status | Notes |
|---|---|---|
| WhatsApp | ❌ | Mainly social (confirmed) — deprioritized. If a business chat matters: Export Chat (.txt, no media) → save to Downloads → auto-harvested. Zero code, on demand. |
| Email (Gmail) | ❌ | Not selected as signal — deprioritized. Revisit if Tax Free ops move to email. |
| iMessage | ❌ | Not requested. Heavy privacy surface; leave out. |

### Systems & ambient

| Source | Status | Notes |
|---|---|---|
| GitHub activity | 🟡 | harvest-github nightly — but repo list is HARDCODED (taxfree-ai-bot, sanbrain). New repos are invisible until added. Fix: dynamic `gh repo list` (Gap Backlog #3). |
| Calendar | 🟡 | Today's events → reminders + brief questions. Past events never become entity timeline entries (who you met = signal). Gap Backlog #4. |
| Downloads desk | 🟡 | .md/.txt content harvested; book PDFs matched. Non-book PDFs, images, spreadsheets: listed on the desk manifest but content never extracted. Drop important ones into raw/ manually, or close with Gap Backlog #5. |
| Pala Padel platform data | ❌ | Your own product's DB (users, tournaments, rankings) — the richest business signal there is. A weekly metrics dump → raw/ would feed context files real numbers. |
| Tax Free ops data | ❌ | Same logic, whatever the system of record is. |
| Photos (x100v, food) | ❌ | ingest's image handler is a stub. Low priority. |
| Health/fitness | ❌ | Not requested. |

---

## Known compression points (deliberate, but visible)

1. claude-extract long sessions: middle of 1000+ message sessions dropped.
2. harvest-openclaw: messages truncated at 4000 chars (counted in digest); tool outputs excluded.
3. Apple AI recording summaries: ingested with `fidelity: apple-summary`, framing distrusted.
4. Morning brief carries max 5 connections / 3 ideas / 5 questions — selection, not capture loss (full data stays in wiki/).

## Gap backlog (ranked by signal value, per 2026-06-09 answers)

1. **LLM session capture — DONE as a habit (2026-06-09):** "wiki this" self-summary at session end → Telegram/raw (`setup/llm-session-summary-prompt.md`). Remaining optional backstop: an export-zip parser for the official Claude.ai/ChatGPT/Grok data exports, if archival completeness ever matters. Build only on demand.
2. **Media-queue sensor** — links shared to Telegram (or a raw/media-queue.md note) get resolved nightly: YouTube transcript fetch, X post text capture → raw/. Until built: the share-to-Telegram habit alone already lands the URL + your one-line take in the vault.
3. **Dynamic GitHub repo list** — replace the hardcoded array with `gh repo list`.
4. **Calendar back-fill** — nightly: yesterday's events → raw/ as meeting stubs (attendees become entity timeline entries even without a recording).
5. **Downloads PDF extraction** — copy small non-book PDFs into raw/ for ingest Phase 2a instead of desk-listing only.
6. **Audio intake hardening** — pending the desktop-mic find-command check: re-point the shortcut at Meetings/ or add its folder to harvest-recordings; widen the harvester from `.m4a`-at-root to common audio extensions (`.wav .mp3 .aac .ogg .caf`) + one level of subfolders, so any recorder that writes into Meetings/ is captured regardless of format.

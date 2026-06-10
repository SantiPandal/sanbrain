## LLM Session Summary — claude-code-web — Phase 1 reliability + input capture system
Date: 2026-06-10

### Problem context
Full-depth audit of the sanbrain repo from first principles (scalability,
reliability, capture completeness), iteration strategy per Jack Dorsey's
"From Hierarchy to Intelligence," combined with researched Garry Tan / GBrain
wiki-building principles. Then implementation of the agreed Phase 1.

### Decisions
- Phase 1 "Trustworthy" built and merged to master (PR #10): vault under git
  with eviction guard (~/.sanbrain-vault.git, outside iCloud); nightly split
  from one 45-min mega-call into 4 staged `claude -p` calls with JSON handoffs,
  machine-written state files, retry, Telegram alerts; mechanical vault-doctor
  feeding the brief; strict two-factor Downloads deletion parsing; >25MB
  recordings ffmpeg-chunked; Apple AI summaries fidelity-marked. Reasoning:
  mechanical work belongs to deterministic scripts (validated independently by
  GBrain's own design); no more silent failure or unversioned LLM writes.
- Input registry created (docs/INPUTS.md) as single source of truth for all
  signal sources; maintenance rule: a source not in the file is a gap by
  definition.
- Capture priorities re-ranked from Santiago's answers: AI chat windows are
  the PRIMARY brain input → top gap; X/YouTube consumption second; WhatsApp
  (social) and email deprioritized.
- Cloud LLM capture (ChatGPT, Claude.ai, Grok): accepted signal-over-verbatim
  trade — session-end "wiki this" self-summaries pasted to Telegram or raw/,
  with `self-summary` fidelity treatment in ingest (1.2.0, Phase 2i). Daily
  9:30 PM close-out nudge makes the habit time-bound.
- Telegram bot daily summaries REJECTED as capture mechanism: harvest-openclaw
  already captures agent conversations verbatim; agent charter workflow 3
  repurposed (was writing duplicate end-of-day summaries).
- Remote Claude Code sessions now self-file: CLAUDE.md contract + sessions/
  directory + harvest-sessions.sh reading all remote branches nightly. This
  file is the first artifact of that contract.
- Phone mic shortcut confirmed captured (saves to iCloud Meetings/). Desktop
  mic shortcut destination unverified.

### Entities mentioned
- Garry Tan — GBrain author; repo + docs distilled for wiki-building principles
- Jack Dorsey — "From Hierarchy to Intelligence" framework applied as iteration model
- Pala Padel — flagged as richest uncaptured business data source (own platform DB)

### Insights
- GBrain independently implements the same three structural fixes the audit
  proposed (vault-in-git, per-skill thin invocations with checkpoints,
  mechanical doctor) — convergent evidence, no longer opinion.
- Scale tripwires from Tan's data: grep retrieval fine now (~210 notes);
  search/graph layer only at ~3-5K pages; git strains ~5K files.
- Fidelity discipline generalizes: AI summaries (Apple, self-summaries) are
  signal not record — extract conservatively, never attribute framing.

### Action items
- [ ] Santiago: pull master on the Mac mini; create ~/.sanbrain.env (move
      OPENAI_API_KEY); brew install ffmpeg; add 9:30 PM nudge + 2/7 PM
      feedback cron lines
- [ ] Santiago: add the "wiki this" prompt to ChatGPT/Claude.ai/Grok custom
      instructions; redeploy openclaw/AGENTS.md to the agents
- [ ] Santiago: desktop mic check — run shortcut, then
      `find ~/Downloads ~/Desktop ~/Documents ~/Library/Mobile\ Documents -name '*.m4a' -mmin -10`
- [ ] Decide: merge current branch (registry + LLM capture + session
      self-filing); next backlog items (media-queue sensor, dynamic GitHub
      repos, calendar back-fill, Downloads PDF extraction)

### Open questions
- Where does the desktop mic shortcut save?
- Phase 2 (contradiction tiering, typed citations, inbox/, brain-lint,
  dossier template, docs DRY) — when to build?

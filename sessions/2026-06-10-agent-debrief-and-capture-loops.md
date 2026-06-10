## LLM Session Summary — claude-code-web — Agent debrief redesign + capture loop fixes
Date: 2026-06-10

### Problem context
Continuation of the Phase 1 session (see 2026-06-10-phase1-reliability-input-capture.md).
Closing the chat-window capture gap and designing the nightly elicitation loop.

### Decisions
- Nightly 9:30 PM debrief REDIRECTED from Santiago to the AI agents — Santiago
  stated he will not answer at that hour; agents answer reliably within
  minutes. Each agent gets a "Daily Signal" question in its own topic, scoped
  to its vantage: xai feed distillation, judge verdicts, openclaw cross-domain
  patterns, sanbrain-admin vault observations. NEW signal only; conversation
  re-summaries remain forbidden (verbatim harvest already captures those).
- Santiago-directed elicitation moved to the morning brief (the hour he
  actually answers): morning-brief 1.2.0 asks once for missing LLM session
  summaries when a day had AI activity but none arrived.
- harvest-openclaw capture-window bug fixed: messages between 10 PM and
  midnight were never captured by any run (today-only filter, 10 PM run).
  Window now spans yesterday 21:00 → today midnight.
- Remote-session self-filing verified end-to-end: branch-only summary
  extracted by harvest-sessions.sh and delivered to raw/, idempotent on rerun.

### Entities mentioned
- xai agent feed — was a fully uncaptured input; now flows via the nightly
  agent debrief (its only path into the brain)

### Insights
- Elicitation must match the responder's availability: agents at 9:30 PM,
  Santiago at 7 AM. A question asked at the wrong hour captures nothing.
- The same mechanism (ask-for-summary) is a duplicate for captured sources
  and the only option for uncaptured ones — redundancy is a property of the
  source, not the mechanism.

### Action items
- [ ] Santiago: deploy — pull branch/merge, redeploy openclaw/AGENTS.md to
      the agents, add 9:30 PM evening-debrief cron line
- [ ] Verify first live agent debrief produces Daily Signal replies and they
      appear in the next openclaw digest

### Open questions
- Merge the 5-commit branch to master now or keep stacking?
- Desktop mic shortcut destination still unverified.

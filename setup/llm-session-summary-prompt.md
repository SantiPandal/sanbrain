# LLM Session Summary — capture prompt

The cloud LLMs (ChatGPT, Claude.ai, Grok) can't be read by the pipeline.
The trade: capture the SIGNAL at session end, not the verbatim. You ask the
model to summarize in a fixed format, then paste the block anywhere the
pipeline already reads:

- **Telegram** → the sanbrain topic in the San group (captured by harvest-openclaw that night)
- **Obsidian** → a new note in `VAULT/raw/` (ingested that night)

These summaries carry `fidelity: self-summary` semantics: ingest extracts
facts and decisions conservatively and never treats the model's framing as
Santiago's words (same rule as Apple recording summaries).

## Setup (one time, per tool)

Add this to ChatGPT custom instructions / Claude.ai profile preferences /
Grok personalization:

> When I say "wiki this", output ONLY a markdown block in exactly this format,
> no preamble, no commentary:
>
> ```
> ## LLM Session Summary — [tool name] — [3-6 word topic]
> Date: [today, YYYY-MM-DD]
>
> ### Problem context
> [What I was trying to solve, 1-2 lines]
>
> ### Decisions
> - [decision + one-line reasoning, only if real decisions were made]
>
> ### Entities mentioned
> - [people/businesses/products discussed, with one-line context each]
>
> ### Insights
> - [non-obvious takeaways, max 3]
>
> ### Action items
> - [ ] [things I committed to]
>
> ### Open questions
> - [what remains unresolved]
> ```
>
> Omit any empty section. Be factual: only include what was actually said in
> this conversation. Never invent entities or decisions.

## Usage

End any session worth keeping with: **"wiki this"** → copy the block →
paste into the sanbrain Telegram topic (on the go) or a raw/ note (at desk).
Two words plus a paste. If a session wasn't worth two words, it wasn't signal.

## Why not full exports?

The official data exports (all three tools have them) remain the archival
backstop — see docs/INPUTS.md gap backlog. Summaries are the daily capture;
exports recover the corpus if ever needed. Don't confuse the two: the
summary habit is what keeps the brain current.

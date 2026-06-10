---
name: claw
description: Consult Santiago's four OpenClaw brain agents (real always-on agents with their own memory, vault access, and Telegram presence — not simulated personas) via the `claw` CLI and get their answer back in-terminal. Use for a board-level verdict or reality check (judge), a product/engineering/leverage critique (xai), vault/entity/relationship context (sanbrain), or broad dot-connecting (openclaw). Use proactively, even when Santiago doesn't explicitly ask — whenever a named person/business/project comes up that the vault may know (sanbrain), or before delivering a go/no-go or strong recommendation (judge). Triggers — "ask the claw", "consult judge/xai/sanbrain", "qué sabemos de X", "what do we know about X", "get a verdict on X", "second opinion", "should I do this deal", "/claw <agent> <question>".
user_invocable: true
---

# claw — consult the OpenClaw brain agents

Santiago runs **four always-on OpenClaw agents** on his Mac mini, reachable through the OpenClaw Gateway. These are *real* agents with their own memory, vault access, and Telegram presence — not the simulated `/ask-munger`-style persona prompts. The `claw` CLI runs one synchronous agent turn and prints the clean answer to stdout.

## Usage

- `/claw <agent> <question>` — consult one agent. e.g. `/claw judge ¿es buen deal el de Pala?`
- `/claw <agent1>,<agent2> <question>` — consult several, present side by side.
- `/claw all <question>` — all four, compare.
- `/claw <question>` (no agent) — infer the best agent, **say which you picked and why (one line)**, then run.

## Run

```bash
claw <agent> "<question>"        # agent ∈ judge | xai | sanbrain | openclaw | all (comma-combine)
```

- **Set the Bash tool timeout to 360000 ms.** Each turn is a real LLM run (30–120s); the CLI allows 300s per agent.
- Not on PATH? Use `~/sanbrain/scripts/claw`.
- `claw --list` = roster + routing table. `claw --doctor` = gateway health. `--tg` mirrors Q+A to the agent's Telegram topic (Santiago's phone) — add it when he says "post it" / "mándalo al grupo".

## The four claws

| Agent | Bot | Reach for it when… |
|-------|-----|--------------------|
| `judge` | @judge_deutsch_bot | High-stakes verdict, reality check, go/no-go, Deutsch hard-to-vary test, kill-the-thesis pressure. |
| `xai` | @xaisanbot | Product/engineering tradeoffs, leverage analysis, architecture critique, feed signal. |
| `sanbrain` | @sanbrainbot | "What do we know about X" — vault data, entity history, decisions, relationships. For a *structured* vault report, prefer `/summary`. |
| `openclaw` | @openclaw8788bot | Broad/half-baked thinking, connecting dots across businesses + personal, default catch-all. |

Routing inference when no agent given: decision/verdict/risk → judge; product/eng/leverage → xai; "what do we know / history / who is" → sanbrain; otherwise → openclaw.

## Present

- Single agent: print the reply verbatim under a `🦞 <agent> —` header. No preamble, no editorializing — these agents have context you don't.
- Multiple: one block per agent, then a 1–2 line synthesis **only if it adds signal** (agreement / disagreement / the decisive point).
- Spanish in, Spanish out.

## Fallback — gateway down

If `claw` reports no answer (`claw --doctor` fails):
1. For `sanbrain`: read the vault directly — `grep -ril "<topic>" ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/VAULT/wiki/` — and answer from it, marked `source: vault (direct read, gateway unavailable)`.
2. For the rest: tell Santiago the gateway is unreachable and offer to post the question to the agent's Telegram topic instead (`openclaw message send --channel telegram --target -1003637114912 --thread-id <32|34|36> --message "…"`) so it gets answered async on his phone.

## Rules

- Pass the question through faithfully; report the answer faithfully. Wrong claw = wrong context — pick deliberately.
- Empty / "not in vault" / "I'd need more" is a result, not a failure — surface it plainly.

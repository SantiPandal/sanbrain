# TOOLS.md — local CLI tools available to the claws

OpenClaw injects this file into every agent session. Notes about tools on this machine (the Mac mini).

## claw — consult a fellow claw, synchronously

Query another agent and get its answer back inline, without posting to the Telegram group:

```bash
claw <agent> "<question>"      # agent ∈ judge | xai | sanbrain | openclaw | all
```

- `judge` — verdicts, reality checks, go/no-go. `xai` — product/eng/leverage. `sanbrain` — vault, entities, history. `openclaw` — broad dot-connecting.
- A turn takes 30–120s; allow a long timeout. Don't `claw` yourself.
- Use it for the mandatory consultation rule (see AGENTS.md) when you want the answer inline. Posting in the agent's Telegram topic is still preferred when Santiago should see the exchange.

---
name: downloads-triage
version: 1.0.0
description: |
  Advisory classifier for ~/Downloads. Reads the desk and the vault and writes a
  per-file recommendation (keep / disposable / save-review / save-legal / crypto)
  to a proposal file. It NEVER touches, moves, or deletes any file — a separate
  deterministic executor (process-downloads.py) consumes the proposal, clamps it
  so nothing irreplaceable can be lost, and is the only thing that acts.
triggers:
  - "triage downloads"
  - "classify downloads"
  - "what's in my downloads"
tools:
  - exec
  - read
  - write
mutating: false
---

# Downloads Triage

## Contract

You are an **advisor**, not an actor. Read `~/Downloads` and the vault, decide
what each desk file *is*, and write a JSON proposal to the path the runner gives
you (`PROPOSAL_PATH`). **You never move, delete, trash, rename, or modify any
file in `~/Downloads`, and you never copy anything into the vault.** The only
file you write is the proposal.

A deterministic executor (`process-downloads.py`) reads your proposal and acts —
but it **clamps** you: it protects crypto and pattern-matched fiscal/legal files
no matter what you say, it never permanently deletes (everything goes to macOS
Trash, recoverable ~30 days), and it always saves a verbatim copy of a valuable
file into the vault *before* clearing it. So you cannot cause data loss. Your job
is **accuracy** — especially the things a filename-only rule gets wrong.

Where you add value over a dumb classifier:
1. **Read content when the name hides the importance.** A signed contract saved
   as `scan001.pdf`, a `factura` that's actually just a quote, a `.pdf` that's a
   throwaway receipt. Peek the content for anything ambiguous.
2. **Check the vault.** Is this document/entity already captured in the wiki? If
   the content is already in the vault, say so (`already_in_vault: true`) — the
   desk copy is then safe to clear.
3. **Be conservative.** When unsure, prefer `save-review` over `disposable`.
   Losing time to a saved copy is cheap; losing a document is not.

## How to run

1. List `~/Downloads` (top level only; ignore dotfiles and directories).
2. For each non-obvious file, read enough to classify it: `pdftotext -l 2 FILE -`
   for PDFs, `head -c 2000 FILE` for text, image/exec names usually need no read.
3. For documents that look like they matter, search the vault for whether they're
   already captured: grep `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/VAULT/wiki`
   for the entity/title.
4. Write the proposal JSON to `PROPOSAL_PATH`. Write nothing else, anywhere.

## Recommendation guide

| recommendation | use for | what the executor does |
|---|---|---|
| `crypto` | private keys, certificates, FIEL/CSD, keychains | never touched |
| `keep` | clearly in active use / wanted on the desk right now | left on the desk |
| `save-legal` | irreplaceable fiscal/legal/identity/financial docs — facturas, CFDI, contracts, deeds, IDs, bank statements | verbatim copy → `raw/legal/`, then desk original cleared (when idle) |
| `save-review` | probably worth keeping, not legal — useful PDFs, datasets, references | verbatim copy → `raw/needs-review/`, then cleared (when idle) |
| `disposable` | re-acquirable / low-value — installers, screenshots, memes, throwaway exports, or anything already captured in the vault | cleared when idle (macOS Trash) |

Note: the executor only *clears* a file once it's been untouched for the idle
window — fresh files always stay. `keep` means "don't clear even when idle".

## Output format

Write to `PROPOSAL_PATH` exactly this shape (no prose, valid JSON):

```json
{
  "generated": "YYYY-MM-DDTHH:MM:SS",
  "files": [
    {
      "name": "<exact filename as it appears in ~/Downloads>",
      "recommendation": "keep|disposable|save-review|save-legal|crypto",
      "reason": "<one short line>",
      "already_in_vault": true
    }
  ]
}
```

Rules:
- `name` must be the **exact** filename. The executor only acts on real files in
  `~/Downloads`; a name that doesn't match a real file is ignored — so don't
  guess names, and don't include files you didn't actually see listed.
- `generated` must be today's date/time — a stale proposal is ignored.
- Include every non-dotfile, non-directory desk file you can classify. Omit
  anything you genuinely can't read or judge (the executor falls back to its own
  deterministic rules for anything you omit).
- If `~/Downloads` can't be listed (no access), write `{"generated": "...",
  "files": []}` — the executor then runs purely deterministically.

## Cron

Runs as `com.sanbrain.downloads-triage` (own launchd job) at a set time daily,
before the 22:00 nightly that executes the proposal. Also runnable by hand.

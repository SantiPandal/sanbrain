---
type: research
project: worldcup-2026-betting
title: WC2026 Quantitative Betting Dossier — Index
date: 2026-06-09
status: phase-1-complete
---

## For future Claude

Research dossier for betting the 2026 World Cup (starts June 11, 2026) Jane Street-style: probabilities, EV, market microstructure, disciplined sizing. Phase 1 (this dossier) = the knowledge base. Phase 2 = build the prediction model. Phase 3 = the sized bet list. Built June 9, 2026 by six parallel research agents + synthesis; all facts web-verified and source-dated.

# World Cup 2026 Betting Dossier

## TLDR

Football is a ~2.7-goals-per-match Poisson process: the better team loses 1 in 4, one variable (team strength) carries most of the predictable variance, and the closing line at sharp venues already prices nearly everything. The durable edges for a solo operator at this World Cup, in order: **(1) promo harvesting** during the books' $3–4B handle war, **(2) venue arbitrage** — sportsbook futures books run 120%+ overround while prediction markets (Kalshi/Polymarket, both live in the US) run ~100.5%, **(3) stacked situational edges** the market underweights (Azteca altitude +0.5 goals/1,000m, heat in 67/104 matches, 4x travel asymmetries within groups, MD3 mutual-draw incentives with 8-of-12 thirds advancing), **(4) pre-committed event windows** (buy any top-6 team at +800+ after a Matchday-1 upset — 2 of the last 4 champions lost their opener), and **(5) expressing dark-horse theses in stage markets, never outrights** — every WC winner since 2002 was top-5 in the pre-tournament market (median ~6/1), while Morocco's famous 2022 run paid 50/1 on "reach the semifinal" and $0 on the 200/1 outright. "Asymmetric upside" without a structural mechanism is just the favorite-longshot bias eating you: −61% expected return at 100/1+. Size fractional Kelly, cap the longshot sleeve at 2–3% of bankroll, measure process by closing-line value, not five weeks of P&L.

## Chapters

| # | File | What it answers |
|---|---|---|
| 1 | [01-match-variables.md](01-match-variables.md) | Every team-quality variable that predicts match outcomes, with effect sizes: Elo, squad value (the best-documented public edge), xG process vs results, fatigue, injuries (5–10pp for superstars), what to ignore (FIFA ranking, cohesion narratives, manager pedigree) |
| 2 | [02-context-tournament-dynamics.md](02-context-tournament-dynamics.md) | Context: host effect (57% of hosts reach semis), altitude, heat, pitches, travel, rest; knockout randomness (34% ET, 23% pens); the ~100-minute match regime; MD3 incentive structure of the 48-team format |
| 3 | [03-market-mechanics.md](03-market-mechanics.md) | The trader's manual: odds→probability, vig removal (Shin), market sharpness hierarchy, CLV, Kelly + correlation, the June 2026 US/MX/CA venue landscape (books, exchanges, prediction markets, promos, taxes) |
| 4 | [04-prediction-models.md](04-prediction-models.md) | How to build the engine: Dixon-Coles + Elo + market blend (70–90% market weight), worked pricing example, 2026 simulation mechanics (tiebreakers, 495-combination bracket annex), data sources, 2–4 day Python build plan |
| 5 | [05-wc2026-landscape.md](05-wc2026-landscape.md) | Ground truth as of June 9, 2026: all 12 groups, schedule, 16 venues, the odds board (Spain/France +450–500 co-favorites), team news (Messi/Yamal hamstrings, Netherlands' gutted defense), rules, bracket paths |
| 6 | [06-asymmetric-upside.md](06-asymmetric-upside.md) | The hard look at "asymmetric upside": 2002–2022 base rates, favorite-longshot bias magnitudes, where genuine convexity lives (stage markets, MD1 repricing, futures-as-options, Golden Boot structure, biscotto draws) and the lottery-ticket taxonomy |
| 7 | [07-playbook.md](07-playbook.md) | **The synthesis**: operating principles, the ranked edge map, the pre-tournament watchlist, daily process loop, Phase 2/3 roadmap, hard risk rules |
| 8 | [08-quant-forecasts.md](08-quant-forecasts.md) | The forecast field vs the market: Nate Silver's PELE (Spain 18.5%, France docked to 11.7%), Opta (Spain 16.1%), Zeileis–Groll hybrid (Germany-bias flag), Goldman (Spain 26%, England 5%), pure Elo, Polymarket/Kalshi (>$2B) — comparison table, model-vs-market disagreements, 2010–2022 track records |

## Status

- **Phase 1 — knowledge base: DONE** (this dossier, 2026-06-09).
- **Phase 2 — prediction model:** build per chapter 4 §7 / playbook §5. Blocker to resolve first: official FIFA tiebreaker order (sources conflict — see playbook §5 open items).
- **Phase 3 — sized bet list:** model output × live prices × the playbook's mechanism filter.

## House rules

This is research, not financial advice. Betting markets are near-efficient; most participants lose the vig. Every number here was verified against June 2026 sources but odds move hourly — never act on a stale price. Only bet what can go to zero without consequence.

## Timeline

- 2026-06-09: Dossier compiled (6 research agents + synthesis). Tournament starts in 2 days.

---
type: research
project: worldcup-2026-betting
chapter: 7
title: The Playbook — Jane Street Operating Manual for WC2026
date: 2026-06-09
status: compiled
---

# The Playbook: Jane Street Operating Manual for WC2026

*Chapter 7 — the synthesis. Everything in chapters 1–6 compressed into an operating system. Tournament starts in 2 days.*

---

## 0. The one-paragraph thesis

The betting market is a derivatives market where the closing line at sharp venues is fair value and your counterparty is either Starlizard (sharp markets) or a guy in a Pulisic jersey (soft markets). You cannot out-model Pinnacle on Asian handicaps. You CAN: harvest promos that are deliberately −EV for the house, exploit the 10–25x margin difference between sportsbook futures (120%+ books) and prediction markets (~100.5%), trade situational edges the market structurally underweights (altitude, heat, MD3 incentives, MD1 overreactions, injury windows), and express dark-horse theses in stage markets instead of outrights. Size everything fractional-Kelly, treat correlated positions as one position, measure yourself on CLV not P&L, and accept that one tournament resolves ~0.13 SD of true edge — process is the product.

---

## 1. Operating principles (non-negotiable)

1. **No probability, no trade.** Every quote → de-vigged implied probability (Shin/power method for anything with longshots, multiplicative only for tight two-ways) before any decision.
2. **Edge = your probability − market fair probability.** Fair = de-vigged sharp close (Pinnacle/Betfair; Kalshi/Polymarket mid for futures). No positive spread after vig → no trade, regardless of conviction.
3. **The market gets 70–90% weight in your final probability.** Your model exists to find the 5–15% of prices where the market is lazy, not to re-derive Spain's title odds.
4. **Size by edge/variance:** f* = edge/(odds−1), then bet ¼–½ of it. Full Kelly = 50% lifetime chance of halving the bankroll.
5. **Correlated bets are ONE bet.** Spain outright + Spain group winner + Spain match lines = one thesis; cap the cluster near the single largest standalone Kelly stake.
6. **Longshot sleeve ≤ 2–3% of bankroll, total.** Asymmetric payoff ≠ asymmetric value; longshots return −18% at 15/1 and −61% at 100/1+ (Snowberg-Wolfers). The convexity you buy must be structurally justified (see §3).
7. **Judge process by CLV.** A 2% edge at −110 loses money over 500 bets a third of the time. Log every bet with the closing price; +2% average CLV = working process, even at negative P&L.
8. **Protect access.** Soft-book accounts are depleting assets (limits arrive within weeks of detectable CLV). Sharp venues (Circa, prediction markets, exchanges) are durable infrastructure.
9. **Account for the 2026 tax drag** (US): OBBBA caps loss deductibility at 90% — high-churn/low-edge strategies now carry a tax cost even at break-even. (MX: ISR withholding via operator.)

---

## 2. The edge map, ranked by reliability

| Rank | Edge | Mechanism | Expected magnitude |
|---|---|---|---|
| 1 | **Promo/boost harvesting** | Books are paying for WC market share: DK $5→$200, FD $5→$350, bet365 $10→$365; boosts reprice −EV to +EV vs sharp line | Highest-Sharpe trade available; bonus bets ≈ 60–75% cash conversion |
| 2 | **Line shopping + venue arbitrage on futures** | Same bet priced +2800 (FanDuel) vs +6000 (other books) vs ~1.3% fair (prediction markets); outright books run 120–125% vs Polymarket ~100.5% | 0.5–2% ROI on match markets; 2–10x payout differences on futures |
| 3 | **Situational/contextual edges** | Altitude (+0.5 goals/1,000m), heat (67/104 matches at risk — unders, fade pressers, open-air afternoon), travel asymmetry (Algeria 4,800km vs Argentina 700km in the same group), ~100-min effective matches (late-goal windows) | A few percentage points each; stack them — single factors are priced, stacks are not |
| 4 | **Event-driven repricing windows** | MD1 upset loss on a top-6 team (Argentina 2022: +550→+850, unchanged fundamentals); injury "doubt→confirmed" gaps (Neymar 2014 = 8-9pp); markets overcorrect salient shocks, correct within ~6 min live | Buy pre-committed: any top-6 at +800+ after MD1 upset |
| 5 | **MD3 incentive spots** | Draw advances both → true draw probability ≫ 25% base rate (France–Denmark 0-0 2018; Sweden–Denmark 2-2 2004); 8-of-12 thirds advancing creates more of these; check third-place GD ladders for anti-draw incentives first | Known spots are partially priced now; the *less obvious* 2026 scenarios (staggered finale days, known thresholds) are not |
| 6 | **Relative value across correlated futures** | "Win" vs "reach final" vs "win group" priced by different desks; conditional P(win final \| reach final) > 60% flags the expensive leg | Spreads, not directional risk |
| 7 | **Stage markets for dark horses** | Morocco 2022: outright 200/1 paid $0, "reach SF" 50/1 paid in full; every celebrated underdog run cashed in stages/groups, never outright | The only honest convexity |
| 8 | **Golden Boot structure** | Penalty taker + likely semifinalist + 20/1+ (James 150/1 in 2014; pens were 4/7 of Messi's 2022 total); fade big names on short-run teams | Genuine live tails exist here, unlike outrights |
| 9 | **Model-driven match edges** | Dixon-Coles blend finds stale cross-confederation lines in the first 10 days; props/derivatives at soft books | 1–3% per bet, needs the Phase 2 model |
| AVOID | Parlays/SGPs (15–31% hold), big-name scorer props, 100/1+ outrights held to settlement, USA/Mexico/England futures at retail US prices (host-flow shading ≈ −60% EV on USA at +2800) | | |

---

## 3. Pre-tournament watchlist (candidates — confirm price vs fair before any action)

These came out of the research with structural support. None is a bet until checked against live de-vigged prices and the Phase 2 model.

**Contextual/structural:**
- Mexico, per-market (chapter 13 verdicts): the flagship is **reach R16 at +125** (Azteca R32 vs a third-placer → true ~52–57% vs 44% implied); **group winner cheap at -110 (DK), rich at -140 (FD)** — the El Tri tax is paid at US books, Caliente does NOT shade Mexico shorter; reach QF +280 fair (likely means beating England at altitude); reach SF/final and outright all rich (the host carpet ends with a Miami QF). Five straight games in Mexico if they win the group; zero home games if they finish second.
- Colombia in Group K: Bogotá-bred squad playing Uzbekistan in Mexico City and DR Congo in Guadalajara — the altitude edge nobody prices outside CONMEBOL qualifiers. Also flagged (SI) as plus-money group-winner value vs Portugal.
- Spain MD3 caution: Guadalajara altitude trip vs Uruguay — a live spot to fade a -250-style favorite, especially if already qualified and rotating.
- Unders/slow-tempo lean in open-air afternoon heat games (Miami, KC, Philadelphia, Monterrey); neutral models at full weight only in roofed venues (Dallas/Houston/Atlanta/Vancouver).
- Travel-stack fades on MD2/MD3: Bosnia (3,129 mi), Algeria (2,998 mi vs Argentina's ~700 km), Czechia (2,799 mi + altitude oscillation).

**Repricing windows (pre-committed rules):**
- Any top-6 team (Spain, France, England, Portugal, Argentina, Brazil) at +800 or better after an MD1 upset loss: buy. (2 of the last 4 champions lost their opener.)
- Injury doubt→resolution gaps on stars: precompute availability-adjusted lines for Messi (hamstring, 39 mid-tournament), Yamal (hamstring), Mbappé (thigh). If the news breaks good/bad, the first hour is the trade.
- France: drifted on a meaningless friendly loss to Côte d'Ivoire (June 4) — the underlying-metrics-over-results trade if the drift persists to June 16.

**Fades:**
- Netherlands deep-run markets: Timber, De Ligt, De Vrij, Simons all out — defense gutted; also degrades Group F winner probability (feeds Brazil a tougher R32).
- Argentina +900 as "value": hardest bracket half of the favorites, R32 vs likely Uruguay in Miami heat, Messi fitness variance. The +900 is fair-ish, not cheap; better expressed as Argentina group winner -250 alternatives or stage spreads.
- USA/Mexico/England outrights at US retail prices: −40 to −60% EV vs prediction-market fair. If long the thesis, buy on Kalshi/Polymarket instead.

**Convexity (within the ≤2–3% sleeve):**
- Golden Boot screen output: Haaland +1400 (16 goals in 8 qualifiers, Norway's group has Iraq; but must escape France's group), Mbappé +600 is the chalk version. Check PK duty lists at squad announcements.
- Mid-tier "reach SF" candidates per the Morocco template (elite defense, set-piece strength, soft bracket quadrant) — finalize after the model runs the bracket, not before.
- Small contender futures bought as hedgeable options (e.g., a +1200-tier team): value = P(reach hedgeable node) × option value there; plan the semifinal/final hedge at purchase.

---

## 4. The process loop (during the tournament)

**Daily:**
1. Pull odds (The Odds API / book screens) → de-vig (Shin) → compare vs model blend → EV table, filter edge > 2–3%.
2. Check team news: lineups drop ~75 min pre-kickoff; injury replacements allowed until 24h before each team's opener (Timber precedent).
3. Harvest the day's boosts/promos across all books; convert bonus bets on mid-odds (+200 to +400) markets for maximum cash equivalence.
4. Log every bet: book, price, stake, de-vigged close, CLV.

**Per matchday cycle:**
- After each group matchday: re-rate (Elo update + λ refit), re-run the bracket sim. Futures reprice sluggishly mid-tournament — the model's biggest window is MD2–MD3 group/advancement/bracket-path markets.
- Before MD3 of each group: enumerate the qualification matrix; flag mutual-draw spots and anti-draw (GD ladder) spots; check rotation news on qualified favorites.
- At QF/SF stage: revisit open futures for hedging/locking (the manufactured-convexity play).

**Live (only if set up for it):**
- Fade overreactions to goals/red cards (~6-minute correction window, +2.79% documented pattern). Never chase the panic.

---

## 5. Phase 2 → Phase 3 roadmap

**Phase 2 — the model (2–4 focused days, per Chapter 4 §7):**
1. Data: martj42 international results CSV + eloratings.net snapshot + fixtures (openfootball) → DuckDB.
2. Ratings: own Elo (K=60/50/40/30/20, margin multipliers, +100 hosts) + Transfermarkt squad values (availability-adjusted).
3. Goal model: Elo→(λ,μ) nested Poisson regression, Dixon-Coles ρ, friendly down-weighting, 2–4yr decay half-life. `penaltyblog` does the heavy lifting.
4. Simulator: 100k Monte Carlo runs of the real bracket — tiebreakers RESOLVED (chapter 9): within-group = head-to-head first (points→GD→goals between tied teams, recursive), then overall GD→goals→conduct→FIFA ranking; cross-group third-place table = overall numbers first. Plus the 495-combination R32 annex, ET at λ/3 with haircut, shootouts 50/50, parameter redraws per run.
5. Market layer: The Odds API → Shin de-vig → blend 80/20 market/model → EV table with fractional-Kelly stakes.
6. Validation gate: blended forecast must weakly dominate market-only on WC 2010–2022 + Euros backtest (RPS/log-loss) before real sizing.

**Phase 3 — the bet list:**
- Output: per-match probabilities for all 104 matches (1X2/AH/totals), group/advancement/stage/outright probabilities from the sim, EV table vs live prices across books + prediction markets, candidate list ranked by edge × confidence, sized at ¼ Kelly with correlation clusters capped.
- The asymmetric-upside list = intersection of (model edge > 0) ∧ (structural mechanism from §2–3) ∧ (longshot sleeve limits). Lottery tickets that fail the mechanism test don't make the list no matter how juicy the payout looks.
- Execution notes per bet: which book/venue has the best price, promo overlay if any, hedge plan for futures.

**Open items to resolve before Phase 2 sizing:**
1. ~~Official 2026 group tiebreaker order~~ RESOLVED (chapter 9): head-to-head first per Article 13 of the official regulations. Bonus finds: yellows wipe TWICE (after groups AND after QFs — accumulation bans for the SF/final are near-impossible); abandoned matches resume from the minute of interruption (most storm suspensions will NOT void bets).
2. Pinnacle's current outright board (couldn't verify) — needed as a sharp futures benchmark alongside Kalshi/Polymarket.
3. Confirm PK takers per squad after first matches (Golden Boot screen input).
4. Santiago's actual venue access (MX: Caliente et al. — retail-grade margins; US books require physical presence; prediction markets per KYC) — determines the executable subset of the edge map.

---

## 6. Risk rules (hard limits)

- Total tournament bankroll: a number you can lose entirely without consequence. Decide it before June 11, never top up mid-tournament.
- Per-bet: ¼ Kelly default, ½ Kelly ceiling on the highest-confidence structural edges.
- Longshot sleeve (everything over +1000): ≤ 2–3% of bankroll combined, mentally marked to zero at purchase.
- Correlation cap: any single-team cluster ≤ the largest standalone Kelly stake within it.
- Stop rule: model edges that fail to show CLV after ~50 bets → halve sizing and audit the model; situational edges keep running (they don't depend on the model).
- A 104-match tournament is ~0.13 SD of a good bettor's edge. P&L over five weeks is noise; the dossier, the model, and the CLV log are the assets that compound to 2030.

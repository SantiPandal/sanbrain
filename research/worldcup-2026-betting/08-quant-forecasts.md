---
type: research
project: worldcup-2026-betting
chapter: 8
title: Quantitative Forecasts — Nate Silver, Opta, Academic Models vs the Market
date: 2026-06-09
status: compiled
---

# Quantitative Forecasts: Nate Silver, Opta, Academic Models vs the Market

*Chapter 8 of the WC2026 betting dossier. Compiled June 9, 2026, T-minus 2 days. This chapter inventories every serious public probabilistic forecast of the tournament, lines them up against market prices, and extracts the disagreements that are candidate value spots. Cross-references: model math in [Chapter 4](04-prediction-models.md), draw/odds landscape in [Chapter 5](05-wc2026-landscape.md).*

**Sourcing caveat:** natesilver.net (Substack) and several aggregators block automated retrieval; Silver Bulletin numbers below were reconstructed from the public/free portion of the post, Silver's X/Substack Notes commentary, and third-party coverage (RealClearMarkets, Oliver's Sportstack, syndicated summaries). Where a number could not be confirmed from two independent surfaces it is flagged.

---

## 1. Nate Silver / Silver Bulletin: the PELE forecast (the user-requested core)

### 1.1 What he published and when

FiveThirtyEight is dead (ABC shut it in March 2025); Silver now publishes at **Silver Bulletin** (https://www.natesilver.net). His World Cup stack landed in three steps:

- **Mid-May 2026 — PELE launch**: "PELE", his new international soccer rating system, billed as "kind of insanely detailed" ([launch note](https://substack.com/@natesilver/note/c-255803577), [X](https://x.com/NateSilver538/status/2052780056171208764)). Initial rankings: **Argentina #1, just edging Spain**; USA "much further down the list."
- **Late May — ratings tweaks**: "Spain is a reasonably clear #1 now with ARG/ENG/FRA basically tied for second" ([X](https://x.com/NateSilver538/status/2056163259019837473), [Substack note](https://substack.com/@natesilver/note/c-259718366)). Separately: "The USA is up to #28 … considerably lower than where FIFA has them (#16). However, home-field advantage is quite large in international soccer and should help USA/CAN/MEX" ([X](https://x.com/NateSilver538/status/2061505754511949879)).
- **June 8–9 — full tournament forecast**: "**2026 World Cup Predictions**" (https://www.natesilver.net/p/world-cup-2026-odds-predictions), with a continuously updating games/landing page and a path-analysis companion ("[What's your team's path to the World Cup title?](https://www.natesilver.net/p/whats-your-teams-path-to-the-world)" — conditional odds by group finish for the top 30 teams). Launch note: "100,000 simulations of every stage of the tournament… projections will be updated regularly" ([Substack note](https://substack.com/@natesilver/note/c-270015271), [X](https://x.com/NateSilver538/status/2062223326244946305)).

**Paywall structure:** the headline analysis and market framing are free; the **full interactive detail (all-team tables, match-level odds, full PELE ratings suite) is paid**, with the first four groups shown as a free preview. Forecast updates promised for "every match result, tiebreaker scenario, and even every injury" (syndicated summaries: [Mogaz](https://www.mogazmasr.com/121304), [El-Balad](https://www.el-balad.com/17017127)).

### 1.2 PELE methodology — SPI's successor, but market-value-aware

From the methodology post (https://www.natesilver.net/p/pele-methodology) and the rankings page (https://www.natesilver.net/p/pele-international-football-rankings-soccer-ratings-projections):

- **PELE = "Predictive Elo with Lineup Equilibria."** Successor to the SPI he built at ESPN (2009) and ran at 538 through 2022.
- **Inputs:** ~50,000 historical international results spanning 150+ years of football, blended with **Transfermarkt player market values** (explicitly intended to align the system more closely with betting odds) and **roster age weighted by player market value**.
- **Structural change vs SPI:** SPI carried separate offense/defense ratings; Silver now argues that split suits American football, not soccer. PELE uses **one overall rating + a "Tilt" parameter** (attacking vs defensive lean) that generates implicit off/def ratings and feeds goal distributions.
- **Home advantage is the headline innovation for 2026:** a customized per-team factor built from **travel distance, altitude, and each team's long-run home performance** — i.e., PELE explicitly models the Azteca altitude effect, and rates **Mexico's HFA among the largest in the world** ("the U.S., Canada and especially Mexico have above-average home-field advantages").
- **Format handling:** the 100k sims model the full 48-team format including **meticulous tiebreakers and the 8-best-of-12 third-place mapping** — Silver flags that "32 of 48 advancing makes for a forgiving format," which is exactly why a hard group costs less than it used to (but still costs through R32 seeding).

### 1.3 The numbers (what's publicly confirmable, June 9)

| Team | PELE / Silver Bulletin | Context from the post |
|---|---|---|
| **Spain** | **18.5%** | Top-rated team, "though injuries knock them down a peg" — model assumes Lamine Yamal limited for MD1, back for MD2 |
| **France** | **11.7%** | Rated ~3rd overall but "docked… well under the market's ~17%, largely for the brutal group" — Group I with Norway and Senegal, "under the old format… a proverbial Group of Death" |
| **England** | **10.4%** | ENG/FRA essentially tied ~#3 in ratings; England's Group L is soft |
| **USA** | **~1%** (16th most likely) | "Considerably higher than they'd be in a tournament played elsewhere"; all group games at home, guaranteed home R32, hosts everything from QF onward |
| Argentina, Brazil, Portugal, Germany etc. | *not publicly itemized* | Full table is in the paid interactive; ARG was ~tied-2nd in ratings pre-tournament |

Sources for the figures: free portion of [the forecast post](https://www.natesilver.net/p/world-cup-2026-odds-predictions) as indexed/quoted, and [RealClearMarkets' June 5 comparison](https://www.realclearmarkets.com/articles/2026/06/05/handicapping_gold_versus_silver_in_the_world_cup_1186836.html) ("PELE blends ratings with squad market value and a 'tilt' parameter, pulling Spain back to 18.5 percent — basically the market"; "PELE rates France around third but docks it to 11.7"). **Flag:** Argentina/Brazil/Portugal/Germany PELE win-probabilities were not retrievable from any free surface as of compile time — capture them once a subscriber screenshot or press write-up circulates.

### 1.4 Silver's qualitative takes

- **Parity:** "an especially large amount of parity" — markets have France/Spain as ~16–17% co-favorites with lots of probability spread across ARG/ENG/BRA/POR. No super-team.
- **Hosts:** PELE "isn't especially bullish on North American soccer" (USA #28 vs FIFA's #16), but the hosts are "relatively tough outs at home"; the HFA boost is the only reason USA reaches ~1%/16th. All three hosts "a tier or two below elite status according to nearly everyone's estimation."
- **Dark-horse mechanics:** the sims include "the possibility of a dark-horse contender getting hot and unexpectedly being in top form"; **Norway and Senegal get an explicit PELE boost from highly-valued players (Haaland, Mané)** — which is what depresses France.
- **Draw asymmetry matters even in the forgiving format:** France's 11.7% vs market ~16–17% is almost entirely a draw-difficulty and R32-path effect, not a ratings disagreement.
- **Betting:** no public "I'm betting X" call found in free content as of June 9 — his framing is explicitly *versus prediction markets* (he quotes market co-favorites at ~16–17% as the benchmark). His Spain number (18.5%) sits slightly *above* market, France well below.
- Related free essay: "[Why isn't the U.S. better at soccer?](https://www.natesilver.net/p/why-isnt-the-us-better-at-soccer)" (structural take on the US program).

### 1.5 The FiveThirtyEight data archive (usable historical SPI)

The old 538 SPI data remains on GitHub — useful as a third-opinion historical prior and for backtesting calibration code (already flagged in Chapter 4):

- Repo dir: https://github.com/fivethirtyeight/data/tree/master/soccer-spi — README confirms files `spi_matches.csv`, `spi_matches_latest.csv`, `spi_matches_intl.csv`, `spi_global_rankings.csv`, `spi_global_rankings_intl.csv`, with documented schemas (SPI ratings, win/draw/loss probs, proj scores, importance, xG, nsxG, adj scores). The CSVs themselves were served from `https://projects.fivethirtyeight.com/soccer-api/club/...` and `.../international/...` (e.g., `https://projects.fivethirtyeight.com/soccer-api/international/spi_global_rankings_intl.csv`) — **live status of those endpoints unverified from this sandbox (allowlist-blocked); data frozen ~2023 either way. Kaggle mirrors exist.**
- WC-specific archives: https://github.com/fivethirtyeight/data/tree/master/world-cup-2018 — README links `wc_matches.csv` and `wc_forecasts.csv` at `https://projects.fivethirtyeight.com/soccer-api/international/2018/...` (timestamped tournament forecasts — gold for calibration studies). A 2022 equivalent lived at `.../international/2022/wc_forecasts.csv` (same caveat).

---

## 2. The rest of the 2026 quant field

### 2.1 Opta supercomputer (Stats Perform)

- **Headline (verified, ~25,000 pre-tournament sims):** **Spain 16.1%, France 13.0%, England 11.2%, Argentina 10.4%, Portugal 7.0%, Brazil 6.6%, Germany 5.1%, Netherlands 3.6%**; ~**35.9% chance of a first-time winner** ([Opta Analyst winner article](https://theanalyst.com/articles/who-will-win-2026-fifa-world-cup-predictions-opta-supercomputer), [group-by-group hub](https://theanalyst.com/articles/fifa-world-cup-2026-groups-predictions-previews)). An earlier May run (via [beIN](https://www.beinsports.com/en-us/soccer/fifa-world-cup-2026/articles/the-10-biggest-favorites-to-win-the-2026-fifa-world-cup-according-to-opta-s-ai-2026-05-13)) had Spain 16.08 / France 12.78 / England 11.01 / Brazil 6.48 / Germany 5.66 / Netherlands 3.84 / Belgium 2.34 — Opta re-runs and the order is stable; some June press cites a 10,000-sim version ([SportBible June 1](https://www.sportbible.com/football/football-news/fifa-world-cup/opta-supercomputer-simulates-world-cup-10-000-times-949560-20260601)).
- **Depth numbers:** Spain 52.1% QF (only team >50%), 39% SF, 25.6% final; Norway ~3.5%, Colombia ~2.1% title (secondary write-ups — treat decimals as soft). Hosts rated cold: **USA ~1.2–1.33% (16th–18th), Mexico ~1.0% (20th), Canada ~0.5% (24th)**; USA 32.83% to win Group D (Türkiye 29.04, Paraguay 20.51, Australia 17.62), ~8% semifinal ([NY Sports Day June 9](https://www.nysportsday.com/2026/06/09/opta-supercomputer-usa-world-cup-2026-predictions/), [Oliver's Sportstack](https://oliverssports.substack.com/p/why-do-the-world-cup-forecasts-disagree)).
- **Method:** attack/defense strength ratings calibrated on historical internationals + betting-market input, full-format simulation. **No evidence Opta applies host/altitude adjustments beyond generic ratings — its host numbers are the lowest of any model.**

### 2.2 Academic: Zeileis/Groll et al. (Innsbruck × TU Dortmund × KU Leuven × Molde)

The long-running bookmaker-consensus + ML collaboration published its 2026 forecast in early June ([Innsbruck release via phys.org](https://phys.org/news/2026-06-world-cup-spain-title-wide.html), [uibk newsroom](https://www.uibk.ac.at/en/newsroom/2026/2026-world-cup-spain-in-the-lead/), [R-bloggers](https://www.r-bloggers.com/2026/06/football-meets-machine-learning-forecasting-the-2026-fifa-world-cup/), [zeileis.org/news/fifa2026](https://www.zeileis.org/news/fifa2026/), authors' own piece at [The Conversation](https://theconversation.com/we-ran-100-000-computer-simulations-of-the-world-cup-and-the-winner-will-be-284629)):

- **Numbers (100,000 sims):** **Spain 14.5%, England 12.4%, France 12.4%, Germany 11.2%, Portugal 8.9%, Argentina 8.2%, Netherlands 5.6%, Brazil 4.7%.** USA 78% to reach R32. Zeileis: "this year's title race is very tight"; Groll: top favorite usually ≤20%, "some other team wins with a probability of 80%."
- **Method:** hybrid random forest combining (1) ability estimates from exponentially-downweighted historical results, (2) **bookmaker consensus from 24 international books** (margin-stripped, logit-averaged — the Leitner/Zeileis/Hornik lineage), (3) covariates: player ratings from club/international play, **average squad market value**, plus the usual socio-economic regressors; trained on major tournaments since WC2006; full draw + FIFA rules simulated. Team: Groll, Rouven Michels, Hvattum, Schauberger (+ Zeileis consensus input).
- **The tell:** **Germany at 11.2% is wildly above every other source (market ~5%)** — a recurring signature of this group's models (see §4.4).

### 2.3 Goldman Sachs (the bank model is back)

- **Numbers (late May, 50,000 Monte Carlo runs):** **Spain 26% (25.7), France 19%, Argentina 14%, Brazil 8%, England 5%, Netherlands 5%** ([Bloomberg](https://www.bloomberg.com/news/articles/2026-05-29/goldman-s-model-shows-spain-as-26-probable-world-cup-winner), [CNN](https://www.cnn.com/2026/06/01/business/betting-world-cup-goldman-sachs-prediction-markets), [Spain in English](https://www.spainenglish.com/2026/06/01/goldman-sachs-model-tips-spain-to-win-2026-world-cup-ahead-of-france-and-argentina/), team list via [The Idea Farm/X](https://x.com/TheIdeaFarm/status/2062164322260840742); full note PDF mirrored at [poder360](https://static.poder360.com.br/2026/05/The-World-Cup-and-Economics_-World-Cup-2026_-Predictions-Probabilities-and-Paths-to-Victory.pdf)).
- **Method:** **Elo-anchored Poisson goal model** (Spain's Elo edge — ~50 pts over Argentina, ~85+ over France — drives the 26%) with add-ons: attacking "top-scorer talent" effect, recent form/momentum, **"mentality"** (tournament over/under-performance vs Elo — England get explicitly docked as systematic underperformers), **geography (travel, heat, altitude)**, and a **"winner's slump"** penalty on defending champs (dampens Argentina). Updated daily during the tournament.
- **Self-reported backtest:** correlation of predicted vs actual goal difference **49% across all WC matches since 1978; 43% in 2018; 45% in 2022**.
- **Market deltas are the largest of any source:** Spain +10 pts over market; **England 5% = less than half of market** ([RealClearMarkets](https://www.realclearmarkets.com/articles/2026/06/05/handicapping_gold_versus_silver_in_the_world_cup_1186836.html) calls England the single biggest disagreement).

### 2.4 Klement (the novelty with the 3/3 record)

Joachim Klement (Panmure Liberum strategist) — correctly named **Germany 2014, France 2018, Argentina 2022** with a model on FIFA ranking, population, GDP and similar covariates — picks **Netherlands over Portugal in the 2026 final**, while himself calling the exercise "completely irrational… like playing the lottery" ([ESPN](https://www.espn.com/soccer/story/_/id/48964113/mathematician-correctly-predicted-three-world-cup-winners-row-named-2026-pick), [his Substack](https://klementoninvesting.substack.com/p/fifa-world-cup-predictions-2026), [beIN](https://www.beinsports.com/en-us/soccer/fifa-world-cup-2026/articles/the-german-mathematician-who-predicted-the-last-three-world-cup-champions-germany-france-and-argentina-2026-06-03)). Treat as entertainment with a survivorship halo — but note Netherlands is also Goldman/consensus' quiet overweight vs Opta.

### 2.5 Pure-Elo and community models

- **Elo-only simulation** (eloratings.net snapshot, early June): **Spain 29.6%, Argentina 18.5%; most likely final Argentina–Spain (10.3%)** ([2026worldcupsim.com](https://www.2026worldcupsim.com/blog/world-cup-2026-predictions-quarter-finals-semis-champion)). Current Elo top-7 (June 8): **Spain 2155, Argentina 2114, France 2062, England 2021, Brazil 1991, Portugal 1986, Colombia 1982** ([eloratings.net](https://www.eloratings.net/), [WC page](https://www.eloratings.net/2026_World_Cup)). Pure results-based ratings love Spain *and Argentina* far more than the market does.
- **Transparent Elo+Poisson community build:** favorite ~15%, "remarkably close to the elaborate models" ([Towards Data Science](https://towardsdatascience.com/who-will-win-the-2026-soccer-world-cup/)). Open-source attempts: [dev.to open model](https://dev.to/jerry_chen_dbaa6838e17336/i-open-sourced-a-world-cup-2026-prediction-model-and-tested-it-honestly-44d1).
- **Kaggle:** "[World Cup Mania — AI Prediction Challenge](https://www.kaggle.com/competitions/wc2026-ai-prediction)" (beat Dixon–Coles and the prediction markets), plus baseline datasets ([Elo-based match probabilities](https://www.kaggle.com/datasets/sarazahran1/wc2026-match-probability-baseline-dataset), [prediction-system dataset](https://www.kaggle.com/datasets/rauffauzanrambe/fifa-world-cup-2026-prediction-system)).
- **Aggregators:** Neil Paine (ex-538) runs a normalized **Polymarket-derived odds tracker** ([neilpaine.substack.com](https://neilpaine.substack.com/p/2026-world-cup-odds-tracker)); LLM-ensemble novelty: 7 AI models polled — Spain 4 votes, Argentina 3 ([DigitalToday](https://www.digitaltoday.co.kr/en/view/61861/ai-models-split-on-2026-world-cup-winner-spain-4-votes-argentina-3)).

### 2.6 The market itself (June 9 snapshot)

- **Polymarket** (June 9, [The Defiant](https://thedefiant.io/news/defi/polymarket-world-cup-winner-markets-1-8b-volume-france-spain)): **France 16.2%, Spain 16.0%, Portugal 11.3%, England 10.9%, Argentina 8.8%, Brazil 8.3%**. France traded >18% before the **2-1 friendly loss to Côte d'Ivoire (June 4)**. Two weeks out it was Spain 17 / France 16 / England 11 / Portugal 10 / Brazil 9 / Argentina 8 / Germany 5 / Netherlands 4 / Norway 3 ([Polymarket Sports/X](https://x.com/PolymarketSport/status/2060037003681452225)).
- **Volume:** winner contract ~$1.6B by June 5 ([KuCoin flash](https://www.kucoin.com/news/flash/as-of-june-5-2026-polymarket-s-world-cup-winner-contract-hits-1-6-billion-in-trading-volume)); **>$2B across Kalshi+Polymarket pre-kickoff** ([Yahoo Finance](https://finance.yahoo.com/markets/options/articles/world-cup-betting-kalshi-polymarket-133600704.html)); Kalshi and Polymarket both ~8.9% on Argentina ([oddschecker](https://www.oddschecker.com/us/insight/soccer/20260609-kalshi-vs-polymarket-where-to-trade-on-the-2026-world-cup)). Live trackers: [defirate VWAP tracker](https://defirate.com/prediction-markets/world-cup-odds/), [Polymarket event](https://polymarket.com/event/world-cup-winner). Books (Ch. 5): Spain/France +450–500, England +650–700, Brazil/Argentina/Portugal +850–1000.
- Note the **Polymarket-vs-books split on Portugal/England**: crypto markets have Portugal (11.3%) *above* England (10.9%); sportsbook boards have England clearly shorter. Retail Ronaldo flow on the exchanges is the likely culprit ([oddschecker](https://www.oddschecker.com/us/insight/soccer/20260609-kalshi-vs-polymarket-where-to-trade-on-the-2026-world-cup)).

---

## 3. Master comparison table (tournament win %, pre-tournament, early June 2026)

| Team | Market (Polymarket 6/9) | Silver/PELE | Opta | Zeileis–Groll hybrid | Goldman | Pure Elo sim | Notes |
|---|---|---|---|---|---|---|---|
| Spain | 16.0 | **18.5** | 16.1 | 14.5 | **26** | **29.6** | Every model ≥ market; results-heavy models extreme |
| France | 16.2 | **11.7** | 13.0 | 12.4 | 19 | – | Only Goldman above market; PELE far below (Group I) |
| England | 10.9 (books ~12–13) | 10.4 | 11.2 | 12.4 | **5** | – | Goldman's mentality dock is the outlier |
| Argentina | 8.8 | n/p | 10.4 | 8.2 | **14** | **18.5** | Results-based ≫ market; value-based ≈ market |
| Portugal | **11.3** | n/p | 7.0 | 8.9 | – | – | Market ≫ all models |
| Brazil | 8.3 | n/p | 6.6 | **4.7** | 8 | – | Models ≤ market |
| Germany | ~5 | n/p | 5.1 | **11.2** | – | – | Academic model 2x market (recurring bias) |
| Netherlands | ~4 | n/p | 3.6 | 5.6 | 5 | – | Klement's outright pick |
| Norway | ~3 | boosted | ~3.5 | – | – | – | PELE/market value models like them |
| USA | ~1–1.6 (+6000 books) | ~1.0 (16th) | 1.2–1.33 | – | – | – | All models: host bump real but small |
| Mexico | ~1 (+6500) | n/p (big HFA) | ~1.0 | – | – | – | PELE: largest HFA in field |

*n/p = not public (paywalled). Sources as cited in §1–2.*

**Where everyone agrees:** Spain is the best team (every model #1 or co-#1); the top is historically flat (only Goldman/pure-Elo put anyone over 20%); hosts are quarterfinal-ceiling teams, not contenders; Opta's 35.9% first-time-winner number says the field is deep.

---

## 4. What the models agree and disagree on (mechanism level)

### 4.1 Host bump and altitude/heat
- **PELE:** the most explicit treatment — per-team customized HFA from travel distance, **altitude**, and long-run home results; Mexico's HFA "among the largest in the world." ([pele-methodology](https://www.natesilver.net/p/pele-methodology))
- **Goldman:** "geography" factor — travel, heat and **altitude penalties** (part of the England dock per [RealClearMarkets](https://www.realclearmarkets.com/articles/2026/06/05/handicapping_gold_versus_silver_in_the_world_cup_1186836.html)).
- **Opta:** no visible special host/altitude machinery; produces the **lowest host numbers** (USA 1.2%, MEX 1.0%, CAN 0.5%) ([Oliver's Sportstack](https://oliverssports.substack.com/p/why-do-the-world-cup-forecasts-disagree)).
- **Academic hybrid:** no published altitude/host adjustment beyond covariates; bookmaker-consensus input *implicitly* imports whatever the market prices for hosts.
- Implication: **host-team group/stage props are where PELE-style models and Opta diverge most in relative terms** — consistent with Ch.5's Azteca/altitude angles.

### 4.2 48-team format and third-place mapping
All four serious simulators (PELE, Opta, Goldman, Zeileis–Groll) run the full bracket with FIFA tiebreakers and the 8-of-12 third-place advancement. Silver is the most vocal about the *strategic* consequence: a 32-of-48 cut is forgiving, so group difficulty mostly transmits through **knockout-path quality, not elimination risk** — his France discount is a path effect. The Conversation/Groll piece similarly leans on path math (USA 78% to R32).

### 4.3 Squad-value vs results-based — the Argentina/Spain axis
The cleanest split in the table: **pure-results models (Elo, Goldman's Elo-anchor) rate Argentina 14–18.5%; market-value-aware models (PELE, Opta, hybrid) and the market itself sit at 8–10.4%.** Argentina's Elo is #2 (2114) on trophies and results, but its squad value (~€821m, mid-pack among contenders, Messi 39 in week 2) drags value-based ratings. Identical mechanism, opposite sign, for **Norway/Senegal** (huge per-player values, thin results history → PELE/market-value models boost them; Elo is cooler). Spain is the only team every methodology loves.

### 4.4 Known model biases to exploit
- The **German academic models have over-rated Germany at every recent edition** (2022 hybrid: Germany 9.2% → group exit; 2026: 11.2% vs ~5% market). Fade their Germany signal, keep their machinery.
- **Goldman historically over-concentrates on the Elo favorite** (2014: Brazil ~48.5%, widely cited; 2018: Brazil favorite ~18.5%) and its own backtest is a 43–49% GD correlation — informative, not oracular.
- **Opta skews to ratings-stable favorites and has no host/altitude sense** — its Mexico/USA group-stage numbers are arguably too low against PELE's HFA evidence.
- **Prediction markets carry longshot bias and narrative flow** (Portugal 11.3% on Polymarket vs 7.0–8.9% in models is the clearest case; France's 2-point drop on one friendly loss to Côte d'Ivoire is classic over-reaction — [The Defiant](https://thedefiant.io/news/defi/polymarket-world-cup-winner-markets-1-8b-volume-france-spain), [KuCoin explainer](https://www.kucoin.com/news/flash/how-2026-world-cup-win-probabilities-are-calculated-market-prices-vs-supercomputing-models)).

---

## 5. Historical accuracy: how these forecasters have actually done

**Silver/538 lineage:**
- **2010 (ESPN SPI debut):** built with ESPN; no clean public archive of pre-tournament table found from this sandbox — not scored here.
- **2014 (ESPN SPI):** **Brazil 45%**, Argentina 13%, Germany 11%, Spain 8% ("[It's Brazil's World Cup to Lose](https://fivethirtyeight.com/features/its-brazils-world-cup-to-lose/)") — the famous 7–1 falsification of a heavy home-bump assumption; contemporaneous criticism: [The New Republic](https://newrepublic.com/article/118192/2014-world-cup-down-nate-silver-and-big-data-predictions). Lesson Silver carried into PELE: home advantage now estimated per-team from data, not asserted.
- **2018 (538 SPI):** Brazil favorite (~19%); eventual winner France mid-pack single digits (methodology: [how-our-2018-world-cup-predictions-work](https://fivethirtyeight.com/features/how-our-2018-world-cup-predictions-work/); exact pre-tournament table lives in the GitHub `wc_forecasts.csv` — **percentages here from memory, unverified this session**).
- **2022 (538 SPI):** **Brazil clear favorite, champions Argentina ~8% (4th)** pre-tournament ([538 launch piece](https://fivethirtyeight.com/features/brazil-is-the-favorite-and-messi-is-the-star-but-the-2022-world-cup-is-up-for-grabs/); Argentina ~8% figure via [KuCoin retrospective](https://www.kucoin.com/news/flash/how-2026-world-cup-win-probabilities-are-calculated-market-prices-vs-supercomputing-models)). Same source reports backtested SPI Brier ≈0.58 on 2018+2022 match 1X2 — "bookmaker-grade," not market-beating; no peer-reviewed market-vs-538 Brier comparison exists.
- Net read: **SPI-family models are well-calibrated at match level but have never beaten closing prices**, and their tournament "favorites" missed in 2014/2018/2022 — as did everyone's.

**Opta:** Euro 2024 pre-tournament: **England 19.9% favorite, France 19.1%; winner Spain was 4th at 9.6%** — though England did reach the final (31% pre-event) ([City AM supercomputer review](https://www.cityam.com/battle-of-the-supercomputers-whose-algorithm-was-best-at-predicting-euro-2024/)). WC2022: favored Brazil; champions Argentina were single-digit pre-tournament (secondary retrospectives — exact figure unverified). Solid match-level engine, no demonstrated edge on outrights.

**Zeileis bookmaker consensus (and hybrids):** correctly made **Spain the 2010 favorite (won)** and Spain again for Euro 2012 (won); Euro 2008 missed the winner but nailed the final; **2014: Brazil favorite (3/4 semifinalists right)**; **2018: Brazil 16.6% > Spain 12.5% > France 12.1% (winner 3rd)** ([fifa2018 forecast](https://www.zeileis.org/news/fifa2018/), [evaluation](https://www.zeileis.org/news/fifa2018eval/)); **2022 hybrid: Brazil 15.0%, Argentina 11.2% (2nd — winner), Netherlands 9.7%, Germany 9.2%** ([fifa2022 multiverse](https://www.zeileis.org/news/fifa2022/)). Honest, well-documented, self-evaluating — and structurally close to market by construction (it ingests 24 books).

**Banks:** Goldman 2014 Brazil ~48.5%; **UBS 2018 picked Germany** (group-stage exit; [UBS release](https://www.ubs.com/global/en/media/display-page-ndp/en-20180517-ubs-calculations-show.html)); UBS has no 2026 winner model found — banks now mostly do WC stock baskets ([CNBC](https://www.cnbc.com/2026/06/04/world-cup-2026-stocks-deutsche-bank.html)). **Klement: 3 straight winners** (2014/2018/2022) — small sample, zero theory.

**Meta-pattern for bettors:** in 2014, 2018 and 2022 the model/market favorite lost and the **winner came from the 8–14% pre-tournament band** (France '18, Argentina '22). Models that load extra mass on one favorite (Goldman 26%, pure-Elo 29.6%) have been systematically overconfident; flat-top forecasts (Opta, hybrid, PELE, market) have been right about the *shape* of the distribution.

---

## Key takeaways for the betting playbook

1. **Spain is the consensus #1 across all six methodologies (14.5–29.6%) vs market 16%** — the only team where models are unanimously at-or-above market. If you want a favorite, Spain at ~+450–500 is the "model-approved" one; but remember no modeled favorite has won since 2010.
2. **France is the most model-faded favorite: PELE 11.7% vs market 16.2%** — Silver's discount is draw-path-driven (Norway/Senegal in Group I), not quality-driven. Laying/under-weighting France outright, or betting *against* France group-winner pricing, is the cleanest Silver-vs-market trade. Goldman (19%) is the lone counter.
3. **Portugal is the most market-overpriced team: Polymarket 11.3% vs Opta 7.0% / hybrid 8.9%** — Ronaldo narrative flow on exchanges; also priced *above* England on Polymarket but below on books. Fade Portugal on exchanges; if you must be long, books are the cheaper venue.
4. **Argentina is the methodology fault line: Elo-family 14–18.5% vs market 8.8% vs value-models ~8–10%.** If you believe tournament results/mentality persist (Elo view), Argentina +900/8.8% is the value long among the big names; if you believe squad value (PELE/Opta), it's fairly priced. Ch.5's bracket warning (Miami-heat R32 vs likely Uruguay) argues for the value-model view.
5. **Fade the academic model's Germany (11.2% vs ~5% market)** — same group's model had Germany 9.2% in 2022 (group exit). Persistent national bias; do not treat it as alpha.
6. **Ignore Goldman's England 5% as a price signal but mine its inputs** — the "mentality dock + heat/altitude geography" reasoning is directionally useful for England *totals/paths*, not for halving England's outright price. Conversely Goldman Spain 26% is the upper bound of respectable opinion, not a target price.
7. **Hosts: models say the market's host longshots are roughly fair, not value** — USA ~1–1.3% across PELE/Opta vs +6000 (1.6% raw, ~1.2–1.3% devigged). The *real* host edge is match-level: PELE's per-team HFA (travel+altitude) says Mexico at Azteca and USA group games are systematically underrated by altitude-blind models like Opta — target derivative markets (group winner, advancement, match handicaps), not outrights.
8. **Norway is the model-vs-Elo special:** PELE boosts Haaland-value, Opta has them top-9 (~3.5%) vs 25/1–35/1 books — consistent with Ch.5's Norway-as-value-longshot call. The PELE mechanism (market value ≫ results history) is exactly the profile that wins "dark horse hot streak" sims.
9. **Use the flat top as a structural fact: best team ≈15–18%, so ~82–85% of the probability is "someone else."** Eight teams ≥3.5% in every flat model. This favors (a) longshot portfolios over single-favorite tickets, (b) reach-SF/final markets where second-tier teams' path value concentrates (Opta: Spain only team >50% to QF).
10. **Watch the venue-specific disagreements as live in-tournament trades:** Silver's page updates per match/injury (Yamal MD1 assumption already priced); Opta re-runs and Goldman updates daily. When PELE moves on an injury before exchange prices do (Substack publishes faster than retail reprices Polymarket longshots), that's the latency edge.
11. **The winner has come from the 8–14% band three straight cups** — today that band is England, Portugal, Argentina, Brazil (+Germany in one model). Structure outright exposure there rather than on the 16% co-favorites.
12. **Market microstructure check (from §2.6):** Polymarket vs books disagree by 1–2 pts on England/Portugal/France right now; with >$2B matched, exchanges are liquid enough to arb against book boards where state access allows (cf. Ch.3 mechanics).
13. **Data ops:** archive Silver's free posts + X chart screenshots daily (paywall may tighten); the 538 GitHub CSVs (`soccer-spi/`, `world-cup-2018/`) are the only clean historical forecast sets for calibrating our own model against; live `projects.fivethirtyeight.com` endpoints unverified — use GitHub/Kaggle mirrors.
14. **Calibration humility: every "supercomputer" is ~bookmaker-grade (SPI Brier ≈0.58; Goldman GD correlation 43–49%)** — the edge isn't any single model, it's the *disagreement structure* between models and the market, plus speed on news. That's items 2, 3, 4, 5, 8.

---

*Compiled June 9, 2026. Primary unverified items flagged inline: Silver's ARG/BRA/POR/GER outright numbers (paywalled), 538's exact 2018 pre-tournament table (use GitHub CSV), Opta's exact 2022 Argentina figure, sub-1% Opta decimals from secondary aggregators.*

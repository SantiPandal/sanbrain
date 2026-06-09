---
type: research
project: worldcup-2026-betting
chapter: 4
title: Prediction Models and Data — Building the Match Prediction Engine
date: 2026-06-09
status: compiled
---

# Prediction Models and Data: Building the World Cup 2026 Match Prediction Engine

*Chapter 4 of the WC2026 quantitative betting dossier. Status: T-minus 2 days to kickoff (opener June 11, Estadio Azteca; final July 19, MetLife). 48 teams, 12 groups, 104 matches, Round of 32 with 8 best third-placed teams.*

---

## 1. Model families: the math you actually need

### 1.1 Independent Poisson (Maher 1982)

The foundation of all football pricing. Goals scored by team *i* against team *j* are Poisson with multiplicative attack/defense structure:

```
X_ij ~ Poisson(λ_ij),   λ_ij = α_i · β_j · γ      (home goals)
Y_ij ~ Poisson(μ_ij),   μ_ij = α_j · β_i          (away goals)
```

where α = attack strength, β = defense weakness, γ = home advantage, fit by maximum likelihood with an identifiability constraint (e.g., Σ log α_i = 0). Maher's "Modelling association football scores" (Statistica Neerlandica, 1982) showed this fits scorelines remarkably well. Known defects: it slightly underpredicts draws and low-scoring outcomes, and assumes home/away goals are independent (empirical correlation is mildly negative-to-positive depending on dataset).

### 1.2 Dixon–Coles (1997): the workhorse

Dixon & Coles ("Modelling association football scores and inefficiencies in the football betting market," JRSS-C 1997) made two fixes that still define the practitioner standard:

**(a) Low-score dependency adjustment.** Multiply the joint probability by τ(x, y):

```
τ(0,0) = 1 − λμρ     τ(0,1) = 1 + λρ
τ(1,0) = 1 + μρ      τ(1,1) = 1 − ρ
```

with ρ typically fit at **−0.03 to −0.13**: this inflates 0-0 and 1-1 and deflates 1-0/0-1, fixing the draw underprediction exactly where it occurs.

**(b) Exponential time decay.** Weight match *t* days old by `φ(t) = exp(−ξt)` in the pseudo-likelihood, and choose ξ by maximizing *out-of-sample predictive* likelihood (not in-sample fit). Club implementations land around ξ ≈ 0.0018–0.0065 in day units (half-life roughly 4–13 months); for international football you want a much longer half-life (Section 3). Reference implementation and tuning discussion: https://pena.lt/y/ (penaltyblog) and https://opisthokonta.net/?cat=29.

### 1.3 Bivariate Poisson (Karlis & Ntzoufras 2003)

"Analysis of sports data by using bivariate Poisson models" (JRSS-D 2003): X = W₁ + W₃, Y = W₂ + W₃ with independent Poissons W_k, so the shared component λ₃ induces Cov(X,Y) > 0 (game-state effects: open games get open at both ends). A diagonal-inflated variant handles draws. In head-to-head tests it buys a small likelihood gain over Dixon–Coles; most shops conclude the added complexity is not where the alpha is. The zero-inflated generalized Poisson extension was used for academic Euro 2020 forecasts (https://arxiv.org/pdf/2106.05174).

### 1.4 Elo → win probability → goal expectancy

The reference international rating is **World Football Elo Ratings** (https://www.eloratings.net, methodology at https://en.wikipedia.org/wiki/World_Football_Elo_Ratings):

```
R_new = R_old + K · G · (W − W_e),    W_e = 1 / (10^(−dr/400) + 1)
```

- dr = rating difference **including +100 for home advantage** (mostly moot at a neutral-venue WC, except de facto hosts: Mexico in Group A, Canada in B, USA in D).
- K by importance: **60** World Cup finals, **50** continental finals/major intercontinental, **40** WC and continental qualifiers, **30** other tournaments, **20** friendlies.
- G = margin multiplier: 1.5 for a 2-goal win, 1.75 for 3, `1.75 + (N−3)/8` for N ≥ 4.

W_e is "win expectancy with draw = ½" — it is **not** a 1X2 price. Two standard conversions:

1. **Nested Poisson regression** (the Groll/Zeileis school, e.g., the AFCON 2019 forecast, https://arxiv.org/pdf/1905.03628): regress goals on opponent rating, `log μ_A = α₀ + α₁·Elo_opp` (plus own rating), fit on a few thousand internationals; this gives you λ and μ directly from ratings, and the score matrix gives all prices.
2. **Supremacy mapping**: regress observed goal supremacy (and total) on Elo difference; on international data the relationship is near-linear over the central range (roughly half a goal of supremacy per ~100 Elo points, steeper in blowout territory — fit it yourself rather than trusting a constant), then split supremacy/total into (λ, μ).

### 1.5 Ordered logit/probit on goal difference

Model the latent result variable directly: `P(home win) = 1 − Φ(c₂ − xβ)`, `P(draw) = Φ(c₂ − xβ) − Φ(c₁ − xβ)` with covariates x (rating difference, etc.). Koning (2000) and Goddard (2005, *International Journal of Forecasting*) found goal-based and result-based models perform almost identically for 1X2 — but the ordered model gives you **no score matrix**, so you can't price totals, correct score, or Asian handicaps from it. Use it only as a sanity check or stacking input.

### 1.6 Pi-ratings (Constantinou & Fenton)

Dynamic ratings updated on **score discrepancies** with diminishing returns for blowouts and separate home/away components (Constantinou & Fenton 2013, *J. Quantitative Analysis in Sports*). Cheap, fast-adapting, and — importantly — they were the **feature set inside the model that won the 2017 international Soccer Prediction Challenge**. Implemented in `penaltyblog`.

### 1.7 Modern ML: does gradient boosting beat Dixon–Coles?

The honest answer from the strongest public benchmark: **only marginally, and only with good features**. The 2017 Soccer Prediction Challenge (52 leagues, 200k+ matches, *Machine Learning* journal special issue) was won by Hubáček, Šourek & Železný with **XGBoost on pi-rating-derived features: RPS 0.2063, accuracy 52.4%**; the best classical-ratings-only entry (Berrar ratings) scored RPS 0.2101 (paper: https://link.springer.com/article/10.1007/s10994-018-5704-6; survey: https://arxiv.org/pdf/2403.07669). That ~0.004 RPS gap is real but tiny — and the challenge had no odds features. For internationals specifically, Groll, Ley, Schauberger & Van Eetvelde's **hybrid random forest** (2019) — boosting/bagging over engineered features including Elo, FIFA rank, **Transfermarkt squad value**, age, and bookmaker odds — outperformed each component model at WC 2014/2018; squad market value and odds consistently rank as the strongest features. Conclusion: ML adds value as an **ensembler of ratings + market + structural features**, not as a replacement for the Poisson machinery that turns strength into a score matrix.

### 1.8 The market as anchor (the most important subsection)

Evidence that the market is the best single forecaster:

- Kaunitz, Zhong & Kreiner ("Beating the bookies with their own numbers," https://arxiv.org/abs/1710.02824): **consensus closing odds are an extremely accurate probability estimator**; their profitable strategy didn't out-model the market, it bet outlier prices against the consensus (+3.5% ROI over 56k historical bets) — and got their accounts limited, hence "the market is rigged."
- Wilkens (2026, SAGE, https://journals.sagepub.com/doi/10.1177/22150218261416681): state-of-the-art statistical models vs Bundesliga odds — margins plus small, unstable mispricings leave little persistent outperformance.
- Štrumbelj (2014) showed **Shin-de-margined** implied probabilities beat proportional normalization — use Shin or power method (both in `penaltyblog`) when converting odds to probabilities.
- The academic "bookmaker consensus model" (Leitner, Zeileis & Hornik 2010) simply de-margins and averages many books, then back-solves an Elo-type rating from outright odds — and has been among the best-calibrated public WC forecasts every cycle.

**Practical recommendation:** final price = `w · p_market + (1−w) · p_model` (or blend in log-odds space), with **w ≈ 0.7–0.9** for liquid 1X2/totals markets, sliding toward 0.5–0.7 for thin markets (third-place permutations, exotic correct scores, early Asian-handicap lines on CAF/AFC/OFC teams) where your model has comparative advantage. You bet only when the blended price still clears the de-margined market price by your edge threshold. Your standalone model's job is to find the 5–15% of prices where the market is lazy — not to re-derive Brazil's title odds.

---

## 2. From ratings to prices: the full chain, with a worked example

Pipeline: **ratings → (λ, μ) → score matrix → every market**.

Take λ_home = 1.6, μ_away = 1.1 (a typical "solid favorite" line, e.g., a top-10 seed vs a playoff qualifier). Independent Poisson:

`P(X=i) = e^(−1.6)·1.6^i/i!` → 0: .2019, 1: .3230, 2: .2584, 3: .1378, 4: .0551, 5: .0176, 6: .0047
`P(Y=j) = e^(−1.1)·1.1^j/j!` → 0: .3329, 1: .3662, 2: .2014, 3: .0738, 4: .0203, 5: .0045

Build the matrix M[i,j] = P(X=i)·P(Y=j) (truncate at ~10 goals; mass beyond is negligible). Then:

- **P(draw)** = Σ M[i,i] = .0672 + .1183 + .0520 + .0102 + .0011 + .0001 = **0.249**
- **P(home win)** = Σ_{i>j} M[i,j] = .1075 + .1807 + .1241 + .0537 + .0175 + .0047 + .0013 = **0.490**
- **P(away win)** = 1 − .490 − .249 = **0.262**
- **P(over 2.5)**: total goals ~ Poisson(2.7) under independence, so P(≤2) = e^(−2.7)(1 + 2.7 + 2.7²/2) = .494 → **P(over 2.5) = 0.506**
- **BTTS yes** = (1−.2019)(1−.3329) = **0.532**
- **Modal correct score**: 1-1 at .3230·.3662 = **11.8%** (1-0: 10.8%, 2-1: 9.5%)
- **Asian handicap −0.5** = P(home win) = .490; **−1.0** = win by 2+ plus half-push on win-by-1; **−1.5** = Σ_{i−j≥2} M[i,j] ≈ .283 — all read straight off the matrix.

Fair odds: home 2.04, draw 4.02, away 3.82, over 2.5 at 1.98. Now apply the **Dixon–Coles τ** with ρ ≈ −0.06: 0-0 and 1-1 get inflated ~1–2%, 1-0/0-1 deflated, pushing the draw to ~25.5–26% and shaving the home win to ~48.5% — a 1.5-tick move that is *exactly* the size of typical 1X2 edges, which is why you never skip the adjustment. For knockout matches, the same matrix conditional on i=j feeds the ET/penalties layer (Section 4).

---

## 3. International-football specifics: where club intuition breaks

**Small samples, big turnover.** National teams play ~10–14 matches/year; a four-year cycle spans two squad generations. Fitting Maher attack/defense on national-team data alone is noise-dominated for sub-elite teams. Mitigations: (i) long decay half-life (2–4 years) but **up-weight competitive matches** — mirror the Elo K-ratios (friendly ≈ 0.33–0.5 weight vs qualifier/tournament 1.0); (ii) shrink attack/defense parameters toward an Elo-implied prior; (iii) use hierarchical/Bayesian pooling (penaltyblog's MCMC models) so weak-data teams borrow strength from confederation-level priors.

**Friendlies are doubly suspect:** rotated lineups, unlimited subs, June-camp experimentation. They carry signal about form and new call-ups but their *scorelines* are unreliable — weight results down, weight lineup information up.

**Cross-confederation calibration is the soft underbelly.** Elo only learns relative strength through played matches; UEFA–CONMEBOL links are decent, but CAF/AFC/OFC/CONCACAF connect to the elite mainly via low-K friendlies and one World Cup every four years. Consequences: confederation-level rating drift (intra-confederation play conserves total Elo, so a collectively improving confederation stays underrated for years), and wide genuine uncertainty on, say, Jordan or Cape Verde vs a European mid-tier. The market shows the same uncertainty as wider spreads and slower line discovery — **group-stage cross-confederation matches in the first 10 days are the single richest mispricing zone of the tournament**, both for you and against you. Sanity-check Elo against (a) Transfermarkt squad values, (b) aggregated club quality of the squad (minutes-weighted league strength + FBref/Opta club xG involvement of the player pool), (c) the archived FiveThirtyEight international SPI as a third opinion (https://github.com/fivethirtyeight/data/tree/master/soccer-spi, file `spi_global_rankings_intl.csv` — frozen since 2023, so use for structure, not levels). Do **not** use the official FIFA ranking as a strength input — its SUM formula ignores goal difference and lets teams duck friendlies; it matters only because FIFA uses it for seeding and as the final tiebreaker.

**Tournament-mode effects.** World Cup scoring runs ~2.5–2.7 goals/match (2018: 2.64; 2022: 2.69 including ET), but composition matters: knockout regulation time is materially cagier than the naive Poisson extrapolation of group-stage λs. Clean-sheet rates rise from ~34% (group) to ~44% (knockout), while third-place playoffs — no jeopardy — average ~3.1 goals (trend data: https://www.sportinglife.com/free-bets/news/world-cup-betting-trends-statistics/652, https://www.footballhistory.org/world-cup/statistics.html). Also: teams already qualified or eliminated in matchday-3 dead rubbers rotate heavily — model "incentive states," especially with 8-of-12 third-place qualification making +1 goal difference on MD3 enormously valuable. Practical fix: a knockout multiplier on both λs of roughly 0.85–0.95 (fit on WC/Euro/Copa knockout regulation-time data), and a draw/totals recalibration check — historical tournament draw rates in regulation (~28–30% in knockouts) exceed what group-calibrated Poisson implies.

---

## 4. Tournament simulation: Monte Carlo on the verified 2026 mechanics

**Group tiebreakers (verified — and changed from 2022).** FIFA moved to a head-to-head-first system for 2026 (https://www.nbcsports.com/soccer/news/what-are-the-new-group-stage-tiebreaker-rules-at-the-2026-world-cup, https://www.foxsports.com/stories/soccer/fifa-world-cup-group-stage-third-place-tiebreakers): after **(1) points**, tied teams are split by **(2) head-to-head points among tied teams, (3) head-to-head goal difference, (4) head-to-head goals scored** (re-applied iteratively if a subset remains tied), then **(5) overall group goal difference, (6) overall goals scored, (7) fair-play points** (yellow −1, indirect red −3, direct red −4), **(8) FIFA ranking**. Your simulator must implement the recursive h2h re-application — a naive GD-first sort (the pre-2026 rule) will misallocate qualification probability in tight groups, which propagates straight into "to advance" and outright prices.

**Third-place ranking (verified):** points → goal difference → goals scored → fair-play → FIFA ranking, across all 12 groups; **8 of 12 advance** (https://www.espn.com/soccer/story/_/id/48703925/world-cup-group-stage-explained-tiebreakers-third-place-teams). Simulate fair-play points crudely (cards/match by team aggression) or default to the FIFA-ranking fallback — it binds rarely but not never.

**Bracket mapping:** the R32 slots for group winners/runners-up are fixed in the match schedule; third-place teams slot into designated winner matches via FIFA's lookup covering **C(12,8) = 495 qualification combinations** (schedule and examples — e.g., Group E winner draws a 3rd from {A,B,C,D,F}, Group I winner from {C,D,F,G,H}: https://www.espn.com/soccer/story/_/id/48939282/2026-fifa-world-cup-fixtures-results-match-schedule-group-stage-knockout-rounds-bracket). Hard-code the official annex table; do not improvise the assignment, because path effects (which giant a third-placed team meets) move outright prices by full percentage points.

**Knockouts:** sample regulation score from the (knockout-damped) DC matrix; if level → 30 minutes of extra time with per-minute scoring at roughly regulation per-minute rates × a small haircut (pro-rata λ_ET ≈ λ_90/3 with a ~10% trim is a defensible default); if still level → **shootout ≈ 50/50**. The claimed first-kicker 60/40 advantage (Apesteguia & Palacios-Huerta) failed to replicate on larger samples (Kocher et al.: ~53/47, insignificant); goalkeeper/experience edges are real but worth at most a few points — a coin flip with ±3% tilt is honest. About **20–30% of knockout matches** historically reach ET, so this layer carries real pricing weight for "to qualify" vs 90-minute lines.

**Engine mechanics:** 100k full-tournament simulations is the sweet spot (outright probabilities resolve to ±0.1–0.3% Monte Carlo error; a vectorized NumPy simulator runs this in minutes). Two correlation points that separate amateur from professional futures pricing: (i) **within-simulation consistency** — group outcomes determine knockout opponents, so "France wins WC" probability automatically integrates over France's possible paths; pricing futures by chaining independent match-win probabilities ignores opponent-distribution covariance and is systematically wrong; (ii) **parameter uncertainty** — redraw each team's ratings every simulation from their posterior (or bootstrap) instead of using point estimates; point-estimate sims overconcentrate probability on favorites, which is precisely the direction the public also leans. Store every simulated bracket so you can price *conditional* markets ("England wins | England tops group") and identify correlated exposures across your futures book.

---

## 5. Validation and benchmarks: what "good" looks like

**Metrics.** Three-way ranked probability score (RPS) is the field standard (Constantinou & Fenton); also log-loss and Brier. Benchmarks to beat:

- **2017 Soccer Prediction Challenge** winner (XGBoost + pi-ratings): RPS **0.2063**, 52.4% accuracy across 52 leagues. Pure ratings: ~0.2101. Bookmaker closing odds on comparable club data typically land **RPS ≈ 0.190–0.205** — i.e., the market sits at or beyond the public academic frontier.
- **FiveThirtyEight SPI**: the most transparent public track record; its own evaluations had SPI roughly matching opening odds and trailing closing odds. The model is dead — FiveThirtyEight froze in 2023 and ABC shut the brand in March 2025 — but methodology (https://fivethirtyeight.com/features/how-our-2022-world-cup-predictions-work/) and data live on in the GitHub archive.
- **World Cup 2022 case study**: 538's launch forecast gave **Brazil 22%**, Spain 11%, France 9%, **Argentina 8%** (joint-4th) (https://fivethirtyeight.com/features/brazil-is-the-favorite-and-messi-is-the-star-but-the-2022-world-cup-is-up-for-grabs/); the betting market was similar (Brazil ~4/1, Argentina ~6/1–7/1, i.e., ~13% de-margined). Argentina winning was a ~7:1 shot landing — *one* tournament resolves almost nothing statistically (n=1 of a 32-leaf tree), which is exactly why tournament-winner hit/miss anecdotes are useless and you validate on **hundreds of match-level forecasts** instead: pool WC 2010–2022, Euros, Copa América (~400+ matches) for backtesting.
- **Calibration methodology:** strictly time-ordered backtests (fit through T, predict T+1); reliability curves on binned predictions; compare your RPS/log-loss against (a) de-margined closing odds (Shin method) and (b) a flat Elo baseline. Acceptance test for the blend: the blended forecast should weakly dominate the market alone out-of-sample; if it doesn't at w=0.8, your model is adding noise, not signal.

---

## 6. Data sources: the procurement list

| Source | What | Access / Cost | Notes |
|---|---|---|---|
| https://www.eloratings.net | World Football Elo, current + historical | Free; no official API — site's TSV/JSON endpoints are scrapeable; community mirrors/Kaggle dumps exist | The core strength input; check mirror freshness |
| https://www.kaggle.com/datasets/martj42/international-football-results-from-1872-to-2017 | ~49k international results 1872–2026 + `shootouts.csv`, `goalscorers.csv` | Free CSV (CC0), maintained; repo https://github.com/martj42/international_results | Everything you need to fit DC/Elo yourself |
| https://github.com/fivethirtyeight/data/tree/master/soccer-spi | Archived SPI: `spi_matches_intl.csv`, `spi_global_rankings_intl.csv` | Free CSV (CC-BY 4.0) | Frozen ~2023; great for backtest features |
| https://www.fifa.com/en/fifa-world-ranking | Official FIFA ranking | Free pages; unofficial JSON endpoint; Kaggle mirrors | Needed only for tiebreaker/seeding logic |
| https://www.football-data.co.uk | Club results + historical closing odds CSVs | Free | No internationals — use to calibrate de-margining and blending machinery |
| https://the-odds-api.com | Live/pre-match odds API, ~40 books, has World Cup soccer keys | Free tier **500 credits/month** (multi-market calls burn 6+ credits each); paid from ~$30/mo | Your live market anchor; alternatives: https://odds-api.io, API-Football, Betfair Exchange API (sharpest prices) |
| https://fbref.com | International + club stats, Opta-powered | Free pages, CSV export; rate-limit ~10–20 req/min | Squad-level xG context |
| https://github.com/statsbomb/open-data | Full free event data incl. WC 2018 & 2022 | Free (research license, attribution) | Player/xG feature engineering |
| https://understat.com | Club xG, top-5 leagues | Unofficial scrapers (`understat` PyPI) | Club form for player-pool aggregation; no internationals |
| https://www.transfermarkt.com | Squad market values | Scrape (ToS prohibits; Kaggle mirrors and community APIs exist) | Top-tier predictor per Groll et al.; mind licensing |
| https://github.com/openfootball | Open results/fixtures incl. World Cup | Free, public domain | Fixture/squad scaffolding |
| FotMob / Sofascore | Player ratings, lineups, live data | Unofficial mobile APIs; ToS-restricted | Lineup news minutes before kickoff — operationally valuable, legally gray |

ToS reality check: for a personal research stack, scraping Elo/FBref/Transfermarkt at polite rates is tolerated practice; anything productized or redistributed needs licensed data (Opta/Stats Perform, Sportradar — five-figure territory).

---

## 7. Concrete build plan in Python

**Core library:** `penaltyblog` (`pip install penaltyblog`, https://github.com/martineastwood/penaltyblog) — Cython-accelerated Poisson, Dixon–Coles, bivariate Poisson, Bayesian hierarchical (MCMC) goal models; Elo/Massey/Colley/**pi-ratings**; **implied-probability extraction with margin removal (incl. Shin and power methods)**; Asian handicap/totals pricing from score matrices; scrapers. Fallback for full control: `statsmodels` GLM (Poisson family, team dummies) + `scipy.optimize.minimize` for the DC ρ and decay, ~150 lines.

**MVP pipeline (realistic estimate: 2–4 focused days for one quant-comfortable Python dev; a week with proper tests):**

1. **Ingest (half-day):** martj42 `results.csv` + current eloratings snapshot + the 48 qualified squads/fixtures (openfootball); store in DuckDB/parquet.
2. **Ratings & goal model (day 1):** compute your own Elo with eloratings K/G rules (so you can update it live during the tournament); fit the Elo→(λ, μ) nested Poisson regression on 2010–2026 internationals with exponential decay and friendly down-weighting; fit DC ρ on the same data.
3. **Score matrices & match prices (half-day):** 15×15 matrices per fixture → 1X2, AH ladder, totals, BTTS, correct score; knockout damping factor.
4. **Simulator (day 1):** vectorized 100k-run Monte Carlo with the verified 2026 tiebreakers (h2h-first, recursive), third-place table, the 495-combination R32 annex mapping, ET (λ/3 with haircut) + 50/50 shootouts, parameter redraws per run.
5. **Market layer & EV table (half-day):** pull The Odds API (free tier suffices pre-tournament if you batch), de-margin via Shin, blend at w = 0.8 market / 0.2 model, output an EV table: `edge = p_blend × odds − 1`, filtered at edge > 2–3% with fractional-Kelly stakes.

**Upgrade path (in order of marginal value):** (1) **lineup/availability shocks** — injury/suspension adjustments via minutes-weighted Transfermarkt value or FotMob lineups, the market's slowest-priced information at international tournaments; (2) **live re-rating** — after each group matchday, update Elo and refit λ regressions; group-stage results move third-place and bracket-path probabilities violently in a 12-group format and futures markets reprice sluggishly mid-tournament; (3) Bayesian hierarchical goal model for honest uncertainty on low-information teams; (4) in-play layer only if you have execution speed to use it.

---

## Key takeaways for the betting playbook

- **Dixon–Coles is still the spine**: independent Poisson + low-score τ adjustment + exponential time decay covers ~95% of the modeling value; bivariate Poisson and deep ML add decoration, not edge.
- **Always price from a score matrix**, never from a 1X2-only model — the same (λ, μ) pair prices 1X2, every Asian handicap, totals, BTTS, and correct score consistently, and consistency across markets is where thin-market edges show up.
- Reference numbers: λ = 1.6 vs 1.1 → **49.0% / 24.9% / 26.2%**, over 2.5 = **50.6%**, BTTS = **53.2%**, modal score 1-1 (11.8%); DC correction moves the draw up ~1 point — edge-sized, never skip it.
- **Use eloratings.net, not FIFA rankings, as the strength input** (K = 60/50/40/30/20 by importance, margin multipliers, +100 home); convert to goals via a nested Poisson regression `log μ = α₀ + α₁·Elo_opp`.
- **The market is your best single model**: consensus closing odds beat essentially all public academic models (RPS ≈ 0.19–0.20 vs ~0.206 for the best ML benchmark). Blend **70–90% market / 10–30% model** in liquid markets; lower market weight only where books are demonstrably lazy.
- De-margin odds with the **Shin or power method** (in `penaltyblog`), never proportional scaling — the favorite-longshot bias otherwise contaminates every downstream EV calculation.
- ML's proven role (Hubáček 2019; Groll et al. hybrid RF) is **ensembling features** — Elo, pi-ratings, **Transfermarkt squad value** (a top predictor), odds — for a ~0.004 RPS gain; it does not replace the goals model.
- **International specifics**: decay half-life of 2–4 years, friendlies down-weighted ~2–3x, hierarchical shrinkage for low-data teams; cross-confederation lines (CAF/AFC/CONCACAF vs UEFA/CONMEBOL) in the first 10 days are the highest-variance, highest-opportunity prices of the tournament.
- **Knockout football is cagey**: damp λs ~5–15% vs group-stage fits (clean sheets jump 34%→44%); third-place playoff is the opposite (≈3.1 goals/game historically) — overs there, unders in tight R16s.
- **2026 tiebreakers changed**: head-to-head (points→GD→goals, applied recursively) now comes **before** overall goal difference, then fair-play points, then FIFA ranking; third-place ranking is points→GD→goals→fair-play→FIFA rank. A simulator using 2022 rules will misprice "to advance" markets.
- **Hard-code FIFA's 495-combination third-place bracket annex** — bracket-path effects (who meets France in the R32) move outright prices by full points; never price futures by multiplying independent match probabilities.
- Model ET at ~1/3 of regulation λ with a small haircut and **shootouts as 50/50** (first-kicker advantage failed replication); 20–30% of knockouts reach ET, so the 90-minute vs to-qualify price gap is material.
- **Simulate with parameter uncertainty** (redraw ratings each of 100k runs): point estimates systematically over-price favorites — the same direction the recreational money leans, so the error costs you twice.
- Validate on **match-level RPS/log-loss vs de-margined closing odds** over WC 2010–2022 + Euros + Copa (~400 matches), not on tournament-winner anecdotes: 2022's "Brazil 22%, Argentina 8%" (FiveThirtyEight) wasn't *wrong*, it was one draw from the tree.
- **MVP is a 2–4 day build**: martj42 CSV + own Elo + penaltyblog DC fit + 100k-sim bracket + The Odds API (free tier) + Shin de-margin + 80/20 blend → EV table. Spend the saved time on lineup news and live re-rating between matchdays — that's where a solo operation actually out-runs the market.

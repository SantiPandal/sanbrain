---
type: research
project: worldcup-2026-betting
chapter: 1
title: Variables That Influence Football Match Outcomes — Team and Player Quality
date: 2026-06-09
status: compiled
---

# Variables That Influence Football Match Outcomes: Team and Player Quality

**Chapter 1 of the WC2026 quantitative betting dossier** — definitive reference for the team-strength block of the World Cup 2026 model (tournament starts June 11, 2026; 48 teams, 12 groups of 4, Round of 32 added, 104 matches, finalists play 8 games over 39 days — [FIFA/Wikipedia format guide](https://en.wikipedia.org/wiki/2026_FIFA_World_Cup)).

The central empirical fact of football forecasting: **a single well-built strength rating captures most of the predictable variance in match outcomes; everything else (form, style, cohesion, fatigue) is a second-order correction worth a few percentage points at most.** Football is low-scoring (~2.7 goals/match), so outcomes are noisy — the better team loses roughly 1 match in 4 even at large rating gaps. Your edge comes from measuring strength slightly better than the market, then layering disciplined corrections the market underweights.

---

## 1. Team strength rating systems

### 1.1 World Football Elo Ratings (eloratings.net) — the workhorse

**Methodology** ([eloratings.net/about](https://www.eloratings.net/about), [Wikipedia summary](https://en.wikipedia.org/wiki/World_Football_Elo_Ratings)): rating update is `Rn = Ro + K·G·(W − We)`, where:

- **K (match importance):** 60 World Cup finals tournament; 50 continental championships and major intercontinental tournaments; 40 World Cup and continental qualifiers; 30 other tournaments; 20 friendlies.
- **G (margin multiplier):** ×1.5 for a 2-goal win; ×1.75 for 3 goals; ×(1.75 + (N−3)/8) for N ≥ 4.
- **Home advantage:** flat **+100 points** added to the home team's rating before computing the expectation (≈ 0.4–0.6 goals; FiveThirtyEight independently used ~0.4 goals for host Qatar in 2022).
- **Expected result:** `We = 1 / (10^(−dr/400) + 1)` where dr = rating difference incl. home bonus.

**Elo-difference → expected score mapping** (the betting-relevant table, [Elo system reference](https://en.wikipedia.org/wiki/Elo_rating_system), [wismuth calculator](https://wismuth.com/elo/calculator.html)): +100 Elo → 64% expected score; +200 → 76%; +300 → 85%; +400 → 91% (a 400-point gap = 10:1 odds by construction). Expected score = P(win) + 0.5·P(draw); since ~22–28% of competitive internationals are drawn, convert to 1X2 with a draw model (Davidson/ordered logit on dr). Rule of thumb: an Elo edge of ~85–90 points ≈ one expected goal of superiority per match.

**Predictive validity.** [Lasek, Szlávik & Bhulai (2013), *Int. J. Applied Pattern Recognition* 1(1):27–46](https://www.inderscience.com/info/inarticle.php?artid=52339) compared eight ranking systems on thousands of international matches: **Elo variants (especially with margin-of-victory weighting) had the best out-of-sample accuracy, and the pre-2018 FIFA ranking was among the worst** of the methods tested. At club level, [Hvattum & Arntzen (2010)](https://www.researchgate.net/publication/46497617_Using_ELO_ratings_for_match_result_prediction_in_association_football) found Elo-based probabilities carry real information but are **dominated by bookmaker odds** — calibrate expectations accordingly: Elo is your prior, not your edge.

**Feature encoding:** raw Elo difference (with +100 if true home team — at WC 2026 only USA/Mexico/Canada get this), plus Elo change over last 12 months as a momentum term. Source: [eloratings.net](https://www.eloratings.net) (free, updated after every international).

### 1.2 The official FIFA ranking (SUM formula) — and why it's weaker

Since August 2018 FIFA uses "SUM" ([official procedure](https://inside.fifa.com/fifa-world-ranking/procedure-men)): `P_new = P_before + I·(W − We)`, with We the same 600-point-scaled logistic, and importance I from 5 (friendlies outside windows) up to 50 (WC through R16) and 60 (WC quarterfinal onward). Three deliberate distortions make it worse for prediction than Elo ([hermann-baum calculation guide](https://hermann-baum.de/excel/WorldCup/en/FIFA_Ranking.php)):

1. **No margin of victory** — a 7-0 and a 1-0 update identically.
2. **No home-advantage adjustment** — systematically misprices teams with home-heavy or away-heavy schedules.
3. **Knockout-loss protection** — losers of knockout games at final tournaments lose **zero** points (and shootout results are scored 0.75/0.5), inflating teams that reach knockouts and lose.

[Szczecinski & Roatis (2022), "FIFA ranking: Evaluation and path forward," *J. Sports Analytics*](https://arxiv.org/abs/2201.00691) analyzed all matches since the 2018 reform and concluded the **match-importance weights are actively counterproductive for prediction**, and that adding home-field advantage, an explicit draw model, and goal-difference weighting **notably improves predictive capability**. Bottom line: the FIFA ranking is an administrative artifact — but it **determined the December 2025 seeding pots for this World Cup**, so its distortions are tradeable (mis-seeded teams create soft and hard regions of the bracket).

**Feature encoding:** do not use FIFA points as a strength input; optionally use (FIFA rank − Elo rank) as a "seeding distortion" feature for bracket-path value.

### 1.3 Bookmaker-implied ratings — the strongest single benchmark

Market prices are themselves a rating system. The [Zeileis–Leitner–Hornik bookmaker consensus model](https://ideas.repec.org/p/inn/wpaper/2018-09.html) strips each book's overround, averages winning odds across books on the log-odds scale, then **inverse-simulates the tournament to recover implied team abilities** that can price any hypothetical pairing. It correctly identified Spain pre-tournament in 2010 and 3 of 4 semifinalists in 2014. The efficiency literature ([Forrest, Goddard & Simmons 2005, ~10,000 matches](https://www.researchgate.net/publication/223256371_Odds-Setters_as_Forecasters_The_Case_of_English_Football)) shows odds-setters ultimately outperform a good benchmark statistical model — odds are well calibrated but **not fully efficient**, which is precisely the gap this dossier hunts.

**Current market snapshot (June 2026):** Spain +470, France +480, England +650, Brazil +850, Argentina +1000 ([ESPN odds board](https://www.espn.com/espn/betting/story/_/id/48386952/espn-soccer-futbol-world-cup-betting-odds-championship-groups), [FOX Sports](https://www.foxsports.com/stories/soccer/world-cup-2026-champion-odds)); prediction markets have France ~16.2% / Spain ~16.0% / England ~10.9% ([DefiRate odds tracker](https://defirate.com/prediction-markets/world-cup-odds/)) — note France drifted after losing 2-1 to Ivory Coast in a June 4 friendly, a classic overreaction-to-form candidate.

**Feature encoding:** consensus no-vig log-odds implied ability (from outright + match markets) as the baseline rating; your model's job is to forecast *residuals* from it.

### 1.4 SPI-style ratings (FiveThirtyEight) and Opta Power Rankings

**SPI** ([methodology](https://fivethirtyeight.com/features/how-our-club-soccer-projections-work/), [2022 WC version](https://fivethirtyeight.com/features/how-our-2022-world-cup-predictions-work/)): each team gets an **offensive rating** (goals expected vs average team, neutral venue) and **defensive rating** (goals conceded vs same), updated after every match using a blend of actual goals, shot-based xG and non-shot xG — so a team that wins while being outplayed can *lose* rating. Matches forecast via two Poissons with diagonal inflation for draws; tournaments via Monte Carlo. International SPI priors lean on player/roster quality (transfer value), which is why SPI-type systems react faster than pure-results Elo to talent turnover. FiveThirtyEight shut down in 2023 — historical SPI data lives on [GitHub](https://github.com/fivethirtyeight/data/tree/master/soccer-spi), and Nate Silver publishes [2026 World Cup forecasts on Silver Bulletin](https://www.natesilver.net/p/world-cup-2026-odds-predictions).

**Opta Power Rankings** ([methodology](https://theanalyst.com/articles/power-rankings-your-club-ranked)): Elo-style net ratings across ~13,000 club teams with goal-difference scaling (diminishing returns above ~3 goals) and competition multipliers; the **Opta "supercomputer" tournament forecast combines Power Rankings with betting-market odds**. Its [pre-tournament 2026 simulation](https://theanalyst.com/articles/who-will-win-2026-fifa-world-cup-predictions-opta-supercomputer): **Spain 16.1%, France 13.0%, England 11.2%, Argentina 10.4%, Portugal 6.8%, Brazil 6.5%, Germany 5.4%, Netherlands 3.8%, Norway 3.4%**. Useful as a second model to triangulate market deviations (e.g., Opta prices Brazil below its bookmaker price).

---

## 2. Squad quality measures

### 2.1 Transfermarkt market value — the best public talent proxy

The academic results are unusually clean here:

- **[Peeters (2018), *Int. J. Forecasting* 34(1):17–29](https://www.sciencedirect.com/science/article/abs/pii/S0169207017300754):** forecasts of international results built on crowd-sourced Transfermarkt squad valuations were **more accurate than FIFA ranking and Elo-based forecasts**, and the improvement was large enough to generate **"sizable monetary gains" in betting strategies** against real odds — one of the few peer-reviewed documented edges in this literature. The wisdom is in the whole crowd: filtering to "expert" valuers didn't help.
- **[Gerhards & Mutz (2017), *European Societies* 19(3)](https://www.tandfonline.com/doi/abs/10.1080/14616696.2016.1268704):** across 12 European leagues and 5 seasons, squad market value alone explained **67–71% of the variance in team performance per season**, and the most expensive squad won the title in **54 of 75 league-seasons (72%)**. Composition variables (inequality, diversity, turnover) were far weaker.

**2026 squad values (Transfermarkt, June 2026):** France ~**$1.76B** (Mbappé $230M), England ~**$1.51B** (Bellingham $161M), Spain ~**$1.45B** (Yamal $238M, tied with Haaland as tournament's most valuable player); Portugal, Germany and Brazil also exceed $1B ([SI ranking](https://www.si.com/soccer/most-expensive-squads-2026-world-cup-ranked), [Yahoo/Sportingpedia](https://sports.yahoo.com/articles/most-expensive-world-cup-squads-173136491.html)). Only ~€60M separates the top three — consistent with the near-three-way co-favoritism in the market.

**Feature encoding:** log(total squad value), log(starting-XI value), and value of top-3 players; for tournament models include value *rank* within the field. Caveat: values embed age and league inflation — use within-tournament z-scores, refreshed at the June 1 squad deadline (final 26-man lists published June 2 — [FIFA squad rules](https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026/articles/squad-lists-number-date)).

### 2.2 Squad depth

2026 is the deepest-squad-demand tournament ever: **26-man rosters, 5 substitutions (+1 in extra time), 8 matches for finalists across 39 days**, summer heat, and continental travel. Depth evidence: with 5 subs at Qatar 2022, substitutes were scoring at the highest rate in WC history — by late group stage **22 of 106 goals (~21%) came from subs**, vs 19% across all of Brazil 2014, the previous high ([ESPN analysis](https://www.espn.com/soccer/story/_/id/37634455/why-substitutes-scoring-more-2022-world-cup)); teams used 4+ subs in 78 of 88 opportunities. **Feature encoding:** value of players 12–18 (bench value), or starting-XI value minus 26-man average; interacts positively with round number (depth matters more from the R16 onward and in extra-time scenarios).

### 2.3 Age curves

[Dendir (2016), *J. Sports Analytics*](https://content.iospress.com/articles/journal-of-sports-analytics/jsa0021): peak performance at **25–27 overall; forwards ~25, midfielders ~25–26, defenders ~27**, with goalkeepers peaking later still ([ESPN age-curve summary](https://www.espn.com/soccer/blog/tactics-and-analysis/67/post/3056495/soccer-age-curves-show-goalkeepers-and-central-defenders-peak-latest)). Tournament-level: the **last 10 World Cup-winning squads averaged 26.9 years**, range Spain 2010 (25.0) to Italy 2006 (28.8), and recent winners came from the top-5 squads by market value with age 26–29 ([ILCUK analysis](https://ilcuk.org.uk/what-wins-world-cups-youth-experience-or-money/)). **Feature encoding:** minutes-weighted squad age and |age − 26.5| penalty term; flag squads with >3 key players aged 33+ (decline risk compounds over an 8-game tournament).

### 2.4 Star dependence

Concentration of output is a fragility measure, not a strength measure. Current example: **Haaland scored 16 of Norway's 37 qualifying goals (43%)** ([UEFA](https://www.uefa.com/european-qualifiers/news/0297-1d5d6735f8d7-9bf819c5c8e9-1000--european-qualifiers-top-scorer-erling-haaland/)); Ronaldo (143 goals in 227 caps) still anchors Portugal's output at 41. The cleanest quantification of what one star is worth comes from the Neymar 2014 natural experiment in §4.3 (≈ 8–9 points of single-match win probability; ~9 points of title equity when combined with a second key absence). **Feature encoding:** share of team's last-24-month goal involvements by top player (HHI of goal contributions); interact with that player's availability/fitness flag. High concentration ⇒ wider variance: fade in outrights, but exploit overreaction if the star's availability flips late.

---

## 3. Underlying performance metrics

### 3.1 Goals vs xG: signal vs noise

Team-level **xG difference predicts future results better than goal difference or shot counts (TSR)** — it stabilizes faster because chance quality varies less game-to-game than conversion ([Hudl explainer](https://www.hudl.com/blog/expected-goals-xg-explained); [tonyelhabr's rest-of-season R² analysis](https://tonyelhabr.rbind.io/posts/xg-predictor-future-results/) finds xG ratio the most predictive early-sample team metric). Teams massively over/under-shooting their xG regress: treat goals−xG gaps over <20 matches as mostly noise. **International caveat:** national teams play only ~10–12 matches/year against wildly heterogeneous opposition, so opponent-adjust xG (regress vs opponent Elo) and pool 2+ years. **Sources:** [FBref](https://fbref.com/en/comps/1/keepers/World-Cup-Stats) (Opta-powered international xG), FotMob, and **StatsBomb's free open event data for WC 2018 and 2022** (github.com/statsbomb/open-data) for building your own international xG model. **Encoding:** rolling opponent-adjusted npxGD per 90 (24-month window, exponential decay), shrunk toward Elo-implied goal difference.

### 3.2 Finishing skill persistence

Mostly noise, slightly skill. Shooting overperformance (goals − xG per shot) shows **weak year-to-year stability**; [Davis & Robberechts (2024), "Biases in Expected Goals Models Confound Finishing Ability"](https://arxiv.org/abs/2401.09940) show that high shot-outcome variance plus model bias make finishing-skill inference unreliable except for extreme multi-season outliers (Messi-class). [Analytics FC's review](https://analyticsfc.co.uk/blog/2025/02/11/are-some-players-consistently-good-finishers/) reaches the same conclusion. **Encoding:** regress team finishing 70–90% to the mean; allow a small positive prior only for squads stacked with proven multi-season overperformers.

### 3.3 Goalkeeper shot-stopping (PSxG − GA)

PSxG (post-shot xG) grades keepers on on-target shots faced. It better isolates the keeper than save percentage, but even PSxG−GA shows **substantial year-on-year volatility** ([Analytics FC](https://analyticsfc.co.uk/blog/2023/08/22/do-goalkeeper-statistics-reflect-individual-ability-or-team-performance/), [Pleuler's reframing](https://github.com/devinpleuler/research/blob/master/reframing-post-shot-xg.md)) — shrink hard. Tournament impact is real though: at Qatar 2022 **Livaković faced 9.3 PSxG and conceded 6 (+3.3 goals prevented)** en route to Croatia's semifinal, ahead of Martínez, Bounou and Courtois ([GiveMeSport/FBref data](https://www.givemesport.com/88095438-world-cup-who-has-been-the-best-goalkeeper-at-qatar-2022/); [FBref WC keeper stats](https://fbref.com/en/comps/1/keepers/World-Cup-Stats)). A hot keeper is worth ~0.5 goals/match for a knockout run — but it's barely predictable in advance. **Encoding:** keeper's 2-season club PSxG−GA per 90, shrunk 50%+ toward zero; bigger value as a *live* shootout/underdog variance flag than as a mean shift.

### 3.4 Set-piece dependence

Get the trend right — it **peaked in 2018 and fell in 2022**, contrary to casual narrative:

- **2018: 73 of 169 goals (43%) from set-piece situations (incl. penalties) — the highest share since at least 1966** ([RTE/Opta](https://www.rte.ie/sport/world-cup-2018/2018/0709/977375-record-number-of-set-piece-goals-scored-at-world-cup/)); England alone scored 9 set-piece goals ([Goal/Opta](https://www.goal.com/en/news/england-set-world-cup-set-piece-record/1c1xmsuse8kwi1a6x9p6jxh0vu)). 29 penalties awarded, 22 scored (first VAR World Cup).
- **2022: set-piece share collapsed to ~24% of 172 goals** (~42 goals), with StatsPerform data showing set-piece chance quality "should have" produced ~52 ([Frontiers in Sports & Active Living, 2024 comparison study](https://www.frontiersin.org/journals/sports-and-active-living/articles/10.3389/fspor.2024.1394621/full) — note: definitional differences put 2018 at 38.5% on the same basis). Corners converted at only **2.6% (15 of 577)** in 2022 ([corner-kick analysis](https://www.researchgate.net/publication/386011283_FIFA_World_Cup_2022_Qatar_Corner_Kicks_An_Analysis_on_Effectiveness_and_Match_Context)).

Why it still matters for 2026: set pieces are the classic **underdog equalizer** (low-possession teams get corners/free kicks regardless of territory), club football's set-piece share has been rising again with specialist coaches, and FIFA's own analysis of the 2025 Club World Cup found more set-play chances created ([FIFA Training Centre](https://www.fifatrainingcentre.com/en/game/tournaments/fcwc/2025/team-analyses/more-goalscoring-opportunities-generated-from-set-plays.php)). **Encoding:** set-piece xG for/against per 90 from qualifying (StatsBomb/Opta tagged), plus aerial-duel win rate; weight up for underdog +handicap and BTTS/under markets.

### 3.5 Penalty conversion

[Opta's World Cup penalty database](https://theanalyst.com/articles/world-cup-penalty-shootouts-the-facts): **in-game WC penalties convert at 79.1% since 1978; shootout kicks at only 69.4%** (pressure effect ≈ −10pp). Within shootouts: kicks 1–3 convert >71%, kicks 4–5 drop to 64.2–66.7%; all 39 on-target attempts into the top third have scored. Penalty xG ≈ 0.78–0.79 — one penalty is worth roughly 35% of an average team's match xG, which is why VAR-era penalty frequency belongs in any total-goals model. Shootouts themselves are near-coin-flips (slight skill/experience tilt) — at 69.4% conversion, treat "to qualify" vs "to win in 90" pricing as a structural arbitrage check.

---

## 4. Form and fitness

### 4.1 Recent results vs underlying metrics

Pre-tournament friendlies are weak signals with strong market impact: lineups are experimental, motivation uneven, and samples tiny. The June 4 France 1–2 Ivory Coast result knocked France off outright co-favoritism in prediction markets ([DefiRate tracker](https://defirate.com/prediction-markets/world-cup-odds/)) despite zero meaningful information about France's xG process — the textbook setup where **underlying metrics > recent results**. Quantitatively, xG-based process measures out-predict W/D/L form streaks at every horizon tested (§3.1). **Encoding:** last-10-competitive-match opponent-adjusted xGD, *not* points won; explicitly down-weight friendlies (Elo already does: K=20).

### 4.2 Club-season fatigue

The classic quantitative result is [Ekstrand's BJSM study of the 2002 World Cup](https://www.researchgate.net/publication/8436901_A_congested_football_calendar_and_the_wellbeing_of_players_Correlation_between_match_exposure_of_European_footballers_before_the_World_Cup_2002_and_their_injuries_and_performers_during_that_World_Cup): among 65 elite players, **60% of those who played more than 1 match/week in the final 10 weeks of the club season underperformed or got injured at the World Cup**; across the sample 29% were injured and 32% played below their normal level. Modern workload context: [FIFPRO monitoring](https://fifpro.org/en/player-iq/men-s-player-workload-monitoring/seven-key-findings-from-fifpro-s-latest-workload-report) shows 17% of elite players exceeded 55 appearances in 2023/24 (88% of high-performance coaches consider 55+ unsafe), and 30% endured 6+ consecutive back-to-back weeks; at Qatar 2022, 44% of surveyed players reported extreme/increased fatigue ([FIFPRO](https://www.fifpro.org/en/articles/2023/03/world-cup-players-experiencing-mental-and-physical-fatigue-fifpro-survey-shows)). **2026-specific:** players from Club World Cup 2025 finalist clubs face a second consecutive summer without an off-season, and the tournament adds heat, travel and a possible 8th match. **Encoding:** squad-minutes load = minutes-weighted club minutes since July 2025 for projected XI (flag players >4,000 minutes and >55 appearances); expect late-tournament decay interaction (load × round).

### 4.3 Injuries and how markets reprice stars

The benchmark natural experiment: **Neymar's fractured vertebra + Thiago Silva's suspension, July 2014.** FiveThirtyEight's model cut Brazil's semifinal win probability vs Germany from **73% to ~65%** for the two absences ([538](https://fivethirtyeight.com/features/how-neymars-injury-affects-brazils-chances-at-the-world-cup/)), and Brazil's tournament-win probability from **54% to ~45%**; betting markets repriced harder — Brazil flipped from clear favorite to **underdog (+175 vs Germany's +160)**, while Argentina's outright probability rose 20%→23% and Germany's 14%→18% ([Bleacher Report line history](https://bleacherreport.com/articles/2120598-brazil-vs-germany-latest-match-odds-predictions-for-2014-world-cup-semifinal)). Working numbers: a true superstar is worth **~5–10pp of single-match win probability** (roughly 0.3–0.5 goals), an ordinary starter ~1–3pp; market reaction is two-phase (instant repricing, then drift as lineup news clarifies) — the documented exploitable window is the gap between "doubt" rumors and official team news ([Action Network on injury line movement](https://www.actionnetwork.com/education/how-injuries-affect-betting-lines-a-guide-to-market-movement)). **Encoding:** availability-adjusted squad value (subtract injured players' value share, weight by minutes-share), refreshed daily against squad news.

### 4.4 Squad cohesion

Evidence says: real but small, and largely absorbed by strength ratings. The largest study — [19,721 internationals, *Journal of Big Data* (2025)](https://journalofbigdata.springeropen.com/articles/10.1186/s40537-025-01239-x) — found **shared-experience metrics had no independent effect on match results once team strength was controlled**, though micro-analysis (1,602 matches) showed shared successful interactions predict pass-completion quality. A complementary study of national teams ([*Wearing the Same Jersey?*, 2023](https://pmc.ncbi.nlm.nih.gov/articles/PMC10141925/)) found shared team tenure positively associated with performance via tacit coordination. **Encoding:** average pairwise shared caps among projected XI + months under current manager, as a low-weight tiebreaker feature (expect <1pp of probability impact); do not pay juice for "cohesion" narratives.

---

## 5. Tactics and style

What survives scrutiny:

- **Pressing intensity (PPDA)** describes *how* teams win, and style asymmetries (a PPDA-7 presser vs a PPDA-13 low block) shape game dynamics ([PPDA explainer](https://jobsinfootball.com/blog/what-is-ppda-passes-per-defensive-action/)), but there is **no robust public evidence that style features add predictive power beyond strength ratings** at the international level. Possession share itself is famously non-causal (Spain 2018 had 75%+ possession vs Russia and lost).
- **Style-vs-style matchups:** practitioner lore (low blocks + set pieces travel well against high-line favorites; counterattacking teams overperform as big underdogs) has anecdotal but not systematic support; encode at most as an interaction term (favorite's xG haircut vs bottom-quartile-PPDA opponents) and validate before weighting.
- **Manager tournament experience:** the coach-change literature finds **new-coach characteristics (experience, elite playing career) do not measurably affect subsequent team performance** ([PMC study](https://pmc.ncbi.nlm.nih.gov/articles/PMC8670813/)); WC-determinants work (1994–2022, [Heliyon](https://www.sciencedirect.com/science/article/pii/S2405844023074601)) finds structural factors (hosting, football tradition) dominate. Treat "experienced tournament manager" as priced-in narrative, weight ~0.
- Where tactical data *does* pay: **set-piece specialization** (§3.4) and **substitution aggressiveness** (5-sub era rewards deep benches and proactive managers — measurable as average sub minute and bench xG share).

---

## 6. Feature summary table

| Variable | Predictive power (standalone) | Best source | Encoding |
|---|---|---|---|
| Bookmaker-implied ability | Highest; beats stat models ([FGS 2005](https://www.researchgate.net/publication/223256371_Odds-Setters_as_Forecasters_The_Case_of_English_Football)) | Pinnacle/exchange closing lines | No-vig consensus log-odds (baseline) |
| World Football Elo | Best public results-only rating ([Lasek 2013](https://www.inderscience.com/info/inarticle.php?artid=52339)); +100 Elo ≈ 64% expected score | [eloratings.net](https://www.eloratings.net) | Elo diff (+100 home); 12-mo delta |
| Transfermarkt squad value | Beats Elo & FIFA for internationals; profitable in-sample ([Peeters 2018](https://www.sciencedirect.com/science/article/abs/pii/S0169207017300754)); 67–71% league variance ([G&M 2017](https://www.tandfonline.com/doi/abs/10.1080/14616696.2016.1268704)) | transfermarkt.com | log XI value, availability-adjusted |
| FIFA ranking (SUM) | Weak; importance weights counterproductive ([Szczecinski 2022](https://arxiv.org/abs/2201.00691)) | inside.fifa.com | Only as seeding-distortion signal |
| Opp-adjusted xGD | Best process metric; > GD for future results | FBref/Opta; StatsBomb open data | Rolling 24-mo npxGD/90, shrunk to Elo |
| Finishing (G−xG) | Weak persistence — regress 70–90% | FBref | Near-zero weight |
| GK PSxG−GA | Real but volatile; ±0.5 goals/match when hot | FBref keeper tables | 2-yr club value, 50% shrinkage |
| Set-piece xG share | Moderate; underdog-specific (43%→24% of WC goals 2018→2022) | StatsBomb/Opta tagged events | SP xGF/xGA per 90 |
| Penalties | 79.1% in-game, 69.4% shootout conversion | [Opta Analyst](https://theanalyst.com/articles/world-cup-penalty-shootouts-the-facts) | Structural constants in sim |
| Minutes load / fatigue | 60% of overworked underperformed/injured (WC2002, [Ekstrand](https://www.researchgate.net/publication/8436901_A_congested_football_calendar_and_the_wellbeing_of_players_Correlation_between_match_exposure_of_European_footballers_before_the_World_Cup_2002_and_their_injuries_and_performers_during_that_World_Cup)) | FBref minutes; FIFPRO | XI minutes since Jul 2025 × round |
| Star availability | 5–10pp/match for superstars (Neymar 2014) | Daily squad news | Value-share subtraction |
| Cohesion (shared caps) | ≈0 after controlling strength ([JBD 2025](https://journalofbigdata.springeropen.com/articles/10.1186/s40537-025-01239-x)) | Cap databases | Low-weight tiebreaker |
| Age profile | Winners cluster 25–29 (avg 26.9) | Transfermarkt | Minutes-weighted age, peak-distance |
| Manager experience | No measurable effect ([coach-change lit](https://pmc.ncbi.nlm.nih.gov/articles/PMC8670813/)) | — | Weight 0 |

---

## Key takeaways for the betting playbook

1. **Anchor on market-implied ratings, not your favorite model.** Closing odds beat statistical models on average ([Forrest–Goddard–Simmons](https://www.researchgate.net/publication/223256371_Odds-Setters_as_Forecasters_The_Case_of_English_Football)); your model exists to find the 2–5% of prices where the market's inputs are stale.
2. **Use Elo as the prior, Transfermarkt as the challenger.** Elo difference maps cleanly to probability (+100 → 64% expected score via `1/(10^(−dr/400)+1)`); Peeters showed squad-value forecasts beat both Elo and FIFA *and* cleared the vig in-sample — the single best-documented public edge in international football.
3. **Never use the FIFA ranking as a strength input** — no margin of victory, no home adjustment, knockout-loss immunity, counterproductive importance weights. Do mine it for seeding distortions: mis-ranked teams create mispriced bracket paths in a 12-group, R32 format.
4. **An Elo edge of ~85–90 points ≈ 1 goal; convert expected score to 1X2 with an explicit draw model** (~22–28% draw base rate in competitive internationals; draws are where naive Elo bettors bleed).
5. **Trust xG process over results, especially in June friendlies.** France's drift after losing to Ivory Coast on June 4 is the archetypal form-overreaction; opponent-adjusted xGD over 24 months is the signal, W/D/L streaks are the noise.
6. **Regress finishing hard (70–90%) and keeper overperformance ~50%.** Goals−xG and PSxG−GA are low-persistence; teams priced up because they "found clinical form" in qualifying are systematic fade candidates.
7. **Set pieces are the underdog's weapon and the trend is regime-dependent:** 43% of WC goals in 2018 vs ~24% in 2022. Price set-piece-strong underdogs up on +handicaps; corners convert at only ~2–3%, so fade corner-count-based narratives.
8. **Penalty constants:** 79% in-game, 69% in shootouts, kicks 4–5 drop to ~65%. Check "to lift the trophy" vs "to win in 90" pricing consistency; shootouts are near-coin-flips, so knockout matchups between near-equals should converge to ~50/50 tails.
9. **Fatigue is measurable and the market mostly ignores it until it shows.** Ekstrand: 60% of players above 1 match/week in the last 10 pre-WC weeks underperformed or got injured. Build a minutes-load index per squad (flag >4,000 club minutes / 55+ appearances, incl. Club World Cup 2025 participants) and bet the decay late in the tournament (unders, fade in QFs+).
10. **Star injuries move outrights by ~5–10x more than the market moves for role players** — Neymar 2014 flipped Brazil from clear favorite to +175 underdog in a semifinal and cut ~9pp of title equity. The exploitable window is between first "doubt" reports and official confirmation; have availability-adjusted squad values precomputed.
11. **Concentration risk is variance, not strength:** Norway run through Haaland (43% of qualifying goals), Portugal through Ronaldo. High-HHI teams are live underdogs match-to-match but structurally overpriced in outrights (one marking plan or one knock kills the run).
12. **Depth is newly decisive in the 8-game, 39-day, 5-sub format:** ~21% of Qatar 2022 goals came from substitutes by late group stage. Weight bench value (players 12–18) explicitly from the R32 onward and in extra-time props.
13. **Age sweet spot 25–29:** last 10 champions averaged 26.9 years and recent winners were top-5 by market value. Squads outside both screens (value top-5, age 25–29) have never won in the modern era — apply as an outright filter, not a match-level input.
14. **Ignore narrative features the data rejects:** manager tournament pedigree, "golden generation cohesion," and possession style add ~nothing once strength is controlled — they are priced into odds via public sentiment, making their *absence* from your model a source of edge.
15. **Triangulate models against the June 2026 board:** Opta sim (Spain 16.1%, France 13.0%, England 11.2%, Argentina 10.4%) vs market (Spain +470, France +480, England +650, Argentina +1000) — model-vs-market gaps (e.g., Brazil and Portugal priced richer by books than by models) are the chapter's working shortlist for value review, not automatic bets.

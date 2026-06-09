---
type: research
project: worldcup-2026-betting
chapter: 9
title: The Rules In Depth — Every Regulation That Can Decide a Bet
date: 2026-06-09
status: compiled
---

# Chapter 9 — The Rules In Depth: Every Regulation That Can Decide a Bet

**Primary source basis.** The governing document is the **Regulations for the FIFA World Cup 26™** (11 June – 19 July 2026), current edition **May 2026**: https://digitalhub.fifa.com/m/636f5c9c6f29771f/original/FWC2026_regulations_EN.pdf (earlier editions mirrored at https://cdn.thuvienphapluat.vn/phap-luat/2022-2/TTKP/FWC26-regulations.pdf and https://www.worldcup2026football.co.uk/wc-2026-regulations.pdf; full-text mirror at https://www.scribd.com/document/874526760/FWC26-Competition-Regulations-EN-%C4%91a-mo-kho-a). On-field play: IFAB **Laws of the Game 2025/26** (https://downloads.theifab.com/downloads/laws-of-the-game-2025-26-single-pages?l=en) plus tournament-specific protocols FIFA confirmed for this World Cup. Discipline: the **FIFA Disciplinary Code**. *Compilation note: this environment could not open digitalhub.fifa.com directly; regulation text is reconstructed from search-engine extraction of the official PDF plus multiple independent outlets quoting it, flagged wherever only secondary confirmation exists.*

---

## 1. RESOLVED: the group-stage tiebreaker order (the dossier's flagged conflict)

**Verdict: Chapter 4 is right; Chapter 5's §6 bullet is wrong and must be corrected. 2026 is HEAD-TO-HEAD FIRST.**

**Article 13 of the Regulations for the FIFA World Cup 26 ("equal points / ranking")** governs. Per the official PDF (https://digitalhub.fifa.com/m/636f5c9c6f29771f/original/FWC2026_regulations_EN.pdf) as extracted via search indexing and corroborated by every regs-based explainer published since the December 5, 2025 draw, teams level on points in a group are separated by, in order:

1. **Greatest number of points obtained in the group matches played between the teams concerned** (head-to-head points);
2. **Superior goal difference resulting from the group matches played between the teams concerned** (head-to-head GD);
3. **Greatest number of goals scored in the group matches played between the teams concerned** (head-to-head goals);
4. **Re-application of criteria 1–3** restricted to the subset of teams still tied (the recursive step — if applying 1–3 separates some but not all tied teams, 1–3 are re-run on the remaining tied teams only);
5. **Superior goal difference in all group matches**;
6. **Greatest number of goals scored in all group matches**;
7. **Highest team conduct score** (fair play — card-based, values below);
8. **FIFA/Coca-Cola Men's World Ranking** (most recent edition).

Corroboration, all consistent: Yahoo/NBC Sports (https://sports.yahoo.com/articles/group-stage-tiebreaker-rules-2026-094000319.html, https://www.nbcsports.com/soccer/news/what-are-the-new-group-stage-tiebreaker-rules-at-the-2026-world-cup), FOX Sports (https://www.foxsports.com/stories/soccer/fifa-world-cup-group-stage-third-place-tiebreakers), ESPN (https://www.espn.com/soccer/story/_/id/48703925/world-cup-group-stage-explained-tiebreakers-third-place-teams), Sofascore (https://www.sofascore.com/news/__trashed-21), and regs-quoting guides (https://worldcuplocaltime.com/world-cup-2026-tiebreaker-rules/, https://gamblingcalc.com/gambling-guides/world-cup-2026-tiebreaker-rules/).

**Why Chapter 5's sources disagreed:** every World Cup from 1970 through 2022 used overall GD → overall goals first, with head-to-head only third (2022 regs Art. 12). The FIFA web article and NBC Philadelphia piece cited in Chapter 5 reproduced the legacy order; the 2026 regulations inverted it. This is a genuine rule change, widely reported as such ("head-to-head results replace goal difference as the primary tiebreaker at the 2026 World Cup").

**Two modeling notes.** (a) The **recursion** matters in 3-way ties: if A beats B and C while B and C draw, h2h splits A out first, then B/C are re-compared on their own mini-table before falling to overall GD. (b) The **final criterion is now the FIFA ranking, not drawing of lots** — regs-based summaries state lots are gone from Article 13 (https://worldcuplocaltime.com/world-cup-2026-tiebreaker-rules/); one aggregator's claim that earlier ranking editions apply sequentially is unverified. Criterion 8 is vanishingly rare to reach, but a free roll if a book ever prices a "lots" scenario.

**Betting impact:** in tight groups (E, F, H, I per Chapter 5), "to qualify"/"group winner" probabilities computed with the 2022 order are simply wrong. Two teams tied at the top where one thrashed a minnow (+5 overall GD) but lost the direct meeting: in 2022 the thrasher tops the group; in 2026 the h2h winner does. Chapter 4's simulator spec already implements this correctly; the live mispricing window is MD3 in-play "group winner" markets.

### 1.1 Third-place ranking across groups

The 12 third-placed teams are ranked together; the **best 8 advance** to the R32. Criteria (regs-based, corroborated by https://www.foxsports.com/stories/soccer/fifa-world-cup-group-stage-third-place-tiebreakers and https://worldcuplocaltime.com/2026-world-cup-third-place-qualification/): **(1) points; (2) overall goal difference; (3) overall goals scored; (4) team conduct score; (5) FIFA ranking.** No head-to-head here (different groups). Note the asymmetry: *within* a group h2h rules; *across* groups it's pure overall numbers — a team can lose a group tiebreak on h2h yet advance comfortably as a third on fat overall GD. 8-of-12 advancing (67%) is the most forgiving rate in WC history: structurally bullish on "to reach knockout stage" for mid-tier teams, and it kills most dead rubbers — MD3 nearly always carries live stakes for someone via the third-place table.

### 1.2 Team conduct ("fair play") points — exact card values

Per the regulations (corroborated at https://worldcuplocaltime.com/world-cup-2026-tiebreaker-rules/ and https://gamblingcalc.com/gambling-guides/world-cup-2026-tiebreaker-rules/), deductions per player/official per match, **only the heaviest one applying**:

- Yellow card: **−1**
- Indirect red (second yellow): **−3**
- Direct red: **−4**
- Yellow then direct red in the same match: **−5**

Higher (less negative) total ranks first. This bound in 2018 (Japan over Senegal on −4 vs −6) — with 12 groups and a 12-team third-place table, the chance it binds somewhere in 2026 is material. If you are trading MD3 in-play qualification markets, **live card counts are tiebreak data, not just props data**.

### 1.3 The third-place allocation annex (the "495 table")

Group winners' and runners-up's R32 slots are fixed in the match schedule; the eight qualified thirds are distributed to face the winners of **Groups A, B, D, E, G, I, K and L** (winners of C, F, H, J play runners-up instead). Which third goes to which winner depends on *which combination of groups* supplies the eight thirds — C(12,8) = **495 possible combinations**, each mapped to a unique assignment in an **annex to the official regulations** (reported as Annex C; mirrored at https://en.wikipedia.org/wiki/Template:2026_FIFA_World_Cup_third-place_table and reflected in https://en.wikipedia.org/wiki/2026_FIFA_World_Cup_knockout_stage). Structure: one row per qualifying combination, eight columns (one per third-receiving winner), with a third never meeting its own group's winner (consistent with the published candidate sets — 1A faces a third from {C,E,F,H,I}, 1D from {B,E,F,I,J}, 1L from {E,H,I,J,K}; see Chapter 5 §6). **Hard-code the official annex table; do not improvise** — the assignment is not "best third to weakest winner," and path effects move outright prices by full points (Chapter 4 §4). The last two matches in each group kick off **simultaneously** (six final-round games per day, June 24–27), so the third-place table resolves in real-time cascades — a classic source of in-play futures mispricing in the 30 minutes after each simultaneous pair ends.

---

## 2. Discipline and suspensions — who can miss which round

### 2.1 Yellow-card accumulation and the two wipe points (changed from 2022)

- **Two cautions in different matches = automatic one-match suspension** (two in one match = sending-off, same one-match ban).
- **NEW for 2026 — two "clean slate" wipes:** single pending yellows are **cancelled after the group stage AND again after the quarter-finals**. Confirmed by the FIFA Bureau of the Council amendment to the regulations (https://inside.fifa.com/news/council-update-regulations-world-cup-2026) and reported by Al Jazeera (April 29, 2026: https://www.aljazeera.com/sports/2026/4/29/fifa-confirms-new-world-cup-rule-on-yellow-cards-to-reduce-suspensions), NBC Sports (https://www.nbcsports.com/soccer/news/2026-world-cup-yellow-card-rules-clean-slate-deadline) and FOX (https://www.foxsports.com/stories/soccer/world-cup-2026-yellow-red-card-accumulation). In 2022 there was a single wipe, after the QFs.

**Accumulation windows are therefore: (i) MD1–MD3; (ii) R32 → R16 → QF; (iii) SF onward.** Consequences:

- A booking on MD1/MD2 creates genuine MD3 suspension/rotation risk — but **nobody carries a group-stage yellow into the R32**.
- **Semi-final risk:** a player misses the SF only by collecting yellows in **two of the three matches R32–QF** (or a QF red). At ~4–4.5 cautions/match, key defensive midfielders/fullbacks on deep runs hit this window often — track per-player caution states from June 28.
- After the QF wipe, **missing the final via accumulation is essentially impossible** (two yellows in the SF itself = red anyway). Only a SF red rules a player out of the final.
- Suspended players cannot be replaced in the squad; accumulation bans are **not appealable**; cautions stand except mistaken identity (now also correctable in-match by VAR — §5).

### 2.2 Red cards, extensions, carry-over, appeals

- Direct or indirect red = **automatic minimum one-match suspension**; the **FIFA Disciplinary Committee can extend** it for serious offences (violent conduct, spitting, discriminatory abuse) — bans of 2–3+ matches are precedented (e.g., extended bans reviewed at https://www.goal.com/en/news/red-card-rules-fifa-world-cup/blt3f3b3dbd12a46a1a).
- **Carry-over INTO the finals** (regs language via https://www.sportsmole.co.uk/football/world-cup-2026/feature/how-do-world-cup-suspensions-work-yellow-and-red-card-rules-explained_598737.html): single qualifying yellows, pending accumulation bans, indirect reds and DOGSO direct reds from the preliminary competition are **not** carried over; **other pending red-card suspensions (e.g., violent conduct) are**.
- **Carry-over OUT:** a suspension not fully served at the World Cup **carries to the national team's next official match** — it does not evaporate with elimination (FIFA Disciplinary Code; same source).
- **Appeals:** on-field refereeing decisions are final (Laws of the Game, Law 5); teams can ask the Disciplinary Committee to quash a wrongly-issued red (mistaken identity, clear error) — the only realistic route to a star avoiding a ban. Decisions appealable per FDC timelines (10 days to request a motivated decision — see the SAFA case at https://inside.fifa.com/news/disciplinary-committee-sanctions-south-african-football-association).
- **New conduct reds in force at this WC** (§5): covering the mouth during confrontations and walking off the pitch in protest are straight reds — novel card-prop and red-card-market inputs with zero historical base rate.

---

## 3. Squads and replacements

- **Provisional release list:** 35–55 players, submitted by **May 11, 2026**; **final list: 23–26 players (minimum 3 goalkeepers)** by **June 1, 2026** (https://en.wikipedia.org/wiki/2026_FIFA_World_Cup_squads; https://www.goal.com/en/lists/world-cup-2026-final-squads-rules-deadline-explained/blt90ccbb1d7731e97e).
- **Injury/illness replacement until 24 hours before the team's FIRST match** — replacements must come from the provisional list, and the incapacity must be certified by both the team doctor and the FIFA General Medical Officer (https://www.moroccoworldnews.com/2026/05/304923/fifa-confirms-rules-for-player-replacements-at-2026-world-cup/). This is how Netherlands swapped Timber→Geertruida (Chapter 5). **Replaced players cannot return.** Until each team's opener, squad lists are soft — re-verify before locking any futures/props.
- **Goalkeeper exception:** GKs may be replaced for serious incapacity **throughout the tournament** (the standard FIFA formulation is "up to 24 hours before the team's next match"; secondary sources confirm the whole-tournament scope: https://www.moroccoworldnews.com/2026/05/304923/fifa-confirms-rules-for-player-replacements-at-2026-world-cup/, https://www.aljazeera.com/sports/2026/5/8/world-cup-2026-squad-deadlines-key-dates-team-lists-final-announcements).
- **Concussion substitutions:** permanent concussion subs are permitted **in addition to** the normal quota; when used, the opponent also receives an extra slot (https://worldcupranking.com/blog/world-cup-2026-substitution-rules/).
- **Outbreak/force majeure:** no public COVID-style clause (minimum-player threshold to play, rescheduling trigger) surfaced for 2026 — unlike Qatar 2022's COVID annex. The regulations give FIFA blanket authority over "all operational and competition matters" and any cases not provided for, decisions final and binding (regs final provisions; see also FIFA's discretion noted at https://content.shurzy.com/post/world-cup-replay-rules-and-policies-explained). Treat any outbreak scenario as FIFA-discretion risk, not rule-determined — flagged unverified.

---

## 4. Match procedures

- **Group stage: 90 minutes, draws stand.** **From the R32 onward: two 15-minute extra-time periods, then kicks from the penalty mark.** **No golden or silver goal** — abolished since 2004; full 30 minutes are always played (https://www.nbcsports.com/soccer/news/2026-world-cup-overtime-extra-time-penalty-kick-rules; https://en.wikipedia.org/wiki/Golden_goal).
- **Penalty shootout procedure** (IFAB Law 10, https://www.theifab.com/laws/latest/determining-the-outcome-of-a-match/): the **referee tosses a coin to choose the goal** at which kicks are taken (changeable only for safety/unusable goal or pitch); a **second coin toss** — the winning team **chooses whether to kick first or second**. Kicks alternate **ABAB** (the 2017–18 "ABBA" trial is dead); five each, then sudden death. Only players on the pitch (or temporarily off with permission) at the final whistle may participate; teams with more players **"reduce to equate"**; the GK may be replaced during kicks only if injured and a sub slot remains; every eligible player must kick before anyone kicks twice. Chapter 4's 50/50 shootout model stands — first-kicker advantage failed replication.
- **Substitutions:** **5 per team in 90 minutes across a maximum of 3 windows** (half-time doesn't count as a window) **+ 1 additional sub and 1 additional window in extra time**; concussion subs separate (https://worldcupranking.com/blog/world-cup-2026-substitution-rules/).
- **The 10-second substitution exit rule (new):** a substituted player has **10 seconds to leave the pitch at the nearest boundary point** once the board is shown; if he dawdles, his replacement enters only **at the first stoppage after one minute has elapsed** following the restart — a team can be briefly down to 10 (https://www.skysports.com/football/news/12098/13549645/world-cup-ifab-confirm-new-var-powers-10-second-substitutions-and-tactical-timeout-ban-in-major-rule-changes; https://www.espn.com/soccer/story/_/id/48954511/world-cup-new-rules-explained-var-corners-no-gk-outs-red-card-covering-your-mouth).
- **Hydration breaks (Dec 2025 policy):** **~3 minutes midway through each half** (around minutes 22 and 67), referee-controlled, whistle-to-whistle — **mandatory regardless of weather**, replacing the old WBGT-triggered cooling breaks (https://kestrelinstruments.com/blog/fifas-hydration-break-rule-explained-what-it-means-for-the-2026-world-cup; https://www.espn.com/soccer/story/_/id/48954511/world-cup-new-rules-explained-var-corners-no-gk-outs-red-card-covering-your-mouth; https://www.thedailystar.net/sports/sports-special/fifa-world-cup-2026/news/var-hydration-breaks-new-rules-the-world-cup-2026-4181816). Whether roofed/air-conditioned venues are exempt is undocumented — flagged. Effects: +6 minutes of baseline stoppage (more late-goal exposure), two predictable in-play "timeout" liquidity points per match, and de facto extra coaching windows.
- **Half-time: 15 minutes** (IFAB Law 7, https://www.theifab.com/laws/latest/the-duration-of-the-match/), with a ≤1-minute drinks break at the interval of extra time. **Exception — the final (July 19, MetLife):** half-time extended to **~24 minutes** for the first-ever WC halftime show (11–15 minute performance; Chris Martin-curated, Madonna/Shakira/BTS reported) — https://www.fourfourtwo.com/competition/world-cup-2026-will-prolong-half-time-interval-for-extravagant-show-acts-announced, https://sports.yahoo.com/articles/fifa-plans-extended-world-cup-194828531.html. For the final only: longer market suspension, cold-restart injury/slow-start risk in the first minutes of the second half — second-half-goal-timing props are calibrated on 15-minute breaks.

---

## 5. The new IFAB/VAR regime in force at this World Cup

Base text: **Laws of the Game 2025/26** (in force since July 1, 2025: https://downloads.theifab.com/downloads/changes-to-the-laws-of-the-game-2025-26?l=en) plus IFAB/FIFA changes confirmed for the tournament (Sky: https://www.skysports.com/football/news/12098/13549645/world-cup-ifab-confirm-new-var-powers-10-second-substitutions-and-tactical-timeout-ban-in-major-rule-changes; ESPN: https://www.espn.com/soccer/story/_/id/48954511/world-cup-new-rules-explained-var-corners-no-gk-outs-red-card-covering-your-mouth; Al Jazeera: https://www.aljazeera.com/sports/2026/6/1/which-football-rule-changes-will-be-implemented-during-the-world-cup; NBC: https://www.nbcsports.com/soccer/news/rule-changes-confirmed-for-2026-world-cup-as-ifab-alters-var-cracks-down-on-subs-and-timeouts; TNT: https://www.tntsports.co.uk/football/world-cup/2026/rule-changes-var-mouth-covering-injured-players_sto23307639/story.shtml).

1. **8-second goalkeeper rule (Law 12, since 2025/26):** GK controlling the ball with hands for more than 8 seconds concedes a **corner kick** (was an indirect free kick pre-2025); referee signals the final 5 seconds with a raised-hand countdown. Already produced corners in club football 2025/26. **Corner-count markets:** books pricing corners off pre-2025 baselines under-count; late-game leaders protecting a lead now leak corners instead of wasting time.
2. **Five-second restart countdowns (new at this WC):** visible referee countdowns for **throw-ins and goal kicks** — throw-in not taken in time → **possession to the opponent**; delayed goal kick → **corner to the opponent**. Novel, zero base rate — corner/possession props have structural drift upward; time-wasting from minute 80 is now mechanically punished.
3. **VAR scope expanded (new at this WC):** VAR may now intervene for (a) **wrongly-awarded second yellow cards** (only to rescind an incorrect second booking — it will not recommend a missed one), (b) **mistaken identity** on any card, (c) **incorrectly awarded corners**, but only where the error is obvious and correctable **without delaying the restart**, and (d) **fouls committed before the ball is in play at set-pieces** (e.g., blocking before a corner) → on-field review, discipline, restart retaken. Baseline VAR scope (goals, penalties, straight reds, mistaken identity) continues. Expect slightly fewer "soft" second-yellow dismissals standing — a marginal deflator on red-card props and on 10-man-team live swings.
4. **Captain-only communication:** only the captain may approach the referee in major incidents (IFAB "captain-only" approach, applied at FIFA tournaments since 2024; https://citisportsonline.com/2026/06/2026-world-cup-goalkeepers-protests-and-var-in-focus-as-ifab-announces-major-rule-changes/). Mass-confrontation yellows down; dissent yellows concentrated on captains — relevant for player-card props.
5. **"Tactical timeout" ban:** during goalkeeper injury treatment, outfield players are barred from gathering at the technical area for instructions; an outfield player treated on the pitch must **stay off for one minute** after restart (deterring fake-injury timeouts) (Sky/NBC links above).
6. **Conduct reds:** covering the mouth in confrontations = red; leaving the pitch in protest = red (staff inciting it sanctioned; **a team causing a match to be abandoned forfeits it** — post-AFCON-final-2025 rule) (ESPN/Al Jazeera links above).
7. **Semi-automated offside (SAOT)** with the adidas **Trionda** connected ball (500 Hz IMU sensor) — faster, earlier disallowed-goal calls (https://www.aljazeera.com/sports/2026/6/6/fifa-world-cup-2026-what-is-new-sensor-match-ball-ai-player-avatar). One report says the revamped system signals only when a player is **>10 cm offside** (a tolerance margin) — single-source, **unverified**; if true it slightly raises marginal-goal survival rates. Referee body-cams are also in use for broadcast.
8. **Not in force:** no challenge/coach's-review system, no temporary dismissals ("sin bins"), no shootout format change.

---

## 6. Abandonment, weather and force majeure — and how books settle it

**This is the highest-leverage "boring" section of the chapter: US summer = thunderstorms, and the protocols are strict.**

- **Lightning protocol:** play is suspended when lightning is detected **within 8 miles** of the stadium; a **30-minute countdown** starts and **resets with every new strike** inside the radius (https://www.cbssports.com/soccer/news/how-summer-weather-and-lightning-delays-could-disrupt-fifa-world-cup/; https://www.themirror.com/sport/soccer/world-cup-thunderstorm-delays-fifa-1869678). Precedent — Club World Cup 2025, same venues/protocol: multiple matches suspended; **Chelsea–Benfica stopped in the 86th minute for 1h53, total match time >4 hours** (CBS link above). Five 2026 venues are roofed (Atlanta, Dallas, Houston, Vancouver, Toronto); the other 11, including MetLife (final), Miami, Philadelphia, Kansas City, are exposed.
- **Suspended/abandoned matches:** if a match cannot be completed, it **resumes from the minute of interruption with the same score and match state** (same lineups/cards/subs context) rather than being replayed (regs-derived; https://content.shurzy.com/post/world-cup-replay-rules-and-policies-explained). There is **no fixed maximum delay** in the regulations before abandonment — FIFA decides case-by-case (same source). A team *causing* an abandonment forfeits (§5). FIFA additionally reserves broad rights over dates, kick-off times and venues (general regulatory powers; any venue change would be a FIFA emergency decision, not a defined procedure).
- **Heat:** FIFA's regulations contemplate match-delay/postponement consideration only above **32°C WBGT**; **FIFPRO advocates 28°C WBGT** as the delay/postpone threshold and 6-minute cooling breaks (https://theconversation.com/world-cup-2026-why-moving-games-to-evenings-isnt-enough-to-tackle-extreme-heat-problem-283410; https://time.com/7303535/extreme-heat-fifa-world-cup-2026/). Projections: ~26 of 104 matches ≥26°C WBGT, ~5 at ≥28°C (https://www.aljazeera.com/sports/2026/5/14/fifa-warned-gruelling-heat-could-impact-quarter-of-world-cup-games; https://www.bloomberg.com/graphics/2026-fifa-world-cup-games-weather/). Expect the mandatory 3-minute breaks (§4) plus ad-hoc measures — and model heat as a totals/intensity variable (Chapter 1), not an abandonment variable.

**Bookmaker settlement — the rules that actually decide your P&L:**

- **90-minute rule:** all standard match markets settle on **90 minutes plus stoppage time only** — extra time and penalties do not count (bet365 soccer rules: https://help.bet365.com/s/en/sportsrules/soccer/result-event-half-time). "To qualify/advance" and outright markets include ET/pens. The R32+ gap between "match odds" and "to advance" prices is structural (20–30% of knockouts reach ET — Chapter 4).
- **Abandoned matches:** bets **void except markets already unconditionally determined** at abandonment (first goalscorer stands if a goal was scored; over 1.5 stands if 2+ goals already in; match result voids) — https://help.bet365.com/s/en/sportsrules/soccer/abandoned-matches.
- **Interrupted/resumed:** bet365 — if resumed from the point of interruption and **finished within 48 hours of the original kick-off, ALL bets stand**; otherwise treated as abandoned (https://help.bet365.com/s/en/sportsrules/soccer/interrupted-matches). FanDuel applies the same 48-hour completion window, postponed games void unless played within it (https://www.fanduel.com/rules; https://support.fanduel.com/s/article/Weather-cancellation-and-postponement-rules); DraftKings publishes equivalent rules (https://sportsbook.draftkings.com/help/sport-rules/soccer). **Interplay:** FIFA's resume-from-the-minute policy + the compressed calendar means most weather suspensions complete same-night or next-day → **bets stand on the eventual result**; do not assume a void. A pre-suspension live position (leading at 86', as in Chelsea–Benfica) rides through a 2-hour delay — and momentum demonstrably resets after long stoppages: a tradable, repeatable spot.
- **Futures:** tournament outrights stand through rescheduling — FanDuel keeps bets active if the governing body reschedules within 90 days (https://www.fanduel.com/rules). Futures only die with official cancellation.
- **House rules vary by book and state** — re-read your specific book's soccer rules before the group stage; the 48-hour convention is common but not universal.

---

## 7. Protests, ineligible players, forfeits, doping

- **Forfeit = 3-0 awarded loss** (or the actual scoreline if worse for the offending team), per the FIFA Disciplinary Code. Fielding an ineligible or suspended player is the canonical trigger (FDC Art. 19 + competition regs).
- **Live precedents from this cycle:** FIFA declared **South Africa 0-3 Lesotho** (originally won 2-0) for fielding **Teboho Mokoena** under an unserved accumulation ban — FDC Art. 19 + Art. 14 of the WC26 Preliminary Competition Regulations, plus a CHF 10,000 fine (Sept 29, 2025: https://inside.fifa.com/news/disciplinary-committee-sanctions-south-african-football-association; https://www.espn.com/soccer/story/_/id/46423108/south-africa-stripped-win-wcq-ineligible-player). **Equatorial Guinea** had two qualifiers forfeited over **Emilio Nsue's** ineligibility, upheld at CAS (https://www.premiumtimesng.com/news/top-news/821645-world-cup-qualifier-equatorial-guinea-punished-south-africa-untouched-in-fifa-disciplinary-update.html). No modern finals-stage forfeit exists — and books settle match bets on the pitch result (a post-hoc 3-0 award does not resettle them), while group/outright futures follow the official classification. Know which your position references.
- **Protests:** referee decisions are final and cannot be protested (Law 5 / regs). Eligibility/procedural protests go through the FIFA general secretariat with short deadlines (reported ~2 hours post-match for match-incident protests with written follow-up — the exact 2026 article number is unverified; lineage from prior WC regs is 24-hour written confirmation; see https://worldcuplocaltime.com/fifa-world-cup-protest-appeals-process/). Parties have 10 days to request motivated FDC decisions, then appeal windows (FDC).
- **Doping:** the largest anti-doping program in WC history — FIFA testing authority with USADA, Sport Integrity Canada and MEX-NADO conducting pre-tournament out-of-competition testing and matchday in-competition support; WADA 2026 Prohibited List in force (https://inside.fifa.com/legal/news/fifa-teams-up-with-anti-doping-organisations-in-fifa-world-cup-2026-tm-host-countries; https://www.usada.org/announcement/fifa-expands-usada-partnership/). A positive A-sample = provisional suspension — a low-probability, high-impact squad shock channel; futures on single-star teams carry this tail.

---

## 8. Everything else in the regulations with betting relevance

- **Prize money (FIFA Council, Dec 5, 2025, Washington DC):** record **$727M total**, **$655M as performance prize money**: champion **$50M**, runner-up **$33M**, third **$29M**, fourth **$27M**, QF losers (5th–8th) **$19M**, R16 exit **$15M**, R32 exit **$11M**, group exit **$9M**, plus $1.5M preparation per team (https://inside.fifa.com/media-releases/council-approves-record-breaking-world-cup-2026-financial-contribution; https://www.aljazeera.com/sports/2025/12/17/fifa-world-cup-2026-winners-prize-money-doubles-to-50m; https://www.givemesport.com/world-cup-2026-prize-money/). **Incentive cliffs:** group→R32 +$2M, R32→R16 +$4M, R16→QF +$4M, **QF→SF +$8M minimum**, SF→title +$17M. For small federations the $4M steps are transformative; the QF→SF cliff means nobody eases off in a quarter-final. Payment is per-round-reached, not cumulative — the third-place playoff still carries a $2M delta (29 vs 27), and it's historically the highest-scoring fixture (Chapter 4: overs).
- **The final's ~24-minute half-time** (§4) — unique settlement/physiology quirk of match 104.
- **Third-place play-off retained** (July 18, the eve of the final; https://en.wikipedia.org/wiki/2026_FIFA_World_Cup_knockout_stage).
- **Stadium Code of Conduct** (https://digitalhub.fifa.com/m/50ebae81c412b7d5/original/FIFA-World-Cup-2026-Stadium-Code-of-Conduct.pdf) — crowd-management provisions; no direct betting effect.
- **Squad-news cadence is regulation-driven:** May 11 (provisional lists) → June 1 (final lists) → rolling 24h-pre-opener replacement deadlines (June 10–16) → GK replacements possible all tournament. Every one of these is a scheduled information event; the last pre-opener window closes for the first matches **June 10–11** — final futures re-check tonight/tomorrow.
- **Mandatory hydration breaks double as coaching windows** (§4) — slightly reduces the live-betting edge from spotting tactical disarray, since coaches get whistle-to-whistle access at ~22' and ~67' in every match.

---

## Key takeaways for the betting playbook

1. **TIEBREAKER ORDER (resolved, Art. 13, Regulations for the FIFA World Cup 26):** points → h2h points → h2h GD → h2h goals → (recursive re-application among still-tied teams) → overall GD → overall goals → team conduct score (−1/−3/−4/−5 card points) → FIFA ranking. **Head-to-head FIRST — Chapter 4's simulator spec is correct; fix Chapter 5 §6 before any MD3 modeling.**
2. **Third-place ranking is overall-numbers-based** (points → GD → goals → conduct → ranking) with **8 of 12 advancing** — be long "to reach R32" on mid-tier sides; expect MD3 goal-chasing for GD across all six simultaneous-kickoff days (June 24–27), which fattens late-game totals.
3. **Hard-code Annex C's 495-combination third-place allocation** (winners of A, B, D, E, G, I, K, L receive thirds; never own group). Bracket-path randomness moves outrights by full points — never price futures off independent match chains.
4. **Yellow wipes happen TWICE (new): after the group stage and after the QFs.** SF-accumulation risk exists only for players booked in two of R32/R16/QF; **no one can miss the final by accumulation** — only by a SF red.
5. **Two yellows across matches = one-match ban; red = minimum one match, extendable by the Disciplinary Committee; unserved bans carry to the nation's next official match** (they survive elimination and the tournament's end).
6. **Squad lists are soft until 24h before each team's opener** (injury replacements from the 35–55 list; GKs replaceable all tournament; concussion subs extra). Re-verify lineups before every futures lock this week.
7. **Knockouts (R32 on): 30 minutes ET then ABAB shootout — no golden goal; ~50/50 shootout; the toss winner chooses kick order; 5 subs/3 windows + 1 sub/1 window in ET.** Keep the 90-minute vs to-advance price gap front of mind: ~20–30% of KOs reach ET.
8. **The 90-minute rule governs match markets; ET/pens settle only "to qualify"/outrights.** Never confuse the two on R32+ slips.
9. **Lightning protocol (8-mile radius, resetting 30-minute countdown) makes multi-hour suspensions likely at the 11 open-air venues** — CWC 2025 saw six delays incl. Chelsea–Benfica's 1h53 at the 86th minute. FIFA resumes from the minute of interruption; **books keep bets alive if play finishes within ~48h of original KO** (bet365/FanDuel) — assume your live position rides through the storm, and trade the documented post-resumption momentum reset.
10. **Abandoned (not resumed) matches: bets void except already-determined markets; postponed: void and refunded; futures survive rescheduling** (within 90 days at FanDuel). Read your book's house rules now, not after the first storm.
11. **Mandatory 3-minute hydration breaks ~22' and ~67' in every match** (weather-independent): more stoppage time (late-goal exposure), two scheduled in-play liquidity/timeout points, and free coaching windows that dampen tactical-chaos edges. The **final's half-time is ~24 minutes** (halftime show) — unique to match 104.
12. **New live-rules with zero base rates reshape props:** GK 8-second rule → corners; 5-second throw-in/goal-kick countdowns → possession/corner sanctions; 10-second sub-exit rule; captain-only dissent; mouth-covering and walk-off reds. Corner and card markets calibrated on 2022/2024 data are stale — early-tournament prop lines are the softest.
13. **VAR now fixes wrong second yellows, mistaken identity and wrong corners (without delaying restarts) and polices pre-restart fouls** — marginally fewer wrongful dismissals standing; SAOT + connected Trionda ball speeds offside calls (reported 10cm tolerance unverified).
14. **Ineligible-player forfeits (3-0) are live, recent precedent** (South Africa/Mokoena Sept 2025; Equatorial Guinea/Nsue) — pitch-result settlement vs official-classification settlement can diverge; know which your market references.
15. **Prize money creates one real cliff — QF→SF is +$8M minimum** ($19M → $27M+); R32/R16 steps of $2–4M are meaningful for small federations. No tanking incentives anywhere in the structure; motivation edges live in group-finale permutations, not money.

> **Historical document.** Retained for its original version/experiment; its recommendations and missing-feature claims may be superseded. For current v0.909 rules, decisions and next work, start with [THREAD_HANDOFF.md](THREAD_HANDOFF.md). Historical results below are not relabelled as current validation.

# Stockade and town expansion — experiment 012, v0.902

Implemented locally; v0.901 remains the published GitHub version.

## Provisional rules used

The special stockade needs six wood. A house may deliver one wood per action for one influence, subject to the ordinary influence cap. Progress is persistent and consumes the token; the finished wall has no production, ownership or ordinary building plot.

At round closure, before the next round's refresh and arrivals, the town consumes only unreserved public wood. It first fills the wall's remaining requirement, then the chapel's one missing wood if applicable. It awards no house income for automatic collection. Active reservations, private stores, export-backing wood and previously consumed project contributions are excluded. Surplus persists once known tasks have their wood. This is deliberately a finite task queue, not an unlimited wood sink.

After the wall, up to two vacant rural plots may each become urban for one stone and one pop. Occupied plots cannot convert. Both conversions must finish before the outer land opens. Four claims then add two forest and two field plots to shared town capacity: each action consumes one pop and awards its actor one prestige. Claims are finite and confer no private ownership. Capacities change from urban 6 / rural 4, through urban 8 / rural 2, to urban 8 / rural 6. Existing urban construction uses the same free-plot counters.

Prices, six-wood size, two-plus-two rural split and the requirement to finish both conversions before claims are implementation assumptions for testing, not settled balance decisions. No new wall art is included: progress and actions appear in Links, and the header shows dynamic land budgets.

## Matched games

Seeds 1, 7 and 42; manual versus preset lumber link; automatic collection enabled versus voluntary-only control. All twelve use partial home upgrades and identical AI. Forty playable rounds, ending at the refresh into round 41. The sweep toggle includes both wall and chapel automatic wood collection, so the comparison does not isolate wall collection from chapel assistance.

| Seed | Lumber | Collection | Wall round | All homes + industries | Four claims round | Chapel round |
|---|---|---|---:|---:|---:|---:|
| 1 | manual | voluntary | 20 | unfinished | 30 | 26 |
| 1 | manual | sweep | 10 | 27 | 34 | unfinished |
| 1 | linked | voluntary | 18 | 21 | 33 | unfinished |
| 1 | linked | sweep | 2 | 23 | 29 | 35 |
| 7 | manual | voluntary | 20 | 33 | unfinished | 29 |
| 7 | manual | sweep | 10 | unfinished | unfinished | 33 |
| 7 | linked | voluntary | 20 | 28 | 37 | 40 |
| 7 | linked | sweep | 1 | 23 | 29 | 35 |
| 42 | manual | voluntary | 20 | 27 | 36 | 40 |
| 42 | manual | sweep | 10 | unfinished | 37 | 27 |
| 42 | linked | voluntary | 18 | 31 | 28 | 24 |
| 42 | linked | sweep | 1 | 32 | 35 | 28 |

The wall finished in all twelve towns. Automatic collection accelerated it to rounds 1–10 versus 18–20 for voluntary deliveries. In sweep games the town supplied 2–3 of the six wall wood and all three houses still made voluntary deliveries. Full expansion finished in five of six games in each group; the chapel also finished in five of six in each group.

All household goals finished in four of six sweep games versus five of six controls. This small deterministic sample does not establish causation or balance. Early public collection changes resource availability and the sequence of decisions; it is not an unconditional economic improvement.

## Findings and discussion suggestions

1. **A real collective project now competes with private progress.** Linked lumber permits wall completion in round 1 or 2, while manual lumber takes ten rounds with collection. Decide whether this infrastructure advantage is desirable before changing the wall price.
2. **Expansion is available but lacks enough uses.** Ten towns opened the full land budget, but the new urban slots stayed vacant in these runs. Existing legal construction paths passed a fixture after expansion; these runs do not demonstrate organic demand for more buildings. Add partial new construction and a useful repeatable project before rewarding more expansion.
3. **Brick allocation still strands households.** Each of the three unfinished-home cases had paid its wood and labour and lacked its brick. Journal audit: seed 7/manual/sweep spent three bricks on town demand and three on caravan exports; seed 42/manual/sweep spent two on demand and four on exports; seed 1/manual/voluntary spent seven on exports. Two homes used one brick each in each case. These were legal competing uses, not disappearing stock. Consider a separate AI experiment on the opportunity cost of spending a brick needed by an unfinished household, without silently granting households extra protection.
4. **Gold now funds competing public works.** Conversions consume stone that could complete the chapel. Two chapels remained unfinished; stone purchase scoring considers both needs, but this does not guarantee coordination or ownership of the next usable stone. Avoid changing prices merely to make every task complete by round forty.
5. **Claims create a finite prestige opportunity.** Some claim rewards concentrate in one house; one control gave all four to Gold. Check whether the reward should compensate useful labour or encourage a race. The current hard cap prevents an infinite prestige loop.
6. **Automatic work gives up player delivery income.** Every automatically collected wall wood removes one potential one-influence delivery. This is the intended tradeoff tested here; reserved and protected wood remains safe.

The AI still prioritises its own home, then industry, then prestige. Settled houses consider stone purchases, chapel work, redevelopment and claims; wall donations are lower priority except when influence-poor with spare wood. These are explicit scores, not a general planning solver. Land contributions can benefit rivals, and no claim of optimal play is made.

## Verification

- All 4,098 decisions passed invariants and replayed exactly; all twelve saves restored exactly.
- 47 stockade checks cover payment, progression, action timing, automatic collection boundaries, export commitments, partial house progress, terrain limits, ordinary construction and expanded-land save/load.
- Existing 31 partial-project checks and 22 trade checks pass.
- The live UI ran a forty-round game through preview/execute and exact save/load, including deliveries and a conversion. Minimum measured layout: 1734 × 1028 at 1920 × 1080.
- A separate fixture executed all twelve stockade/land actions through the UI, including four claims, and saved/restored exactly. Minimum layout: 1723 × 1028.
- All 83 archived UI states and selections/previews passed the existing UI check. Minimum layout: 1713 × 1028.

These checks exercise state and layout; they are not a fresh visual-art review. Raw journals are generated locally by `tests/stockade_experiment.gd`; compact results are in `experiments/stockade/results.json`.

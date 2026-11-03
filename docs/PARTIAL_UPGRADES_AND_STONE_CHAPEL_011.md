> **Historical document.** Retained for its original version/experiment; its recommendations and missing-feature claims may be superseded. For current v0.909 rules, decisions and next work, start with [THREAD_HANDOFF.md](THREAD_HANDOFF.md). Historical results below are not relabelled as current validation.

# Partial home upgrades and stone chapel · v0.901 · experiment 011

Version numbering now advances within 0.9xx: 0.901, 0.902, and so on. This is local work; nothing was uploaded.

## Implemented scope

This increment performs the previously proposed first comparison of partial home upgrades, adding the stone/chapel task in both arms. Twelve matched games: three seeds (1, 7, 42), two timber starts (manual or preset link), and atomic versus partial home-upgrade rules. The chapel can be upgraded in stages in both groups. Other prices, trade offers, house goals and AI rules are matched between those groups.

A contribution is a normal action, consuming its goods immediately and recording paid quantities on an upgrade project. It may contribute one token or an affordable bundle of missing goods. The relevant card goes to discard and cycles normally. Progress persists across rounds and saves, cannot be purchased with influence, and is not counted in private stockpile capacity because its tokens have been consumed. Future contributions pay only what remains. Full payment in one action remains possible if all missing inputs are available.

An incomplete upgrade retains the old building functionality. New outputs unlock only at completion. An automated home may begin an off-card upgrade; its partial-upgrade card then cycles while the baseline contract continues operating. Contract establishment/cancellation preserves that project card and paid progress, without duplicating the card. Finishing an automated home's upgrade keeps the previously established incremental-production model.

Consumed labour frees a slot in the existing finite pop-token pool. Other resources follow their existing production/source-and-sink rules; no new global token cap for wood, brick or stone has been invented.

The wider design of partially built new buildings with reserved plots, partial contract/supply establishment, and full-price forced overbuilding remains recorded for subsequent implementation. No new plot-reservation or forced-takeover mechanism is claimed by these upgrade tests. Owned buildings remain protected under the existing rules.

## Caravan stone and chapel

The caravan offers two stone per visit, shared across all houses, at one gold per stone. Stone is a physical good in public/reserved/private circulation, with normal one-action purchase priority and the three-token stockpile limit. The caravan still buys one brick for one gold per visit and sells prestige for two gold. Stone purchases consume gold and are tracked separately from prestige purchases.

Chapel upgrade costs a provisional two stone, one wood and one pop. Contributions may come from different houses. The chapel remains unownable and on its free special plot. It stays at two influence per activation while incomplete; completed output is exactly three, not four or five. Its existing lagging-house eligibility condition remains. The AI pursues chapel contributions only after its own brick home and industry goals are met; other houses may still be lagging. Legal player actions are not gated by that preference. There is no extra prestige award for completing the chapel.

The completed chapel is a shared benefit and a post-foundation gold/material sink, not a new hard victory condition. It can finish before the final lagging house, which may then use the improved catch-up output.

## Matched outcomes

All runs execute 40 action rounds and the refresh into round 41. Housing plus industry completion remains a recorded milestone while play continues.

| Seed | Timber | All goals, atomic home upgrades | All goals, partial home upgrades | Chapel complete, partial group |
|---|---|---|---:|---:|
| 1 | Manual start | 32 | 27 | 24 |
| 1 | Preset lumber | 18 | 13 | 31 |
| 7 | Manual start | 35 | 23 | 20 |
| 7 | Preset lumber | 20 | 27 | 20 |
| 42 | Manual start | unfinished | 30 | 18 |
| 42 | Preset lumber | unfinished | 14 | 21 |

Atomic controls completed both house goals in four of six towns; partial-upgrade towns completed in all six. All eighteen houses in the partial group used multiple contributions to finish their home upgrades. Completion ranged from rounds 13–30. One matched town was slower (20 → 27), showing the feature is not an unconditional speed bonus. Contributions require actions and card cycles, while protecting already-paid progress from competing resource demand.

Both seed-42 atomic cases remained unfinished by the cutoff; their partial counterparts finished in rounds 30 and 14. The previously observed reserved-brick competition can still occur before a contribution is made. The improvement is that a legally contributed brick is already part of the upgrade, rather than a token someone else may acquire for influence.

Every chapel completed: rounds 15–31 across all twelve runs, and 18–31 in the partial-home group. Each town bought exactly two stone and spent two gold on them. In the six partial-home runs, the chapel was activated 62 times at the old output and 59 times at the upgraded output. Thus the new three-influence function was exercised in natural games, not only in a fixture.

## Limits and interpretation

These are small matched samples under a hand-scored policy, not proof that a general planner discovered staged construction or that the contribution rules are optimally priced. The AI explicitly prioritises consuming useful inputs into its own upgrade and uses spare post-foundation resources for the chapel. The loss of a physical token to a rival remains possible until the house gets an eligible contribution action.

One gold can now become useful stone rather than remaining an unspendable half of a prestige purchase. The two-stone stock and finite chapel requirements bound that demand. After the chapel is finished, later gold again has only the existing prestige use.

Questions for later: general partial construction and plot reservation; full-price forced overbuilding; whether particular construction stages should unlock intermediate benefits; project cancellation/refunds (none are introduced here); and pricing larger civic projects or rewards for their contributors.

## Validation

All twelve final journals replay exactly: 4,244 decisions, with no invariant failures. Every run writes a save, reads it back and restores the exact state and RNG. Early implementation failures involving deserialised numeric bundles and automation of an active project were corrected before these final runs; none are counted as game outcomes.

31 focused checks pass: contribution consumption, progress protection, old functionality during work, exact remaining costs, serialisation, completion without double payment, card rotation, stone stock/pricing, gold accounting, chapel output exactly three, special ownership/plot rules, and progress surviving automation and cancellation. Existing trade tests (22) and priority/ownership tests (47) also pass.

The live UI executes a full seed-7 game through previews and action handlers, including nine partial contributions, two stone purchases and chapel completion, then restores an exact save. The calculated minimum is 1723 × 1028, fitting 1920 × 1080. The archived 83-state inspection/preview checks also pass. Stone is currently text-only; no stone sprite was commissioned. Building inspection shows project progress and action previews charge only missing inputs.

```sh
godot --headless --editor --import --quit
godot --headless --path . --script res://tests/project_checks.gd
godot --headless --path . --script res://tests/project_experiment.gd
godot --headless --path . --script res://tests/contract_ui_check.gd
```

Results, saves, snapshots, decisions and contribution events are in `experiments/projects/`. New live games enable partial home upgrades and the chapel task.

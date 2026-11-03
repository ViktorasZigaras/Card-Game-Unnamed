> **Historical document.** Retained for its original version/experiment; its recommendations and missing-feature claims may be superseded. For current v0.909 rules, decisions and next work, start with [THREAD_HANDOFF.md](THREAD_HANDOFF.md). Historical results below are not relabelled as current validation.

# Initial test report — 2026-10-31

Godot 4.5.1 stable, Linux, headless. Prototype 0.1.0.

## Results

- 307 regression assertions passed; zero failures.
- 40 seeded games: seeds 0–19 in each of river valley and northern woodland.
- 60 rounds per game: 2,400 completed rounds, 47,292 accepted actions/decisions.
- Resource/coin accounting, contract escrow, storage, ownership, terrain totals, and persistent card identity checked after every batch action; no violations.
- Every implemented action category occurred in the batch.
- Actual JSON save/load: 100 subsequent AI decisions matched and every resulting state matched.
- Regression journal replay passed. Separate main-scene smoke run: seed 907, river valley, 30 rounds, 625 recorded decisions replayed with exact state agreement.
- Inspector CLI successfully selected decision 25; Python tools compiled.

| Action | Batch count |
|---|---:|
| Activate | 4,519 |
| Buy ownership | 3,165 |
| Construct | 140 |
| Accept contract | 773 |
| Buy market good | 6,219 |
| Sell market good | 10,211 |
| Pass | 7,200 |
| Sell ownership | 3,013 |
| Upgrade | 340 |
| Work | 11,712 |

## Observations and next experiments

All river-valley games reached 10 built buildings; northern-woodland games reached 7. The woodland profile's one field and one clay site are occupied by initial producers, preventing extra farms/clay workings. This demonstrates a real locale constraint, though it needs design review rather than acceptance as desirable balance.

Owner compensation occurred 1,229 times in river-valley games and 1,053 times in woodland games. Thus separation of owner and activator is exercised by actual AI play, not only a fixture.

By round 60 the bank held 0–5 coins in river-valley runs and 0–7 in woodland runs. This is an economic bottleneck. The current fallback and processing outputs draw from the same finite bank, with few reasons for houses to return money. Invariant success does not establish economic health.

Ownership churn is excessive: 3,165 purchases and 3,013 divestments. Liquidity heuristics, available work, fixed prices, and absent long-term goals can generate repeated asset cycling. The current AI is an explainable rules exerciser, not a convincing economic planner. Candidate next tests: portfolio commitment/cooldowns, explicit investment goals, better comparison against passing, alternate income/coin circulation, and whether activation should consume an entire action budget differently.

The six-action limit guarantees rounds finish; that is not evidence that the underlying economy avoids strategic deadlocks. No victory objective or population consumption exists, so these runs measure mechanical progression and diagnostics only. Logs should guide the next design discussion before tuning around an unapproved win condition.

## Corrections made during verification

JSON converts numbers and sorts dictionary keys. Save/load initially changed action tie order and caused textual state comparisons to fail. Legal candidate generation now sorts dictionary-derived keys, state comparison normalizes numeric serialization, and the RNG's 64-bit state is stored as a string. These changes passed continued-play and replay tests.

## Evidence

`evidence/batch_results.json` contains per-game summaries and aggregates; `evidence/test_output.txt` contains the successful regression output. `evidence/seed907/` contains a complete short investigative run: decisions, final save, and summary. Generated working runs and Godot import caches are excluded from the source archive. Evidence is retained deliberately as a reproducible baseline.

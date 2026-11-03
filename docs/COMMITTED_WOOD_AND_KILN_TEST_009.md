> **Historical document.** Retained for its original version/experiment; its recommendations and missing-feature claims may be superseded. For current v0.909 rules, decisions and next work, start with [THREAD_HANDOFF.md](THREAD_HANDOFF.md). Historical results below are not relabelled as current validation.

# Committed export wood and the public kiln · experiment 009 · v0.85

Six matched games: seeds 1, 7 and 42, each with permanently backed clay import and either no kiln option or a buildable kiln. All six start with manual timber, so the paired difference is kiln availability, rather than the old preset-lumber intervention. Each game executes 40 action rounds and the final automatic refresh into round 41. No uploads.

## The export-capacity rule

The setup wood for the clay link becomes a permanently committed token. It is no longer recorded as consumed or included in the public pile, reservations, private stockpiles or accessible goods. Influence cannot obtain it. The token remains physically accounted for as export capacity; its setup pop remains committed as before and its setup chest is consumed. No additional wood is charged at establishment beyond the existing one.

The link still delivers its first clay immediately and one clay on each later caravan visit. Later visits require no fresh wood, so there is no wood-payment failure or retry window for this link. The standing capacity backs the supply. Cancellation returns exactly one wood to public circulation and releases the committed pop; it does not mint a new wood or return the consumed chest. Cancellation and ownership prices otherwise retain v0.75 assumptions.

This rule deliberately substitutes reversible capacity investment for recurring physical exports. In this small experiment it makes the clay schedule reliable by construction. It does not prove one wood plus one pop is a balanced long-term price for unlimited future visits.

## The kiln offer

- Construction: 2 wood + 1 pop, on the remaining ordinary urban plot; no brick prerequisite or new construction reward.
- Recipe: 1 clay + 1 pop → 1 brick.
- Starts public, receives one cycling card, and obeys existing once-per-round activation and one-token next-action priority rules. Ordinary claims and paid access remain available.
- Direct caravan brick barter remains available at one chest per brick.
- The kiln stays level 1 for this comparison. No fuel commodity, specialist, kiln contract or extra upgrade has been introduced.

A resource icon and labelled town marker represent the kiln temporarily; no new sprite artwork was commissioned. The interface exposes construction, activation, committed export wood and the changed caravan terms. Town assets now scroll so the additional building fits the minimum window.

## Results

| Seed | Variant | Upgrade rounds Blue / Red / Gold | Everyone housed | Kiln built | Local bricks | Purchased bricks |
|---|---|---|---:|---:|---:|---:|
| 1 | Capacity only | 17 / 12 / 8 | 17 | 0 | 0 | 3 |
| 1 | Kiln offered | 15 / 8 / 12 | 15 | 6 | 3 | 0 |
| 7 | Capacity only | 8 / 17 / 12 | 17 | 0 | 0 | 3 |
| 7 | Kiln offered | 14 / 11 / 9 | 14 | 6 | 3 | 0 |
| 42 | Capacity only | 8 / 17 / 12 | 17 | 0 | 0 | 3 |
| 42 | Kiln offered | 14 / 8 / 10 | 14 | 6 | 3 | 0 |

All six towns completed the housing objective. Capacity-only controls finished in round 17 for all seeds; kiln-enabled towns finished in rounds 15, 14 and 14, an average gain of 2.7 rounds in this sample.

All six received 13 clay deliveries through the observation horizon, with zero missed clay shipments. Each retained exactly one committed wood token. This should not be compared as a price-neutral fix to the earlier recurring-payment rule: the meaning and cost structure of the link changed.

Each kiln town built in round 6, with Gold paying the construction cost. Each activated the kiln three times, supplying all three housing bricks. No kiln town bought a brick; every control bought three. The AI therefore exercised both production routes across the comparison rather than merely leaving the new workshop unused.

The shared benefit and private cost remain a design question. Gold constructed every kiln in these seeds; no extra prestige reward for that service was added. A different policy or starting order could distribute that burden differently.

## Material trade-off and payback

For three additional housing bricks, excluding the common clay-link setup and house-upgrade costs:

| Route | Wood consumed | Labour spent | Clay consumed | Added urban plots |
|---|---:|---:|---:|---:|
| Make three chests and buy three bricks | 6 | 3 | 0 | 0 |
| Build kiln and fire three bricks | 2 | 4 | 3 | 1 |

The kiln saves four wood but uses one additional labour and the final urban plot. It matches the direct route's wood consumption after one brick and saves wood from the second brick onward. This is recipe-level payback, not a complete economic valuation: timing, card rotation, influence access, construction action, plot opportunity cost and the clay supply remain relevant.

There was no rival construction competing for that last plot, so the land cost was occupied but not competitively priced or strategically contested.

## AI and scope of the finding

The same new policy runs in both arms. It was explicitly taught to build a kiln once clay import exists and unfinished homes need bricks, prefer firing it when possible, and reduce carpenter/brick-barter priority when local clay is usable. The comparison tests the resulting policy and production chain. It is not evidence that a generic planner independently discovered kiln economics or chose the optimal strategy.

All three kilns stopped after three bricks: the housing milestone exhausted their immediate purpose. They remain on the map and their cards continue rotating, consuming space in both senses. No continuing brick demand, business conversion or overbuilding objective is present yet. No natural cancellation or demolition occurred in these games.

The next meaningful test is continuing shared demand for bricks after houses are finished, with a town reward for supplying it. That can establish whether the kiln becomes an ongoing enterprise. A subsequent competing urban project would give an actual reason to consider replacing a workshop whose former supply role has become unnecessary.

## Validation

- Six final journals replay exactly: 2,169 decisions, no invariant failures.
- Each game writes a save, reads it back, and restores the exact snapshot and RNG state.
- 25 focused checks pass: committed wood conservation, exclusion from influence access, no recurring wood charge, reliable visits with zero circulating wood, exact cancellation release, no double release, brick-free construction, urban plot use, card identity, kiln input/output provenance, retained direct barter and disabled control construction.
- Existing priority/ownership/incremental-upgrade suite: 47 checks pass.
- Original marketplace regression: 82 checks / 486 decisions pass.
- Archived UI validation: all 83 states and previews pass, with manual execution, AI step and exact save/load.
- Live UI executes a full seed-7 kiln-enabled game through preview/execute handlers, including kiln construction and firing, and preserves exact save/load. Calculated minimum 1590 × 1054 fits 1920 × 1080. The kiln uses a temporary marker, not a finished building sprite.

## Reproduce

```sh
godot --headless --editor --import --quit
godot --headless --path . --script res://tests/kiln_checks.gd
godot --headless --path . --script res://tests/kiln_experiment.gd -- --batch=3
godot --headless --path . --script res://tests/contract_ui_check.gd
```

Results, saves, full decisions and snapshots are under `experiments/kiln/batch_3/`. Live games offer the kiln by default. The six-game comparison is deliberately small; larger samples and different objectives are needed before fixing prices or claiming broad AI competence.

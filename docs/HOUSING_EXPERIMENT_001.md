> **Historical document.** Retained for its original version/experiment; its recommendations and missing-feature claims may be superseded. For current v0.909 rules, decisions and next work, start with [THREAD_HANDOFF.md](THREAD_HANDOFF.md). Historical results below are not relabelled as current validation.

# Experiment 001 — influence, resident labour, and housing

2026-10-31 · prototype 0.2.0 · no visible UI.

## User hypothesis

The town is not a cash economy. Influence, labour, and resources matter. Population lives in housing occupying limited plots that compete with buildings and undertakings. The town begins with huts; each house wants at least one upgraded hut, and more if able. Test several runs and observe.

## Reversible implementation assumptions

- No coins, bank, fixed cash prices, buying/selling property, or cash export contracts in this variant. The old cash simulation is retained separately, not mixed with housing state.
- Three houses, initially two people each. Three public huts, capacity two each, initially house these six people. Residents have a house affiliation independent of property ownership. A house may own a hut containing a rival's residents; residents do not change allegiance on a claim.
- Same ten terrain plots per locale, five initially occupied by industry. The three huts consume three more plots, leaving two vacant. Huts may occupy any terrain, with initial placement preferring town, then field, forest, claybank. Industry retains its terrain prerequisites. No clearing, demolition, relocation, or land expansion yet.
- Same four tangible goods: wood, grain, clay, brick. Each house starts with 1 wood, 2 grain, 1 clay, 0 brick, and 2 influence. Market starting stocks retain the baseline locale differences. Barter swaps one good for one other good held by the market; no direct house-to-house negotiation or exchange-rate differentiation yet.
- One resident provides one labour per round to their affiliated house. Labour expires and refreshes; it cannot be stored or traded. Six non-pass actions per house remains a separate test bound. With two residents, a house initially has only two labour, even though six action slots exist.
- Claim a public hut: 2 influence + 1 labour. Upgrade an owned hut: 2 wood + 1 brick + 2 influence + 2 labour. Construct another basic hut: 2 wood + 2 influence + 2 labour + one free plot. Each house retains three total property slots, shared by housing and industry.
- Hut upgrades raise capacity from two to four; they do not instantly create people. At round close, each owned hut with a spare bed can attract one resident affiliated with its owner, consuming one grain. Starting residents remain alive without food upkeep. That deliberate simplification makes this an expansion test, not a survival test.
- Each occupied upgraded hut generates 1 influence per round for its owner. Rallying support spends 1 labour to generate 1 influence. Influence is earned/spent, not transferred as money or stocked in a bank. The carpenter consumes wood to generate influence; the bakery consumes grain/wood to generate influence. Productive-building claims cost 4 influence/1 labour; construction costs 2 wood/1 brick/3 influence/2 labour; industrial upgrades cost 1 brick/3 influence/2 labour. Industrial outputs double at level 2.
- Production uses 1 labour and a revealed unused industrial card. Another house activating owned industry generates 1 influence for its owner, without a payment from the activator. Housing has no activation action; ownership/upgrade opportunities are available only when its card is revealed. All built huts join the shared cycling deck, potentially diluting production opportunities.
- AI first tries to own and upgrade a hut. Then it pursues more upgraded housing, with productive investments competing for resources, property slots, labour, and plots. Influence/resource needs derive from the next concrete step; no winning score exists.

These choices are experimental, especially growth, resident affiliation, influence income, barter ratios, initial hut placement, and housing in the shared deck.

## Run budget and method

Ten games total, each 40 rounds:

1. Six diagnostic pilot games: seeds 1, 7, 42 in both river valley and northern woodland. Policy `housing_1`.
2. Four corrected follow-up games: seeds 1 and 42 in both locales, keeping mechanics, seed, and initial conditions unchanged. Policy `housing_2`.

The pilot exposed two policy implementation mistakes: constructing/claiming additional huts could outrank finishing the first upgraded home, and the AI overvalued intermediate clay/wood, refusing to consume them to make needed bricks. Only Gold upgraded a hut in those six games, on rounds 5, 6, or 7. These were diagnosed as AI errors, not evidence that housing was economically impossible.

The policy corrections enforce the current housing step and distinguish intermediate-input usefulness from the opportunity cost of final construction supplies. They do not change housing costs, production, initial stocks, or growth. Focused regression fixtures cover these errors. Pilot policy and full journals remain available for comparison. Pilot summaries truncated by buffered writes were reconstructed from their complete aggregate; later writes close files explicitly.

## Corrected results

| Locale / seed | First upgrade: Blue / Red / Gold | Upgraded huts at round 40: Blue / Red / Gold | Population | All plots occupied by round |
|---|---|---|---:|---:|
| River valley / 1 | 6 / 10 / 5 | 2 / 1 / 1 | 16 | 10 |
| River valley / 42 | 6 / 7 / 6 | 1 / 2 / 2 | 20 | 14 |
| Northern woodland / 1 | 6 / 10 / 5 | 3 / 1 / 1 | 20 | 10 |
| Northern woodland / 42 | 6 / 7 / 6 | 2 / 1 / 2 | 20 | 8 |

All twelve house-game cases in the corrected sample met the first-upgraded-home objective by round 10. Eight of these twelve first upgrades occurred by round 6; the slowest two were Red on round 10. This is a small deterministic sample, not a probability estimate.

Only river-valley seed 1 added new industry: one clay workings. The other games spent both vacant plots on housing. The resulting town had four or five huts, all upgraded, and five or six industries. Upgrading existing huts increased population capacity without consuming additional plots.

Growth raised total population from six to sixteen or twenty, and therefore raised labour availability. The sharpest difference was woodland seed 1: Blue ended with three upgraded huts and twelve affiliated residents; Red and Gold each had one upgraded hut and four residents. Thus additional housing can support a labour advantage, but this result is also affected by policy preferences and deck order. A claim of unavoidable runaway growth would require a controlled follow-up.

By the end, houses held 22–84 influence each. With plots full, no upkeep, no new town objectives, and no new land, influence and labour outlived useful spending opportunities. The last non-pass action occurred between rounds 19 and 30; the remaining rounds contained only passes plus automatic income/growth resolution. This is saturation of the current toy scenario, not proof of a robust long-term economy.

## Verification

- Pilot: 63 assertions passed; zero detected invariant failures; 920 recorded decisions.
- Corrected sample: 51 assertions passed; zero detected invariant failures; 726 recorded decisions.
- Full journals for all ten games replayed with exact post-action state agreement.
- Actual save/load checkpoints in every game matched their next decision and next resulting state.
- Invariants after every decision cover goods/influence source-sink accounting, nonnegative stocks, plot occupation, ownership/storage limits, hut capacities, resident affiliations, and resident labour granted/spent.
- Housing fixtures verify claim costs, illegal-action atomicity, two-labour upgrade restrictions, added beds versus actual population, grain-funded arrivals, next-round labour, influence generation, and construction plot use.
- Historical cash journal replay remains compatible. No additional AI game batch was run for that check.

## Interesting questions retained for later

- Should housing growth be voluntary, and what recurring food/support cost should residents have?
- Does labour belong to a resident's house affiliation, to the owner of their housing, or to a town labour pool?
- Should housing claims/upgrades depend on shared-deck draws, and should housing dilute industrial access?
- Should a scarce plot be buildable for any housing, or should terrain conversion carry a cost?
- Is influence a personal stock, a recurring capacity, or a contested relationship? The current stock accumulates after useful spending ends.

## Reproduce and inspect

`python tools/run_checks.py --godot /path/to/Godot` reproduces the four corrected games and fixtures. `experiments/housing/results.json` contains corrected aggregates/timelines; `pilot_results.json` preserves the original six. Full journals and checkpoints are under `evidence/` and `pilot_evidence/`. Use `tools/inspect_run.py` for any individual decision and `tests/replay.gd` to verify recorded state transitions. Normal main-scene execution defaults to housing; `--experiment=cash` selects the historical baseline.

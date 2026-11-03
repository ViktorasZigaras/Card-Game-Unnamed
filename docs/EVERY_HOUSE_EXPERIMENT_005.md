> **Historical document.** Retained for its original version/experiment; its recommendations and missing-feature claims may be superseded. For current v0.909 rules, decisions and next work, start with [THREAD_HANDOFF.md](THREAD_HANDOFF.md). Historical results below are not relabelled as current validation.

# Experiment 005 — a decent house for every house · v0.65

All six unchanged-policy games completed within 40 rounds. This is a local experiment; nothing was uploaded.

## Change and controls

Completion now requires Blue, Red and Gold each to own an upgraded hut, plus an established clay contract that has delivered. The interface describes the new goal. No goods, recipes, prices, rewards, AI scores, caravan timing or resource caps were changed. Rules record the objective in saves; older snapshots without the setting retain the original one-home goal. The former experiment remains reproducible with all_houses_goal=false. Version 0.60 is preserved separately.

## Results

| Seed | Supply | Upgrade rounds Blue / Red / Gold | Completion | First-to-last gap | Missed clay shipments |
|---|---|---|---:|---:|---:|
| 1 | Manual timber | 26 / 15 / 3 | 26 | 23 | 6 |
| 1 | Lumber link | 11 / 16 / 7 | 16 | 9 | 0 |
| 7 | Manual timber | 10 / 16 / 23 | 23 | 13 | 5 |
| 7 | Lumber link | 7 / 16 / 10 | 16 | 9 | 0 |
| 42 | Manual timber | 24 / 10 / 3 | 24 | 21 | 1 |
| 42 | Lumber link | 7 / 10 / 17 | 17 | 10 | 0 |

Manual completion averaged 24.3 rounds; linked completion averaged 16.3. Only three matched seeds were tested. The link both automates wood and removes its card from the rotating deck, so these results do not isolate the effect of wood quantity from deck access.

## Interpretation

Every one of the 18 house cases obtained a home. Waiting behind the first success was substantial: gaps were 13–23 rounds with manual timber, versus 9–10 with linked timber. Early success did not guarantee a short route for the final house.

Manual towns missed 12 standing clay shipments; linked towns missed none. Those imports require public wood at the instant the caravan is processed. Shared supply timing remains vulnerable even when private resources exist. However clay is not used to make bricks in this scenario: bricks are imported separately for chests, and there is no kiln. These misses show an unreliable supply link, not a demonstrated cause of slower housing completion.

The unchanged AI continues preparing inputs after its own home is upgraded: successful houses still produce labour, take pop/wood/brick/chests into their stockpiles, trade, and convert influence to prestige. Some also produce shared timber, grain and chests. There is no explicit completed-house helping policy. This mix did not permanently block another house in these six games; it also does not establish efficient coordination.

No decision opportunity observed an exhausted town-wide unissued pop reserve. Carpenter availability and affordability were more selective: in two games, one house never had a legal carpenter activation at its own decision points, yet still finished using the shared economy. All three houses in every game executed their upgrade at the first decision where that upgrade was legal under this policy. Delays occurred in reaching that opportunity, rather than refusing the final action.

Prestige Blue / Red / Gold at completion: manual seed 1 = 10/6/9, 7 = 8/8/7, 42 = 9/9/7; linked seed 1 = 7/8/6, 7 = 7/9/5, 42 = 8/8/6. Longer games allow more influence conversions, so total prestige is not directly comparable as a performance score.

## Validation

Six complete original journals replay exactly: 956 decisions, with invariant checks after every decision and no reported failures. Six targeted goal boundary checks verify no premature completion after one or two homes, delivery requirement, correct reason and no legal actions after completion. The preserved original scenario regression still passes 82 checks / 486 decisions. Native UI checks also pass across 83 archived states, selections, previews, manual execution, AI stepping and exact save/load. Calculated minimum remains 1590 × 1061, within 1920 × 1080.

## Next useful experiment

Keep this baseline. Compare it with a policy-only variation in which a house with a finished home stops reserving personal upgrade inputs and prioritises town supply for unfinished houses. Keep private prestige incentives and economic rules unchanged. Measure whether that reduces the final-house delay and import misses. This tests the need for coordination before introducing a new commodity, kiln or subsidy. No such correction has been applied in this experiment.

## Reproduce

`godot --headless --path . --script res://tests/every_house_experiment.gd`

Evidence, saves, decision alternatives, action events and diagnostic counters are in `experiments/every_house/`. The 40-round cutoff is diagnostic; it is not an in-game victory condition.

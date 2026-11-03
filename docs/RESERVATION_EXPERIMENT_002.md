> **Historical document.** Retained for its original version/experiment; its recommendations and missing-feature claims may be superseded. For current v0.909 rules, decisions and next work, start with [THREAD_HANDOFF.md](THREAD_HANDOFF.md). Historical results below are not relabelled as current validation.

# Experiment 002 — urban/rural plots and reserved production

2026-10-31 · prototype 0.3.0 · no visible interface.

## User intent

Separate plots inside town (urban) and outside (resources). Basic huts consume a grain and provide/regenerate one pop; upgraded huts consume a grain plus a minor luxury and provide two. Pops are used in workshops and rural activities. Whoever activates a building reserves its output for one turn. Passing generates influence; three influence claims anything. These are provisional test amounts. The domestic economy is deliberately cashless; real money is reserved for possible foreign trade and specialist wages later.

## Exact temporary interpretation

- A pop is a usable labour token, not an indefinitely growing permanent resident. Activating basic housing consumes 1 grain and produces 1 pop. Upgraded housing consumes 1 grain + 1 luxury and produces 2 pops. Working or building spends a pop. Unspent pops expire at round end, representing unused labour time. A hut does not automatically activate or incur a cost when it is not used.
- Six urban plots and five resource plots per locale: eleven total. River valley resources are 2 forest, 2 field, 1 claybank; woodland is 3 forest, 1 field, 1 claybank. Urban and resource plots cannot substitute for one another. No clearing, demolition, or downgrade action.
- Start with three public basic huts on urban plots, two urban workshops (brick kiln and pottery workshop), and three rural producers (lumber camp, grain farm, clay pit). Thus one urban and two rural plots remain empty. Five permanent industries plus three huts gives an eight-card starting deck. Other definitions include additional farms, woodlot, clay workings, carpenter, and bakery.
- Grain farm outputs 2 grain for 1 pop. Lumber camp outputs 2 wood for 1 pop. Clay pit outputs 2 clay for 1 pop. Kiln consumes 2 clay + 1 wood + 1 pop for 2 bricks. Pottery consumes 1 clay + 1 pop for 2 minor-luxury tokens. Carved woodwork and bakery are alternative abstract luxury recipes. All remain provisional; the luxury token currently aggregates several possible minor luxuries.
- River-valley starting stock: 7 wood, 12 grain, 8 clay, 1 brick, 2 luxury. Woodland: 11 wood, 8 grain, 5 clay, 1 brick, 2 luxury. No initial pops and no free automatic worker refresh.
- All goods/pops are stock lots in the town. No permanent private commodity inventories, bank, domestic cash prices, barter, cash exports, resident growth, or automatic ownership income in this variant. Local money is absent; international money is not implemented yet.
- An activation creates output lots reserved for that activator through the END of that house's NEXT action. Opponents act in between. The producer can spend reserved stock during that next action. Any remainder then becomes public and rivals can use it. A later activation creates a new reservation; it does not extend old ones. Passing counts as the next action and releases leftovers. New physical goods persist after release; pops last only until round close.
- Inputs are drawn from the acting house's reservations first, then public lots; another house's reserved lots cannot be consumed. No separate collect/hoard action exists. Shared input goods can be used directly by a workshop or construction action.
- Passing gives exactly 1 influence and ends that house's participation in the round. Therefore each house gets one influence per round, whether it worked before passing or passed immediately. This prevents pass farming but makes influence effectively a fixed per-round allowance; this timing interpretation deserves review later.
- Every public building claim costs exactly 3 influence, including huts and rural producers. Claims require a revealed card and a free property slot. Each house retains three property slots. Claims do not consume a pop. Ownership allows upgrading; it does not exclude other activators or entitle the owner to output.
- Construction consumes 2 wood + 1 brick + 1 pop and occupies an appropriate plot. Newly built assets are PUBLIC; claiming them is a separate action costing 3 influence once the card is available. Hut construction is urban only. Upgrading an owned revealed asset consumes the same construction bundle and no extra influence. A hut then uses its two-pop recipe; industry doubles its output. These construction/upgrade costs are inherited scaffolding adjusted to one pop, not user-confirmed amounts.
- Existing deck convention retained: four revealed cards per round, one activation per card per round, alternating houses, up to six non-pass actions each, all passing closes the round. Housing cards share this deck, so food, housing, luxury production and work must line up with card availability.
- AI objective remains one owned upgraded hut per house, then further housing/industry. The policy values food reserves and productive capacity but is not an optimal scheduler.

## Six-game test

Seeds 1, 7, 42 in both locales, forty rounds each: six games total, 240 rounds, 1,032 recorded decisions. No economic rule or policy variant was swapped mid-test.

| Locale / seed | First upgrade round: Blue / Red / Gold | Final upgraded huts: Blue / Red / Gold | Last economic action round | End condition |
|---|---|---|---:|---|
| River valley / 1 | 4 / 5 / 14 | 1 / 1 / 1 | 16 | All huts upgraded; no luxury or pops |
| River valley / 7 | 4 / 8 / not reached | 1 / 1 / 0 | 40 | Basic hut retained; activity continues |
| River valley / 42 | 7 / 6 / 6 | 2 / 1 / 1 | 24 | All huts upgraded; no luxury or pops |
| Woodland / 1 | 4 / 5 / 8 | 2 / 1 / 1 | 15 | All huts upgraded; no luxury or pops |
| Woodland / 7 | 4 / 8 / 14 | 1 / 1 / 1 | 24 | No grain or pops; fourth hut still basic |
| Woodland / 42 | 7 / 6 / 6 | 2 / 1 / 1 | 10 | All huts upgraded; no luxury or pops |

Five of six games met every house's first-upgraded-home objective. Those five also became unable to generate any further pops. Four depleted luxury with no remaining basic hut; the fifth depleted grain. Shuffling cannot restart production in either condition. No automatic rescue was added.

The remaining river-valley seed 7 retained Gold's basic hut. It still had nine grain and three luxuries at round forty and continued taking economic actions. Gold failed to coordinate bricks, wood, a pop, and its hut's available card for an upgrade while rivals continued investing. This shows that mechanical reachability and actual heuristic success differ. The result does not establish that refusing upgrades is universally optimal.

Urban/resource separation worked as intended: urban housing never occupied forests/fields/claybanks. River-valley games added rural farms; urban housing and workshops competed for the final urban slot. By the end, four games used that slot for a fourth hut, river-valley seed 7 used it for a bakery, and river-valley seed 1 left it empty. Every game retained one or two vacant forest plots; spare land of the wrong category did not resolve food/luxury locks.

## Reservation and pop measurements

Across the six games:

- 412 output units produced with reservations.
- 130 units consumed by their producer while reserved.
- 282 units released into public stock; 190 subsequently consumed from released stock by any house.
- 178 pops supplied, 139 used for work/construction, 39 expired unused.
- Houses activated rivals' owned huts 69 times; claims confer upgrade control, not exclusive labour rights under these rules.

These are mixed units across commodities and pops, useful for tracing flows rather than valuing economic output. Public consumption can include the original producer after release. Reservations confer a real first-use opportunity; they do not solve multi-action scheduling or ownership incentives automatically.

## Assessment

The rules produce a coherent domestic allocation loop: food/luxury → usable labour → primary/processed goods → improved housing and capacity. Timing and access create decisions without a general-purpose domestic currency. Keeping foreign money and future specialist pay separate is compatible with this structure.

The largest design effect is upgrade dependency. A basic hut can restart labour using grain alone. An upgraded hut requires luxury, but making luxury itself requires labour. Mandatory upgrading can remove the simpler restart path. The sample's failures are genuine consequences of the tested mechanics and policy, not a negative-balance or reservation-theft bug.

There is no permanent population growth advantage in this interpretation: an upgraded hut raises labour produced per activation, paid for by recurring luxury. That is a different incentive from the previous experiment's permanent resident growth.

Passing currently awards everyone one influence each completed round. It affects withdrawal timing and claim pacing, but does not reward a house with more total influence for working less within that round. Final stocks of 31–37 influence also show that the current three-property ceiling leaves few late spending opportunities.

## Verification and limitations

79 checks pass, including fixtures, saved checkpoints matched to their original next action/state, full six-game journal replay, final invariants, and exclusive influence sourcing/spending. Every original decision was checked for nonnegative accounting, reserved access, pop spending/expiry, plot categories/capacity, ownership limits and deck identity.

Initial journal verification found a serialization-order issue: JSON sorted recipe keys, changing the order of simultaneous input-consumption records. Consumption now follows a fixed explicit resource order matching the original execution. All six ORIGINAL journals and checkpoints were reverified successfully; no additional AI games or evidence rewrites were needed. Initial failures remain recorded in results.json for auditability.

Important open interpretations: pop lifetime/regeneration, a personal action versus a whole round as reservation length, pass ending participation versus merely skipping one action, shared production ownership benefits, and whether an upgraded hut may use the basic recipe. These were choices for testing, not final decisions. Logs expose the AI's limited planning; outcomes are not estimates of optimal play or player enjoyment.

## Reproduction

Default main-scene mode is now `--experiment=reservations`. Previous modes `housing` and `cash` remain separate. `python tools/run_checks.py --godot /path/to/Godot` runs these six games and fixtures. To verify existing evidence without another AI batch:

```
godot --headless --path . --script res://tests/reservation_experiment.gd -- --verify-existing
```

Results and timelines: `experiments/reservations/results.json`. Per-game complete decision journals, checkpoints, final saves, and summaries: `experiments/reservations/evidence/`.

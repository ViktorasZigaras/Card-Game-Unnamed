# Caravan retry window · experiment 008 · v0.80

Six matched games, seeds 1, 7 and 42, manual-timber start and preset lumber link, using the same v0.75 AI, recipes, ownership costs and first-pick reservations. Local work only; no uploads.

## One rule change

An existing clay-import contract still first attempts its shipment at caravan arrival. If public wood is unavailable, that visit opens a retry window. After every house has performed its first action in the round, the shipment retries once using only public, unreserved wood. Passing and paid/free activations count as actions. Repeated actions by one house cannot substitute for another house's first action. The retry runs before a final pass can close the round.

A successful retry consumes one wood and delivers one clay. Each caravan visit may deliver clay at most once, including immediate contract creation. Cancelling and recreating the link cannot obtain a second immediate delivery during the same visit. A link may be re-established at a later visit. Success at arrival never opens a retry window. Failed retry produces nothing and has no further automatic attempts that visit.

Late clay retains contract priority, expiring on the holder's next action, even if the holder was the third actor that triggered the retry. The system does not reach into protected stockpiles or pay influence on the town's behalf. Other imported goods retain their existing rules; this experiment changes the clay shipment only.

## Matched results

| Seed | Starting supply | Housing completion: before → retry | Initially blocked visits | Recovered by retry | Retry failed | Pending at cutoff |
|---|---|---|---:|---:|---:|---|
| 1 | Manual start | 17 → 17 | 3 | 0 | 3 | no |
| 1 | Linked | 14 → 16 | 3 | 1 | 2 | no |
| 7 | Manual start | 18 → 18 | 2 | 0 | 2 | no |
| 7 | Linked | 15 → 15 | 3 | 1 | 2 | no |
| 42 | Manual start | 18 → 19 | 3 | 1 | 2 | no |
| 42 | Linked | 14 → 15 | 4 | 1 | 2 | yes |

All six towns still housed all three houses. Completion shifted from rounds 14–18 to 15–19; three matched games were unchanged and three completed later. A retry window did not make the housing objective faster in this sample. Housing still depends on separately purchased bricks, not on consuming imported clay.

Across the new runs, 18 visits were initially blocked. Seventeen reached the retry decision: four recovered and thirteen failed. One window is pending at the final refresh into round 41, before any round-41 house actions. Therefore the final diagnostic missed counter is 14 (13 failed + 1 pending), not 14 definitively lost shipments. The older runs had 16 permanently missed shipments under the no-retry rule. The recovered four cannot simply be subtracted from that older 16 because additional goods change subsequent AI choices and new initial blocking events occurred.

## Why retries still failed

A separate exact replay inspected inventory at the retry itself, before any following round refresh could add more wood:

| Situation at a failed retry | Visits |
|---|---:|
| No physical wood remained | 7 |
| Wood existed only in private stockpiles | 4 |
| A newly produced wood token was still reserved | 2 |

The one-action priority rule was respected. It also remains possible for the owner to spend the wood during their first action, or for another house to consume released wood before the final first action opens the retry. Simply adding a later opportunity cannot guarantee that the required input survives until it.

## Assessment and next narrow test

Keep the retry as an opportunity, not a guarantee of fulfilment. It rescues a real subset of timing failures without granting free resources or seizing private goods. It does not solve the AI's continuing supply obligation.

The next useful comparison is AI-only: while a caravan shipment is outstanding, recognise one public wood as its input target; prefer leaving or returning that wood instead of consuming it in idle bulk exchange. This should remain a behavioural choice, allowing a house to choose its private objective instead. Keep ownership, paid access, prices and retry timing unchanged. Measure shipment completion and opportunity costs rather than judging only housing speed.

No cancellation or demolition was selected in these six runs. The towns did not need a destructive escape route merely because some shipments failed.

## Validation

All six new journals replay exactly: 2,173 decisions, no invariant failures. Each game also writes and reloads its save to verify exact state restoration. A separate instrumented replay of the same journals derives the failure table while asserting exact snapshots at every step.

Twenty focused retry checks pass: window timing, no attempt after only one or two houses, retry before round closure, resource consumption, one delivery per visit, preserved late-output priority, next-action expiry, no retry after upfront success, no free clay when wood is missing, and no cancel/recreate double delivery. The prior 47 ownership/reservation/upgrade/cancellation checks also pass.

A full live UI game executes through previews and action handlers, including ownership purchases and bulk exchanges, and preserves exact save/load. Its calculated minimum remains 1600 × 1061. The old marketplace regression is retained separately.

## Reproduce

```sh
godot --headless --editor --import --quit
godot --headless --path . --script res://tests/retry_checks.gd
godot --headless --path . --script res://tests/retry_experiment.gd -- --batch=3
godot --headless --path . --script res://tests/retry_inspect.gd
```

Results, original journals, saves and per-retry diagnostics are under `experiments/retry/batch_3/`. Observation covers 40 house-action rounds and the automatic refresh into round 41. A three-seed sample per mode cannot establish general balance. Previous versions remain separate local projects.

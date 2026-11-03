> **Historical document.** Retained for its original version/experiment; its recommendations and missing-feature claims may be superseded. For current v0.909 rules, decisions and next work, start with [THREAD_HANDOFF.md](THREAD_HANDOFF.md). Historical results below are not relabelled as current validation.

# Priority, ownership and last-resort cancellation · experiment 007 · v0.75

Six fresh towns, seeds 1, 7 and 42, each with a manual-timber start or preset lumber link. Played through 40 action rounds; reported end stocks and automatic deliveries include the refresh into round 41, as in v0.70. Housing completion is a milestone, not a terminal state. Nothing was uploaded.

## Rules applied from the discussion

An activation reserves one output token for the activator through their next action. Extra tokens from the same batch are immediately public. Passing expires the priority. A paid/free building activation also spends a pre-existing priority opportunity while retaining the normal turn; its newly generated output receives a new next-action reservation. This boundary was checked explicitly, then the six-game batch was rerun; final outcomes were unchanged.

Establishing a contract does not grant ownership. The creator gets one temporary reservation on the first delivery. Generic links still first deliver on a later eligible refresh; the existing clay link keeps its immediate first delivery. No extra social reward for establishment has been invented here.

Owning a contract reserves one token on subsequent deliveries until the owner's first action afterward. Ownership only applies when a delivery actually occurs; a caravan link does not generate goods on non-visit rounds. A purchase does not reassign goods already delivered or held in stockpiles. The first creator reservation precedes recurring ownership if a link is purchased before its first delivery.

Purchases cost 3 prestige, then takeovers cost 5, 7, 9 and so forth. Currency is consumed, not paid to the previous owner. Building takeovers remain unavailable. Influence access remains 1 per rival reserved token, transferred to that token's holder; protected stockpile access remains 2 per token. Contract ownership and building ownership are separate.

Cancellation stays legally available to any house that can pay. Its provisional price is the greater of (current ownership purchase quote + 3) and (old rural/urban/import cancellation cost + 4). Initial rural/import cancellation therefore costs 6, urban 7; ownership purchases raise it further. Prestige is consumed. Owned buildings still cannot be demolished, and active source contracts must first be cancelled.

A contracted building may be upgraded off-card. Its automatic baseline continues, while its card returns to discard for incremental activation: upgraded inputs minus base inputs, and upgraded outputs minus base outputs. For a hut, automatic grain-to-one-pop continues; the incremental card consumes one luxury for one additional pop. For a linked farm or lumber camp, the incremental card consumes one pop for one additional grain or wood. Extra output follows the ordinary one-token next-action reservation. Cancelling an upgraded link restores full manual recipes without duplicating its card. The provisional upgrade cost is the existing 2 wood + 1 brick + 1 pop for all supported building types; only housing improvements receive the existing housing prestige reward.

## Six-game results

| Seed | Starting supply | Upgrade rounds Blue / Red / Gold | Everyone housed | Purchases | Of those, takeovers | Missed clay shipments |
|---|---|---|---:|---:|---:|---:|
| 1 | Manual start | 9 / 13 / 17 | 17 | 7 | 4 | 3 |
| 1 | Preset lumber link | 6 / 10 / 14 | 14 | 7 | 4 | 3 |
| 7 | Manual start | 18 / 16 / 9 | 18 | 6 | 3 | 2 |
| 7 | Preset lumber link | 15 / 7 / 12 | 15 | 7 | 4 | 3 |
| 42 | Manual start | 16 / 18 / 9 | 18 | 7 | 4 | 2 |
| 42 | Preset lumber link | 6 / 10 / 14 | 14 | 7 | 4 | 3 |

All 18 house cases improved their homes. The six towns completed in rounds 14–18, versus 16–19 in the previous batch. Several mechanics and AI priorities changed together, and only three seeds per supply variant were tested; this does not isolate a causal effect or establish balanced prices.

There were 41 purchases: 18 first purchases and 23 takeovers, consuming 191 prestige. Actual paid prices were 3 (18 purchases), 5 (12), and 7 (11). The resulting next quote reached 9; nobody paid 9 in these runs. Wood accounted for 18 purchases, clay 17, grain 6. Twenty purchases occurred before the all-house milestone. These were real ownership transfers, not compensation trades or free ownership assigned to creators.

The towns continued making bulk exchanges after housing. No imported bricks were bulk-exchanged in the six games. There were zero natural cancellations, zero demolitions, and zero upgrades of contracted sources. Consequently the natural runs demonstrate ownership and priority competition, but not the strategic value of incremental upgrades or cancellation; those features were checked in focused scenarios.

## The timing conflict

Sixteen clay shipments missed their required public wood. At the post-refresh snapshot of every miss, wood was present but reserved, with no public wood available. This observation alone does not prove that every miss was caused by ownership: the inherited refresh order differs between the starting supply variants.

Nine misses were in preset-link towns. Their new lumber token is delivered before the caravan check and can be reserved for its owner, so the automatic shipment cannot consume that token. Seven were in manual-start towns with player-established wood automation, which is processed after the caravan check. That new wood arrives too late for the check and can then appear reserved in the resulting snapshot. Priority and refresh order therefore both matter; the variants should not be treated as a clean comparison of equal-timed supplies.

The next narrow experiment should retry an initially blocked shipment after the houses have had their first actions, at most once successfully per caravan visit. This would preserve first-pick ownership while testing whether the town needs a later fulfilment opportunity. Do not simply remove ownership priority to force the shipment to succeed.

## AI cancellation diagnostics

Cancellation is a high-price legal action, not a legally enforced last-resort rule. The AI records an objective, physical and committed labour counts, alternative access/import/production/upgrade routes, and a counterfactual cancellation when considering it.

The implemented detector is deliberately conservative: for an unfinished house, all six pop tokens committed and zero physical pops constitutes a recognised capacity lock. It checks a cloned state to see whether cancellation frees a token and makes a housing labour recipe fundable, possibly awaiting that card's appearance. The clone must not mutate the real game. Paid access cannot buy a physical token that does not exist; current imports do not import labour; an upgrade still cannot exceed the token cap. A positive result can justify cancellation.

A focused scenario genuinely established six one-pop commitments, leaving no physical labour. The AI selected cancellation, consumed its prestige, released one capacity slot and reopened housing production. The ordinary-town fixture rejected cancellation as unnecessary. This is an inspectable bounded policy, not a claim that the AI can diagnose every possible economic deadlock or reason over an arbitrary dependency tree.

The natural towns retained alternatives, so none selected cancellation. That restraint follows the agreed intention; scarcity alone is not treated as grounds to dismantle another supply link.

## Validation

- All six final journals replay exactly: 2,199 decisions, with no invariant failures.
- Each run writes a save, reads it from disk and checks exact snapshot restoration, including RNG state.
- 47 focused checks pass: one-token reservations, pass expiry, paid/free-action expiry, creator priority, ownership separation, prestige sinks, escalating takeovers, influence access, off-card upgrades, incremental input/output accounting, cancellation without duplicate cards, and a genuine locked-capacity rescue.
- Existing marketplace regression: 82 checks / 486 decisions, no failures.
- Archived interface validation: 83 recorded states and action previews, manual execution, AI stepping and save/load.
- New live interface: a full 40-round seed-7 game through preview/execute handlers, including six ownership purchases, contract creation and bulk exchange; disk save/load remains exact. Calculated minimum is 1600 × 1061, fitting 1920 × 1080.

## Reproduce locally

```sh
godot --headless --editor --import --quit
godot --headless --path . --script res://tests/priority_checks.gd
godot --headless --path . --script res://tests/priority_experiment.gd -- --batch=3
godot --headless --path . --script res://tests/contract_ui_check.gd
```

Final results, complete snapshots, decision alternatives and events are in `experiments/priority/batch_3/`. The interface starts v0.75 games with the latest policy. Older v0.65 and v0.70 working projects are preserved separately. The simulator still has no building buyouts or general-purpose construction/replacement objective.

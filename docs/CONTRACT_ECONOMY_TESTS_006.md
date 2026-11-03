> **Historical document.** Retained for its original version/experiment; its recommendations and missing-feature claims may be superseded. For current v0.909 rules, decisions and next work, start with [THREAD_HANDOFF.md](THREAD_HANDOFF.md). Historical results below are not relabelled as current validation.

# Contract economy laboratory · v0.70

Eighteen original games in three adaptive batches of six; no uploads. Seeds 1, 7 and 42, each manual timber and preset lumber link. Older v0.60 and v0.65 projects are preserved.

## Scope and timing

The all-house housing objective is recorded as a milestone rather than ending play. Each run executes rounds 1–40; its final state includes the refresh into round 41. Delivery and inventory counters therefore include that final refresh, while no round-41 house actions occur. Live play continues beyond this diagnostic cutoff. The finite pop cap stays six and influence stays capped at ten.

Contracts deliver one unit to unreserved public supply, not to their sponsor. Only one standing contract per resource is allowed. Local automation removes its source card from rotation; the building stays on its plot. A source must be built, not already activated this round, and either public or owned by the sponsor. Labour links require an owned hut. Foreign links require a built marketplace and a currently visiting caravan. No setup reward is added for the new generic contracts.

## Provisional prerequisites and prices

| Output | Setup consumed | Ongoing public input | Source / timing | Pop committed | Cancel prestige |
|---|---|---|---|---:|---:|
| Wood | 1 wood + 1 pop | None | Lumber camp / each refresh | 1 | 1 |
| Grain | 1 wood + 1 pop | None | Farm / each refresh | 1 | 1 |
| Chest (`furniture`) | 2 wood + 1 pop | 2 wood in batches 1–2; 1 in batch 3 | Carpenter / each refresh | 1 | 3 |
| Labour (`pop`) | 1 grain + 1 wood | 1 grain | Owned hut / each refresh, cap permitting | 0 | 3 |
| Brick | 1 chest + 1 pop | 1 chest | Marketplace / each caravan, shares two-brick visit limit | 1 | 2 |
| Minor luxury | 2 wood + 1 pop | 2 wood | Marketplace / each caravan | 1 | 2 |
| Clay, existing link | 1 chest + 1 pop + 1 wood | 1 wood | First delivery at setup, later caravan visits | 1 | 2 |

Generic links first deliver on a subsequent eligible refresh; they do not immediately create a token. A consumed setup pop is committed rather than left available for regeneration. Cancelling releases that commitment to the unissued reserve, not into public supply. The labour link commits no pop and still respects the finite token cap. Imported brick contracts share the existing caravan stock; they do not create a second unrestricted brick supply.

Recurring inputs use public, unreserved tokens only. Private stockpiles are never seized automatically. Missing inputs pause delivery; missing capacity also pauses labour output. Processing follows deterministic contract creation order after the older lumber/clay processing. That order is an unbalanced provisional priority rule.

A normal action spends prestige to cancel a link: rural 1, urban 3, imports 2. In this experiment any house may cancel any public link, even if another sponsored it; this authority is a test assumption, not a settled ownership rule. Cancelling restores a local source card to discard.

Demolition is a normal action: 1 prestige for an unowned rural building, 3 for an unowned urban one. Active contracts must first be cancelled. Owned buildings and the special off-budget chapel are protected. The plot is freed and all copies of the card removed. No salvage is awarded. The current scenario has no general rebuilding action, so this is deletion and land release, not a completed overbuilding system.

An idle house gathers varied resource types into its three-token stockpile. A normal bulk action consumes all three tokens for 3 influence, with normal cap overflow. These tokens leave the economy as a civic delivery/resource sink; pops represent civic labour and return to the regenerable reserve. Taking each token, exchanging, and converting 5 influence to 1 prestige are separate actions. This is an equal-token valuation, deliberately not a market price.

## Adaptive batches

| Batch | Change | Completed towns | Manual completion, seeds 1 / 7 / 42 | Linked completion | Cancellations | Bulk exchanges | Missed clay shipments |
|---|---|---:|---|---|---:|---:|---:|
| 1 | Broad automation and idle collecting; completed-home support | 0/6 | unfinished / unfinished / unfinished | unfinished / unfinished / unfinished | 35 | 85 | 28 |
| 2 | AI supply buffers, donations, cautious automation and cancellation | 6/6 | 21 / 21 / 21 | 25 / 19 / 25 | 2 | 77 | 1 |
| 3 | Cheaper workshop recipe plus tighter labour/luxury-link policy | 6/6 | 16 / 18 / 18 | 19 / 18 / 18 | 0 | 100 | 8 |

### Batch 1: automation and prestige consumption can defeat the town goal

No town completed. Only 8 of the 18 house cases upgraded. There were 35 cancellations, repeatedly paying to restart carpenter or labour links. Carpenter links generated zero chests: public inputs were spent elsewhere. Bulk exchanges consumed 11 imported bricks before housing completion, along with 128 pop tokens. Several labour links also removed the basic hut card that its owner needed to upgrade. These were policy and dependency failures, not invariant violations.

Discussion: should progress resources be protected by AI alone, or should the town impose contracts/reservations? Is automating an unfinished hut a commitment that requires cancellation before upgrading, or should upgrading remain accessible off-card?

### Batch 2: protect milestones and make automation earn its place

AI changes only: a finished house no longer takes personal upgrade inputs for their own sake, donates cached needed goods, and gathers only goods above town-wide reserve targets. Bulk exchange rejects stock needed to preserve those targets. Hut automation waits for an upgraded home. Carpenter automation requires eight public wood; brick links require two physical chests. A few missed deliveries no longer trigger arbitrary cancellation.

All six towns completed in rounds 19–25. Bricks were not bulk-exchanged before the goal; one surplus brick was exchanged later. Only two contracts were cancelled. Clay misses fell to one. Carpenter contracts were never selected. Labour output frequently paused at the physical token cap (146 scheduled misses combined). A zero free-pop reserve can mean saturated stocks plus commitments, not absence of spendable labour.

Discussion: this is stable production with conservative buffers, not proof of globally intelligent planning. Idle bulk demand turns automatic surplus into prestige, so there is no natural saturation of the prestige objective.

### Batch 3: less idle automation, faster homes, weaker continuing imports

The workshop link is offered at one wood per chest and a four-public-wood buffer. The AI avoids new labour links when capacity is tight or everyone has a home, cancels persistently blocked labour links after completion, and avoids luxury links without sufficient wood and token headroom. These changes were tested together; this is not a clean single-variable causal comparison.

All six towns completed in rounds 16–19, with 100 bulk exchanges, no cancellations, and no bricks exchanged. Four runs avoided labour automation entirely; two manual runs did establish it. Carpenter automation still was not selected, so the discounted price has no autonomous gameplay balance evidence. The new recipe is present and checked, but not exercised by these six AI runs. Clay misses increased to eight, showing that completed housing and ongoing trade reliability are different objectives.

Discussion: should the next shipment reserve wood automatically, use a dedicated buffer, or compete with idle civic delivery? Should post-housing supply targets retain an ongoing trade budget?

## Per-game observations

| Batch | Seed | Starting lumber link | Upgrade rounds Blue / Red / Gold | Goal round | Final prestige Blue / Red / Gold |
|---|---:|---|---|---:|---|
| 1 | 1 | no | 25 / 32 / — | — | 6 / 6 / 5 |
| 1 | 1 | yes | 7 / — / 18 | — | 7 / 8 / 1 |
| 1 | 7 | no | 38 / — / 17 | — | 4 / 0 / 1 |
| 1 | 7 | yes | — / — / — | — | 7 / 7 / 6 |
| 1 | 42 | no | 19 / — / — | — | 1 / 0 / 3 |
| 1 | 42 | yes | 40 / — / — | — | 11 / 7 / 6 |
| 2 | 1 | no | 7 / 21 / 15 | 21 | 15 / 15 / 15 |
| 2 | 1 | yes | 6 / 22 / 25 | 25 | 13 / 15 / 13 |
| 2 | 7 | no | 18 / 21 / 9 | 21 | 14 / 17 / 13 |
| 2 | 7 | yes | 13 / 7 / 19 | 19 | 16 / 17 / 14 |
| 2 | 42 | no | 7 / 21 / 15 | 21 | 15 / 16 / 14 |
| 2 | 42 | yes | 6 / 22 / 25 | 25 | 12 / 16 / 12 |
| 3 | 1 | no | 7 / 16 / 12 | 16 | 15 / 16 / 12 |
| 3 | 1 | yes | 6 / 19 / 12 | 19 | 15 / 16 / 12 |
| 3 | 7 | no | 13 / 18 / 9 | 18 | 15 / 18 / 13 |
| 3 | 7 | yes | 18 / 7 / 12 | 18 | 15 / 17 / 12 |
| 3 | 42 | no | 7 / 18 / 15 | 18 | 14 / 17 / 13 |
| 3 | 42 | yes | 6 / 18 / 12 | 18 | 14 / 16 / 11 |

## What the system has become

A small shared production economy now supports a second economy of standing supply commitments, and a third conversion path from surplus tokens to influence to prestige. Prestige grants restructuring power as well as recording achievements. The interesting constraint is no longer only whether a recipe exists: it is whether inputs remain accessible at the needed time, whether finite labour is committed or usable, and whether private prestige incentives serve the town objective.

Every natural run recorded zero demolitions. The mechanic works in focused tests, but the scenario has no obsolete redundant factory or competing new land use. Do not infer a balanced land market or demonstrated overbuilding behaviour. Similarly, brick and luxury contracts were only selected in some earlier batches; breadth of legal possibilities exceeds what these AI priorities choose.

## Suggestions to discuss, in order

1. Shipment commitment: should standing contracts reserve their next input before idle bulk trades can consume it? Batch 3 makes this the clearest next comparison.
2. Bulk exchange valuation: are three arbitrary tokens equivalent civic contributions, or should delivered items satisfy town needs? Cheap automatic grain and imported brick currently have the same influence yield.
3. Cancellation authority: may any house spend prestige to revoke any public link, or is sponsor consent, town authority, or compensation needed? No hostile policy was tested.
4. Rewards after rebuilding: clay setup still awards 3 prestige while cancelling it costs 2. A repeated setup/cancel cycle can yield net prestige at the expense of goods, labour and actions. Decide whether this is legitimate repeated service or whether milestone rewards should be awarded once.
5. Automation and upgrading: does contracting a hut deliberately remove upgrade access until cancellation, or should an owner be able to improve a linked building separately?
6. Genuine overbuilding test: add one obsolete public building and a concrete competing construction objective. Until then, demolition has a cost without a demonstrated benefit.
7. Contract throughput and duration: the unselected carpenter discount is still an offer, not a proven balance improvement. Add a focused multi-chest objective before changing its price again.

## Validation and reproducibility

All 18 original journals replay exactly, covering 6,252 decisions and invariant checks. Each run also checks exact in-memory snapshot restoration; actual disk save/load is checked by the live UI test. Sixty-six focused contract checks pass, covering all seven goods, prerequisites, upkeep pauses, cancellation, card restoration/accounting, ownership protection, demolition, reclaimed land, bulk consumption, atomic rejection and the batch-three recipe setting. The old marketplace regression still passes 82 checks / 486 decisions. Archived UI checks pass 83 states, previews, manual execution, AI step and save/load. The new live UI also executes a full 40-round seed-7 game through preview/execute handlers, including contracts and bulk trades, and preserves exact save/load.

Commands:

```sh
godot --headless --path . --script res://tests/contract_checks.gd
godot --headless --path . --script res://tests/contract_experiment.gd -- --batch=1
godot --headless --path . --script res://tests/contract_experiment.gd -- --batch=2
godot --headless --path . --script res://tests/contract_experiment.gd -- --batch=3
godot --headless --path . --script res://tests/contract_ui_check.gd
```

The interface uses batch-three assumptions for new games. Original batch results, saves, events, candidate choices, and snapshots are retained under `experiments/contracts/`. A three-seed sample per supply mode is small, adaptive tuning may overfit, the starting lumber link changes both supply and deck access, and post-goal observations differ in duration because towns complete at different times.

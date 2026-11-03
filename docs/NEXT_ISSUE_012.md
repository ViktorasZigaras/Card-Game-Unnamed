> **Historical document.** Retained for its original version/experiment; its recommendations and missing-feature claims may be superseded. For current v0.909 rules, decisions and next work, start with [THREAD_HANDOFF.md](THREAD_HANDOFF.md). Historical results below are not relabelled as current validation.

# Proposed next issue: partial construction, plot reservation and forced overbuilding

Status: partly implemented in v0.903 for House Halls and the sawmill. Marketplace/kiln partial construction and general forced replacement remain deferred.

Experiment 013 now demonstrates demand for expanded urban land: two hall sites per town compete for the two extra slots. The immediate AI follow-up is to stop manufacturing planks for a third hall that cannot secure land. See HOUSE_HALLS_AND_SAWMILL_013.md.

The v0.902 stockade experiment now opens two extra urban slots, which stayed vacant in the matched games. Give that capacity a concrete economic use while implementing partial new construction. Separately test AI brick allocation: legal exports and town demand still strand unfinished homes. See STOCKADE_AND_LAND_TEST_012.md.

Partial upgrades now work and improve completion in matched tests. New buildings still appear only after a complete payment, so unfinished construction cannot reserve land, compete for it or be deliberately replaced. Complete that part of the agreed design before adding another economic subsystem.

## Proposed behaviour

- Starting a building requires a real, nonzero contribution and an action, reserving its appropriate urban/rural plot immediately.
- Its construction card cycles. Paid progress persists; the unfinished building provides no production or other completed functionality.
- Later contributions consume only missing goods; the physical tokens are no longer stored at the site.
- The reservation persists until completion or a permitted full-price forced overbuild. No free abandonment, progress transfer or salvage is introduced.
- A forced replacement pays the replacement's complete construction cost in one action; the previous paid progress does not discount it. Preserve the current protection for owned buildings and special chapel rules.

## Acceptance checks and experiment

Plot accounting must include built and reserved sites exactly once. Completion must grant functionality and card identity exactly once. No zero-cost land reservations, duplicated resources, double payments or production from unfinished sites. Saves and replays must preserve progress and reservation status.

Run six towns with a concrete competing use for the final urban plot. Record whether the AI finishes its existing project or pays for a full replacement, why the replacement is useful, completion delays, lost contributions and any stale reservations. A forced replacement that occurs only in a fixture does not demonstrate useful economic restructuring.

Use the existing marketplace/kiln construction paths as the first implementation targets. Choose the competing project's purpose before claiming a natural overbuilding test; the current housing milestone alone does not provide that pressure.

Partial supply/contract establishment remains a separate follow-up. No new prices or resources are needed merely to implement construction progress.

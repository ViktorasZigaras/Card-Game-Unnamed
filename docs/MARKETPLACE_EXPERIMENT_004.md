> **Historical document.** Retained for its original version/experiment; its recommendations and missing-feature claims may be superseded. For current v0.909 rules, decisions and next work, start with [THREAD_HANDOFF.md](THREAD_HANDOFF.md). Historical results below are not relabelled as current validation.

# Experiment 004 — how hard can a decent house be?

31 October 2026 · Godot prototype 0.5.0 · simulation and logs only.

## The requested scenario

The town needs a small wooden marketplace. A visiting caravan should offer a clay-import contract for a thematic input and sell bricks because neither local clay nor existing bricks are available. The scenario ends when clay import exists and at least one upgraded brick house exists. Building the marketplace, securing the import, and improving a home award prestige, in addition to incidental one-way influence conversions.

This also runs the previously proposed comparison: three matched seeds with manual timber production, and the same three with a preset lumber supply link. Six AI games total. No corrective AI game reruns were required.

## Result

**All six towns completed the objective.**

| Seed | Manual timber: completion round | Preset lumber link: completion round | Manual / linked decisions |
|---|---:|---:|---:|
| 1 | 8 | 7 | 71 / 64 |
| 7 | 10 | 7 | 82 / 60 |
| 42 | 20 | 7 | 151 / 58 |

Completion is a shared scenario condition, not a final individual victory rule. It requires an active clay link, at least one actual clay delivery, and at least one owned upgraded hut. It does not require every house to improve its home.

The games stopped on that condition, not after a fixed number of rounds. Forty rounds was only the diagnostic limit. Total recorded decisions: 486.

## Thematic, provisional trade terms

### Wooden chests as the export

The existing carpenter makes one **wooden furniture unit, represented by simple chests**, using two wood and one pop. Chests are durable manufactured goods that plausibly interest a caravan and give the town an export based on its available timber and labour.

These are board-game commodity units; one brick unit represents a useful bundle, not one literal brick for an entire house.

| Action or service | Cost | Result |
|---|---|---|
| Build wooden marketplace | 3 wood + 1 pop | Persistent public market; +2 prestige to builder |
| Carpenter activation | 2 wood + 1 pop | 1 chest/furniture token |
| Establish clay-import link while caravan is present | 1 chest + 1 pop + 1 wood | First clay delivered, one pop permanently committed for this test, +3 prestige to sponsor |
| Later automatic clay shipment | 1 unreserved public wood per caravan visit | 1 clay; shipment pauses if public wood is unavailable |
| Buy imported bricks by barter | 1 chest | 1 brick unit; at most 2 offered per visit |
| Improve an owned hut | 2 wood + 1 brick + 1 pop | Upgraded house; +5 prestige to its owner |
| Convert influence | 5 influence, ordinary action | 1 prestige; no reverse conversion |

The clay link abstracts a standing wooden-goods export service: the first chest establishes the relationship, a committed artisan token supports it, and later public wood supplies the export line automatically. It does not pretend a single chest buys an endless free stream of clay. The recurring one-wood cost is a provisional abstraction, not a finalized furniture-production recipe.

The carpenter remains available to make other chests for spot purchases. It uses another available pop for each such manual activation; committed labour cannot be borrowed for it.

### Caravan timing

The first caravan arrives at the hand refresh after the market is built. It stays for that round, then returns every third round: a market built in round 1 brings visits in rounds 2, 5, 8, 11, and so on. “Every few turns” was interpreted as hand-refresh rounds for this experiment.

There is no real money system yet: brick purchases are barter. Clay and bricks have no other source in this scenario. No kiln or clay pit is secretly added.

The three milestones reward the house actually delivering each result. More than one house may improve a home before the overall town condition is fulfilled, and each receives the stated house-improvement reward. Prestige is recorded, not converted into a victory score or spent on invented benefits.

## Latest core decisions now implemented

The experiment also replaces several outdated 0.4.0 assumptions:

- Passing skips a normal turn; a house may return to action. Three consecutive passes, one from each house, refresh the hand. Any substantive action, including a free paid use, resets that chain.
- A house may receive one idle-pass influence reward per round if it has not acted before that pass. A later action does not undo the earlier reward. This at-most-once reward is a documented temporary interpretation.
- Activation immediately moves a card from hand to discard. No building can activate twice in a round. Owning a building does not keep its card available after use.
- Six pop tokens exist locally. Unused tokens remain usable in piles/stores; spent tokens return to the unissued reserve. Huts cannot issue more than the reserve permits. Standing contracts reduce that reserve by their committed tokens.
- Basic huts use grain for one pop; upgraded huts retain that recipe and may use grain plus luxury for two. Basic rural production provides one unit with no pop; upgraded rural recipes retain the base option. The scenario's objective ends at the first qualifying upgraded house, so not every general recipe is exercised by AI before completion.
- Normal access to a rival reserved unit costs one influence. Otherwise inaccessible rival stockpiles can supply a unit for two influence as part of immediate actual consumption. Payments transfer to the holder; no bidding, counterbidding or buying merely to hoard is implemented.
- Owned rival-building activation costs one influence and is a free action, retaining the payer's normal turn. Input fees are free inline payments and do not make an otherwise ordinary operation free.
- Influence is capped at ten. Surplus receipts are discarded and logged. Conversion to prestige is voluntary and one-way.
- The chapel is special, unownable and outside the ten ordinary plots. For this test, houses tied for the fewest upgraded huts can use it; it gives two influence when activated. This catch-up proxy is provisional.

The two-influence override cannot create a physically absent resource or borrow a committed pop. It uses real existing tokens from an inaccessible holder. This is the finite-pool interpretation tested here.

## Initial town and paired variant

Ten ordinary plots: six urban, two forest, two field. There is no clay terrain. Initially built are three huts, a carpenter, a lumber camp and a grain farm; the chapel is additional, off-budget space. The market is a construction candidate, occupying one ordinary urban plot when built. It is passive infrastructure, not another activation card.

Initial shared stocks are five wood and six grain, with zero clay, bricks, furniture, luxury or usable pops. Houses begin with zero influence and prestige, three property slots and three-token private stores. The shared hand has four cards. Construction of the wooden market needs no brick, so the scenario does not require its own end product to start.

In the preset-link variant, one of the six pop tokens is committed from the outset to a public lumber supply link. It supplies one wood at every hand refresh, including the first. The lumber camp remains physically built but its manual card is outside the rotation. No house gets an achievement reward for a link already present in the initial scenario.

The clay link later commits another pop. Thus the manual-timber scenario can have five uncommitted tokens after securing imports; the linked scenario can have four. Other than this intervention, both scenarios use the same initial ordinary stocks, prices, goals and policy. Matching seeds does not preserve identical hand sequences after removing a card; changed deck access is part of the intervention.

## Who did what?

| Seed / timber | Market | Clay link | Upgraded houses before completion |
|---|---|---|---|
| 1 / manual | Blue, round 1 | Gold, round 8 | Gold, round 3 |
| 1 / linked | Blue, round 1 | Red, round 5 | Gold, round 7 |
| 7 / manual | Blue, round 1 | Red, round 5 | Blue, round 10 |
| 7 / linked | Blue, round 1 | Red, round 5 | Blue, round 7 |
| 42 / manual | Blue, round 1 | Red, round 20 | Gold, round 3; Red, round 10 |
| 42 / linked | Blue, round 1 | Red, round 5 | Blue, round 7 |

The linked seed-1 run split all three milestones between different houses: the public market builder did not automatically receive the import or house reward.

The manual seed-42 town already had a good house in round 3, and a second in round 10, but waited until round 20 for the clay contract. Bricks are a separate caravan offer, so the two conditions can be fulfilled in either order. The game correctly waited for both. If a strictly ordered progression is desired later, that would be an additional rule, not a repair to this conjunction-based end condition.

Blue built the market first in all six games. Blue also always begins the first round and uses the same scenario policy. This exposes a possible initial-turn/goal-priority advantage; these tests do not establish balanced prestige distribution.

## Observations

### The standing lumber link helps in this small scenario

Manual runs took 304 total decisions, linked runs 182. The link removed manual felling activations, added predictable wood and changed access to the remaining cards. It did not cause a large unused timber mountain: peak public wood was six in linked runs and five in manual runs.

However, the labour price was not strongly binding. At least one unissued pop token remained throughout every linked run. The experiment demonstrates useful automation and timing effects; it does not establish that committing one pop is a balanced price. It also cannot separate increased timber throughput from the smaller deck without another controlled variant.

### A contract has a real input dependency

In manual seed 7, a later caravan could not deliver its automatic clay shipment because no unreserved public wood was available. Private/reserved wood was not automatically confiscated to satisfy the standing link. The contract stayed established and logged a missed shipment.

Only one clay delivery occurred in each completed game: usually the setup delivery was sufficient for the scenario, and the one scheduled repeat that occurred before completion was missed. Therefore long-term clay-link reliability remains mostly untested in AI play. A focused fixture verified that a later caravan does deliver automatically when public wood is supplied.

### Safekeeping and access affect the route to a house

Across the sample there were 62 stockpiling actions, seven emergency uses of rival protected tokens, twenty uses of rival reserved inputs, and three paid free building activations. Resources were used directly at the stated influence prices; they were not bid away or acquired for speculative hoarding.

Twelve pass/re-entry events were recorded. The longer manual seed-42 run also performed four incidental influence-to-prestige conversions. The shorter scenarios often ended before anyone had surplus influence to convert.

### The town goal gives the existing pieces a reason to interact

The target tied together lumber, labour, carpentry, civic construction, a visitor schedule, trade, ownership and housing. It created a meaningful public dependency and house-specific rewards with only one new commodity type: furniture/chests.

The town directive and reward ladder are fixed scenario rules in this version. There is no claim that a general autonomous town planner, dynamic quest generator, full transport model or international monetary economy has been implemented.

## Verification and evidence

The six-game harness passed 75 original assertions, including six saved-checkpoint continuations and six complete replay checks. Final focused validation passed 46 fixture assertions after adding explicit checks for paid free turns, discard and chapel eligibility. All six original journals were then replayed again, reproducing all 486 decisions without further AI games.

Every game decision checked accounting, stockpile/influence caps, actual input access, finite pop availability and commitments, persistent card/asset identity, correct plot use, prestige totals and the terminal condition. Clay source accounting is exclusively import deliveries; brick source accounting is exclusively caravan barter. Illegal reverse conversion and premature completion are rejected.

Evidence is under `experiments/marketplace/`: the aggregate `results.json`, complete `decisions.jsonl` histories for all six cases, checkpoints, final saves, per-game summaries and verification output. The run stops immediately on success or reports the round limit honestly; it does not award a house or import to force completion.

## Questions retained, without changing the tested rules

- Is the clay link intended to be required before a house can use imported brick, or is the two-condition finish correct?
- Is one committed pop a sufficient long-term cost for removing a recurring operation and improving supply predictability?
- Should a standing contract reserve its next input in advance, rather than depend on whatever public stock remains at caravan arrival?
- Does always giving the initial market opportunity to the starting house need a scenario setup or turn-order change?

These are future discussion items, not extra changes to these six runs.

## Reproduce

```
python tools/run_checks.py --godot /path/to/Godot
```

This defaults to the six matched marketplace scenarios. For a single main-scene run:

```
godot --headless --editor --import --quit
godot --headless --path . -- --experiment=marketplace --seed=7 --rounds=40 --lumber_link=false --output=res://runs/market7
```

Set `--lumber_link=true` for the paired variant. Use `tests/replay.gd` or `tools/inspect_run.py` with any journal to inspect a specific decision. There is still no visible game interface.

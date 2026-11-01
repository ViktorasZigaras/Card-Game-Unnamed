# Brick demand, industries and gold · experiment 010 · v0.90

Twelve towns: six initial runs and six follow-ups with corrected AI planning. Each batch uses seeds 1, 7 and 42 with manual timber or a preset lumber link. Each runs 40 action rounds plus the automatic refresh into round 41. Original failures are retained. All work is local; nothing was uploaded.

## Provisional rules and interpretation

The town has a standing, unlimited brick demand: a normal action consumes one brick and creates two influence for the delivering house. The influence cap remains ten and excess is accounted for as overflow. This is a fixed demand offer, not yet a mayor AI selecting and escalating town projects.

Each caravan visit has one shared brick purchase order, paying one gold coin for one brick. The order is per visit, not per house, and renews on the next visit. The caravan sells one prestige for two gold as a normal action. Prestige purchases have no additional stock limit beyond available coins and caravan presence. Old direct brick barter and the old caravan brick-import contract offer are disabled for this experiment; bricks come from the local kiln. Other contracts remain available.

Gold belongs to houses, persists between rounds, and is kept in a separate wallet rather than occupying the three-token goods stockpile. It has no use beyond the provisional prestige purchase, and no transfer or gold-denominated input/building market has been added. Exported bricks leave the local economy; coins enter from external trade. Prestige purchases consume the coins. All sources and sinks are tracked.

The house objective is one upgraded brick home plus one owned industry, then prestige accumulation. The policy pursues the home first, industry second, and defers active prestige conversion, contract-priority purchases, bulk surplus exchange and gold-funded prestige purchases until both are achieved. This sequential preference is an AI assumption, not a legal restriction: the player can choose other priorities. Incidental milestone rewards and access-fee income still occur before goals are complete.

Industry means a productive rural building or workshop: lumber camp, farm, carpenter or kiln. Housing, marketplace and chapel do not count. A public automated industry remains claimable off-card for three influence and a normal action; automation removed its activation card, not its existence as public property. No forced building buyouts have been enabled. Industry ownership and prestige-bought contract output priority remain separate.

## Two batches, unchanged economy

The initial policy completed both goals in four of six towns. It retained an obsolete chest-for-brick plan after brick barter had been removed. Some unfinished houses filled their stores with furniture they could not use for their immediate objective, while automated carpenters kept supplying more. Other completed houses exported bricks or delivered them to the town.

The follow-up policy stops prioritising chests/carpenter automation after the clay link is secured, returns unneeded cached furniture while pursuing foundational goals, and prioritises taking an available upgrade brick before less urgent work. Prices, access rules, production recipes and trade offers are unchanged. The same six seed/supply cases were rerun. Five completed; one still did not. One matched town became slower, so this is not a universal improvement claim.

| Seed | Timber start | Initial both-goal completion | Follow-up completion | Follow-up town deliveries | Brick exports | Prestige bought for gold |
|---|---|---|---|---:|---:|---:|
| 1 | Manual start | 38 | 20 | 4 | 5 | 2 |
| 1 | Preset lumber | unfinished | 36 | 3 | 7 | 3 |
| 7 | Manual start | 18 | 17 | 1 | 8 | 3 |
| 7 | Preset lumber | 29 | 20 | 1 | 8 | 3 |
| 42 | Manual start | 14 | 30 | 2 | 7 | 3 |
| 42 | Preset lumber | unfinished | unfinished | 5 | 5 | 2 |

Completed follow-up towns reached both goals in rounds 17, 20, 20, 30 and 36. The remaining linked seed-42 town had two successful houses but Red still lacked its upgraded home and industry at the round-40 cutoff. This is observed stagnation within the horizon, not proof of an irreversible deadlock.

## Demand now keeps the kiln operating

The six follow-up towns made 73 bricks in total: 17 went into house upgrades, 16 to the town, and 40 to caravan exports. No bricks were bulk-exchanged. Each town fired its kiln 12 or 13 times, compared with three times in the preceding housing-only scenario. The new incentives therefore gave existing infrastructure a continuing use.

Town deliveries generated 32 gross influence. Exports created 40 coins; 32 coins purchased 16 prestige, leaving eight coins across the six towns. Some individual houses retained one coin and could not buy prestige yet; coin transfer or change-making is not implemented. Older influence-to-prestige conversion remains available alongside the new gold route.

These counts do not establish an optimal price ratio. A nominal brick yields two influence (0.4 prestige at the five-influence conversion) or one coin (0.5 prestige at the two-coin shop), but normal actions, access fees, cap overflow, a shared export order and fragmented coin balances affect the actual payoff.

## The surviving failure is about access and competing objectives

In follow-up seed 42 with preset lumber, Red ended with ten influence, three incidental prestige, one stored pop and one stored wood, but no brick and no completed home. It never had a legal owned-hut upgrade opportunity in the recorded decisions.

Rivals legally consumed six bricks held or reserved by Red for town deliveries or exports, paying the existing access fees. The fees compensated Red in influence while removing the physical input its home needed. Red's influence reached the cap, so more social income was not itself a solution. This is permitted by the agreed one-influence reserved-input and two-influence protected-input access rules, not an accounting failure or an unauthorised resource grab.

The logs establish the transfers and the unmet goal. They do not prove that no more capable plan could complete Red's home, or that changing this one rule would guarantee success. Card timing, labour availability and the house-first policy also constrain opportunities. Because Red never finished its home, the sequential policy deferred its industry goal despite public property being claimable.

No AI cancellation or demolition was selected. The cancellation policy recognises a complete token-capacity lock, while this situation retains circulating labour and other potential routes; it does not force demolition merely because one house is behind.

## Next design choice to discuss

Should a house be able to commit a brick to an explicit construction project before every other input and its hut card are simultaneously ready? That would distinguish a binding project allocation from a stockpile that others can access for influence. It could fit the existing commitment/contract language, but it needs limits so it does not become unrestricted hoarding.

Alternative tests could keep the current access rules and improve multi-action preparation, or allow the home and industry goals in parallel rather than enforcing the current house-first policy. No construction protection, higher access fee, coin transfer or further AI correction was silently applied to these results.

## Validation and reproducibility

All twelve original journals replay exactly: 4,296 decisions, with no invariant failures. Each run writes and reloads its save and reproduces the exact snapshot and RNG state. The follow-up alone contains 2,185 decisions.

Twenty-two focused checks pass: town brick consumption and influence award, overflow accounting, one shared order per visit, renewal, gold minting and spending, insufficient funds, prestige purchase, removal of brick-sale/import offers, off-card industrial ownership and prevention of forced building takeovers.

A full live seed-7 game executes through the UI preview/execute handlers, including industry claims, town delivery, eight exports and three prestige purchases, then preserves exact save/load. Gold is visible on house panels; the caravan and Links inspectors expose the new offers. Calculated minimum remains 1590 × 1028. The archived 83-state UI checks also pass. The original marketplace regression is retained separately.

```sh
godot --headless --editor --import --quit
godot --headless --path . --script res://tests/trade_checks.gd
godot --headless --path . --script res://tests/trade_experiment.gd -- --batch=3 --policy=1
godot --headless --path . --script res://tests/trade_experiment.gd -- --batch=3 --policy=2
godot --headless --path . --script res://tests/contract_ui_check.gd
```

Evidence is under `experiments/trade/batch_3_policy_1/` and `batch_3_policy_2/`. New live games use policy 2. Six cases per batch are a small adaptive sample; the failures and planner limitations are part of the findings.

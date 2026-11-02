# Card Game — Town and Houses · v0.905

A native 2D Godot prototype of competing noble/merchant houses in one developing town. The current AI pursues a good home, an owned industry, a House Hall, then further opportunities. This is a planner's economy with persistent goods, scarce labour, shared cards and consequential access rights.

## Run

1. Use Godot 4.5 or newer, standard edition.
2. Extract the source ZIP and import `project.godot`.
3. Press F5. The interface targets 1920 × 1080; F11 toggles fullscreen.

This is an editor-playable source project. Art is included; external plugins are not required. Source version: 0.905.

## New financing policy

The AI compares finite cargo with a limited, prefunded standing route. It counts cargo already returning, requires operating gold and cancellation prestige, protects those budgets and pays for exit when its bounded delivery target is reached. Contract previews show an advisory funding assessment; human legal choices remain available.

No prices, legal moves or delivery rules changed. Schema 16 adds saved acquisition observations so the policy can reconstruct its budget after loading. Ordinary route funding has an economic ceiling: the cheapest import spends one gold each round while the entire town's caravan export order earns only one gold every three rounds.

[Experiment 015](docs/ROUTE_FINANCING_TEST_015.md) compares twelve towns. The financing policy imported 31 units versus 20, selected no standing routes in the ordinary sample, and had zero route misses versus 37. All eighteen houses per policy completed Halls. Three separately funded cases show that the AI can take a real four-unit contract, deliver without misses and pay to release transport; three finite-cargo cases avoid binding transport.

All 9,532 ordinary and 299 directed decisions replay exactly. The new financing suite has 52 checks, alongside the previous 93 expedition checks and older regressions. These small samples do not establish optimal play or permanent-route profitability.

## Core mechanics carried forward

- Social clearing/claiming and material construction are separate actions. Paid sites reserve land and are protected while unfinished. Partial construction covers marketplace, kiln, sawmill and Halls; demolished completed sites can be rebuilt without stale progress records.
- Eligible occupied rural plots can be cleared and converted, including cancellation costs for dependent legacy contracts. The combined cancellation rule is deliberately provisional.
- Recipe unlocks are global and permanent. Rural claims roll the woodland biome's provisional 65% forest / 35% field distribution.
- Each completed Hall supplies one land transport capacity.
- An expedition consumes one grain, holds one real labour token as crew, travels for six future normal town actions, then presents two buying/contracting offers and two selling offers to its sponsor.
- Goods are selected from the known material catalogue. Each direct offer has two finite units; the sponsor's trading window lasts at most six normal actions. The expedition also needs six normal actions to return.
- Purchases travel as cargo and are delivered on return into private storage if space exists, otherwise unreserved public supply. Sales use ordinary legal input access, including influence fees to rival holders.
- A standing route is owned at establishment and has automatic one-token output priority. It keeps transport committed after crew return and attempts one paid import each round. Independent routes can bind the same good. Missed payments produce missed deliveries, not free goods.
- A useful first clay expedition contract can earn a one-time town prestige reward. Route buyouts transfer both priority and transport obligations; costly cancellation releases route capacity.

The AI now distinguishes a future replacement route from readiness to execute it, gathers Hall inputs before clearing the kiln, avoids idle storage reversals that formerly prevented round closure, and reserves some gold for route operation. It remains a bounded rule-based player, not a general strategic search engine.

## Controls and inspection

Select a town object, asset, house or resource; preview its legal action and execute it. **Links** contains site claims, protected construction and land development. **Caravan** also contains expedition launch/trade/return and route actions. Travel status, finite offers, cargo, ownership and route commitments are shown there. AI step/play can substitute for manual turns; pause it before inspecting choices.

The header tracks home → industry → Hall progression. Sawmill/Halls/kiln use labelled temporary markers; stone and planks are text-only. Save/load preserves RNG, journeys, cargo, commitments and project progress. The historical replay is older material, not a recording of the current expedition rules.

## Validation and limits

See [the financing report](docs/ROUTE_FINANCING_TEST_015.md) and [the earlier expedition report](docs/LAND_EXPEDITIONS_AND_DEVELOPMENT_014.md) and compact results under `experiments/expeditions/results.json`. Full journals are generated locally and omitted from normal source packages.

```sh
godot --headless --editor --import --quit
godot --headless --path . --script res://tests/financing_checks.gd
godot --headless --path . --script res://tests/financing_experiment.gd
godot --headless --path . --script res://tests/expedition_checks.gd
godot --headless --path . --script res://tests/expedition_experiment.gd
godot --headless --path . --script res://tests/expedition_ui_check.gd
godot --headless --path . --script res://tests/contract_ui_check.gd
godot --headless --path . -- --ui-check
```

The current financing suite has 52 checks; the expedition suite retains 93. Older Hall/stockade/project/trade/priority suites remain available for regressions. Replay correctness validates recorded paths; it does not prove balance or optimal play.

Local standing contracts still use the older one-per-resource representation. Quantity-aware bindings are implemented for separate expedition routes, not yet for every local manufacturing chain. General duplicate industry construction, specialist/class systems, sea transport, broader exploration, terrain-clearing/drainage work, research, privileges, business/guild institutions and final victory conditions remain future development. Partial supply establishment also remains pending. Unlimited town brick demand remains an intentional testing outlet.

The authoritative November 2 clarification snapshots are preserved as `docs/CONFIRMED_ISSUES_AND_QUESTIONS.md` and `docs/CONFIRMED_Medieval_Town_Design_Synthesis_and_Next_Test.md`; dated earlier reports describe historical assumptions.

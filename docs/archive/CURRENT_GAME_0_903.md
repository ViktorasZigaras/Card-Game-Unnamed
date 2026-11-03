> Historical source preserved on 3 November 2026. This is not the current v0.909 rulebook. See [the handoff](../THREAD_HANDOFF.md) and canonical references. Original wording follows unchanged.

# Medieval Town — what exists in the game

**Reviewed 1 November 2026 · local version 0.903 · save schema 13**

This describes the current executable prototype, rather than the full intended game. It was checked against the active Godot simulation, live-session adapter, AI policies and experiment 013 results. The most recently uploaded repository version is 0.901; the stockade and House Halls belong to local 0.902/0.903 development. This review changes documentation only.

## The intended experience

The designer is the primary player and evaluator. The intended appeal is a planner's thinking game: understanding what a house could become, choosing a worthwhile direction, arranging dependencies, and making decisions that have consequences while rivals pursue opportunities first. Constant rewards, fast completion and universal success are not the design target.

The current prototype can test economic mechanisms and expose obstructions. The designer has not yet substantially played it or evaluated its interface/art in use. Simulated completion, replay correctness and UI layout checks do not establish human satisfaction. A useful question is whether choices produce understandable opportunities, commitments and consequences—not simply whether an AI accumulates prestige quickly.

## Starting situation and objective

Three player houses—Blue, Red and Gold—share a medieval town. All begin with zero influence, prestige and gold, no private goods and no ordinary property. They have three-token stores and a normal ownership limit of three buildings. A dedicated House Hall is exempt from that ownership limit but still uses land.

The current clayless-valley scenario starts with five wood and six grain. Its ordinary plot budget is six urban, two forest and two field. Built assets are three basic huts, a carpenter, a lumber camp and a grain farm. The unownable chapel occupies a special space outside this budget. Thus four urban and two rural plots are initially occupied. Marketplace and kiln construction fill the remaining two ordinary urban plots.

The executable player goal used by the AI is: obtain an owned brick home, then an owned industry, then pursue prestige and investments. The town records whether every house has a good home and an industry after clay importing is established. This is a milestone, not a victory condition. Play continues. House Hall completion is recorded separately and is not yet a required stage in the AI's named goal sequence, despite its growing importance to the intended house identity.

## Turns, rounds and the deck

A round starts with automatic supply processing, any scheduled caravan arrival, a shared four-card hand, and a rotating starting house. The market brings the first caravan in the following round; later visits occur every three rounds. A visit remains available during that round and has shared finite offers.

Houses normally alternate one action at a time. Passing skips the current opportunity; it does not permanently withdraw a house. Non-pass actions reset the consecutive-pass chain. Three consecutive passes end the round. Unused hand cards enter discard; the next round is processed and a new hand is drawn. If the deck empties during that round-start draw, discard is shuffled and drawing continues. Ordinary actions do not refresh the hand or schedule an extra caravan arrival.

Ordinary manual activation needs the building's card in the shared hand. It consumes inputs, produces output and immediately discards that card. A building can manually activate at most once per round. Buying access to another house's ordinary building costs one influence, paid to its owner, and that activation retains the acting house's normal turn. Fees for using somebody else's ingredients do not by themselves make an action free.

Claiming ordinary property generally also requires its card in hand. Automated public rural/workshop assets remain claimable through a separate path. Project contributions cycle their cards. Completed House Halls are an explicit exception to hand-based availability: their owner has one workshop opportunity each round independently of the shared hand.

The 40- or 60-round horizons in reports are test-script limits. The active game has no implemented final victory or mandatory end at round 40.

## Physical goods, labour and access

Physical goods are wood, grain, clay, brick, furniture/chests, minor luxury, labour/pop, stone and planks. Influence, prestige and house-held gold have different accounting and are not three-token-store goods.

Goods persist between rounds. Produced goods enter the general supply. At most one token from an output batch is reserved for the producing house until its next action; the remainder is public. Passing expires old priority, and a paid rival-building activation also expires old priority even though it retains the normal turn. Existing priority can be overridden by the defined influence payment; it is not an absolute exclusion right.

| Access | Current consequence |
|---|---|
| Public goods | Immediately usable as inputs |
| Own reserved goods | First opportunity to use; no access payment |
| Rival reserved input | One influence per unit to its holder; consume immediately |
| Own protected store | Usable for own input payments |
| Rival protected store | Two influence per unit to its holder for immediate input use |
| Take action | Move one eligible token into own three-token total store |
| Committed export wood | Excluded from ordinary public/private input payment |
| Paid project progress | Already consumed; cannot be seized or reused as goods |

The protected-store override currently does not require an additional proof of emergency. It also does not let a house stockpile a rival's bought-through resource. All access paths require an existing physical token and enough influence; they cannot create missing brick or labour.

Labour has a town-wide maximum of six tokens. Physical labour in supply/stores plus committed labour plus unissued capacity equals six. Work consumes a physical labour token and frees capacity so housing can manufacture labour again. These are not individually housed residents. Town expansion does not currently raise this cap. Several contracts can commit capacity, potentially leaving too little labour for ordinary work.

## Buildings and recipes

| Asset | Ordinary function | Improved function / restriction |
|---|---|---|
| Lumber camp | No input → one wood | One labour → two wood; basic option retained |
| Grain farm | No input → one grain | One labour → two grain; basic option retained |
| Basic hut | One grain → one labour | Upgrade needs two wood, one brick, one labour |
| Brick home | Basic hut recipe retained | One grain + one minor luxury → two labour, if capacity exists |
| Carpenter | Two wood + one labour → one furniture/chest | Ordinary workshop; can be automated |
| Kiln | One clay + one labour → one brick | Build for two wood + one labour; kiln upgrades disabled in this scenario |
| Small sawmill | One wood + one labour → two planks | Build for two wood + one labour on a forest plot; upgrades disabled |
| Chapel | No input → two influence | Two stone + one wood + one labour upgrades output to exactly three influence |
| Marketplace | Passive caravan access | Build for three wood + one labour on an urban plot |
| House Hall | One chosen known workshop recipe per round | Three planks + one stone + one labour; three influence consumed on starting |

The sawmill is a rural processing exception: unlike the camp/farm's basic gathering recipes, it consumes both wood and labour. The chapel is unownable and usable by houses tied for the fewest upgraded homes; it is a temporary catch-up measure based on one metric.

An ordinary industry is a built rural or workshop asset owned by a house. An automated owned camp/farm/workshop counts. A Hall has a separate role and does not count toward that objective.

## Social currencies and exchange

Influence is capped at ten per house. A first idle pass can award one influence if the house has done no work that round and has not already received that round's idle reward. Later re-entry is permitted; the earlier reward is not clawed back. The chapel, public deliveries and bulk exchange provide other sources. Access fees transfer influence; ownership and some development actions consume it. Receipts above the cap are lost.

| Action | Cost / reward |
|---|---|
| Claim ordinary public building | Consume three influence |
| Hall start | Consume three influence, in addition to physical construction |
| Convert influence | Five influence → one prestige; normal action |
| Bulk exchange | Consume three stored physical tokens → three influence |
| Build marketplace | Award two prestige |
| Establish clay service | Award three prestige |
| Complete brick-home upgrade | Award five prestige |
| Deliver town brick | One brick → two influence, currently standing/uncapped demand |
| Deliver stockade wood | One wood → one influence, only while its six-wood requirement remains |
| Claim outer rural plot for town | One labour → one prestige, at most four claims |

Bulk exchange consumes tokens in the fixed goods order until three have been spent. It is not a player-selected three-item bundle. Prestige has implemented expenditure on priority titles, title buyouts, eligible cancellation and unowned demolition. It is not only a score.

## Standing supplies and property rights

Three separate advantages exist: owning the production building; establishing its supply link; owning a prestige-bought recurring output-priority title. They are not interchangeable.

A generic standing contract consumes setup inputs, often commits a labour-capacity token, removes ordinary manual card operation from its source, and attempts one output per eligible refresh. Its recurring inputs must be public; missing inputs cause a missed delivery. There is currently at most one standing contract per resource, across the whole town.

The live adapter uses contract-policy batch 3. In this configuration:

| Supply | Setup consumed | Capacity held | Recurring public input | Cadence |
|---|---|---:|---|---|
| Wood | One wood + one labour | One labour | None | Each round |
| Grain | One wood + one labour | One labour | None | Each round |
| Furniture | Two wood + one labour | One labour | One wood | Each round |
| Labour from an owned hut | One grain + one wood | None | One grain; free token capacity required | Each round |
| Minor luxury | Two wood + one labour | One labour | Two wood | Caravan visits |
| Planks | One wood + one labour | One labour | One wood | Each round |
| Clay import | One chest consumed; one wood and one labour held | One labour, plus the separate wood backing | No further wood payment | Immediately on setup, then each visit |

The wood/grain/furniture/labour/plank sources must exist; local source ownership restricts who may establish the link. Generic setup itself does not consume influence/prestige. The separately purchased priority right does. This distinction matters when interpreting “buy a contract using social currencies.”

The preset lumber comparison uses one committed labour and an existing automatic lumber source. Generic contracts normally first deliver at a later refresh. Clay is the explicit immediate-delivery exception. Cancelling its service releases its backed wood and committed labour; setup chest is not refunded.

A standing title begins at three prestige. Each purchase consumes the displayed price and raises the next buyout price by two. The first scheduled delivery priority belongs to the creator; subsequent deliveries use the current title owner, if any. Priority reserves one output token, not the entire stream forever. Cancellation is legal at an elevated prestige price; the final formula is the greater of current title price + three and the underlying service's cancellation base + four. The AI's cancellation policy is much narrower than legal permission.

The broad design intention permits supply arrangements for any physical resource. The current catalogue does not fully implement that intention: direct brick-import contracts are deliberately filtered out of the current scenario, and there is no stone standing contract. Existing local brick production is manual kiln/Hall work.

Upgrading an automated source preserves its base automatic supply. Its returning card performs only the extra inputs and extra output; it cannot manufacture the automated base output a second time. Partial upgrade cards also retain their own explicit circulation rules.

## Caravan and trade

Each visit has one shared brick export order: one brick earns one gold. Gold is held by houses outside their physical stores. Stone costs one gold, with two stone available per visit. Prestige costs two gold. Bricks are not currently sold to houses; the caravan's retained older `bricks_left` field is not proof of an active brick-sale action. There is no implemented domestic cash market, treasury, transport fleet or rotating trade deck.

## Public work and land

The stockade is a special construction requiring six wood. Voluntary one-wood deliveries award one influence each. At round closure the town takes unreserved public wood to fill its remaining wall need, then the chapel's missing one wood if relevant. It does not touch active reservations, protected stores, export backing or consumed project progress, and awards no house currency for automatic collection. It stops when these known tasks have their wood.

After the wall, two vacant rural plots may become urban for one stone and one labour each. Both conversions are required before four outer claims unlock. Claims consume one labour, benefit the shared town, award the acting house one prestige, and add exactly two forest plus two field plots.

The budget therefore changes from urban 6 / rural 4, to urban 8 / rural 2 after conversion, and finally urban 8 / rural 6 after all claims. Houses perform the claim actions on the town's behalf; there is no general independent town turn/planning engine. The end-of-round wood routine is limited town agency, not a mayor AI.

## Construction, demolition and the missing replacement action

Home/chapel upgrades accept partial physical contributions; their base function remains until the new level completes. New sawmill/Hall construction also accepts partial payment, but remains nonfunctional until finished. Starting a new site requires a nonzero contribution and reserves land immediately. A sponsor must finish its existing new site before starting another; other houses may help a public sawmill. Completed Halls lose their construction cards; the sawmill retains a production card.

Marketplace/kiln construction is still all-at-once. Partial service establishment is not implemented. The active legal action list does not expose general construction of additional huts or duplicate workshops, despite older inherited code and data fields mentioning construction.

Paid demolition exists for eligible built, unowned, nonspecial assets with no protected active dependency. It consumes one prestige for rural or three for urban. Private property is not ordinarily claimable/demolishable through these actions.

**Full-price force overbuilding is part of the agreed design but is not implemented.** There is no atomic replacement transaction that pays the replacement price, resolves the old site/rights and builds the new structure. Two extra vacant urban slots therefore do not establish an intended permanent maximum of two Halls; they expose the missing restructuring path.

**Confirmed bug:** legally demolishing a completed public sawmill leaves its completed construction record behind. The building becomes absent but the site record still says complete; the invariant fails and new construction cannot restart it. The audit reproduced this without modifying the game. Consequently, earlier wording that demolition could cleanly rescue the early-sawmill expansion obstruction was too strong.

## What has actually been validated

Experiment 013: twelve 60-round games, with six feature-enabled towns and six controls. All 6,218 recorded decisions passed then-current checks, replayed exactly, and all twelve saves restored exactly. Enabled towns built six sawmills, started twelve hall sites, completed eleven Halls and performed seventeen Hall operations, all brickmaking. The remaining Hall lacked stone. All towns had only two additional free urban slots.

Dedicated Hall checks total 56, plus existing stockade/project/trade checks of 47/31/22. UI checks cover a live game, new construction/manufacturing commands, 83 archived states and exact saves. They establish tested mechanics and measured layout, not finished art or personal play satisfaction. The newly reproduced sawmill-demolition failure was outside the actions selected in those games and narrows any blanket claim of completeness.

## Not present yet

General force overbuilding; a complete catalogue of source-specific/alternative contracts; partial construction for every old building; partial supply establishment; individual specialists or class/training; land/sea transport; expeditions; a town treasury; rotating trade decks; actual research; privileges; business/guild/institution mechanics; final victory conditions; adaptive player learning or a general multi-turn planner.

The two companion documents explain the active player policy and the updated design direction. `ISSUES_AND_QUESTIONS.md` separates implementation work from twelve answerable design decisions.

## Source map

The live entry point is `ui/live_session.gd`: `HallSimulation`, `HallAI`, batch 3. Active mechanics flow through `hall_simulation.gd`, `stockade_simulation.gd`, `project_simulation.gd`, `trade_simulation.gd`, `capacity_simulation.gd`, `priority_simulation.gd`, `contract_simulation.gd`, and `marketplace_simulation.gd`. Definitions and initial parameters begin in `data/marketplace_rules.json` and are extended by these classes. Evidence comes from `experiments/halls/results.json`, the test scripts and this review's `AUDIT_EVIDENCE_0903.json`.

## Designer clarifications — 2 November 2026

All twelve audit questions have now been answered. These are design instructions, not a claim that the v0.903 code has been updated. The original inventory/policy descriptions remain statements about that executable version. If an earlier provisional suggestion conflicts with the following answers, the answers take precedence.

**Design target:** clearing/claiming uses social currency and is a separate action from material construction; ongoing sites are protected from further overbuilding. Clearing may include dependent-contract cancellation at its added price, highly provisionally. Otherwise legal occupied rural plots may convert at their full associated costs. Halls retain owner-only off-deck use and a unique allowance; all unlocks are global and permanent. Bindings attach to quantities of supply, not a resource monopoly. Expansion is biome-weighted with later terrain transformation. Unlimited brick demand remains a test placeholder. None of these clarifications silently changes the executable v0.903 rules listed above.

See the updated `ISSUES_AND_QUESTIONS.md` and design synthesis for all twelve answers and their qualifications.


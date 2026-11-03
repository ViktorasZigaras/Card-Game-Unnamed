> Historical source preserved on 3 November 2026. This is not the current v0.909 rulebook. See [the handoff](../THREAD_HANDOFF.md) and canonical references. Original wording follows unchanged.

# Medieval Town — what the player AI is and how it chooses

**Reviewed 1 November 2026 · local version 0.903 · active policy: HallAI**

This is a description of executable behaviour, not a fictional account of the houses' reasoning. It distinguishes actual scoring, the small amount of explicit counterfactual testing, observed outcomes and the planning capabilities still missing.

## What “AI” means here

The current player is a deterministic, rule-based action selector. For the acting house, it obtains the simulation's legal actions, assigns scores, applies several successive policy layers and selects the highest final score. Ties keep the earliest candidate because selection uses a strict greater-than comparison. Legal-action enumeration order can therefore affect equal-score outcomes.

It is not an LLM operating inside the game, a trained neural player, an opponent that learns from past games, or a general search over future turns. It is not the advisor/general/governor hierarchy used in the separate Alien Planet project. Blue, Red and Gold each run the same policy code against their own current situation.

The simulation owns legality and resolves consequences. The policy cannot spend nonexistent inputs, ignore an access payment, exceed a land budget or invent a manufacturing recipe through its scores. Conversely, making an action legal does not guarantee that the policy gives it a useful score or recognises when it matters.

## A decision, step by step

1. Read the current house, town stocks, private stores, reservations, buildings, known recipes, project payments, contracts, land, current hand and caravan state.
2. Ask `legal_actions()` for the actions permitted now, including payable construction bundles and paid input-access plans.
3. Run the inherited scoring layers. Earlier scores may be replaced by later ones; they are not all independent benefits being summed.
4. Return the chosen action, final score and candidate records, alongside objective/status fields and some explanations.
5. The probe applies the action, checks invariants, and records its result and complete snapshot. The next decision is recomputed from the resulting state.

The last step is reactive reconsideration, not persistence of a declared project plan. A partially built site persists in the game, but there is no separate AI plan object saying “obtain stone next, finish this Hall by round 45, and stop spending gold elsewhere.”

## The active policy layers

The live session instantiates `HallAI` and uses contract batch 3. Its chain is:

`MarketplaceAI → ContractAI → PriorityAI → KilnAI → TradeAI → ProjectAI → StockadeAI → HallAI`

MarketplaceAI inherits the HouseAI interface but builds its own candidate list. The older CommonsAI/ReservationAI/HousingAI policies remain in the project for earlier experiments; their full decision procedures do not form the active chain. Counting every old script as a current personality or planning subsystem would be misleading.

| Layer | Role in current choices |
|---|---|
| Marketplace | Produce and build toward market, clay access and an improved home |
| Contract | Supply thresholds, automatic links, surplus management and idle collection |
| Priority | Buy recurring priority, check extreme labour-lock cancellation, support incremental upgrades |
| Kiln | Build and operate a local clay-to-brick route |
| Trade | Define home/industry/prestige phase; sell brick, obtain gold, purchase prestige |
| Project | Prioritise full/partial home upgrades and later chapel investment |
| Stockade | Donate wood, convert rural land and claim outer plots |
| Hall | Preserve initial rural space, build sawmill/Halls, buy stone and perform a known workshop recipe |

The highest-level file does not rewrite every candidate. Some old assumptions and explanations therefore survive underneath a newer phase. For diagnosis, the final action, final score and payment plan are stronger evidence than a generic reason string inherited from an earlier experiment.

## The named objective hierarchy

TradeAI computes three phases:

| Phase | Condition and usual focus |
|---|---|
| Home | No owned level-two hut: secure/upgrade a home and obtain its ingredients |
| Industry | Good home exists but no owned rural/workshop asset: acquire an industry |
| Prestige | Both exist: prestige conversion, trade, public works and later investment |

This is a policy convention, not a legality rule. A human may take a legal Hall or trade action in a different order.

Halls have construction scores inside the prestige phase; there is no fourth named “establish headquarters” objective. This falls short of the latest design emphasis on a house needing its seat. Similarly, the policy has no business/guild/institution objective yet.

The early MarketplaceAI also carries a town stage: marketplace absent; clay service absent; otherwise brick-house development. These older stage labels coexist with the newer house phase and can affect leftover scores.

## Important final scores and conditions

Scores are relative priorities, not economic prices, expected profit, probabilities, or a common measure of prestige. They make the policy's ordering reviewable but do not prove the ordering is strategically correct. Later rules can override earlier scores or suppress an action.

| Choice | Score / gate used by the active layers |
|---|---|
| Complete an owned home upgrade | 300 |
| Partial home contribution | 200 + ten per supplied unit, plus twenty if brick is included |
| Start own Hall | 245 + bundle units; only after home and industry, with sawmill built and planks in the initial bundle |
| Supply a new construction site | 240 + bundle units; only after home and industry |
| Start sawmill | 235 + bundle units; after home/industry and at least one outer rural claim |
| Buy stone for own Hall | 225 when a Hall route/plot exists, stone is missing and no physical stone exists town-wide |
| Operate sawmill | 215 while settled and physical planks are below the policy's estimated Hall demand |
| Complete chapel upgrade | 210 if settled; otherwise suppressed |
| Buy stone for town works | Normally 205; 207 under stockade/land demand conditions |
| Buy caravan prestige | 200 in prestige phase |
| Partial chapel contribution | 190 + supplied units if settled |
| Claim first industry | 185 when home exists and industry does not |
| Claim outer rural plot | 180 if settled |
| Export brick for gold | 170 in prestige phase |
| Convert rural plot to urban | 155 if settled |
| Hall brickmaking | 150 when total physical brick is below unfinished-house count + two |
| Hall carpentry | 150 only while clay importing is absent and physical furniture is below one |
| Cancel a contract | 145 only if the narrow labour-lock assessment is justified |
| Chapel for Hall influence | At least 140 if settled, Hall route exists and influence is below three |
| Make labour for later construction | At least 130 if settled, fewer than two physical pops exist, and own Hall or mill is unfinished |
| Town brick delivery | 130 if already settled and influence at most eight; can be 175 when industry acquisition needs influence |
| Stockade donation | 75 when settled and influence at most nine; 110 in an influence-poor spare-wood case |
| Influence → prestige | Common settled score 45; suppressed while saving for a feasible Hall if influence is below eight |
| Pass | Normally zero; therefore beats suppressed negative-score choices |

Many foundational choices have conditional scores rather than one place in this table. Market construction and clay service setup begin at 180 minus input-access cost. Early manual production uses supply thresholds and sometimes the house's production bias. Kiln work is favoured while unfinished homes need brick. Full legal-action and score records in the journals are the authoritative explanation for a particular decision.

## How it handles materials and social currencies

The policy uses current stock thresholds and reserves rather than a complete projected bill of materials. It tries to keep wood for unfinished homes, grain for labour, and scarce brick for house upgrades. A missing home can take a brick into its store; partial upgrades can consume a brick immediately into persistent progress so another house cannot purchase it away later.

Idle houses may collect surplus tokens using a deterministic hash of seed, house, round and resource. This gives varied choices without advancing the simulation RNG during decision inspection. It is not random deliberation or learning.

The policy can exchange stored surplus for influence, convert influence to prestige, and consume prestige on recurring priority rights. HallAI avoids exchanging stored stone/planks while its own Hall is unfinished and saves influence in some feasible-Hall cases. These are specific guards, not a universal future-budget system.

Current weaknesses include using town-wide physical stone as a purchase threshold even when that stone is controlled by someone the acting house cannot afford to pay; and counting an unbuilt third Hall in plank demand without checking whether it can secure a plot.

## Contracts and buyouts

Basic supply scoring responds to low wood/grain/labour/furniture/luxury stocks and finite labour capacity. Batch-3 amendments constrain automation when committing a token would leave too little free labour, and suppress redundant furniture production after clay service setup. Plank supply contracts are legal and fixture-tested but lack a dedicated proactive AI establishment score; the latest enabled games never established one.

Recurring priority purchases use current scarcity and a short list of needed resources. Before a good home exists, the buyout score starts at 72 minus twice the title price; after a good home it starts at 38 minus twice the price. TradeAI suppresses these purchases outside the prestige phase, so the earlier “before a home” purchase branch is effectively overridden in the active policy. This illustrates why inherited intentions are not equivalent to final behaviour.

A higher-priced title can be bought out legally. The policy does not generally calculate the long-term return, the number of future deliveries needed to justify the purchase, or an opponent's willingness to buy it back.

## The actual counterfactual reasoning

There is one narrow explicit “what if” check for cancellation. If the acting house lacks an improved home, no physical labour exists and all token capacity is committed, PriorityAI clones the current simulation and tries the proposed cancellation. It checks whether capacity is freed and some built labour-producing recipe would then be fundable. It records the assessment and the possible need to wait for a card.

This is genuine executable counterfactual evaluation, but it is restricted. It does not verify a complete sequence to that house's finished home, calculate a waiting horizon, compare all import/upgrade/replacement alternatives, or apply the same reasoning generally to stone, land, Halls and industry. Its import-alternative comments are assumptions about the current catalogue, not an exhaustive general route search.

The rules permit elevated-price cancellations more broadly than this policy chooses them. Ordinary demolition is scored useful only in a narrow camp/farm-surplus case, not as a general route to a missing Hall. Force overbuilding has no action or AI evaluator at all yet.

## What the houses do not model

- No persistent ordered construction/supply plan with a reserved future budget.
- No broad search over several turns or predicted shared-hand draws.
- No explicit rival plan, forecast of what rivals will buy next, or adversarial response tree.
- No learned strategy or adaptation across simulation runs.
- No general comparison of “keep current use of land” against “replace it and obtain headquarters.”
- No universal expected return calculation for buildings, titles or imported stone.
- No general fairness objective or guarantee of a home/Hall for every house.
- No coherent town government inside the player policy; common-benefit heuristics coexist with private export incentives.

Those limits matter for the intended planner's game. A human may exploit recognisable thresholds and tie order. More simulation runs of the same policy cannot alone demonstrate that a new rule offers a strong strategic choice.

## Personalities: what is and is not active

Blue stores production 1.3, ownership 1.2, trade 0.7; Red stores 0.9/0.8/1.5; Gold stores 1.0/1.4/1.0. The active MarketplaceAI uses production bias in some early output choices. The active policy chain does not generally use the stored ownership/trade weights. Later construction and trade rules use shared scores.

The policy reads the full current simulation state, including all houses' stored goods and titles; no hidden-information restriction is currently implemented.

Thus a result in which Gold claims several plots is not sufficient evidence of a fully implemented ownership-driven Gold personality. Current variation mainly comes from position/order, card sequence, ownership, stocks and a limited production preference.

## What the recent games demonstrate

The six Hall-enabled towns built all six sawmills, completed eleven Halls and performed seventeen Hall operations—all brickmaking. One Hall lacked stone, and one house per town lacked an additional vacant urban slot. All six made ten planks despite two Hall sites requiring only six. This is a demand-estimation error, not a new rule requiring ten planks.

Enabled games reached all home/industry goals in five of six, controls in four of six, by round 60. Some goal differences occurred before the first completed Hall; the treatment changes policy as well as available mechanics, so the difference cannot be credited solely to Hall production.

An action audit of the six enabled journals found no luxury supply contracts and no enhanced hut activations. Huts were used in basic mode; the chapel did use its enhanced mode 28 times. Thus the improved-home manufacturing recipe exists, but these games did not demonstrate a policy that plans the luxury input to exploit it. The correct conclusion is limited coverage and weak capability use, not that the recipe is absent.

The same audit accounts for every produced brick across the enabled games: 73 kiln bricks + 17 Hall bricks = 90; 17 home upgrades + 24 town deliveries + 49 caravan exports = 90. Scarce brick was being allocated to legal uses. Simply increasing output would not explain or repair which plan gets priority.

All 6,218 decisions in the twelve-game batch replayed exactly. That proves those recorded choices reproduce their consequences. It does not establish optimal play, equal opportunity or coverage of every legal action. The review's separate sawmill-demolition fixture found a bookkeeping failure outside the selected batch paths.

## What should improve next

First make the agreed restructuring actions executable and fix the confirmed demolition bookkeeping error. Then make the AI recognise a concrete blocked goal, compare legal routes to it, preserve a short plan and price the loss of the displaced function. Fix feasible plank demand rather than simply suppressing all surplus production. Promote headquarters to an explicit objective in the order the designer selects.

For future policy experiments, record the proposed goal, alternative routes, scarce inputs/rights/land, expected completion sequence, opportunity cost, reasons to reject alternatives and conditions that trigger replanning. That would make smart decisions inspectable in the planner's game the user actually wants, without pretending a score table already provides that reasoning.

## Source map

`ui/live_session.gd`; `hall_ai.gd`; `stockade_ai.gd`; `project_ai.gd`; `trade_ai.gd`; `kiln_ai.gd`; `priority_ai.gd`; `contract_ai.gd`; `marketplace_ai.gd`; `game_probe.gd`; `tests/hall_experiment.gd`; `experiments/halls/results.json`. The review distinguishes static code findings, existing experiment outcomes and a new focused audit fixture. No AI behaviour was changed for this document.

## Designer clarifications — 2 November 2026

All twelve audit questions have now been answered. These are design instructions, not a claim that the v0.903 code has been updated. The original inventory/policy descriptions remain statements about that executable version. If an earlier provisional suggestion conflicts with the following answers, the answers take precedence.

**Policy target:** home → industry → Hall → remaining opportunities. Seek an identifiable benefit for the acting house; if the private gain is unclear or absent, pursue useful town development. Prefer a credible visible supply/production route, allowing for plausible stochastic supply; prepare brute force only when none can be deduced. Planning must also account for quantities bound along enabled production chains and biome-dependent land. These are the agreed targets for a future policy update, not new capabilities of the scored v0.903 player. All unlocks are global and permanent.

See the updated `ISSUES_AND_QUESTIONS.md` and design synthesis for all twelve answers and their qualifications.


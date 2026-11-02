# Medieval Town — audit findings and twelve answered design decisions

**Updated 2 November 2026 · code baseline v0.903 · all twelve clarification answers recorded**

This replaces the stale 0.5-era queue. The original fifteen ideas remain in the rewritten design synthesis. The current-game inventory and player-AI reference describe the executable system. No mechanics were changed during this review.

## Working agreement and intended appeal

The designer is the primary player. This is a planner's thinking game about what a house can become, consequential smart decisions and rivals securing opportunities first. More rewards, faster completion or success for every simulated house are not automatic improvements.

Keep assumptions explicit. Test small batches with reproducible seeds and log consequences. Simulations provide evidence about the model and policy; first-hand UI/art and human strategic judgment remain to come. This broad audit lists the decisions together because it was requested; discussion can still proceed one topic at a time.

There are **twelve answered design decisions below**. They were not twelve errors; implementation gaps and the confirmed defect remain separately tracked. Programming defects, already-agreed mechanisms and provisional balance numbers are separated so they do not become unnecessary questions for the designer.

## A. Findings that do not need the designer to decide them again

| ID | Finding | Required handling |
|---|---|---|
| G1 | Force overbuilding/full-price replacement is part of the intended design but has no executable action. Existing demolition is not equivalent. | Implement the already-intended staged transaction using Q01–Q04; numeric costs and Q02 remain test assumptions. Do not treat two free urban slots as a permanent intended two-Hall ceiling. |
| G2 | Any physical resource should in principle admit an appropriate supply contract, but the current scenario disables brick-import contracts and has no stone standing service. | Preserve the design intention; document catalogue restrictions and add justified prerequisites/routes when those resources need general supply options. |
| G3 | Partial work is intended generally, but only home/chapel upgrades and new sawmill/Hall builds implement it. Market/kiln construction and service establishment remain atomic. | Track the missing paths as engineering scope. Do not claim universal partial construction already works. |
| G4 | Old documents still described recurring public-wood clay payments, imported-brick barter, no prestige spending and no town action. | Supersede those statements with the current reference; retain historical reports as history. |

**Confirmed defect B1 — completed sawmill demolition:** an allowed demolition removes the public building, frees its plot and spends prestige, but leaves `houseworks.sites.small_sawmill.completed = true`. The building is then absent, `construction functionality: small_sawmill` fails, and new sawmill construction cannot restart. This is bookkeeping failure, not a question of whether the designer wants a demolished building to remain completed. The focused audit reproduced it from a valid fresh fixture; no game code was edited. Evidence is in `AUDIT_EVIDENCE_0903.json`.

The earlier experiment's 6,218 passing/replayed decisions remain valid for their paths. None of the six Hall-enabled games selected demolition. They did not test this escape route, so earlier statements that a completed early sawmill could simply be demolished to rescue expansion need this correction.

## B. AI limitations to fix or test, rather than ask as game rules

- **Feasible demand:** HallAI counts planks for a third unbuilt Hall without checking that it can secure land. All six enabled towns made ten planks although the two Hall sites needed six. Do not balance the sawmill around that error.
- **Short-term choice:** scores select the best-looking legal action now; the policy has no general multi-turn construction/supply plan or future budget. Most “reasoning” is explicitly supplied rules. A narrow labour-cancellation clone check is the exception.
- **Stale priority/explanation:** later policy layers can replace old scores without fully replacing their explanations. Record the final score and actual alternative routes; do not present inherited text as proof of comprehensive reasoning.
- **Limited personality:** ownership/trade bias values are stored but largely unused by the active policy. Production bias affects some early choices. Do not attribute a land grab to a rich personality merely because a coloured house performed it.

A further coverage limitation: the six enabled journals contain no luxury contract and no enhanced hut activation, despite the improved recipe being legal in suitable conditions. Improved housing is therefore demonstrated as a home/prestige milestone, but not as an actively exploited advanced labour plan in this batch.

These are implementation/policy issues. They do not require declaring the game easier or prohibiting legal competitive actions.

## C. Twelve answered design decisions

The clarification sequence is complete. The answers below supersede conflicting provisional interpretations. Numeric balance and the explicitly uncertain cancellation rule remain subject to tests.

### Q01 — Clearing, claiming and building are separate stages

Social currency clears and claims the site; physical construction inputs build the replacement. Clearing/claiming and construction are two separate actions. The ongoing construction process is protected: nobody may overbuild that site again while it is underway. Exact currency denominations remain testing parameters; the answer establishes the cost categories and action separation, not automatic approval of every example price. This protection supersedes the earlier tentative full-price exception for displacing unfinished construction.

### Q02 — Clearing may include dependent-contract cancellation — highly provisional

Choose combined cancellation: clearing the site may cancel its dependent contract, adding the cancellation price to the clearing bill. It does not need a separate preceding cancellation action. The designer explicitly attaches huge uncertainty to this choice until the situation is encountered and simulated. Rights, committed tokens and dependent chains must be resolved consistently in those tests; do not treat this provisional answer as proven balance.

### Q03 — Occupied rural plots may be converted when otherwise legal

Anything otherwise eligible may be converted to urban, including an occupied plot. Account for the associated clearing, contract, conversion and lost-function costs; a legal conversion may be expensive and strategically pointless. A fresh empty unowned plot is usually preferable because those additional costs are avoided. This does not waive ownership protection, construction protection or conversion allowances.

### Q04 — Pursue credible routes; prepare brute force when none is visible

If a real theoretical way out is visible, pursue it. Include plausible randomness of supply when assessing the route. If no visible route can be deduced even after considering that supply uncertainty, prepare the resources and social currency needed to force a way through. Preparing is not automatic immediate destruction. The AI must distinguish an actionable theoretical route from indefinite vague hope, and expose why it believes a route exists or fails; numerical confidence/waiting thresholds remain untested.

### Q05 — The house development sequence

Good home → owned industry → House Hall → exploit the remaining mechanisms for prestige and further advantage. Headquarters is an explicit stage before farming the leftover opportunities, not an optional score bonus inside a generic prestige phase.

### Q06 — Permanent owner-only Hall opportunity

Confirmed: a completed Hall gives its owner one workshop opportunity each round, independent of the shared deck. Choose a known/unlocked recipe and pay its inputs; no passive production is implied.

### Q07 — A unique headquarters allowance

The headquarters is the core of that player house and one of a kind for it. Each house has its own unique Hall allowance outside the three ordinary property slots. It still requires its urban plot.

### Q08 — All unlocks are global and permanent

All unlocks are for everyone, permanently. This applies beyond the current kiln recipe example; the per-house knowledge hook must not accidentally become an exclusive knowledge design. Keep the possible late-game consequence for later: unlocking something unnecessary for your own victory may help rivals too much. This is a deferred strategic consideration, not a new mechanic to implement immediately. Shared unlocks do not supply free ingredients or automatically satisfy operational prerequisites.

### Q09 — Bind meaningful quantities of supply, including production chains

If three grain outputs are possible in town, each should be meaningfully bindable. Do not impose one monopoly contract per resource type, or assume that one contract per building is sufficient if one source supplies several outputs. Bindings must account for enabled production chains and a theoretical way to obtain upstream inputs. Processing may extend or enlarge downstream supply—for example, two grain into two or more bread. Bread is an illustrative future recipe, not an instruction to add it now; an upstream possibility is not magically guaranteed stock.

### Q10 — Biome-weighted rural expansion, with later terrain work

New rural plot types come from a percentage roll based on the town biome, rather than a fixed two-forest/two-field package or unrestricted player selection. Terrain can subsequently be transformed by appropriate work, such as cutting woodland or draining swamp. Probability tables, costs, yields and consequences need later specification/testing; do not create free conversion or swamp mechanics just to fill them in.

### Q11 — Brick demand is a testing shortcut

Unlimited brick-for-influence is a provisional reason to manufacture, standing in for unrealised and untested dependencies and uses. It is a preview of future demand, not a commitment to permanent unlimited town consumption and not an instruction to invent a quota immediately.

### Q12 — Private benefit first; civic development as a useful fallback

Benefit the acting house when able. If private gain is uncertain or there is no outright private gain, improve the town through useful available work. Civic development is a fallback rather than a blanket instruction to sacrifice a clear private opportunity. It need not guarantee an immediate personal payout; the AI should identify the public improvement it is pursuing.

## D. Already settled; do not recycle as questions

- Passing allows re-entry; consecutive passes close the round.
- Paid ordinary rival-building activation retains the normal turn.
- Resource-access payment buys immediate use, not a bidding contest or a right to stockpile the bought-through resource.
- Influence/prestige expenditure should create a need to replenish social currencies.
- A reservation is temporary first access; consumed project progress is no longer a stored good.
- Partial builds can reserve land and remain nonfunctional; partial upgrades retain the old function until complete.
- Full-price forced replacement is intended to address genuine blockages; its absence from code is not an argument against the concept.
- A House Hall is the house's seat and is not yet a business, guild or institution.
- The finite labour-pool concept remains; its current cap and balance prices are test parameters.
- Human satisfaction is to be evaluated for the designer's planning preferences, not inferred from reward frequency or universal AI completion.

## E. Suggested implementation and testing order

The question sequence is complete. Implement the confirmed stage/protection rules and fix B1; test the highly provisional combined contract cancellation explicitly. Update the AI objective to home → industry → Hall → leftover opportunities, with Q04 route assessment and Q12 civic fallback. Quantity-based bindings and biome-weighted expansion are confirmed directions that need scoped implementation, not silent one-resource monopolies or fixed terrain. Global permanent unlocks must remain consistent across future systems.

A useful next matched test should show a real house lacking a Hall site, compare keeping versus replacing an eligible use, pay the complete bill, and observe the displaced supply's consequences. Include finished sites, rejection of overbuilding any protected ongoing site, active rights, no-cost-replacement rejection, card identity, token/commitment conservation and saves. Correct the feasible plank estimate in a separately attributable change. Do not quietly enlarge land or forbid exports to force a preferred result.

## Evidence and scope

Reviewed the v0.903 live adapter, active simulation/policy chain, original Library synthesis/queue, experiment 013 results and a new isolated demolition fixture. No game rules, AI scores, code version or repository upload were changed. The two new reference documents and rewritten synthesis provide the detailed context for this register.

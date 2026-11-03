> **Historical document.** Retained for its original version/experiment; its recommendations and missing-feature claims may be superseded. For current v0.909 rules, decisions and next work, start with [THREAD_HANDOFF.md](THREAD_HANDOFF.md). Historical results below are not relabelled as current validation.

# Medieval Town — design synthesis, current ideas and the next useful test

**Updated 2 November 2026 · code baseline v0.903 · designer clarifications incorporated**

This replaces the old 0.5-era synthesis as the current design reference. Its original fifteen concepts are retained below, with their present status. Earlier versions and experiment reports remain historical evidence, not current specifications. This is documentation reconciliation, not authorization to change all provisional rules at once.

## 1. The game being designed

Noble/merchant houses compete and cooperate within one developing town. A house should be able to establish itself, secure useful dependencies, obtain a recognised seat, acquire capabilities and become something more substantial. Rivals may secure those opportunities first. The town has interests of its own, which sometimes align with a house and sometimes compete for its materials, labour or land.

The designer is the primary intended player. The appeal is a **planner's thinking game**: recognising possibilities, making smart consequential decisions and understanding what a house might become. Immediate reward frequency, rapid prestige accumulation and completion by every player are not substitutes for that purpose. UI/art judgment will come from actual use; the designer has not yet substantially played the prototype.

Cards limit and vary current opportunities, while physical resources, titles, commitments, projects and land persist. The important distinctions are between owning a building, being allowed to use it, having usable output now, securing future priority and possessing the capability to perform a more advanced activity.

A promising progression remains: operate → secure → commit → specialise → restructure → achieve. This is a useful description of possible development, not a compulsory identical ladder or a final victory condition.

## 2. Status language

- **Design commitment:** stated direction to preserve unless the designer changes it.
- **Executable:** available in local v0.903, with the limits described in the current-game inventory.
- **Provisional:** an implementation price, restriction, ordering or yield supplied for testing rather than final design.
- **Deferred:** a recorded idea that must not be described as already functioning.
- **Implementation gap:** an intended mechanism is missing; it is not a request for the designer to approve the same idea again.

A replayed simulation validates its recorded consequences. It does not settle strategic value, fairness, human satisfaction or optimal play.

## 3. The original fifteen concepts, reconciled

| Original topic | Present status and retained direction |
|---|---|
| 1. Passing and re-entry | Executable: pass skips a turn; all houses passing consecutively closes the round. An idle reward is currently limited to once per eligible house per round. |
| 2. Paid access | Executable: one influence for a rival building or reserved input; two for protected stored input; transfers pay holders and buy immediate use. It cannot create absent tokens or reclaim consumed progress. |
| 3. Building/card availability | Executable for ordinary manual buildings: one activation per round, discard immediately. Automation, partial-project cards and permanent Halls are explicit exceptions requiring coherent documentation. |
| 4. Finite labour | Executable: a town-wide token pool; work releases capacity for later generation, while commitments retain capacity. Six is the current test cap, not a demographic conclusion. |
| 5. Catch-up chapel | Executable: special, unownable and outside ordinary land. Current access uses fewest upgraded homes; upgrade raises output from two to three influence. That single-metric ranking is provisional. |
| 6. Influence/prestige | Executable: capped influence, voluntary five-to-one prestige conversion, title purchases/buyouts, cancellation and demolition expenditure. No final victory use or universal currency price schedule is settled. |
| 7. Contracts | Partly executable: resource-backed standing supplies, labour commitment, recurring priority and rising buyout prices. The catalogue is incomplete; partial establishment, multiple alternative suppliers and transport-backed links remain future work. |
| 8. Specialists | Deferred: class and training are separate, may overlap, and should enable qualitatively different work; specialists can still perform basic work when appropriate. |
| 9. Transportation | Deferred: scarce land/sea capacity supports standing links and individual deliveries; assigning it creates opportunity costs. Conditions may attract visitors or enable routes. |
| 10. Money and foreign trade | Partly executable: house-held gold, one caravan brick export order, stone and prestige purchases. Treasury, rotating offers, themed visitors, broader barter and expedition opportunities are deferred. |
| 11. Research | Deferred except a recipe-unlock hook. Advances may arise locally, through wider networks or acquired sophisticated knowledge; scholars, merchants, squires and professors may contribute in different contexts. |
| 12. Privileges | Deferred: situational rights/rewards, permanent or timed, transferable or restricted as appropriate. Add particular privileges for a concrete story and balance purpose, not as an automatic catalogue. |
| 13. Institutions | Deferred: business → guild → institution is a possible trajectory supporting house or town achievement. A House Hall does not itself establish the business phase. |
| 14. Town agency | Partly executable: standing brick demand, a wood wall task, limited end-of-round public wood collection and shared land expansion. General need assessment, reward escalation, treasury and an autonomous town planner are deferred. |
| 15. Overbuilding/restructuring | Design commitment with an implementation gap: consequential full-price replacement should relieve stagnation and permit changing land use. Eligible unowned demolition is only a fragment of this mechanism. |

The old synthesis called gold, cancellation, town action and prestige expenditure entirely future work. Those statements are superseded. Conversely, current contract/Hall demonstrations do not establish specialists, transport, research, guilds or a complete restructuring system.

## 4. Additions that connect the early concepts

### Contracts: supply, ownership and output rights

A standing link replaces repeated manual operation with a continuing supply attempt, subject to its inputs and commitments. The source remains a physical town asset. The prestige-bought title provides recurring one-token priority; it is not ownership of every output forever. Social currencies are consumed when acquiring ordinary property, a title or a Hall seat. Physical setup and social purchase are currently distinct transactions.

The intention that any physical resource can be secured through a suitable contract remains broader than the current catalogue. Stone lacks such a service and imported brick contracts are deliberately disabled in this scenario. Do not treat that scenario restriction as a permanent prohibition.

Automation should simplify routine card handling while preserving consequential dependencies. The upgraded source's extra operation can return to the deck without duplicating its automated base output. Missing public recurring inputs can still block deliveries; a printed contract is not guaranteed physical supply.

### Committed export backing and shared goods

The clay line currently consumes its setup chest and retains one labour capacity and one wood token as backing. It delivers clay immediately and at later visits without repeatedly charging wood. The backed wood is not available for ordinary interim use; cancellation releases it. This supersedes the old report's recurring public-wood export cost and should be treated as the current implemented variant, not conflated with all historical alternatives discussed.

Goods in a reserved output lot, a protected store, a standing capacity commitment and consumed construction progress are different states. A two-influence access override reaches an existing private-store token; it does not reclaim a wood backing or unbuild a paid wall. This distinction keeps partial contribution meaningful.

### Partial work

The designer wanted partial supplies, upgrades and construction to be possible: a contribution can consume a token into persistent progress; incomplete construction reserves its plot but provides no completed function. A partially upgraded existing building retains its base function until it finishes. The subsequent clarification protects ongoing construction from further overbuilding. Social currency clears and claims the plot first; material construction is a separate action. This supersedes the earlier tentative exception allowing full-price replacement to displace an unfinished building.

Current code covers home/chapel upgrades and new Hall/sawmill construction. It does not yet cover every old building, partial service establishment or full-price forced replacement. Those are implementation gaps, not reasons to discard the design.

### Public investment and land

The wall gives surplus wood a public use and active delivery a social reward. The town's automatic wood collection creates a real opportunity cost: an unreserved token left at round end may cease to be available for private work. It does not collect indefinitely without a known task.

The stockade permits two rural-to-urban conversions, then four outer rural claims benefiting the town. The exact six-wood wall, conversion costs, two-forest/two-field claim split, vacant-only conversion rule and sequencing are test choices. Keep the distinction between enlarging the town, changing a plot's type and replacing a site's use.

### House Halls: establishment before business

A noble/merchant house needs an identifiable seat. **House Hall** is the working name; it avoids declaring that a manor estate, guild organisation or mature business already exists. Its workshop activity makes the seat useful at this stage without prematurely conferring those later statuses.

The Hall permits one chosen known workshop recipe per round, paying the existing manufacturing recipe. It currently knows carpentry; a built town kiln shares brickmaking knowledge. The current code's per-house unlock function is only a hook, not a technology system. The clarified design requires every unlock to be global and permanent. Any later dilemma about helping rivals by advancing knowledge is retained for future development.

The physical construction price and precise social charge remain provisional. Owner-only off-deck access and the dedicated one-per-house ownership allowance are now confirmed. The target development order is home → industry → Hall → remaining opportunities; social clearing/claiming and material construction must be separate actions. Normal temporary output-priority rules remain in effect. Halls provide no passive currency, business charter or automatic prestige merely for existing.

The small sawmill adds a forest-based wood-to-planks step with a specific demand: building Halls. This is a useful new material distinction because it connects a new activity to a new investment, rather than adding a resource name without a purpose.

## 5. What the larger ideas should eventually do

**Specialists and class** should open activities, not merely multiply output. Both usable specialist tokens and ongoing supported roles remain possible forms. Their training, class, support costs and access rights can interact. A scarce trained person working a field might be legal but wasteful; the game needs a reason to value the forgone activity before implementing such a choice.

**Transport and foreign connections** should make external alternatives meaningfully different. Capacity assigned to a route cannot serve every delivery. Themed caravans/ships, rotating imports/exports, barter and expeditions can coexist; none should be selected as the sole model by accident. A future treasury would give town action a budget rather than letting it conjure progress.

**Research** should expand feasible plans. Local development, access to wider knowledge and acquisition of advanced machinery are distinct routes. Different professions may support different advances. Hall recipe knowledge is a small preparatory interface, not proof that any research economy is operating.

**Privileges and institutions** should turn sustained specialised activity and achievements into particular rights, obligations and ambitions. A business need not be only a Hall with a larger number; it could involve the capabilities, supplies, clientele, status or commitments that make a different plan possible. No exact prerequisites are specified here.

**Town agency** should identify useful work and make it attractive, perhaps with increasing rewards, while remaining constrained. An authority that automatically resolves every scarcity would remove the value of the house's decisions. Today's end-of-round wood routine demonstrates only a small piece of the idea.

**Restructuring** should change dependencies. A dependable external supply might make a local source expendable, but replacing it should expose the town to the import route's costs and reliability. Replacement may involve buildings, source cards, paid progress, output titles and transport commitments; coherent treatment matters more than a demolition button.

## 6. Findings that should not become accidental doctrine

| Observation | Appropriate interpretation |
|---|---|
| Only two additional urban slots existed for three Halls | Land pressure exposes the missing intended overbuilding path; it does not establish a deliberate permanent two-Hall limit |
| An early sawmill obstructs vacant-only rural conversion | The current sequence is fragile. AI was explicitly told to wait for outer land; it did not discover a general land-use plan |
| Ten planks were made per enabled town for six planks of viable Hall sites | The policy counts an unrealised third Hall and ignores its absent plot; fix feasible demand before balancing sawmill yield around this waste |
| Halls naturally chose only brickmaking | The current demand catalogue favours brick. A two-recipe interface exists, but useful strategic diversification is not yet demonstrated |
| Some homes remain unfinished while bricks go to demand/export | Legal competing uses plus a short-sighted policy can strand a house; this is not proof that materials vanished or that those uses should be forbidden |
| Goal completion improves in some Hall-enabled games | The enabled policy also changes labour/material decisions before any Hall completes; do not assign all benefit to Hall production |
| The recorded 6,218 decisions replayed exactly | Recorded paths are reproducible. An unselected legal sawmill-demolition path still has a confirmed bug |

The AI can remain a useful experimental player without being described as more strategic than it is. It currently scores available actions with layered rules, has a narrow labour-cancellation counterfactual, and lacks general multi-turn route comparison. The desired human game makes that planning gap increasingly significant.

## 7. Contradictions and gaps discovered in this review

1. **Intended forced replacement versus executable demolition.** The intended escape from land blockage is missing, so the prior “third Hall cannot fit” analysis overstated a model limitation as a design conclusion.
2. **Completed-project bookkeeping versus demolition.** A focused fixture confirmed that demolishing the public sawmill leaves a completed site record, breaks an invariant and prevents restart. This is a code defect, not a design question about whether to allow replacement.
3. **Universal contract intention versus limited scenario catalogue.** New physical resources need real supply paths; some remain absent or deliberately disabled.
4. **General partial-work intention versus selective implementation.** New Hall/sawmill work is partial; market/kiln builds and service establishment are not.
5. **Headquarters as a house ambition versus an optional score bonus.** The active AI phase is still home → industry → prestige, with Hall investment inside the last phase.
6. **Planner's desired decisions versus immediate scored moves.** The policy can obey hard-coded sequences without valuing the long-term alternatives that make the game interesting.
7. **Declared house flavour versus active personalities.** Stored ownership/trade biases largely do not drive the current policy; colour and a simulation outcome do not establish a rich personality.
8. **Old documents versus new rules.** Initial clay upkeep, brick barter, zero prestige spending and entirely future town action are historical statements, not current instructions.

The first four contain straightforward engineering work already implied by the design. The remaining boundaries include design choices and AI limitations; they should be made visible rather than silently normalised by more fixed scores.

## 8. Next useful work

Before another feature layer, reconcile the replacement action and the confirmed demolition defect. Retain established restrictions and sunk-cost rules; use the answered question register for action stages, protected construction and provisional clearing/cancellation composition. Make the AI identify its blocked Hall goal, enumerate actual alternatives, value the displaced use and pursue a short route with conditions for replanning.

Then compare a small matched batch with and without that planning/replacement path. Observe what is removed, whose plan gains, what the town loses, whether replacement relieves a real block, and whether a new dependency becomes fragile. Do not add a third free urban plot merely to make every Hall complete, and do not label any forced replacement useful unless it solves an actual goal obstruction.

Separately correct feasible plank-demand estimation. Broader demand for furniture may later make Hall recipe selection interesting, but it needs an explicit purpose. Specialists, transport, research, privileges and institutions remain recorded candidates; they are not discarded merely because interim mechanics have grown.

`ISSUES_AND_QUESTIONS.md` now records **all twelve answered design decisions**, distinguishes confirmed rules, explicitly provisional choices and code work, and gives the implementation/test order. The current-game and AI documents provide the detailed executable reference behind this synthesis.

## Designer clarifications — 2 November 2026

All twelve audit questions have now been answered. These are design instructions, not a claim that the v0.903 code has been updated. The original inventory/policy descriptions remain statements about that executable version. If an earlier provisional suggestion conflicts with the following answers, the answers take precedence.

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


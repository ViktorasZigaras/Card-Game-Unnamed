# Medieval Town — design synthesis and the next useful test

**31 October 2026 · discussion synthesis, not a final specification**

This document consolidates the user's proposals and explains how they can form one game. Core clarifications are distinguished from future design concepts and proposed experiment defaults. This synthesis originally preceded the 0.5.0 marketplace test. The clarified core and the user's new marketplace/import/brick-house scenario have now been implemented and tested in six games. See **MARKETPLACE_EXPERIMENT_004.md** for current executable rules, results and limits. The original experiment proposal below is retained as design history; future systems remain provisional.

## 1. The game emerging from these ideas

Several houses compete and cooperate inside **one developing town**. They share a physical economy, gain different forms of access to it, and pursue increasingly specialised ambitions. The town also has interests of its own.

The domestic game centres on **materials, labour, limited space and influence**. Money has a more specific later role in external trade and possibly specialist work. Owning something, being able to use it, having its output available, and being able to secure that output are different advantages.

A promising progression is:

- **Early:** operate buildings, feed housing, obtain labour, secure supplies and improve a modest portfolio.
- **Middle:** turn selected repeated operations into standing supply links; develop a business and then a guild; invest in specialists, knowledge and transport that support distinct capabilities.
- **Late:** use institutions, advanced networks and consequential town development to pursue a house victory or a town victory. Reorganise scarce land as old local supply arrangements become redundant.

This is an interpretation of the proposed direction. It does not set victory conditions, require every house to follow an identical ladder, or commit development to every future system.

## 2. The core rules most recently described

### Buildings, plots and the shared hand

- Urban plots and rural/resource plots serve different uses. The current discussion refers to **ten normal plots**, with a special chapel space outside that budget. The urban/rural split needs to be explicit in the next test.
- A shared cycling deck makes particular buildings available. A round corresponds to one hand refresh.
- Every building, owned or public, activates at most once per round. Activation immediately moves its card from the available hand to discard; the physical building remains in town.
- Houses alternate normal actions. Passing skips a turn; a house may act again while others continue. **Consecutive passes by all houses** end the round.
- Whether claiming/upgrading a building also requires its card to be in hand remains inherited prototype scaffolding, not a separately discussed final rule. In particular, immediate activation/discard now makes that availability question consequential.

### Production and labour

- Basic rural buildings produce **one unit without requiring a pop**. An upgraded rural producer can use **one pop for two units**, while retaining the lower-input option.
- Basic housing consumes **one grain for one pop**. Upgraded housing can consume **one grain plus one minor luxury for two pops**, or fall back to the grain-only recipe.
- Workshops use resources and labour. Exact industrial recipes and how partial-input operation scales beyond the explicit housing/rural examples remain provisional.
- Pops are labour tokens drawn from a **finite local maximum**, not named residents assigned to individual huts. Spending a pop removes it from usable labour and returns it to the available token reserve for later regeneration. Housing cannot issue tokens already occupied elsewhere in that finite pool.
- Unused physical goods persist. The latest test also preserved unused pops; their finite maximum is a subsequent clarification. Counts must include public stock, reserved output and private stores; future committed tokens need equally explicit accounting.

### Access, influence and safekeeping

- Output initially belongs in the general pile with a temporary first-use reservation for its activator. The tested convention was through the end of that house's next normal action; precise free-action interaction still deserves explicit verification.
- Each house can take tokens into a **three-token total stockpile**, one taking action per token. Ordinary public access excludes that protected stock.
- Ordinary rival-building use costs **one influence**. Direct use of a rival's reserved resource costs **one influence per token**. Payment transfers to the relevant house; it is permission to use the thing outright, without bidding.
- Paid rival-building activation is a **free action**. It still consumes the building's one activation for that round.
- The user subsequently added a **two-influence override** for a resource inaccessible this turn or generally deadlocked, applying to **all stockpiles**. This supersedes absolute private protection. Exact eligibility, how this fee combines with ordinary charges, and a payment destination for unowned resources remain open.
- A house that has already done something during the round gains no influence on a later pass. With passing now allowing re-entry, repeated idle-pass rewards need an explicit rule; the earlier withdrawal model never had that situation.
- Influence is capped at **ten per house**.
- An ordinary turn action can convert a provisional **five influence into prestige**. One prestige per conversion is a proposed test denomination, not a final reward scale. Prestige's varied future uses remain undesigned.

### The chapel

The chapel is **special and unownable**, occupies free urban space outside the ten ordinary plots, and is intended to help lagging houses catch up. It provides two influence when used. Its intended purpose is clear; the precise definition of lagging or any priority/eligibility rule has not been specified.

## 3. Future concepts and the jobs they would do

These are design candidates for later implementation, testing, revision or removal.

| Concept | User's proposed form | What it contributes |
|---|---|---|
| Contracts | Resource-backed, automatic, binding links or boons; a supplied token establishes an ongoing capability or supply contribution | Converts repeated operations into infrastructure and makes dependency choices consequential |
| Specialists | Social class and training are separate traits that can overlap; specialists can still do basic field work | Makes scarce people, upkeep and access matter by unlocking more advanced activities |
| Transportation | Land/sea capacity for standing links and individual deliveries; scarce, costly and committed elsewhere when used | Gives links an opportunity cost and makes distant supply different from local supply |
| Foreign trade | Priced import and export decks, themed visitors, barter and expedition-unlocked opportunities, possibly coexisting | Creates alternative supply sources and external opportunities without pricing every domestic action in cash |
| Money and treasury | Money mostly belongs to houses; a town treasury may fund shared expansion | Supports private external ambitions and a possible public-development budget |
| Research | Practical upgrades through sophisticated industry and ships; local work, wider networks and acquired knowledge; varied participating roles | Expands what the town can meaningfully attempt and who can attempt it |
| Privileges | Situational rewards, permanent or timed, transferable or restricted | Recognises achievements and allegiances with particular rights or better terms when story/balance justify them |
| Institutions | Business → guild → institution as a possible development arc; individual or town victory | Provides progression and eventual purpose beyond accumulating stocks |
| Town agency | A town authority identifies needs, offers increasingly attractive milestone rewards and acts itself when houses cannot or will not | Gives public development direction without relying on random quests |
| Overbuilding | Replacement or repurposing as land becomes scarce and old supplies become redundant | Lets an evolving economy change its physical footprint rather than only add upgrades |

### Contracts are infrastructure abstractions

The example is paying a pop once to secure a constant lumber contribution from a lumber yard to the total supply. The Steam-style delivered-cube analogy is about establishing an industry link: the ongoing boon becomes the important state to manage.

This is not a request for a recurring manual delivery task. It might remove routine card handling and support a tree of interdependent capabilities, both locally and in foreign trade.

However, “constant one lumber” could mean a standing available unit, production capacity, or a flow over time. Those are mechanically different. Likewise, a paid pop might be permanently committed, consumed, or replaceable. Neither timing nor token commitment should be silently finalised. Cancellation, when an AI should pursue a link, and transport requirements were expressly left for later.

### Research, specialists and institutions form a capability layer

A specialist's importance is not merely producing a larger number. Its class, training, upkeep and privileged availability can enable something strategically different. A merchant, squire or professor may participate in different forms of advancement. Some knowledge must be developed locally before wider networks become accessible; some advanced mechanical knowledge must be acquired.

Examples of research range from a level-two lumber mill to a steel mill or capable ocean-trade ship. Privileges may reward building something, researching something or choosing a winning side, with duration and transferability determined case by case.

Research creates possibilities; specialists and supported roles help operate them; institutions give sustained specialised activity a direction. Privileges can be added where a specific achievement or political context deserves one. These concepts need not become four independent currencies or four large upgrade trees.

### External connections provide alternatives

Several foreign channels may operate simultaneously: rotating goods for sale at stated prices, rotating export offers paying stated prices, themed caravans or ships with semi-random selections, goods-for-goods exchanges, and opportunities unlocked by a house-sponsored expedition. Visitors may require town conditions or supplied requirements. Land/sea transport capacity can support a standing link or a particular delivery, with expense, scarcity and competing uses. Money mostly belongs to houses; a town treasury might fund shared expansion while houses pursue other things.

### The town provides public purpose

The town assesses what is needed and currently possible, announces a meaningful objective such as a sawmill, and makes delivering it increasingly attractive. If houses remain unable or unwilling, the town can pursue progress itself.

This is a potential mechanism for aligning private ambition with public development. It still needs a budget, action rules and limits: a town that can conjure resources or automatically solve every obstacle would erase the houses' decisions. That is an implementation concern, not a reason to discard the idea.

## 4. What overbuilding adds

Overbuilding is **economic restructuring under land pressure**. It is not yet a rule permitting extra buildings above a plot limit.

A local raw or intermediate source may be replaced by another crop, a reliable import, or a better production arrangement. Existing workshops, businesses or homes can then become candidates for replacement. A field previously needed for grain might become attractive for a cash crop or raw-material plantation.

An illustrative sequence, combining the user's concepts, is:

1. Local grain supports housing and labour.
2. A dependable external supply offers another way to obtain grain.
3. Transport capacity and money or trade goods must support that alternative.
4. Land becomes more valuable for a different crop or enterprise.
5. Redevelopment improves another capability while making the town more dependent on the import route.

This example is not a specified mechanic. In particular, replacement costs, permissions, compensation, ownership, housing consequences and the fate of existing links are open. “Reliable import” must eventually have a mechanical meaning before an AI can safely reason about replacing local food production.

## 5. Why the bucket can make sense as one game

The connecting theme is **changing dependencies**.

| Stage of play | Typical decision |
|---|---|
| Operate | Which available building should I use with today's stock and labour? |
| Secure | Which resources or access rights are worth protecting or paying for? |
| Commit | Which repeated operation deserves a standing link, and what scarce capacity does that tie up? |
| Specialise | Which knowledge, people and facilities let my house do something distinctive? |
| Restructure | Which old use of land or capacity can be replaced, and what new dependence does that create? |
| Achieve | Which private ambition or shared milestone gives this development a purpose? |

The shared town means private success can create common benefits and common vulnerabilities. An automated lumber source helps rivals too; a ship assigned to one route cannot serve every other route; a specialist can work a field but may be more valuable elsewhere; imported food can free land while creating exposure to trade access.

These are useful consequences to aim for. The current small prototype has not demonstrated all of them.

There is a distinctive balance to preserve: ordinary production should remain understandable and recoverable, while ambitious arrangements should create opportunity costs and dependencies. Adding many resource names alone will not establish that balance.

## 6. Historical implementation status when this synthesis was written

The tested 0.4.0 baseline supported flexible housing/rural recipes, persistent stocks and pops, three-token stores, paid direct access, an influence cap and a built chapel. Its six forty-round games produced an upgraded hut for every house in rounds three to nine and maintained economic activity through round forty. It passed sixty-nine checks.

**Those 0.4.0 results did not validate the later clarified rules.** The table below records the implementation gap at that time; these core changes are now tested in 0.5.0 with explicitly provisional defaults:

| Later clarification | Required change from 0.4.0 |
|---|---|
| Passing means skip/re-enter | Replace withdrawal with consecutive-pass round ending |
| Activated card immediately enters discard | Remove the card from the available hand immediately, not only mark it used |
| Two-influence blocked-resource override | Add a controlled direct-use path, including private stockpiles |
| Finite pop-token supply | Account for unused, usable, stored and any committed labour tokens |
| Special catch-up chapel | Make it unownable and outside ordinary plots; define a temporary eligibility rule if needed |
| Prestige conversion | Add the ordinary conversion action and bookkeeping |
| Ten ordinary plots | Correct the previous eleven-plot test setup and state the urban/rural split |

Current status: 0.5.0 adds two small supply-link forms, caravan barter, a scenario directive and prestige milestones. Specialists, general transport, real foreign money, research, privileges, institutions, autonomous public development and redevelopment remain future systems.

## 7. Recommendation: one contract, using existing goods

**Do not add a broad set of new goods next. First test whether one standing industry link produces the kind of change intended.**

The immediate hypothesis is:

> A simple automatic lumber link can reduce routine activation/card dependence, while committing scarce labour gives that convenience a meaningful cost. It should help houses pursue improved housing without making all later decisions automatic.

The clarified core must be reconciled first. That is implementation work and focused validation, not a separate large balancing project. Then use one six-game comparison to see both the reconciled baseline and the smallest contract variant.

### Proposed six-game experiment

| Parameter | Proposal, not a final rule |
|---|---|
| Game pairs | Three matched pairs, seeds 1, 7 and 42 |
| Locale | One river-valley scenario, keeping geography fixed |
| Duration | Forty hand refreshes per game |
| Baseline | Clarified core rules, no contract |
| Comparison | Identical core and initial ordinary stocks, plus one preset public lumber link |
| AI goal | Each house obtains an upgraded hut, then pursues further useful improvements |
| New goods | None: use wood, grain, clay, brick, the existing abstract minor luxury and pops |
| Contract agency | Preset scenario link; do not yet ask AI when it should choose or cancel a contract |
| Transport/foreign trade | None in this first local-link test |
| Victory | No new win condition; compare progress and decisions |

This is six games total, not six per variant. Removing a card intentionally changes later hand sequences, so matching seeds does not mean every revealed hand remains identical. The aim is descriptive comparison, not a statistical claim.

### Concrete contract variant to make the experiment reviewable

The smallest proposed implementation is:

- One public lumber yard remains a built town asset but is operated through a standing link.
- One token from the finite pop pool is **committed for the entire experiment**, unavailable for ordinary labour generation or use.
- The link adds **one wood to the public pile at each hand refresh**.
- The yard's ordinary activation card leaves circulation while linked. It must not also provide its manual activation output.
- The link cannot be cancelled in this first experiment. This holds the comparison steady while leaving the future cancellation system undesigned.
- No prestige award, privilege, private income, new transport or town AI is attached to creating the link.

The output cadence and committed-token interpretation are explicitly **my proposed test defaults**, not claims about what the user already specified. A preset link avoids introducing an untested AI investment policy before its economic effect is understood. It also avoids treating contracts as manually fulfilled delivery promises.

If “constant one lumber” is intended as a standing supply entitlement rather than a per-refresh flow, substitute that interpretation before running the experiment; do not mix the two in the results.

### Other minimum defaults to expose before that test

These close implementation gaps without designing later systems:

- **Land:** proposed six urban plots and four rural plots, plus the separate chapel. River valley: one forest, two fields, one claybank. This gives one vacant normal urban plot and one vacant rural plot after the existing three huts/two workshops/three rural producers. It permits a little expansion instead of pre-filling all urban space.
- **Pop maximum:** proposed six tokens for the whole town. In the contract scenario, one is committed and five remain available for the ordinary reserve/pile/stores lifecycle. In the baseline, all six remain available. This is a test parameter, not a demographic model.
- **Idle influence:** initially propose at most one idle-pass reward per house per round. Taking a later action does not claw back a previously earned reward. Record pass/re-entry patterns because this is an unconfirmed interpretation and can favour an early skip. The alternative of rewarding every eligible idle pass is a different rule to test separately.
- **Chapel eligibility:** proposed access for houses tied for the fewest upgraded huts; ties include all tied houses. This is a transparent temporary catch-up proxy, not a final ranking system.
- **Override:** for the test, two influence replaces the ordinary resource-access fee when consuming an existing otherwise inaccessible rival-stored/reserved token; a separate building-use fee may still apply. Pay a private holder when one exists. It cannot create a physically absent token or exceed the finite pop maximum. Whether any broader emergency access should exist remains open.
- **Prestige:** use the provisional five influence → one prestige action, with no prestige spending or victory rewards yet. Log it as an outlet, not a measure of who played best.

These assumptions belong in the experiment configuration and report. If they prove distracting or conflict with the intended core, run the six corrected-core games first and postpone the contract comparison; do not hide a broken baseline behind automation.

### What the logging tool should compare

1. Which houses reach their first upgraded hut, and when; time to any additional meaningful improvement.
2. Actions and unproductive passes needed per milestone, including pass/re-entry and free paid uses.
3. Wood stock, wood shortages, unused wood accumulation and manual card handling avoided.
4. Labour issued, worked, stored, available in reserve and committed; blocked housing activations because the finite pool is exhausted.
5. Grain/luxury supply problems, resource overrides and private-stock use, including whether the link shifts a bottleneck elsewhere.
6. Influence transfers, chapel distribution, cap losses and prestige conversions.
7. Whether every house benefits or one gains an outsized timing/access advantage.
8. Whether fewer routine activations leave more consequential decisions, or merely make the game emptier.

Maintain full decision histories, snapshots, source/sink accounting, token/commitment conservation, card identity, save/load continuation and replay checks. A contracted asset needs a distinct recorded state so its card is neither duplicated nor treated as destroyed.

### How the result should guide the following step

- If the link saves routine operations at a noticeable labour cost, the next contract experiment can let a house choose to establish it.
- If it is always beneficial because labour is abundant, examine its opportunity cost before adding more contracts.
- If it makes wood pile up without changing useful decisions, a per-refresh flow may be the wrong interpretation of a constant supply link.
- If it simply moves the bottleneck to grain, luxury or clay, that is evidence to inspect the current chain; it is not automatically a request for ten new goods.
- Add **one** additional good only when an observed decision needs it—for example, an input with a distinct opportunity cost or a crop that makes land conversion worth choosing.

The recommended order is therefore: **reconcile the core → compare one standing link → let AI choose a link → introduce one new economic distinction when the logs justify it**. Richer trade, specialists and town milestones can then attach to a tested capability rather than arriving as one large untestable bundle.

## 8. Decision to carry forward

The fifteen initial topics now describe a coherent direction, but they do not require fifteen immediate systems. The next useful question is narrower:

**Does converting one repeated local operation into a supply link create meaningful choices about scarce labour, shared benefit and card access?**

That is a more informative next experiment than expanding the resource catalogue immediately. The user subsequently authorized this comparison with a marketplace scenario. It has now run as experiment 004; consult that report for actual results rather than treating this proposal as current unexecuted work.

# Medieval Town — decisions, gaps and discussion queue

Updated 3 November 2026. Current executable **v0.909 / schema 18**, code baseline `30514b0228bafc34aa37aaa8d8027db6c207fdb9`. Documentation-only reconciliation. This is the canonical decision register; old `CONFIRMED_…` documents are historical copies. [Current game](CURRENT_GAME.md), [actual AI](PLAYER_AI.md), [design ideas](Medieval_Town_Design_Synthesis_and_Next_Test.md), [handoff](THREAD_HANDOFF.md).

## Authority and working agreement

Explicit designer answers take precedence over earlier suggestions. Code establishes what currently executes, not final design. Reproducible tests establish consequences on their paths, not optimality, balance or human satisfaction. Numeric costs/yields/thresholds and temporary demand remain provisional unless explicitly settled. Preserve the designer's planner-oriented appeal: consequential choices and possibilities for a house, rather than maximum reward frequency or universal simulated completion.

The twelve-question clarification sequence is complete. **Do not ask those twelve questions again.** Their original qualifications are retained below. New choices can be discussed one at a time. An implementation gap is not a request to reapprove an agreed direction.

## Status of the previous audit

| Earlier finding | v0.909 status | Remaining boundary |
|---|---|---|
| G1 forced replacement absent | Implemented for supported new sites with separate social claim and full later material supply | General arbitrary building/asset replacement is not exposed; strategic cost judgments remain heuristic |
| B1 sawmill demolition leaves completed record | Fixed: retired site bookkeeping and map identity checked | Historical v0.903 evidence remains true for that version; do not carry it as an open current defect |
| Q01 protected ongoing sites | Implemented, including empty-progress social claims | Not an invitation to restore the earlier unfinished-site force exception |
| Q02 combined dependent cancellation | Implemented, still highly provisional | Needs consequential economy/rights tests, not just successful transaction bookkeeping |
| Q03 occupied rural conversion | Implemented for otherwise eligible unowned sites at complete associated costs | Private/special/ongoing protection and allowances still apply |
| Q05 explicit Hall objective | Implemented in PlannerAI | Successful scripted completion is not proof of deep planning |
| G3 selective partial building | Extended to marketplace/kiln as well as sawmill/Hall and home/chapel upgrades | Partial supply/contract setup and an arbitrary construction catalogue remain absent |
| Q08 shared permanent unlocks | Implemented for existing recipe hooks | No research economy or late-game knowledge-denial model yet |
| Q09 meaningful quantity bindings | Still a design/implementation gap | Local contracts remain one per resource; independent expedition routes do not solve general local source/quantity chains |
| Q10 biome rolls | Implemented: woodland 65% forest / 35% field | More biomes, cutting woodland and draining swamps remain deferred |
| Old AI inheritance chain | Replaced live by one inspectable PlannerAI pipeline | Many fixed scoring rules remain; consolidation is not general search |
| External route funding | Bounded funded bridge/finite cargo/exit checks implemented | Long-term profitable supply and ownership value beyond short private goals remain unproved |
| Old no-transport/no-stone-route statements | Superseded by Hall land capacity and expedition routes | Local stone service, sea fleets and general network trade remain absent |

## Twelve answered design decisions


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


## Earlier settled details

- Passing permits re-entry; three consecutive passes end the round. Paid ordinary rival-building activation retains the normal turn.
- Produce/activate and recurring priority give one output opportunity until the holder's next action: take it or do not; no indefinite reservation carryover.
- Legal access can reach reserved inputs for one influence or stored inputs for two, for immediate use; it cannot stockpile the rival's bought-through token. No separate emergency proof currently gates this access.
- Social currencies must be consumed by property/priority/development investments so houses have a reason to replenish them. Startup social policy is not enough to buy everything outright.
- Source upgrades should retain automatic base supply while the returning card pays only extra inputs for extra outputs. Existing scenario upgrade gates still apply.
- Hostile interference is deliberately more expensive. The intended strategic justification is a genuinely locked important plan after plausible legal imports, upgrades and other supply routes have been considered; current legality does not implement that universal proof test.
- The legacy clay link's wood is permanently held backing while active, not recurring export expenditure and not interim stock. Cancellation releases backing/capacity. The interim-use alternative was discussed and superseded by this implementation.
- Partial paid progress consumes goods and persists. Partial upgrades keep old function; new sites are nonfunctional until finished. Social claiming is separate from material construction. The later ongoing-site protection supersedes the earlier tentative unfinished force-overbuild exception.
- House Hall is the current working headquarters name. One per house, owner-only off-deck workshop, outside the ordinary three-property allowance but using urban land. This is not the business phase.
- An external offer can be finite cargo or a committed route. Public output still has a paying sponsor and uses transport; ownership/priority is a separate social investment. Cheap voluntary cancellation differs from hostile interference.
- Versions advance as 0.9xx. Current code is 0.909; a documentation-only update does not make it 0.910.

## Open work — not yet new questions requiring immediate answers

| ID | Topic | Evidence/decision still needed |
|---|---|---|
| O01 | General quantity-based local supply | Define independently bindable quantities, source identity, competing bindings, upstream feasibility, conservation, cancellation and partial establishment. Preserve Q09; do not silently add bread. |
| O02 | Strategic value of priority | Compare repeated privately useful inputs against paid access and exit cost. Existing six paired fixtures show equal home timing and favour public access; do not add an artificial lock merely to make ownership look necessary. |
| O03 | Replacement consequences | Follow lost production, dependent titles, capacity, backing, card identity and delayed rival outcomes after Q02 clearance; include a worthwhile route and a legal-but-pointless route. |
| O04 | Planner confidence | Specify observable reasons to wait, commit, replan or prepare force under uncertain hands/supply; no general search is implemented. |
| O05 | Human interface/art test | Designer tries the tabbed screen: can they find a goal, needed token, rights/costs, partial progress, trade arrival and the next legal action? Judge map readability/motion from actual play. |
| O06 | Replacing testing demand | Find justified future uses/dependencies before replacing unlimited brick demand. No automatic quota or removal is agreed. |
| O07 | Wider ambitions | What makes a real business possible beyond home/industry/Hall? Specialists, research, privileges and institutions remain candidates; prerequisites and win conditions are unsettled. |
| O08 | Terrain and town agency | Future terrain work, biome tables, treasury, need assessment and incentives need coherent costs/consequences. Existing scenery and wood routine do not implement them. |
| O09 | Strategic diversity | Determine whether recipe choice, personalities, civic fallback and long-term trade produce meaningful alternatives rather than a single scored ladder. |

## Suggested next development experiment

First obtain the designer's initial play observations of the published UI. Then, if focusing on mechanics, compare public versus owned supply for a **repeated private need**, keeping costs/access rules constant. Use six matched seeds/cases, log final scores, private units, access fees, delivery misses, operating/exit balances, completion timing and opportunity costs. Add a blocked/clearance counterexample rather than assuming every legal investment is sensible. Comment on the six results and suggestions before another round. Do not promise endless automatic batches or infer final balance from one run.

If the next feature is quantity binding instead, scope that separately and start from Q09. Do not combine an ownership-value experiment with new business, tech, demand and binding rules: their effects would be impossible to attribute.

## Evidence preservation

The historical v0.903 audit and its 6,218 recorded decisions are retained as history, including the then-real B1 defect. v0.909 fresh evidence is in [RECOVERY_0_909.md](RECOVERY_0_909.md) and compact `experiments/*/results.json`. The unpublished v0.906–v0.908 originals were lost; v0.909 is a tested reconstruction, not byte-identical restoration. No test result should silently change version or be described as proof of optimal play.

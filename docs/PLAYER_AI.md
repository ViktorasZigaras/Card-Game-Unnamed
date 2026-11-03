# Medieval Town — actual player AI

Updated 3 November 2026. **v0.909 / schema 18 / live policy `PlannerAI`**. Code baseline `30514b0228bafc34aa37aaa8d8027db6c207fdb9`. This document replaces the v0.903 HallAI description; historical results remain historical. See [current rules](CURRENT_GAME.md), [decisions](ISSUES_AND_QUESTIONS.md) and [handoff](THREAD_HANDOFF.md).

## What the player is

Blue, Red and Gold use the same deterministic heuristic action selector against their own state. The simulation enumerates legal actions and enforces goods, money, rights, land and travel. The policy scores those actions and selects the highest final score, preserving the first candidate on ties. It is not an LLM, a learned player, a general game-tree search or a separate autonomous person for each colour. It reads current shared state and private stores without a hidden-information restriction.

The explicit goal order is **owned good home → owned industry → unique House Hall → leftover opportunities**. Private identifiable benefit comes first; civic improvement is a useful fallback when private benefit is unclear. This is a policy convention, not a human legality restriction or a final victory rule. House colours retain bias data; production bias affects some early decisions, but stored ownership/trade weights do not constitute rich strategic personalities.

## One decision pipeline

`PlannerAI` extends `HouseAI` as an interface, seeds its own candidates and does not call an inherited `decide()` chain. Older MarketplaceAI through FinancingAI scripts remain historical regression references. The consolidated policy still contains many of their scoring rules; consolidation improved inspectability, not the depth of every rule.

| Stage | Executable work |
|---|---|
| Base town needs | Seed legal candidates, production/market/clay/home needs |
| Town and household needs | Contract, priority, kiln and trade scoring |
| Development routes | Project, stockade, Hall and land/replacement scoring |
| External opportunities | Expedition launch/trade/cargo/route options |
| Budget and exit commitments | Offer/route funding, ownership value, reserved operating/exit budgets, veto/reselection effects |
| Final selection | One highest-score selection, strict greater-than comparison |

Decision output contains the chosen action, final score, candidate reasons and stage score traces. `plan` contains goal, a land-route assessment, external alternatives, budget and next action. These are bounded assessments and diagnostics, not an exhaustive ordered plan or a proof of route feasibility. Alternative records concentrate on expedition purchase/contract/title/cancellation actions; they are not a complete branch tree for every town action.

Inspection is intended to be state/RNG pure. Seeded variation in idle collection uses a deterministic hash rather than drawing gameplay randomness during deliberation. Simulation state owns persistent projects, contracts, funding observations, rights and travel; there is no hidden cross-save AI memory. Replanning occurs after each resulting state.

## Development reasoning

The planner identifies its current milestone and practical Hall-land routes: existing own protected site, vacant urban site, wall/conversion route, or preparation to clear an eligible unowned use. It considers rough loss-of-function rankings and required social/material costs. It should pursue a credible visible route, including plausible random supply, before preparing force. Preparation is not automatic immediate destruction.

This is still heuristic. It does not search all sequences of hands, rival purchases, contract dependencies or replacement alternatives. Its loss ranking is not a complete discounted value of the displaced economy. Confidence/waiting thresholds for random supply and a general proof that no alternative exists remain unresolved. Forced replacement is legal more broadly than the AI necessarily selects well.

Hall resource decisions preserve useful stone/planks and account for development/land routes; the old v0.903 description of Halls as an optional prestige-phase bonus is obsolete. One off-deck known recipe per round still requires its inputs. Shared permanent knowledge does not create those inputs. The existence of two recipe choices is not evidence of strategic diversification.

## External supply and funding

The policy distinguishes finite cargo, a temporary funded public bridge and priority ownership. It counts current physical goods and its incoming cargo, including incoming bricks against clay needs. Need estimates are bounded by a six-round forecast and a minimum three-unit bridge assessment; they are approximations of demand, not a full supply-chain solver.

An offer assessment exposes units needed, finite offer availability, setup gold, operating gold, current cash/shortfall, prestige setup/exit requirement, possible town reward and shared export opportunities. A shared caravan brick order is only an upper bound on future gold; rivals may use it. The possible clay reward is not spendable upfront. A standing bridge must carry a bounded operating budget and safe exit budget. Small needs are candidates for finite cargo; unfunded/obsolete routes can be declined, shrunk in the need assessment or cancelled rather than assumed sustainable indefinitely.

Route funding observations are saved with the route. Budget reservations constrain other spending; the policy does not quietly promise that somebody else will finance public imports. Public means shared output, with the sponsor still paying gold and transport. Crew/cargo cannot be instantaneously reclaimed by cancellation or buyout.

## Buying priority rather than merely wanting supply

Ownership value separates **the acting house's unfinished milestone inputs** from a larger town buffer. It subtracts relevant own incoming cargo. It compares bounded access charges (up to two influence per private input) against two influence for priority and the cost of a later one-prestige priority exit. The existing one-way five-influence prestige conversion provides a provisional comparison weight; it does not authorize buying influence back with prestige.

The assessment can recognise influence liquidity pressure when several privately needed inputs exceed cash-on-hand influence, provided exit prestige is still available. It assumes no unproven completion-speed benefit. Public goods already delivered stay public after later ownership. Exact thresholds remain experimental. Long-horizon profitable businesses and strategic denial are not valued generally.

Hostile buyout/cancellation legality belongs to the simulation; scoring has conservative guards rather than a universal adversarial model. A need for clay does not automatically justify taking ownership of every clay stream.

## Local supply, access and civic fallback

Stock thresholds favour needed wood/grain/labour, clay-to-brick work, home progress and social-currency replenishment. Contracts hold scarce labour capacity, so setup is constrained by remaining work capacity. Stored surplus can be exchanged for influence; selected stores preserve useful milestone inputs. Bulk exchange itself consumes in fixed goods order; the policy does not gain a custom bundle action.

The legacy local contract buyout logic and several production rules still use fixed conditional scores rather than return-on-investment calculations. A narrow explicit cancellation counterfactual clones the simulation when a house lacks a home, no physical labour exists and capacity is committed. It checks that cancellation frees capacity and a built labour-producing recipe becomes fundable. This is real executable counterfactual evaluation, but does not demonstrate a complete route to the home or exhaustive alternatives.

Civic work includes wall wood, shared land, chapel investment and town brick demand. The town's round-end wood collection is a separate deterministic routine, not a fourth player with the houses' reasoning. The unlimited brick sink and single-metric chapel access are test scaffolds; policy exploiting them is not evidence that their final strategic role is settled.

## Evidence and its limits

| Validation | What it establishes |
|---|---|
| Six original-economy comparisons, 4,806 decisions | Consolidated selector reproduces v0.905 choices and every candidate score on those paths; inspection preserves state/RNG |
| Six mapped 80-round towns, 4,793 actions | Exact replay/save/invariants on selected paths; all 18 Halls finish in these towns |
| Six directed cargo/bridge cases, 302 actions | Finite cargo returns, public bridges deliver paid clay and can release transport |
| Six public/priority pairs, twelve trials, 220 actions | Same home completion round in all pairs; access costs differ; policy recommends public in all six starting fixtures |
| Eight ownership-value checks | Private-versus-town units, own cargo, comparison costs and liquidity guards |

The paired competition fixtures arrange a Hall before the missing-home goal to isolate the mechanism. That is legal fixture construction, not proof the organic policy follows that development order. Counts and reproduction commands are in [the fresh recovery report](RECOVERY_0_909.md). The old 6,218-decision Hall batch belongs to v0.903 and must not be added to v0.909 totals or treated as current evidence.

Neither exact replay nor eighteen completed Halls proves optimal play, fairness, a useful ownership investment in every setting, comprehensive legal-action coverage or human satisfaction. Headless interface checks cannot settle art direction. An inherited reason string is weaker evidence than the final score, payment plan and resulting state.

## Remaining capabilities to develop

- A general multi-step supply/construction plan with opportunity cost and explicit reasons to wait, replace or abandon.
- Feasible quantity bindings across upstream production chains, beyond the local one-contract-per-resource catalogue.
- Wider valuation of public versus owned supply where repeated private use actually justifies the investment.
- A real model of rival plans, uncertain hands/supply, business returns and long-term research effects.
- Deliberate strategic personalities if useful to the intended human experience.

These are implementation/design topics, not claims of existing intelligence. There is no training, learning between runs, full rival-response search, town treasury planner or separate Alien Planet advisor hierarchy here.

## Relevant files

Live: `src/planner_ai.gd`, `ui/live_session.gd`, `src/mapped_town_simulation.gd`. Foundations: `src/house_ai.gd`; historical rule/policy pairs remain in `src/`. Evidence: `tests/planner_equivalence.gd`, `mapped_town_experiment.gd`, `flexible_directed.gd`, `priority_competition.gd`, `priority_value_checks.gd` and corresponding `experiments/*/results.json`. `src/game_probe.gd` records full action/snapshot journals; the live state's short history is limited to 64 events. Large regenerated journals are not all shipped in the source archive.

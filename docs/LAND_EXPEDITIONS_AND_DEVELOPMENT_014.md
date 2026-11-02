# Land expeditions and protected development — experiment 014

**2 November 2026 · local v0.904 · schema 15. No repository upload.**

## What was implemented

Each completed House Hall supplies one land transport capacity. Launch consumes one grain and holds a real labour token as crew. The crew is excluded from usable labour but remains conserved, and returns to public labour supply when the party gets home. Travel takes six future normal town actions in each direction; paid rival-building free activations do not accelerate it.

At the destination, the sponsor receives two distinct goods it can buy or contract and two other distinct goods it can sell for cash. The four materials are shuffled from the known catalogue: wood, grain, clay, brick, furniture, minor luxury, stone and planks. Labour is crew rather than a commodity in this model. Offer generation happens once on arrival and is saved; inspecting or previewing does not reroll it. The prototype has no map, battles or sea expeditions.

Each direct purchase/sale offer has two finite units. Purchases cost one gold per material except brick/furniture/luxury, which cost two. Exports pay one gold. These prices and quantities are test assumptions. A normal action handles one unit. Sale inputs may come from any ordinarily accessible public/reserved/private stock, subject to existing influence fees; commitments and consumed project progress are not sale stock.

Purchased goods remain cargo until return. They then fill the sponsor's three-token store if space exists; overflow enters unreserved public supply. Cargo cannot be used before home and finite offer units do not regenerate at a round refresh. Cargo units are booked as actual imports when they arrive, rather than being spendable paper stock while abroad. If several goods arrive, the existing stable resource order is used for storage allocation.

The sponsor can depart explicitly. After six normal sponsor actions at the destination, the party automatically begins its six-action return. The launch, outbound journey, trading stay and return all occupy transport. The party cannot be launched a second time while away, and offers are sponsor-specific.

## Owned standing routes

Accepting a buying offer as a standing contract consumes its quoted gold setup price and three prestige. It establishes an already-owned, one-unit supply route with automatic temporary output priority; no separate priority-purchase action is required. Delivery begins at a refresh after the party is home and thereafter attempts once per round, paying the quoted gold price from the current owner's wallet. Missing gold causes a missed shipment. The route retains the Hall's transport capacity after crew return.

The journey and the route formed on it share one transport allocation, not two. Route buyouts are possible after the originating party is home: the new owner must have a free land capacity and pay the displayed prestige price, initially five and rising by two. Both operation costs and transport obligation transfer with priority. Cancellation costs current buyout price plus three prestige. A still-travelling party must return even if its route is cancelled; cancellation does not teleport crew/cargo home.

Independent routes can bind the same resource. The focused checks establish two separately owned clay routes without a resource-wide monopoly. This is not yet a rewrite of the older local contract/title dictionaries, which still limit local contracts by resource. General input/output quantity bindings through arbitrary manufacturing chains remain unfinished.

The first new clay route can earn three town prestige if clay is currently needed. The tested need heuristic counts unfinished homes and low-brick conditions with existing brickmaking capability, including known Hall brickmaking. The reward is once per town and is attached to securing the useful route, not every delivery or cancellation/re-establishment. This prevents repeat setup-reward farming but does not guarantee its operation will remain affordable.

## The earlier clarifications carried into this version

Social clearing/claiming and physical construction are now separate actions. A Hall claim consumes three influence; a public marketplace/kiln/sawmill site claim consumes a provisional one influence. That first action reserves a protected site without producing a finished building. Later card-based material contributions pay the full remaining cost. Anyone can help a public site; only the owning house builds its Hall. Ongoing sites cannot be overbuilt again.

The public marketplace, kiln and sawmill, as well as Halls, now use partial new construction. Completed public-site demolition retires its old site record and preserves sunk material/social accounting, fixing the reproduced sawmill bug. A legal unowned replacement clears its predecessor for one rural or three urban prestige plus dependent legacy-contract cancellation prices, then requires the separate physical construction. The combined cancellation bill remains highly provisional, as requested. Private ownership and special buildings are protected.

An eligible occupied rural source can be cleared and converted at its full associated costs. Vacant rural conversions remain cheaper. Four outer claims are now biome rolls; the initial woodland profile is 65% forest and 35% field. Individual terrain totals may exceed two while total new claims stay four. Woodland-to-field work, wetlands and drainage are not implemented by this probability table.

Recipe unlocks are shared permanently. The AI explicitly names home → industry → Hall → leftover opportunities. It prefers a remaining expansion route before urban clearance. It distinguishes a prospective replacement site from readiness to clear it, and gathers the complete Hall material bundle before removing a kiln that may be needed to earn the stone money. Feasible plank demand includes a real prospective clearance route but does not blindly assume a free third urban slot.

## Final matched experiment

Twelve eighty-round towns: seeds 1, 7 and 42 × manual/preset lumber × expeditions disabled/enabled. All use the new staged development policy; expedition availability is the comparison toggle. The snapshot is the refresh into round 81. The common RNG also serves cards and biome rolls, so enabling expeditions can change later random sequences; the seed pairing does not isolate goods alone.

| Seed | Lumber | Home/industry round: control / enabled | Completed Halls: control / enabled | Trips launched | Returned by cutoff | Routes established |
|---|---|---|---|---:|---:|---:|
| 1 | manual | 34 / 34 | 3 / 3 | 17 | 17 | 1 |
| 1 | linked | 24 / 24 | 3 / 3 | 16 | 15 | 1 |
| 7 | manual | 29 / 29 | 3 / 3 | 13 | 13 | 0 |
| 7 | linked | 21 / 21 | 2 / 3 | 14 | 13 | 0 |
| 42 | manual | 65 / 59 | 2 / 3 | 15 | 14 | 1 |
| 42 | linked | 32 / 32 | 3 / 3 | 15 | 14 | 1 |

Final totals: **9,324 decisions**, **90 launches**, **86 returns**, **34 gold earned through expedition sales**, and **20 actual imported units** in enabled games. Journeys still away at cutoff remain saved and can continue; they are not treated as lost crew or goods.

Standing routes delivered **7 units** and missed **37 shipments** for lack of owner gold. In the final batch clay routes were established in four enabled towns. This is useful evidence of the economic constraint, not universal success: owned priority, a destination offer and a transport commitment do not supply recurring cash automatically.

All six enabled towns completed three Halls; four of six controls did so. Each completed third Hall in these runs used an unowned-kiln replacement after material preparation. The result is not a guarantee: town progress, currency, card timing and legal property rights still constrain the route. No free land or permission to destroy private property was added.

## Failures discovered and corrected during development

1. An inherited take/return-grain cycle could keep a round open indefinitely. The first attempt reached the decision guard. Low-value same-round storage reversals are now suppressed; later final runs completed their eighty rounds.
2. Early clearance of a kiln could destroy the cash-making path before the last construction stone was acquired. The AI now prepares material funding before executing the clearance, while still recognising the future plot route before all materials are held.
3. JSON decoding turns numeric offer/route IDs into floats. Legal-action dictionaries expected integers, causing the first expedition trade replay to diverge. These ID fields are now normalised on apply; the final recorded games replay exactly.
4. A party can return on the action that closes a round, allowing a legitimate import at the following refresh. The tests now distinguish this from an illegal pre-return delivery.
5. Spending operating cash on prestige could strand a newly formed route before its first shipment. The policy now reserves a small operating amount and can cancel an owned repeatedly unfunded route if it can afford the social cost. It still does not have a sustainable multi-turn funding plan, and the final missed shipments show that limitation clearly.

These corrections are disclosed rather than presenting the final batch as the first attempt. The final sample remains small, deterministic and policy-dependent.

## Verification

All twelve final games passed invariants, saved/restored exactly and replayed exactly: **9,324 decisions**. Ninety-three dedicated checks cover real crew conservation, transport exclusivity, timing, finite offers, private/overflow cargo, paid rival-stock sales, global unlocks, protected construction, dependent-contract clearance, demolition/rebuild, route ownership/buyout/cancellation, repeated-clay-reward protection, multiple same-good bindings, operating-budget guards and state round-trips.

Earlier Hall/stockade/project/trade/priority suites passed 56/47/31/22/47 checks respectively. These instantiate their earlier classes and establish regression coverage; they do not replace the new-runtime checks.

The live interface ran a forty-round game with preview immutability and exact save/load, minimum 1525 × 1028. A separate nineteen-command expedition fixture exercised Hall claiming/construction, launch, destination purchases/sales/contract, timed return and save/load, minimum 1515 × 1028. All 83 archived UI states and their existing selection/preview/manual/AI/save checks passed. These are mechanics/layout checks, not a claim of finished artwork.

## What to test next

**Fund the route before binding scarce transport.** Compare a finite cargo purchase with a standing contract using the same cash, and explain the expected operating income—not only a low-stock threshold. Track gold earmarked for operation, who captures the resulting brick/export income, misses, and the cost of recovering transport. The current rule-based player is not a general multi-turn planner.

Local quantity-aware manufacturing bindings, universal partial service establishment, general duplicate-building construction and terrain transformation remain pending. These are not silently supplied by the expedition prototype. The broader manned-expedition system is still a deliberately small timed trade model.

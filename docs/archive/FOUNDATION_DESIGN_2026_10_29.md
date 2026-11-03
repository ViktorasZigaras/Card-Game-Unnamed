> Historical source preserved on 3 November 2026. This is not the current v0.909 rulebook. See [the handoff](../THREAD_HANDOFF.md) and canonical references. Original wording follows unchanged.

# Medieval Town — Economic Card Game
## Codex design brief and evolving specification
**Status:** Concept exploration / prototype planning. **Authority:** The user's design intent takes priority over illustrative examples. **Implementation preference:** Godot 4, GDScript, data-driven content, turn-based play. **Working title:** Placeholder.

## 1. Executive summary
A turn-based, primarily card-and-token economic game about several competing houses jointly developing a medieval-ish castle town. Houses own, sponsor, acquire, improve, and divest buildings, but the town is a shared, persistent economy. The game should produce situational choices, trade-offs, specialization, dependencies, negotiations, and emergent economic histories rather than a single obvious optimal build. The tone may be historical-ish, stylized, and lightly playful; mechanics and replayability matter more than exact historical simulation.

Inspirational references, **not templates to copy**: Cultist Simulator's card-like interaction and tabletop visual vocabulary; Dominion's cycling/reshuffling deck; Colonization's concrete goods, production chains, and trade; broader economic strategy games' specialization. Do not copy proprietary assets, text, maps, or rules verbatim.

**Core distinction:** Buildings are persistent town assets represented by cards in a shared cycling town deck. Resources are finite **tokens/state quantities**, not cards shuffled into that deck. Ownership of buildings can change while buildings remain in the town.

## 2. Confirmed or strongly intended pillars
1. Several player-controlled or AI-controlled competing houses operate within **one shared town**, rather than each having a separate private city.
2. A **shared rotating deck of building cards** determines which buildings become accessible/available for activation or other actions in a round. Deck cycling/reshuffling is part of the concept; exact draw/discard timing is undecided.
3. Players alternate meaningful actions after the round draw (e.g., activate, exchange, buy, improve, negotiate), continuing until everyone passes. Exact action economy is open.
4. Buildings persist in the town even when bought, sold, or transferred. Building ownership should confer useful benefits, potentially income, influence, privileges, or other advantages, **even when another player activates the building**. Precise owner/activator split requires experimentation.
5. Houses have **limited ownership slots**. Upgrades, specialization, selling assets, and evolving into institutions compete for this scarce capacity.
6. Resources are **finite tangible commodities**, produced, consumed, stored, exchanged, traded, or held. Storage can be in shared market/town stores or private inventories. Production and storage limits should matter.
7. Buildings can have levels/upgrades, labor requirements, capacities, production inputs/outputs, terrain prerequisites, and dependencies.
8. Population may exist as workers, specialists, consumers, and inhabitants of housing. They may work terrain/buildings, need food and goods, and contribute income or influence. **Not yet a fixed model.**
9. Terrain is a finite set of **landscape cards / development slots** (forests, hills, riverbanks, deposits, etc.). Terrain constrains what can be built and may be transformed, such as clearing forest for farmland. Some terrain may become available later.
10. **Climate/geographical locales** shape the terrain-card pool, local special amenity resources, production chains, and opportunities. Different sessions can produce substantially different economic situations under the same core rules.
11. A separate **foreign-trade deck** rotates, presenting outside markets, merchants, imports, exports, contracts, and opportunities. Local scarcity makes trade useful and sometimes necessary for advanced development; randomness should not create unavoidable deadlocks.
12. **Contracts** are persistent trade relationships that reserve/consume limited inputs, shipping or transport capacity, and/or output over time; exact enforcement and timing are open.
13. Houses can evolve into specialized **institutions** (college, church, shipyard, architects' guild, etc.) when they meet prerequisites. Institutions may have unique services/resources and fewer ownership slots than their supply chains require, fostering dependence on other houses and town trade.
14. Several broad accomplishment/victory paths may emerge: scholarship, exploration, population, influence, conquest, commerce, etc. These are **ideas, not finalized win conditions**.
15. The game should support simple, intelligible **AI houses** with imperfect, biased, somewhat rigid, slightly random decision-making. They need to behave plausibly and distinctively, not play optimally. AI-only batch simulations should help identify deadlocks, dominant strategies, and pacing.
16. If a house cannot take a meaningful normal action, there should probably be a fallback action. Design and test rather than assuming a final rule.

## 3. Geography and local specialization
Each session selects or generates a **locale profile**. The profile influences terrain distribution, starting conditions, common and rare local resources, possible local industries, and trade demand. A climate is not a rigid one-resource label: local geography varies within the same broad climate. Avoid essentializing real regions or assuming every named crop/resource occurs in every area.

**Illustrative locale profiles, not fixed content:**

| Locale | Terrain tendencies | Possible local specialties | Industries and strategic implications |
|---|---|---|---|
| Temperate river valley | Fields, riverbanks, wetland, woodland | Clay, wicker, reeds, fish, hemp | Pottery, bricks, baskets, rope, river trade |
| Northern woodland | Forest, lakes, uplands, limited arable land | Fur, resin, wax, timber | Trapping, wood products, exports; potential food/import pressure |
| Mediterranean hills/coast | Dry hills, terraces, valleys, shore | Olives, grapes, aromatic herbs, selected resins | Oils, wine, specialty processing, sea trade |
| Humid tropical coast | Forest, river mouths, fertile lowlands | Spices, aromatic woods, fibers | Specialty exports, textiles, maritime connections |

**Illustrative chains:** clay → pottery / bricks / tiles; fur → clothing / luxury exports; incense/resins → ceremonial supply / prestige trade; spices → cuisine / medicine / luxury export; wicker → baskets / containers / furnishings; hemp → rope / cloth / sails. Each chain should have alternative uses and sensible demand. A special resource can be a bonus or accelerator without making a critical institution impossible in every locale lacking it.

Two river-valley sessions can differ because one has several clay sites and a navigable river, while another has little clay but extensive forest and hills. Terrain cards and deposits can be partly revealed through exploration/development if testing supports that.

## 4. Shared town and resource model
### 4.1 Building cards
Proposed data fields: `id`, `name`, `tier`, `category`, `owner_house_id`, `terrain_requirements`, `workforce_requirements`, `inputs`, `outputs`, `capacity`, `upgrade_options`, `construction_cost`, `activation_cost`, `owner_benefits`, `activator_benefits`, `institution_tags`, `visual_asset`, `rules_text`. Not all fields need implementation in the first milestone.

**Example from discussion:** A basic lumber camp might allow **at most 1 lumber token** in town; an upgraded camp might require a worker and allow **at most 3**. Multiple camps' capacities can add. This is a conceptual illustration; clarify whether the capacity is production, storage, available supply, or a combined rule before implementation. Do **not** silently canonize this ambiguous example.

### 4.2 Resources and inventories
Use a centralized resource registry with commodity categories and quantities. Distinguish: global town market inventory, house-held inventory, committed/reserved contract goods, and capacity limits. Consumption and replenishment timing are **not settled**. Start with an explicitly documented provisional rule that can be changed without rewriting UI.

### 4.3 Ownership and activation
Separate the **building's owner** from the **player choosing to activate it**. Test compensation schemes (owner earns rent/influence; activator obtains output; owner receives privilege; activation requires consent or fee; shared public benefits). Prefer mechanics that generate interaction rather than passive ownership alone. Ownership slots should encourage strategic portfolio choices.

### 4.4 Population
Potential types: general workers, skilled craftspeople, administrators, scholars, clergy, sailors. Housing may create residents, consumption needs, revenue, and prestige. Population could work tiles and buildings, as in the user's wider design interests. Avoid implementing a complicated labor market before the core deck and goods loop is enjoyable.

## 5. Rounds and actions — candidate flow, not locked rules
1. Draw/reveal building cards from the cycling **shared town deck**.
2. In alternating order, houses choose actions: activate available buildings, buy/sell/transfer ownership, upgrade, exchange commodities, commit contracts, recruit/assign labor, construct where terrain allows, or pursue institution objectives.
3. Continue until all houses pass or a tested action-limit condition applies.
4. Resolve consumption, contracts, production/replenishment, maintenance, income, and progression at a clear phase boundary.
5. Discard/reshuffle cards per tested deck-cycling logic; buildings remain persistent in the town.

Open issues: Does the deck contain every existing building or only active opportunities? Can one card be activated multiple times? Are actions paid? Who may activate privately owned buildings? How are draws balanced when town grows? Make these explicit questions for prototype tests.

## 6. Trade, scarcity, and international markets
### 6.1 Local market
A shared town market may hold persistent commodity stocks, enabling exchange, storage, competition, and cooperation. Private house stores can coexist. Prices may be fixed, variable, negotiated, or event-driven: **not decided**.

### 6.2 Contracts
Persistent links may reserve e.g. one shipping capacity and recurring pottery output to import dye, or commit timber to a shipyard. Design contracts as stateful objects with parties, inputs, outputs, duration, capacity commitments, cancellation/breach behavior, and fulfillment history. Test whether complexity adds decisions or mere bookkeeping.

### 6.3 Foreign trade deck
A separate rotating deck supplies both recurring connections and occasional opportunities. Example cards previously discussed:
- **Northern Fur Merchant:** offers fur for grain, cloth, or manufactured goods.
- **Eastern Spice Caravan:** scarce spices/aromatics for a limited window.
- **Overseas Building Contract:** export demand for bricks, timber, or finished construction materials.
- **Permanent Maritime Route:** recurring import/export arrangement consuming shipping capacity.

**Important balancing principle:** Imported goods may be necessary for *overall advanced development*, but a bad draw should not freeze the town. Candidate safeguards: costly baseline imports, scouting/diplomacy to seek markets, multiple substitutes, or predictable minimum trade access. Rare opportunities can remain random.

## 7. Institutions, progression, and incentives
Houses can transition from general portfolios to institutions with prerequisites, privileges, and special outputs. Candidate examples:
- **College:** knowledge, instruments, manuscripts, engineering; depends on supplies and specialists.
- **Church/temple:** legitimacy, ceremonial goods, social services; optional incense and luxury demand.
- **Shipyard:** ships, shipping capacity, exploration, imports; demands timber, hemp/rope, metal, labor.
- **Architects' guild:** advanced construction, skilled labor, technical services; demands stone, brick, tools.

A sophisticated institution may have **fewer ownership slots than its complete supply chain requires**. It must obtain inputs from rivals, market, or foreign partners. Institutional evolution should be a meaningful trade-off, not a strict upgrade every player must rush. Alternative achievements and victory conditions should be discovered through playtesting, not over-specified now.

## 8. AI houses and simulation
Use explainable heuristic/utility scoring rather than heavy machine learning. Personalities might prefer trade, vertical integration, public construction, prestige, risk avoidance, or rapid institution development. Add slight randomness, inertia, limited foresight, and optional memory. Keep a **decision diary**: action, candidates, score components, reasons. AI should remain capable of taking sensible fallback actions.

Provide a **headless simulation mode** for thousands of turns/games using seeded randomness. Record: resource deadlocks, action pass rates, ownership concentration, unused buildings, trade volume, time to first institution, institution diversity, session duration, resource bottlenecks, and victory distributions. AI performance is a test instrument, not proof of fun.

## 9. Godot implementation architecture
- Godot 4 + GDScript, 2D card/table interface.
- Keep **pure simulation/state** separate from **presentation** and **player input**. Avoid game rules inside button handlers.
- Data-driven definitions in JSON or Godot Resources for buildings, resources, locales, terrain, contracts, institutions, and trade cards.
- Seedable RNG; save/load; deterministic replay where practical.
- Main components: `GameState`, `TurnManager`, `TownDeck`, `BuildingInstance`, `HouseState`, `Market`, `TerrainPool`, `TradeDeck`, `ContractManager`, `InstitutionSystem`, `AIHouse`, `SimulationRunner`.
- UI: town overview, shared building card area, house portfolios, resource stocks, terrain, market/trade opportunities, institution progress, action log, and tooltips. Show actionable information without excessive navigation.
- Use placeholder card art first. Later add pregenerated, approved card illustrations and simple effects.

## 10. What Codex may generate or expand
**Allowed / encouraged:** alternative rule variants, schemas, placeholder assets, UI layouts, AI personalities, seeded test scenarios, example building/terrain/trade card sets, balance reports, debug tools, documentation, save format, and automated tests. It may propose realistic production chains and resource substitutions. Every generated content set should be marked *provisional* and editable.

**Do not decide silently:** exact turn order, deck draw frequency, activation privileges, commodity pricing, replenishment, victory conditions, population simulation depth, starting resources, climate-specific restrictions, and institution prerequisites. Where implementation needs a decision, pick the **smallest reversible default**, document it as an assumption, and ask for confirmation before treating it as final.

## 11. First playable milestone — suggested
Build a **single-town, 2–3-house, 8–12-building** Godot prototype with:
- shared cycling building deck and alternating action/pass loop;
- 3–5 resource types, finite inventories, a market, basic production/consumption;
- ownership and ownership-slot limit;
- 3–4 terrain cards and two locale profiles (e.g. river valley vs northern woodland);
- 1 simple foreign trade opportunity and 1 persistent contract;
- one basic upgrade; a simple heuristic AI opponent;
- turn log, tooltips, save/load if practical, seeded simulation tests.

Defer institutions, extensive population classes, advanced trade, and full victory system until the core loop demonstrates interesting decisions.

## 12. Initial Codex instruction
> Read this entire brief. This is an exploratory game design, not a finalized rules specification. First propose a minimal Godot 4 architecture and a list of ambiguous decisions, clearly distinguishing established concepts from your temporary assumptions. Then implement a small playable vertical slice with data-driven content, one AI house, logs, and headless tests. Do not add large systems or lock in victory rules without approval. Prioritize meaningful decisions, clarity, and easy iteration over content volume.

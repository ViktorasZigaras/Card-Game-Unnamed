> **Historical document.** Retained for its original version/experiment; its recommendations and missing-feature claims may be superseded. For current v0.909 rules, decisions and next work, start with [THREAD_HANDOFF.md](THREAD_HANDOFF.md). Historical results below are not relabelled as current validation.

# Card game — interface proposal for version 0.50

31 October 2026. Proposal for review before repository upload. No artwork or Godot gameplay interface has been added.

## Version and scope

The current version is **0.50**, also written 0.5. Subsequent releases advance by **0.05**: 0.55, 0.60, 0.65. Historical 0.5.0 filenames refer to this same prototype. An interface proposal does not itself create a release.

Repository: [ViktorasZigaras/Card-Game-Unnamed](https://github.com/ViktorasZigaras/Card-Game-Unnamed), empty when inspected. Nothing has been pushed.

This is a **2D sprite game**. The proposal establishes structure, names, selection and action feedback. Sprite appearance, perspective, architectural style, colours and animation remain undecided.

## Screen structure

| Area | Position at a 1440 × 900 reference size | Contents |
|---|---|---|
| Turn bar | Across top | Version, round, current house, pass chain, game menu |
| Houses | Left, about 220 px | Influence, prestige, ownership count, private storage, finite pop accounting, selectable town assets |
| Town objective | Above town | Shared end condition and prestige milestones |
| Town canvas | Centre, flexible width, at least 320 px tall initially | Reserved space for future 2D sprites; plot usage only for now |
| General pile | Below town | Resource names, quantities, free/reserved split |
| Shared hand | Below pile | Four building cards; draw/discard inspection |
| Inspector | Right, about 320 px | Selection, costs, recipes, legal actions, source allocation and fees |
| Footer | Bottom | Pass, influence conversion, recent events, laboratory toggle |
| Laboratory | Collapsible below board | State, replay, decision history and testing controls |

At about 1024 px width the side columns can shrink to roughly 158 and 248 px. Below that, move the inspector under the board. On narrow screens stack main board, inspector and houses. This makes the proposal viewable on a phone without committing the Godot game to a mobile release.

The town area stays available throughout testing. Do not fill it with permanent debug panels. A building's eventual sprite, card and asset-list entry select the same object. The building remains in town after its activation card goes to discard.

## Object sizes

- Building cards: **5:7 ratio**, up to **160 × 224 px** in the four-card hand. Show name, kind, owner, level, recipe and availability. Put detailed choices in the inspector.
- Expanded card, if useful later: **320 × 448 px**. The inspector itself need not be a literal enlarged card.
- Resource controls: approximately **36–44 px** targets with names and quantities. One control represents a pile rather than one control per token.
- Private stores: three unit slots per house. Two units of wood occupy two slots; these are not three unlimited resource categories.
- Ownership: always write the house name; eventual colour is supplementary.
- Pop pool: reserve, usable public tokens, private tokens and committed tokens. Do not depict residents assigned to individual huts.

## Inspector and action review

Local tabs: **Selected**, **Caravan**, **Links**, **Journal**. Selecting a card, asset, resource, house or milestone updates the same inspector.

Before executing an action, show the result, normal/free action status, chosen recipe, inputs and outputs, actual source of each input, influence recipients, prestige changes and plot/pop commitments. Unavailable actions explain why: missing brick, discarded card, full ownership slots, exhausted pop reserve, and so on. Selection and preview consume no actions.

An actual Godot interface should have one Execute control after review. The supplied example is recorded replay, so it allows inspection and stepping but cannot execute new game actions.

## Current mechanics covered

| Thing already in the game | Interface treatment |
|---|---|
| Blue, Red and Gold houses | Left column; actor also named in turn bar |
| Influence cap 10; separate prestige | House summary; overflow receipts logged |
| Three owned-property slots | Count and selectable owned assets |
| Three-token private storage | Three unit slots; inspect take/return options and access costs |
| Wood, grain, clay, brick, luxury, furniture/chests, pop | Shared pile; free and reserved quantities distinguished; private tokens shown separately |
| Six-pop finite pool | Reserve + public + private + committed accounting |
| Four shared cards, draw and discard | Hand row; used cards leave immediately; town assets persist |
| Claim | Building inspector: three influence, ownership constraints |
| Basic hut production | One grain → one pop, subject to remaining reserve |
| Upgraded hut | Retains basic recipe; grain + luxury → two pop as a separate choice |
| Basic rural buildings | One output without pop |
| Upgraded rural buildings | Retain basic recipe; pop → two output as another choice |
| Carpenter | Two wood + one pop → one furniture/chest |
| Hut improvement | Two wood + one brick + one pop; owned hut card must be available; five prestige |
| Rival building activation | Review shows one-influence transfer and free-action status |
| Rival reserved input | Holder and one-influence access fee per unit |
| Inaccessible private input | Two-influence override per unit, transferred to holder during actual consumption |
| Production reservation | Resource inspector shows holder and expiry |
| Passing | Pass chain and refresh after three consecutive passes; house may act again after passing |
| Idle-pass influence | Preview explains once-per-round eligibility and whether house has already acted |
| Chapel | Special, unownable asset outside ordinary plots; two influence, with catch-up eligibility explained |
| Ordinary plots | Urban 6, forest 2, field 2 usage beside town; chapel excluded |
| Build wooden market | Objective action: three wood + one pop, one urban plot, two prestige; passive public asset rather than hand card |
| Caravan | Present/away, next arrival, current brick stock and offers |
| Brick barter | One chest → one brick; two available per caravan visit |
| Establish clay contract | Caravan present; one chest + one pop + one wood; committed pop, first clay and three prestige |
| Recurring clay delivery | Links tab: one unreserved public wood → one clay per caravan visit; log a pause if wood unavailable |
| Preset lumber link variant | Committed pop, one wood each hand refresh; manual lumber card outside rotation |
| Prestige conversion | Ordinary action: five influence → one prestige, one way |
| Milestone rewards | Market +2, clay link +3, upgraded house +5; show recipients and rounds |
| Scenario completion | Clay import delivered and at least one owned upgraded brick house; either may be achieved first |

The caravan arrives at the refresh after market construction and every third round thereafter. Clay import and brick barter are independent offers. Clay does not become brick automatically; no kiln is implied.

Access payments use real resources immediately. They cannot create absent goods, borrow committed pop, or buy rival goods merely to hoard them. A free rival-building activation retains the normal turn; input access payments alone do not make an ordinary action free.

## Laboratory

Closed by default, available throughout development. Keep raw state out of the reserved town canvas. The footer shows only recent events; the full journal remains inspectable.

Expose the existing engine's scenario/seed configuration, manual versus preset-link setup, single-action stepping, run to objective/diagnostic limit, save/load and replay. A small batch defaults to six runs, following the agreed five-to-ten-run approach. These are proposed interface controls over existing engine workflows; the mockup does not add a new runner.

Each decision should show sequence, round, actor, chosen action, legal alternatives, AI scores/reasons where recorded, state changes, influence transfers and invariant failures. Mark historical playback distinctly from a live game.

The interactive example uses the existing **seed-7 manual-timber journal: 83 snapshots, initial state plus 82 decisions**. Cards, resources, houses, tabs, previews and replay controls inspect those real states. Its final snapshot is the actual round-10 completion. No new AI runs were performed. Game action and save/load controls are disabled in replay.

JavaScript syntax, element identifiers, all 83 snapshots and selection/preview/drawer branches were checked with a local DOM stub. This verifies logic, not browser rendering or final Godot layout.

## Godot separation

Keep simulation and journal authoritative. The UI receives state, legal actions and previews, then sends validated commands to the simulation. Do not duplicate costs or payment logic in button scripts.

- Game host: simulation, command dispatch, save/load, journal.
- Town view: `Node2D`; optionally isolated through `SubViewportContainer` and `SubViewport`.
- Interface: `CanvasLayer` with `Control` containers for the turn bar, houses, pile, hand, inspector and footer.
- Laboratory: separate collapsible `Control` backed by the same journal and runner.

Share presentation-only selection across cards, town assets and future sprites. No 3D scene is needed.

Later contracts, specialist classes, transportation, money, research, privileges, institutions, overbuilding and autonomous town development remain future design topics. Do not add empty permanent tabs for them now.

## First review

Review the spatial hierarchy first: houses left, town centre, shared actions below it, one inspector right, laboratory underneath. If accepted, the next implementation can use plain Godot names and rectangles with the sprite canvas reserved.

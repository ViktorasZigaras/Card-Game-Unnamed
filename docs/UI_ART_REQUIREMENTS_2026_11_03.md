# Medieval Town — UI and art development instructions

Prepared 3 November 2026 from the Medieval Town discussion thread, following the designer's first inspection of the playable screen.

## Task and authority

Implement the interface and presentation redesign described below in the existing native Godot game. This document records new requirements; it does not report implemented changes. The discussion thread has not modified game code.

Repository: https://github.com/ViktorasZigaras/Card-Game-Unnamed

The handoff read in this discussion identifies v0.909 / save schema18 as the tested reconstructed gameplay baseline, commit `30514b0228bafc34aa37aaa8d8027db6c207fdb9`. Inspect latest main before working: it may have advanced. Read `docs/THREAD_HANDOFF.md`, `CURRENT_GAME.md`, `ISSUES_AND_QUESTIONS.md`, `PLAYER_AI.md`, and `FILES_AND_DOCUMENTS.md`. Preserve the twelve recorded design answers and their qualifications. This project is separate from Alien Planet.

This is a presentation and interaction change, with manual site selection now requested. Preserve economic rules, legal actions, costs, turn timing, partial contributions, rights, AI behaviour and save compatibility except where an explicit requirement below demands an interaction change. Follow current versioning practices; do not reset an advanced branch to v0.909.

## Visual reference and intended result

The designer's first impression of the existing UI was “ugly” and “mechanical”: the town read as a schematic rather than a picturesque place. Stylised buildings alone did not solve the composition, and basic effects felt stylistically disconnected.

The new target is a coherent, atmospheric sprite town with a tactile illustrated interface. References discussed: picturesque medieval Anno town views, original Colonization interface surfaces, Settlers II opened menus, and small local building activities reminiscent of classic town views. These are visual references, not assets to extract or demands to reproduce those engines.

Generated concept approved as a substantially better direction:

[Medieval Town: Opening Village Strategy.png](https://chatgpt.com/library?file_id=libfile_cd9ac5413f408191a9b8e5e290019b6f&account_id=personal)

Inspect that image before building the new presentation. It is an opening **play screen**, not a title menu. It is a visual target, not a one-for-one specification or executable screenshot. Its exact counts, exchanges, house ownership placements, deck contents, caravan timing and decorative progress are illustrative. Do not import them as new game rules. In particular, the mockup's house-coloured goods rows must not imply that every resource type belongs to a different house; show actual token rights.

No side-by-side comparison with an old actual screenshot was performed in this discussion. The handoff lists `docs/images/v0_60.png` as historical and `town_layout_0_909.png` as a static study rather than a Godot capture. Capture the actual current UI for the development comparison.

## 1. Main screen arrangement

| Area | Requirement |
|---|---|
| Top | Available shared action cards always visible, plus draw/deck and discard access |
| Left | Goods displayed as individual tangible tokens with actual rights indicated visually |
| Centre | Picturesque layered town, largest visual focus |
| Right | Discoverable action categories and contextual object/action details |
| Bottom | Trading cards / trade opportunities |
| Utility controls | Separate Game and Info menus; House Info is a standalone button for now |

Remove the current need to visit a Cards tab to see the shared hand. Move the left Buildings tab into an Info-menu button. Replace the left House-info area with a House Info button, freeing that area for goods.

Interpret bottom trading cards against the current executable trade systems. Surface real exchanges/opportunities and meaningful availability; do not invent barter recipes to match the mockup. The exact treatment of persistent contracts versus transient offers is a routine layout choice unless it changes rules.

Retain the existing minimum 1920×1080 design target. The mockup establishes relationships rather than fixed panel dimensions. Preserve legibility, useful town area, tooltips and access to long lists when content grows.

## 2. Atmospheric surfaces and controls

Every surface should have a deliberate background: restrained wood grain, plaster, parchment, cloth or stone as appropriate. Buttons need woody/material edges and understandable interaction states. Decorative flourishes and economically unnecessary objects are desired: a barrel here, a branch there, a stone, a sack, leaves or workshop belongings.

Place decoration deliberately around edges and gaps. Keep texture quiet under text, token silhouettes distinct, and selection/hover/disabled/pressed states readable. Many tokens should be borderless; ownership markings are purposeful additions. Use a coherent perspective, palette, light direction, pixel scale and level of detail across town, controls, icons and animation.

## 3. Town as a layered place

Create a landscape background with multiple layers above it to provide depth and the illusion of a real place. The town remains sprite based; an elevated three-quarter/2.5D appearance is suitable. Avoid exposed plot grids, schematic boxes and address labels in normal play.

Suggested composition:

- Background landscape and distant scenery.
- Ground surfaces, worn paths, paving and foundations.
- Changeable vegetation, clearing, fields, construction and buildings.
- Local fences, barrels, woodpiles, gardens and other small scenery.
- Foreground roofs, trees or walls that naturally overlap objects behind them.
- Local animations and restrained contextual interaction overlays.

Preserve persistent plot identities and land rules beneath the scene. Arrange properties convincingly along paths with enough room for supported upgrades and future construction. Removable vegetation must be a removable layer; do not bake it into an unchangeable background. Roads currently remain atmospheric. Do not add adjacency, travel costs or free economic land through the art redesign.

### Stockade and ongoing projects

The stockade exists mechanically, requiring six wood in the documented baseline. Its actual current visible representation was not established in this discussion; inspect source and running game. Provide an unmistakable town perimeter: incomplete sections during construction and a coherent completed stockade when finished. Make the project selectable, exposing progress, contribution choices and completion benefits from actual rules.

Half-built and partly upgraded buildings must show their supplied and outstanding costs on the map, near the relevant site. Preserve old function during partial upgrades according to existing mechanics. Plan spacing/overlap handling for several active projects without burying the buildings.

## 4. Small local sprite animations

Use mostly static building artwork with small individually animated regions. Examples: a worker raising and striking a hammer inside a workshop, sparks on impact, a saw moving, smoke above a chimney, a banner swaying, occasional window activity/light.

Attach animation anchors to the building's local coordinates, so relocation, scaling and camera changes keep the insert aligned. Use foreground architecture or masks where necessary to make workers appear inside openings. Do not animate whole buildings merely to indicate activity.

Short sprite sequences, pauses and varied start times should feel observed rather than synchronised and mechanical. Reuse compatible effects such as smoke, while allowing building-specific characteristic activity. Maintain the same pixel-art treatment throughout; generic smooth glows or effects that conflict with the scene are unsuitable.

Animate only the necessary region instead of storing complete-building frames. Share sprite sheets/resources across instances. Keep cosmetic randomness separate from simulation randomness, retain animation-disable support, and pause hidden presentation where appropriate. Initial scope can be one convincing characteristic activity per building; unique animation for every decorative object is unnecessary.

## 5. Tokens are the common visual language

Use actual resource/token sprites and repeated shapes for costs, inputs, outputs, upgrades, trade and construction progress. For example, display “Building cost:” followed by two wood sprites, rather than “You need two wood.” The shape identifies the resource; the number of shapes communicates quantity.

Every token type needs a corresponding pair of visuals:

| Visual | Meaning in the labelled context |
|---|---|
| Active/default | Available, supplied or output token |
| Depleted/missing counterpart | Missing or still required token |

“Mirror” here means a matching counterpart state, not a requirement to flip the image horizontally. Preserve the silhouette and identity in the missing state. Distinguish states beyond colour alone. Apply a consistent convention everywhere.

For project progress show the full requirement, with paid/supplied tokens active and remaining tokens depleted. These are committed progress indicators, not collectible inventory. For an action preview, distinguish available inputs from missing ones. Do not confuse available goods with already paid construction materials. Label context and provide explanatory tooltips.

Small quantities should be individually countable. If large quantities need grouping/overflow, preserve exact totals and expandable inspection; do not silently truncate. Social currencies and capacity requirements also need clear consistent symbols while retaining their distinct mechanics.

### Rights and reservations

Use a house crest and/or house-coloured outline to communicate ownership and reservation on relevant goods. Crests supplement colour for recognition. Avoid repetitive “reserved by...” text in the ordinary display. Tooltips/details must still explain the exact right, expiry, access cost and commitment where relevant.

Public goods must remain visibly public. A crest does not make reservation, private storage and committed backing equivalent: keep those states distinguishable with grouping, small secondary marks or details.

## 6. Discoverable actions and contextual information

The designer had difficulty discovering how to build despite knowing the intended mechanics. Expose recognisable action categories, including Build, Upgrade, Contracts and Trade/Expeditions as applicable.

Construction flow: **Build → catalogue of buildings → choose building → choose eligible coordinates/site → perform the applicable legal action**. Site choice comes after deciding what to build. Implement location selection against existing plot eligibility; do not change costs or allow unsupported placements.

Respect the separate social site claim and later material contributions. Do not turn staged construction into an atomic build or automatically spend extra actions. Label the immediate action honestly (for example, claim site, contribute, finish) and show the broader material requirement.

Catalogue entries should show appearance, purpose, benefit, token cost, prerequisites and availability. Keep unavailable options discoverable with clear reasons.

Selecting a map object should make its function, ownership and activity apparent. Show whether it is upgradeable, why the upgrade is useful, the before/after result, token costs and missing requirements. Provide a clear upgrade action. Similar intention-first entry points should support contracts and other systems without forcing players to infer hidden navigation conventions.

## 7. Immediate execution and Safe Actions

Move the existing infrequently used top-right utility controls into **Game**. Include a persistent **Safe actions: On/Off** preference.

- Off: a click on a fully specified action executes it. Skip skips immediately; a complete build/contribution action runs immediately. Remove redundant preview-then-Execute clicking for such actions.
- On: provide the protective confirmation step, explaining the actual consequence and cost.
- Necessary choices remain necessary: choosing a category, target or location is not redundant confirmation.
- Display costs and requirements before execution in both modes. Object selection/inspection must not inadvertently execute an economic action.

The default setting was not selected in discussion; choose and document a sensible default. Preference persistence is separate from economic simulation state. Safe Actions must not alter legal rules or AI decisions.

## 8. Human-readable feedback; diagnostics behind the menu

The player does not need raw JSON. Normal logs and explanations should say what happened, why an action is blocked, and the heuristic reasoning behind an AI choice when inspected.

Examples of the form, not fixed claims about current AI: “Saving timber for the home”; “Postponing the kiln until clay supply is secured”; “Public access meets this plan; priority would add cost without improving it.” Explain actual evaluated motives and constraints. Do not generate plausible explanations disconnected from final scores, payments and results.

Put JSON, internal identifiers and detailed diagnostic records behind developer diagnostics in Game/the existing laboratory. Keep technical evidence available for debugging and export. Make recent player-facing events and explanations accessible without restoring a large permanent technical log to the main screen.

## 9. Implementation and verification

Inspect current source and running UI first. Relevant baseline paths include `ui/play_interface.gd`, `live_interface.gd`, `interface.gd`, `live_session.gd`, `town_view.gd`, `town_ambience.gd`, `goods_view.gd`, `artwork.gd`, `src/town_layout.gd` and `src/mapped_town_simulation.gd`. These are navigation clues, not a mandate to preserve the current presentation architecture.

Deliver an integrated playable screen using reusable layered assets, not a single flattened mockup covering interactive controls. New art should follow the approved direction. Do not settle for moving old schematic boxes around and calling the visual redesign complete.

Verify these concrete cases:

1. Opening screen at 1080p: hand on top, goods left, town centre, actions right, trade below, both menus and House Info accessible.
2. Find Build without prior knowledge, inspect costs, select an eligible plot, claim it and contribute materials on separate actions.
3. Select an upgradeable building; understand benefit and requirements; pay partially; see correct persistent map progress.
4. See and inspect unfinished/completed stockade and its true progress.
5. Distinguish public, reserved, private and committed goods; expired reservations refresh accurately.
6. Inspect remaining deck composition and discarded cards with exact counts. Show remaining contents, not secret shuffled order.
7. Skip and another fully specified action execute once with Safe Actions off; confirmations work when on; cancellations do not spend resources or advance turns.
8. Read meaningful feedback without encountering JSON; open technical diagnostics when needed.
9. Save/reload preserves gameplay, plot identity and project progress; animations do not change deterministic outcomes; zoom/scaling keeps overlays aligned.

Run meaningful existing regression checks for affected paths and inspect script errors as well as exit codes. Capture actual Godot screenshots and inspect layout, clipping, contrast and token recognition. Observe animations in the running game: headless geometry checks and still screenshots cannot establish their quality.

Checkpoint source and documentation durably during substantial work. Update the decision register and UI documentation to separate this specification from delivered behaviour and remaining limitations. Report what is implemented, what is still provisional, validation performed and where to get the runnable result. This instruction document itself makes no claim of implementation or repository publication.

## Starter message for the development thread

> Continue Medieval Town in ViktorasZigaras/Card-Game-Unnamed. Read the current handoff and this UI/art development instruction document, then inspect the linked opening-screen mockup and actual current game. Implement the integrated interface redesign, preserving the economic rules and recorded decisions. Priorities are atmospheric layered sprite presentation, local coherent animation, visible hand and trade cards, goods on the left, intention-first actions, token costs/progress, heraldic rights, menus, optional confirmations and human-readable explanations. Keep staged construction intact. Validate the running 1080p screen and affected interactions, preserve durable checkpoints, and provide actual screenshots and the playable result for review.

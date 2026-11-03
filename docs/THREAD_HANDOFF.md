# Medieval Town — handoff for fresh development and discussion threads

Prepared 3 November 2026. **Game v0.909, live saves schema 18. This handoff is documentation-only.** Working title: Card Game / Medieval Town / Town and Houses. Wider project: AI Generated Games. This is separate from Alien Planet; do not import that project's AI hierarchy, version or rules.

## Start here

Canonical source: [ViktorasZigaras/Card-Game-Unnamed](https://github.com/ViktorasZigaras/Card-Game-Unnamed). Main contains the tested reconstruction and this documentation cleanup. Immutable gameplay baseline: [`30514b0228bafc34aa37aaa8d8027db6c207fdb9`](https://github.com/ViktorasZigaras/Card-Game-Unnamed/commit/30514b0228bafc34aa37aaa8d8027db6c207fdb9). [Download that game baseline](https://github.com/ViktorasZigaras/Card-Game-Unnamed/archive/30514b0228bafc34aa37aaa8d8027db6c207fdb9.zip); use repository main for the latest consolidated docs. Never rely on an old conversation download path as the only copy.

The unpublished v0.906–v0.908 scratch files were removed during automatic maintenance. v0.909 was reconstructed from preserved v0.905 source/art and the conversation, then freshly tested and uploaded. It is **not a byte-identical restoration**. Historical reports are retained, and new evidence is identified separately. Recovery checkpoints also exist on `recovery/v0.909`.

Read in order:

1. [CURRENT_GAME.md](CURRENT_GAME.md): what executes, quantities, timing, rights, projects, land, trade and UI.
2. [ISSUES_AND_QUESTIONS.md](ISSUES_AND_QUESTIONS.md): all twelve answered questions, qualifications, current gaps and next-test options.
3. [PLAYER_AI.md](PLAYER_AI.md): actual consolidated policy and its limits.
4. [Medieval_Town_Design_Synthesis_and_Next_Test.md](Medieval_Town_Design_Synthesis_and_Next_Test.md): all retained concepts, additions, deferred systems and reconciled contradictions.
5. [FILES_AND_DOCUMENTS.md](FILES_AND_DOCUMENTS.md): file roles, exact inventory, document authority and historical artifacts.
6. [RECOVERY_0_909.md](RECOVERY_0_909.md): recovery boundaries, fresh results, reproduction commands and visual study.

## Where development stands

The game is a native Godot 2D prototype of three competing noble/merchant houses in a shared clayless town. Persistent physical tokens, scarce labour capacity, shared card opportunities, titles, social currencies, finite land and imports create dependencies. Current house goals: good owned brick home → owned industry → unique Hall → remaining opportunities. This is not a victory definition. The intended human appeal is making smart plans toward what a house could become; rewards and universal completion are not the measure of fun.

Already implemented: partial home/chapel improvement; staged claim/partial market, kiln, sawmill and Hall construction; protected ongoing sites; eligible unowned clearance/forced replacement and occupied rural conversion with full associated costs; wall/land tasks; biome rolls; globally permanent recipe unlocks; Hall land transport, crew expeditions, finite cargo and recurring funded public/priority routes; cheap voluntary versus expensive hostile cancellation; escalating buyout prices; social-currency sinks; one consolidated inspectable PlannerAI pipeline; tabbed screen, tangible goods, saved fifteen-position town, decorative vegetation/roads and subtle motion.

Important unfinished directions: general independently bindable local quantities and enabled upstream chains; partial contract establishment; wider strategic planning/ownership valuation; actual technologies, specialists, businesses/guilds/institutions, privileges, sea fleets, town treasury/general city planner and final victory. Do not describe these as lost working features. Dedicated Hall/sawmill art, manual plot selection, adjacency and road/travel economics are also absent.

The old sawmill-demolition bookkeeping defect, optional-Hall objective, atomic market/kiln builds and fixed outer two-forest/two-field split are superseded. Current local one-contract-per-resource remains a genuine gap against Q09. Combined cancellation on clearance remains highly provisional even though it executes. Unlimited brick demand is deliberately testing scaffolding. All numbers remain provisional unless separately confirmed.

## Do not reopen the twelve answers

Social claim then material construction on separate actions; ongoing-site protection; highly provisional combined dependent cancellation; legal occupied rural conversion with all costs; credible routes before preparing force; home/industry/Hall/leftovers order; owner-only Hall workshop; unique HQ allowance; everyone shares all unlocks forever; meaningful quantity bindings; biome probabilities with later terrain work; temporary unlimited brick demand; private gain then useful civic fallback. Full wording and qualifications are in the decision register. The later protection answer supersedes the earlier tentative unfinished-site replacement exception.

## Suggested next work

The designer was about to inspect the uploaded tabbed/map screen. Obtain those observations before assuming UI/art direction is settled. A useful next mechanics experiment is repeated **private** supply demand where ownership may repay access/exit costs. Current six paired home fixtures show public and priority finish at the same round; priority cannot be justified by invented delay. A distinct next feature candidate is quantity-based local bindings under Q09. Scope one causal change at a time and discuss after six matched tests rather than treating automated completion as success by definition.

## Run and validate

Use Godot 4.5.1 standard or newer. Import `project.godot`, allow script-class registration, F5 to play; F11 fullscreen. No external game plugins. Source project targets 1920×1080. Main scene `ui/interface.tscn`; live controller `ui/live_session.gd` creates `MappedTownSimulation` and `PlannerAI`, contract batch 3. New live games are schema18; historical engines keep their own schema/replay paths. Do not silently reinterpret older saves.

From the repository root, with `godot` on PATH:

```bash
godot --headless --path . --editor --import
godot --headless --path . --script tests/mapped_town_checks.gd
godot --headless --path . --script tests/flexible_contract_checks.gd
godot --headless --path . --script tests/recovered_ui_checks.gd
```

Choose meaningful additional checks for the change. `planner_equivalence.gd` checks historical policy preservation; `mapped_town_experiment.gd` runs six 80-round towns; `flexible_directed.gd` tests cargo/bridges; `priority_competition.gd` tests six access pairs; `priority_value_checks.gd` tests ownership calculations; `expedition_ui_check.gd` covers trade UI. `godot --headless --path . -- --ui-check` exercises archived native UI. Inspect logs for script errors as well as exit status. Large replay journals/saves are regenerable and intentionally excluded from the source ZIP.

Fresh v0.909 results: 4,806 identical baseline decisions/candidate scores; 4,793 mapped actions exactly replayed and all eighteen Halls complete; 302 controlled cargo/bridge actions; 220 paired competition actions; focused contract/map/value/UI checks. These are separate datasets and should not be summed into a single success metric. Fixtures can arrange a Hall before a missing home to isolate trade and do not demonstrate organic progression. Headless geometry is not a visual playtest. See the recovery report for exact counts and seeds.

## Working practices for the split

Development thread owns source edits and runnable validation; discussion thread owns proposals and explicit decision records. Carry any new agreed decision into the canonical register with status/date before implementing it elsewhere. Avoid two threads editing the same branch blindly: inspect latest main, use isolated commits/branches as needed, and resolve the actual new head before publishing. Do not discard existing changes just because a local checkout is stale.

Keep implementation, intended design, provisional balance and deferred concepts separate. Preserve historical test reports and attach version/scope. Use six matched tests with comments, observations and suggestions between rounds when experimenting. Inspect final candidate scores and actual payment/result rather than trusting an inherited reason string. Reuse explicit decisions; ask only genuinely new material questions, preferably one at a time. Make routine reversible implementation choices within authorised scope.

Checkpoint source and documents in the repo during substantial work and verify the published head before reporting upload complete. Save user-facing document updates to their existing persistent identities. Temporary workspace copies can vanish. Next gameplay change advances from 0.909 to 0.910; this cleanup itself does not advance the game. Do not run one-time reconstruction scripts as ordinary setup. Do not automatically add new business/technology systems just because the backlog names them.

## Starter for a new development thread

> Continue the Medieval Town / Card Game project in `ViktorasZigaras/Card-Game-Unnamed`. Read latest main's `docs/THREAD_HANDOFF.md`, `CURRENT_GAME.md`, `PLAYER_AI.md`, `ISSUES_AND_QUESTIONS.md` and `FILES_AND_DOCUMENTS.md` before editing. Gameplay baseline is v0.909/schema18, reconstructed and tested; no claim of byte-identical recovery. All twelve design answers are recorded; preserve their qualifications. First inspect current repository state and my latest play observations, then implement the specifically selected next task with meaningful tests and durable checkpoints. Keep gameplay and discussion changes attributable; do not invent missing tech/business rules. Use six matched cases and discuss evidence between batches for balance experiments.

## Starter for a new discussion thread

> Continue design discussion of Medieval Town / Card Game, separate from Alien Planet. Read latest main's `docs/THREAD_HANDOFF.md`, `Medieval_Town_Design_Synthesis_and_Next_Test.md`, `CURRENT_GAME.md` and `ISSUES_AND_QUESTIONS.md`. The intended appeal is a planner's thinking game for my preferences. Distinguish implemented v0.909 mechanics, twelve already answered decisions, provisional test constants, real implementation gaps and deferred ideas. Do not repeat settled questions or silently change code. Discuss one concrete new issue at a time and record agreements/qualifications so the development thread can implement and test them.

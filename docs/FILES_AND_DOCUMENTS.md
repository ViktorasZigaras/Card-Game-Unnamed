# Medieval Town — files and document inventory

Prepared 3 November 2026. Current gameplay **v0.909 / schema18**, immutable baseline `30514b0228bafc34aa37aaa8d8027db6c207fdb9` in [ViktorasZigaras/Card-Game-Unnamed](https://github.com/ViktorasZigaras/Card-Game-Unnamed). This inventory distinguishes durable source, documentation, historical evidence and temporary working outputs. Paths below are repository-relative unless explicitly described as temporary.

## Canonical document map

| File | Purpose and authority |
|---|---|
| [CURRENT_GAME.md](CURRENT_GAME.md) | Executable inventory: goods, recipes, rules, costs, projects, trade, land, map/UI, limits |
| [PLAYER_AI.md](PLAYER_AI.md) | Current PlannerAI pipeline, goals, route/ownership/budget heuristics, actual limits and evidence |
| [Medieval_Town_Design_Synthesis_and_Next_Test.md](Medieval_Town_Design_Synthesis_and_Next_Test.md) | Original fifteen topics plus foundation concepts and later additions; implemented/confirmed/provisional/deferred status |
| [ISSUES_AND_QUESTIONS.md](ISSUES_AND_QUESTIONS.md) | Twelve original answers preserved, previous audit status, settled details and open queue |
| [THREAD_HANDOFF.md](THREAD_HANDOFF.md) | Read order, code baseline, run/check instructions, split-thread practices and two starter prompts |
| [FILES_AND_DOCUMENTS.md](FILES_AND_DOCUMENTS.md) | This registry and exact file listing |
| [RECOVERY_0_909.md](RECOVERY_0_909.md) | Reconstruction history, fresh tests, limits, commands and static visual study; preserved as a release record |
| `README.md`, `VERSION` | Entry instructions and gameplay version; docs-only cleanup does not increment it |

Explicit designer decisions outrank earlier illustrative suggestions. Code is the authority on executable behaviour; canonical documentation distinguishes code from intended design. Test results are version/path-specific evidence. Neither an old `NEXT_…` filename nor a `CONFIRMED_…` prefix gives its entire old body priority over the current register.

## Existing user-facing document identities

These existing documents were updated in place for this consolidation; the old filename of the first two is retained for continuity but their current **content describes v0.909**. Their original v0.903 contents are archived in the repository and retained in version history.

| Existing filename | Canonical repository equivalent | Persistent identity |
|---|---|---|
| `Medieval_Town_Current_Game_0903_2026-11-01.md` | `docs/CURRENT_GAME.md` | `libfile_6b20add78e748191be1b34fe0cee517d` |
| `Medieval_Town_Player_AI_0903_2026-11-01.md` | `docs/PLAYER_AI.md` | `libfile_e14af72ea95081919a06edf6e190fe32` |
| `Medieval_Town_Design_Synthesis_and_Next_Test.md` | Same basename in `docs/` | `libfile_70125ef3b45481918b5e447a1451e575` |
| `ISSUES_AND_QUESTIONS.md` | Same basename in `docs/` | `libfile_8ee6fa1592988191aa356825641eb210` |
| `medieval_town_card_game.md` | Historical `docs/archive/FOUNDATION_DESIGN_2026_10_29.md` | `libfile_77ec4407025c8191966c627e5e201265` |

The foundation brief keeps its original body with a historical-status notice and links to current references. New standalone deliverables are `THREAD_HANDOFF.md` and `FILES_AND_DOCUMENTS.md`. Repository-relative links work in the repository edition; standalone editions include a link to that edition at the top.

Older downloadable prototypes remain historical artifacts, not current backups: `Medieval_Town_Godot_Prototype_0_1_0.zip`, `0_2_0.zip`, `0_3_0.zip`, `0_4_0.zip`, `0_5_0.zip` (each name begins `Medieval_Town_Godot_Prototype_`). They are not overwritten with a differently versioned game. The current immutable source archive is [v0.909 at the verified code commit](https://github.com/ViktorasZigaras/Card-Game-Unnamed/archive/30514b0228bafc34aa37aaa8d8027db6c207fdb9.zip). Use main for these latest docs. Unrelated image search matches and other games are outside this handoff.

## Active code map

| Files/group | Role |
|---|---|
| `project.godot`, `ui/interface.tscn` | Godot project and actual main scene |
| `ui/play_interface.gd` → `live_interface.gd` → `interface.gd` | Current tabbed playing screen over existing action/session interface |
| `ui/live_session.gd` | Live adapter: MappedTownSimulation + PlannerAI, batch 3; legal previews, play/save/replay integration |
| `src/mapped_town_simulation.gd`, `src/town_layout.gd` | Schema18 saved plot addresses/terrain/occupancy and map invariants |
| `src/flexible_contract_simulation.gd` | Schema17 public/priority route choice, social ownership costs, creator/owner exit prices and delivered-clay reward timing |
| `src/financing_simulation.gd` | Schema16 funding observations/state used in route-budget assessment |
| `src/expedition_simulation.gd` | Travel clock, real crew, offers, finite cargo, routes, gold/transport accounting |
| `src/development_simulation.gd` | Social claim/material build separation, protected sites, clearance/retired records, occupied conversion, global unlocks and biome rolls |
| `src/hall_simulation.gd` through `marketplace_simulation.gd` and earlier foundations | Inherited live mechanics: Hall/sawmill, stockade, partial projects, trade, kiln/labour, priority, contracts, market and physical foundations |
| `src/planner_ai.gd` | Live consolidated scoring pipeline with final selection, goals, alternatives, funding/priority assessment and diagnostics |
| Other `*_ai.gd`, `src/house_ai.gd` | Older policies/test references and base interface. They are not all active decision layers or separate personalities |
| `src/retry_simulation.gd` | Historical branch for earlier retry experiment, not the current direct mechanics ancestry |
| `src/game_probe.gd`, `src/laboratory.gd`, `laboratory.tscn` | Journals, snapshots, seeded experiment/replay/AI diagnostic tools |
| `data/marketplace_rules.json` | Base live scenario definitions; subclasses extend/override them |
| Other `data/*rules.json` | Earlier experiment/foundation definitions; not five independently active live scenarios |
| `ui/town_view.gd`, `town_ambience.gd`, `goods_view.gd`, `artwork.gd` | Map, cosmetic effect clock, tangible token groups and atlas handling |
| `ui/recorded_preview.json`, `ui/verification.txt` | Earlier preview/verification material; do not treat as current dynamic rules |

Mechanics ancestry: MappedTown → FlexibleContract → Financing → Expedition → Development → Hall → Stockade → Project → Trade → Capacity → Priority → Contract → Marketplace → earlier housing/reservation/commons/town foundations. New live schema18 does not erase the historical schema-specific replay engines. See `PLAYER_AI.md` for the distinct consolidated policy pipeline.

## Tests, results, tools and artwork

Current focused files: `tests/flexible_contract_checks.gd`, `mapped_town_checks.gd`, `priority_value_checks.gd`, `recovered_ui_checks.gd`, `expedition_ui_check.gd`. Current experiments: `planner_equivalence.gd`, `mapped_town_experiment.gd`, `flexible_directed.gd`, `priority_competition.gd`; `flexible_fixture.gd` supports directed fixtures. Earlier `tests/*` remain targeted historical regression/experiment entry points; do not assume every old experiment is the current live engine.

Fresh compact results: `experiments/planner_equivalence`, `mapped`, `flexible_checks`, `flexible_directed`, `priority_competition`, `priority_value`, `mapped_checks`, `recovered_ui`. Earlier financing/projects/marketplace evidence has its own provenance; do not pool counts across versions. Large generated JSONL journals and save fixtures may be excluded and regenerated. The current evidence counts and limitations are in `RECOVERY_0_909.md`.

`tools/run_checks.py` and `inspect_run.py` support checks/inspection. `make_expedition_report.py` and `make_financing_report.py` generate experiment summaries. `render_town_preview.py` makes a static data-driven layout study. **`reconstruct_planner.py` and `restore_policy_changes.py` are one-time recovery tools, not required setup or normal migrations**; do not rerun them over current source casually.

`art/buildings.png`, `goods.png`, `town_ground.png` are original generated prototype assets; `art/README.md` explains atlas/provisional use and `PROMPTS.md` records prompts. Style references are the approved medieval collage and classic Colonization-like sprites/Anno-like buildings, not extracted proprietary assets. Current effects/roads/vegetation are code presentation. `docs/images/v0_60.png` is historical; `town_layout_0_909.png` is a static design study, not a captured Godot screen. No new artwork was generated during this documentation cleanup.

## Historical document cleanup

The following files now carry a prominent historical notice. Their bodies/results are preserved; recommendations such as “next implement force replacement” apply to their old baseline, not current v0.909:

- [BRICK_DEMAND_GOLD_AND_INDUSTRY_TEST_010.md](BRICK_DEMAND_GOLD_AND_INDUSTRY_TEST_010.md)
- [CARAVAN_RETRY_TEST_008.md](CARAVAN_RETRY_TEST_008.md)
- [COMMITTED_WOOD_AND_KILN_TEST_009.md](COMMITTED_WOOD_AND_KILN_TEST_009.md)
- [COMMONS_EXPERIMENT_003.md](COMMONS_EXPERIMENT_003.md)
- [CONFIRMED_ISSUES_AND_QUESTIONS.md](CONFIRMED_ISSUES_AND_QUESTIONS.md)
- [CONFIRMED_Medieval_Town_Design_Synthesis_and_Next_Test.md](CONFIRMED_Medieval_Town_Design_Synthesis_and_Next_Test.md)
- [CONTRACT_ECONOMY_TESTS_006.md](CONTRACT_ECONOMY_TESTS_006.md)
- [EVERY_HOUSE_EXPERIMENT_005.md](EVERY_HOUSE_EXPERIMENT_005.md)
- [HOUSE_HALLS_AND_SAWMILL_013.md](HOUSE_HALLS_AND_SAWMILL_013.md)
- [HOUSING_EXPERIMENT_001.md](HOUSING_EXPERIMENT_001.md)
- [LAND_EXPEDITIONS_AND_DEVELOPMENT_014.md](LAND_EXPEDITIONS_AND_DEVELOPMENT_014.md)
- [MARKETPLACE_EXPERIMENT_004.md](MARKETPLACE_EXPERIMENT_004.md)
- [NATIVE_INTERFACE_0_55.md](NATIVE_INTERFACE_0_55.md)
- [NEXT_ISSUE_012.md](NEXT_ISSUE_012.md)
- [NEXT_SCENARIO_005.md](NEXT_SCENARIO_005.md)
- [PARTIAL_UPGRADES_AND_STONE_CHAPEL_011.md](PARTIAL_UPGRADES_AND_STONE_CHAPEL_011.md)
- [PRIORITY_CONTRACT_TEST_007.md](PRIORITY_CONTRACT_TEST_007.md)
- [PROVISIONAL_RULES.md](PROVISIONAL_RULES.md)
- [RELEASE_0_60.md](RELEASE_0_60.md)
- [RESERVATION_EXPERIMENT_002.md](RESERVATION_EXPERIMENT_002.md)
- [ROUTE_FINANCING_TEST_015.md](ROUTE_FINANCING_TEST_015.md)
- [STOCKADE_AND_LAND_TEST_012.md](STOCKADE_AND_LAND_TEST_012.md)
- [TEST_REPORT.md](TEST_REPORT.md)
- [UI_SCHEMA_0_50.md](UI_SCHEMA_0_50.md)

The five files under `docs/archive/` preserve the reviewed foundation, v0.903 inventory, v0.903 AI, synthesis and twelve-answer audit. Those are archival snapshots. The `CONFIRMED_…` originals are also retained with historical notices rather than deleted or silently merged into a new false test report.

## Temporary working outputs used in this thread

These paths identify the current workspace layout for troubleshooting only; a future thread must start from the repo if they are gone.

| Path/group | Purpose | Continuity rule |
|---|---|---|
| `card-game-recovery/` | Working source tree and documentation edits | Local git index was still at the older checkout during reconstruction; do not publish its whole apparent diff blindly |
| `card-game-0.909.zip` | Tested recovery source package, 242 files, 9,025,216 bytes | Code baseline package predates this doc cleanup; repo main has updated docs |
| `package-check/card-game-0.909/` | Extracted package used for independent import and focused checks | Disposable reproduction copy |
| `runtime/Godot_v4.5.1-stable_linux.x86_64` | Downloaded test engine | Obtain Godot independently if missing |
| `verification/package_manifest.json`, `UPLOAD_VERIFIED.json`, `remote-blob-shas.json` | Exact package hashes and 242 remote blob checks; zero mismatches | Baseline code publication evidence, not a manifest of this later docs commit |
| `verification/*.log` | Import, mechanics, UI, experiment and packaging logs | Supporting local evidence; durable compact results are in repository |
| `verification/checkpoint*.json`, `blob-*.txt`, `new-binaries.json` | Recovery upload transport/checkpoint material | Temporary implementation intermediates, not game input |
| `doc-work/downloads/` | Identity-preserving copies of five existing documents before cleanup | Originals archived; updated user-facing identities preserved |
| `doc-work/write_registers.py`, `finish_docs.py` | One-time documentation assembly/archive/inventory scripts | Not runtime dependencies; final documents are authoritative |
| `doc-work/library-search.json`, `library-tools/` | Private discovery/transfer intermediates | Not project files and not needed by either new thread |
| `doc-work/validation.json`, `publication.json` | This cleanup's checks and published-doc commit record | Temporary receipt; verify current repo when continuing |

No byte-identical v0.906–v0.908 source survives here. This file does not invent filenames or contents for lost outputs. The exact baseline ZIP SHA-256 is `dba8781d05140ed17353395b7d38462e0af33b3fc337b1787d2341c71f3d8658`. A copy containing later documentation will naturally have a different archive hash.

## Exact repository file inventory

This lists the 242 verified baseline package paths plus the six canonical new/replaced reference paths and five archived sources, deduplicated. It excludes generated Godot import caches, local journals excluded from the package, private transfer helpers and unrelated workspace material. `.uid` and shipped `.import` sidecars, where present, are source-side metadata rather than additional mechanics. Existing root package-control metadata remains in the repo; source roles are described above. Directory grouping is for navigation, not an assertion that every historical script is active.

### Project entry files

- `README.md`
- `VERSION`
- `laboratory.tscn`
- `project.godot`

### Simulation and AI

- `src/capacity_simulation.gd`
- `src/capacity_simulation.gd.uid`
- `src/commons_ai.gd`
- `src/commons_ai.gd.uid`
- `src/commons_simulation.gd`
- `src/commons_simulation.gd.uid`
- `src/contract_ai.gd`
- `src/contract_ai.gd.uid`
- `src/contract_simulation.gd`
- `src/contract_simulation.gd.uid`
- `src/development_ai.gd`
- `src/development_ai.gd.uid`
- `src/development_simulation.gd`
- `src/development_simulation.gd.uid`
- `src/expedition_ai.gd`
- `src/expedition_ai.gd.uid`
- `src/expedition_simulation.gd`
- `src/expedition_simulation.gd.uid`
- `src/financing_ai.gd`
- `src/financing_ai.gd.uid`
- `src/financing_simulation.gd`
- `src/financing_simulation.gd.uid`
- `src/flexible_contract_simulation.gd`
- `src/flexible_contract_simulation.gd.uid`
- `src/game_probe.gd`
- `src/game_probe.gd.uid`
- `src/hall_ai.gd`
- `src/hall_ai.gd.uid`
- `src/hall_simulation.gd`
- `src/hall_simulation.gd.uid`
- `src/house_ai.gd`
- `src/house_ai.gd.uid`
- `src/housing_ai.gd`
- `src/housing_ai.gd.uid`
- `src/housing_simulation.gd`
- `src/housing_simulation.gd.uid`
- `src/kiln_ai.gd`
- `src/kiln_ai.gd.uid`
- `src/laboratory.gd`
- `src/laboratory.gd.uid`
- `src/mapped_town_simulation.gd`
- `src/mapped_town_simulation.gd.uid`
- `src/marketplace_ai.gd`
- `src/marketplace_ai.gd.uid`
- `src/marketplace_simulation.gd`
- `src/marketplace_simulation.gd.uid`
- `src/planner_ai.gd`
- `src/planner_ai.gd.uid`
- `src/priority_ai.gd`
- `src/priority_ai.gd.uid`
- `src/priority_simulation.gd`
- `src/priority_simulation.gd.uid`
- `src/project_ai.gd`
- `src/project_ai.gd.uid`
- `src/project_simulation.gd`
- `src/project_simulation.gd.uid`
- `src/reservation_ai.gd`
- `src/reservation_ai.gd.uid`
- `src/reservation_simulation.gd`
- `src/reservation_simulation.gd.uid`
- `src/retry_simulation.gd`
- `src/retry_simulation.gd.uid`
- `src/simulation.gd`
- `src/simulation.gd.uid`
- `src/stockade_ai.gd`
- `src/stockade_ai.gd.uid`
- `src/stockade_simulation.gd`
- `src/stockade_simulation.gd.uid`
- `src/town_layout.gd`
- `src/town_layout.gd.uid`
- `src/trade_ai.gd`
- `src/trade_ai.gd.uid`
- `src/trade_simulation.gd`
- `src/trade_simulation.gd.uid`

### Presentation

- `ui/artwork.gd`
- `ui/artwork.gd.uid`
- `ui/goods_view.gd`
- `ui/goods_view.gd.uid`
- `ui/interface.gd`
- `ui/interface.gd.uid`
- `ui/interface.tscn`
- `ui/live_interface.gd`
- `ui/live_interface.gd.uid`
- `ui/live_session.gd`
- `ui/live_session.gd.uid`
- `ui/play_interface.gd`
- `ui/play_interface.gd.uid`
- `ui/recorded_preview.json`
- `ui/town_ambience.gd`
- `ui/town_ambience.gd.uid`
- `ui/town_view.gd`
- `ui/town_view.gd.uid`
- `ui/verification.txt`

### Data definitions

- `data/commons_rules.json`
- `data/housing_rules.json`
- `data/marketplace_rules.json`
- `data/reservation_rules.json`
- `data/rules.json`

### Tests

- `tests/commons_experiment.gd`
- `tests/commons_experiment.gd.uid`
- `tests/contract_checks.gd`
- `tests/contract_checks.gd.uid`
- `tests/contract_experiment.gd`
- `tests/contract_experiment.gd.uid`
- `tests/contract_ui_check.gd`
- `tests/contract_ui_check.gd.uid`
- `tests/every_house_experiment.gd`
- `tests/every_house_experiment.gd.uid`
- `tests/every_house_goal_check.gd`
- `tests/every_house_goal_check.gd.uid`
- `tests/expedition_checks.gd`
- `tests/expedition_checks.gd.uid`
- `tests/expedition_experiment.gd`
- `tests/expedition_experiment.gd.uid`
- `tests/expedition_ui_check.gd`
- `tests/expedition_ui_check.gd.uid`
- `tests/financing_checks.gd`
- `tests/financing_checks.gd.uid`
- `tests/financing_experiment.gd`
- `tests/financing_experiment.gd.uid`
- `tests/flexible_contract_checks.gd`
- `tests/flexible_contract_checks.gd.uid`
- `tests/flexible_directed.gd`
- `tests/flexible_directed.gd.uid`
- `tests/flexible_fixture.gd`
- `tests/flexible_fixture.gd.uid`
- `tests/hall_checks.gd`
- `tests/hall_checks.gd.uid`
- `tests/hall_experiment.gd`
- `tests/hall_experiment.gd.uid`
- `tests/hall_ui_check.gd`
- `tests/hall_ui_check.gd.uid`
- `tests/housing_experiment.gd`
- `tests/housing_experiment.gd.uid`
- `tests/kiln_checks.gd`
- `tests/kiln_checks.gd.uid`
- `tests/kiln_experiment.gd`
- `tests/kiln_experiment.gd.uid`
- `tests/mapped_town_checks.gd`
- `tests/mapped_town_checks.gd.uid`
- `tests/mapped_town_experiment.gd`
- `tests/mapped_town_experiment.gd.uid`
- `tests/marketplace_experiment.gd`
- `tests/marketplace_experiment.gd.uid`
- `tests/planner_equivalence.gd`
- `tests/planner_equivalence.gd.uid`
- `tests/priority_checks.gd`
- `tests/priority_checks.gd.uid`
- `tests/priority_competition.gd`
- `tests/priority_competition.gd.uid`
- `tests/priority_experiment.gd`
- `tests/priority_experiment.gd.uid`
- `tests/priority_value_checks.gd`
- `tests/priority_value_checks.gd.uid`
- `tests/project_checks.gd`
- `tests/project_checks.gd.uid`
- `tests/project_experiment.gd`
- `tests/project_experiment.gd.uid`
- `tests/recovered_ui_checks.gd`
- `tests/recovered_ui_checks.gd.uid`
- `tests/replay.gd`
- `tests/replay.gd.uid`
- `tests/reservation_experiment.gd`
- `tests/reservation_experiment.gd.uid`
- `tests/retry_checks.gd`
- `tests/retry_checks.gd.uid`
- `tests/retry_experiment.gd`
- `tests/retry_experiment.gd.uid`
- `tests/retry_inspect.gd`
- `tests/retry_inspect.gd.uid`
- `tests/reverify_expeditions.gd`
- `tests/reverify_expeditions.gd.uid`
- `tests/run_tests.gd`
- `tests/run_tests.gd.uid`
- `tests/stockade_checks.gd`
- `tests/stockade_checks.gd.uid`
- `tests/stockade_experiment.gd`
- `tests/stockade_experiment.gd.uid`
- `tests/stockade_ui_check.gd`
- `tests/stockade_ui_check.gd.uid`
- `tests/trade_checks.gd`
- `tests/trade_checks.gd.uid`
- `tests/trade_experiment.gd`
- `tests/trade_experiment.gd.uid`

### Tools

- `tools/inspect_run.py`
- `tools/make_expedition_report.py`
- `tools/make_financing_report.py`
- `tools/reconstruct_planner.py`
- `tools/render_town_preview.py`
- `tools/restore_policy_changes.py`
- `tools/run_checks.py`

### Artwork

- `art/PROMPTS.md`
- `art/README.md`
- `art/buildings.png`
- `art/goods.png`
- `art/town_ground.png`

### Documentation and images

- `docs/BRICK_DEMAND_GOLD_AND_INDUSTRY_TEST_010.md`
- `docs/CARAVAN_RETRY_TEST_008.md`
- `docs/COMMITTED_WOOD_AND_KILN_TEST_009.md`
- `docs/COMMONS_EXPERIMENT_003.md`
- `docs/CONFIRMED_ISSUES_AND_QUESTIONS.md`
- `docs/CONFIRMED_Medieval_Town_Design_Synthesis_and_Next_Test.md`
- `docs/CONTRACT_ECONOMY_TESTS_006.md`
- `docs/CURRENT_GAME.md`
- `docs/EVERY_HOUSE_EXPERIMENT_005.md`
- `docs/FILES_AND_DOCUMENTS.md`
- `docs/HOUSE_HALLS_AND_SAWMILL_013.md`
- `docs/HOUSING_EXPERIMENT_001.md`
- `docs/ISSUES_AND_QUESTIONS.md`
- `docs/LAND_EXPEDITIONS_AND_DEVELOPMENT_014.md`
- `docs/MARKETPLACE_EXPERIMENT_004.md`
- `docs/Medieval_Town_Design_Synthesis_and_Next_Test.md`
- `docs/NATIVE_INTERFACE_0_55.md`
- `docs/NEXT_ISSUE_012.md`
- `docs/NEXT_SCENARIO_005.md`
- `docs/PARTIAL_UPGRADES_AND_STONE_CHAPEL_011.md`
- `docs/PLAYER_AI.md`
- `docs/PRIORITY_CONTRACT_TEST_007.md`
- `docs/PROVISIONAL_RULES.md`
- `docs/RECOVERY_0_909.md`
- `docs/RELEASE_0_60.md`
- `docs/RESERVATION_EXPERIMENT_002.md`
- `docs/ROUTE_FINANCING_TEST_015.md`
- `docs/STOCKADE_AND_LAND_TEST_012.md`
- `docs/TEST_REPORT.md`
- `docs/THREAD_HANDOFF.md`
- `docs/UI_SCHEMA_0_50.md`
- `docs/archive/CURRENT_GAME_0_903.md`
- `docs/archive/DECISION_AUDIT_0_903.md`
- `docs/archive/DESIGN_SYNTHESIS_0_903.md`
- `docs/archive/FOUNDATION_DESIGN_2026_10_29.md`
- `docs/archive/PLAYER_AI_0_903.md`
- `docs/images/town_layout_0_909.png`
- `docs/images/v0_60.png`

### Compact experiment evidence

- `experiments/financing/results.json`
- `experiments/financing_directed/results.json`
- `experiments/flexible_checks/results.json`
- `experiments/flexible_directed/results.json`
- `experiments/mapped/results.json`
- `experiments/mapped_checks/results.json`
- `experiments/marketplace/results.json`
- `experiments/planner_equivalence/results.json`
- `experiments/priority_competition/results.json`
- `experiments/priority_value/results.json`
- `experiments/projects/results.json`
- `experiments/recovered_ui/results.json`


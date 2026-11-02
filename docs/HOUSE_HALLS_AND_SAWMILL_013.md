# House Halls and the small sawmill — v0.903, experiment 013

Local development only. No new GitHub upload. The name **House Hall** identifies a permanent seat for the player house. “Manor” suggests a landed estate; “guild headquarters” would imply a professional institution we have not yet established. Business formation, markets controlled by businesses, guild privileges and research systems remain deferred.

## Implemented model and provisional choices

| Item | Rule used in this experiment |
|---|---|
| House Hall | One identity per house; one urban plot; permanent owner-only manufacturing access |
| Hall construction | Three planks, one stone, one pop; additionally consume three influence when starting |
| Hall operation | One chosen unlocked workshop recipe per round, consuming one normal action and the existing recipe inputs |
| Carpentry | Two wood + one pop → one furniture; initially known |
| Brickmaking | One clay + one pop → one brick; becomes known to all houses when the town builds its kiln |
| Future unlocks | Per-house `unlock_recipe(house_id, recipe_id)` validates against the recipe catalogue, is idempotent, and persists in saves |
| Small sawmill | One public forest building; construction costs two wood + one pop |
| Sawmill work | One wood + one pop → two planks, through its ordinary shared production card |
| Plank standing contract | Existing contract mechanism: setup one wood + one pop, commit one labour capacity, consume one public wood for one plank each round; normal title purchases and cancellation rules apply |

These prices, yields and initial knowledge are provisional testing choices. The sawmill is a rural processing building, so its recipe explicitly consumes inputs. It is initially public and may be claimed through normal industry ownership rules. A hall has a dedicated one-per-house identity, consumes urban land, and is exempt from the ordinary three-building ownership count. It does not count as the “own one industry” objective.

Completed halls operate independently of the shared hand. They grant no passive output, guaranteed profit, business status, or prestige merely for existing. Manufacturing still requires a legal input payment plan, including normal paid access to others' goods when necessary. Outputs follow existing supply rules: one token reserved until the owner's next action, then public availability. A hall does not permanently privatise manufactured output.

## Partial construction

Both new building types accept partial physical contributions. The first nonzero contribution reserves the correct plot immediately; a hall also consumes its influence price immediately. Later contributions require its construction card in the shared hand. Each contribution consumes physical tokens, records persistent paid progress, and cycles the card. An unfinished site cannot produce, be claimed as a working industry, or provide hall activity.

A sponsor must finish its existing new site before starting another. The shared sawmill can receive contributions from other houses; a hall is supplied by its own house. On completion the sawmill keeps one production card. A completed hall's construction card disappears and its permanent once-per-round activity becomes available. The plot and influence are not charged a second time.

This implements partial construction for the two new building types. Retrofitting marketplace/kiln partial builds, partial supply establishment, and general full-price forced replacement of unfinished sites remain pending. There is no free cancellation or refund of paid progress.

## Experiment

Twelve sixty-round games: seeds 1, 7, 42 × manual/preset lumber × halls enabled/disabled. The six controls use StockadeAI behaviour; the six enabled games use HallAI. All use automatic town wood collection, partial housing, the stockade and the chapel. End state is the refresh into round 61. This compares the complete feature-and-policy package, not only the isolated effect of extra manufacturing.

| Seed | Lumber | Control: all homes + industries | Halls: all homes + industries | Sawmill round | Completed hall rounds | Hall operations |
|---|---|---:|---:|---:|---|---:|
| 1 | manual | 27 | 24 | 35 | Blue 40, Gold 45 | 6 |
| 1 | linked | 23 | 23 | 30 | Blue 58, Red 56 | 1 |
| 7 | manual | unfinished | unfinished | 50 | Blue 54 | 1 |
| 7 | linked | 23 | 23 | 30 | Gold 43, Red 38 | 5 |
| 42 | manual | unfinished | 41 | 28 | Blue 51, Red 48 | 2 |
| 42 | linked | 32 | 32 | 35 | Gold 44, Red 43 | 2 |

All six enabled towns completed a sawmill. Twelve hall sites started, eleven completed, and one remained unfinished with all three planks and its labour paid but one stone missing. No town found land for a third hall. The completed halls performed seventeen workshop operations; every naturally selected operation was brickmaking. Carpentry and switching between recipes were exercised in fixtures, rather than naturally useful in this scenario.

All household objectives completed in five of six enabled games versus four of six controls by round sixty. This is not evidence that hall output solved housing: the completed-home differences in seeds 1/manual and 42/manual occurred before their first hall was complete. The enabled AI also changes labour production and material retention while planning construction. Keep that policy effect separate from the extra bricks.

## What the system has become

1. **Land investment now has a concrete use and a loser.** The original six urban plots are occupied by the starting assets, marketplace and kiln. Two conversions add room for only two halls. This is actual competition, rather than an assumed universal entitlement to a seat. Decide later whether a third house must buy more development rights, replace a legal site, or remain without a hall.
2. **Timing the sawmill matters.** Starting it on the original vacant forest plot prevents the two vacant-rural conversions needed to unlock the four outer claims. That is legal and passes invariants, but can obstruct expansion until the site is finished and the unowned building is demolished. HallAI therefore waits for an outer-land claim before starting the mill. This is an explicit planning rule, not a hidden legality restriction. No new automatic remedy was added.
3. **Inputs, rather than “business status”, limit hall value.** Seventeen operations across eleven completed halls is modest. The halls compete with the kiln for imported clay and finite labour. Extra capacity does not itself create raw materials or buyers. One should not yet attach a guaranteed prestige income or business privilege to these buildings.
4. **The manufacturing catalogue is narrow.** Carpentry is rarely useful after the clay-import setup, while brick exports and town demand remain useful. A permanent choice of two recipes is implemented, but these runs selected only one. The next meaningful demand might be furniture for civic work or fitting out an institution; it should have a concrete use before being added.
5. **Demand forecasting is imperfect.** Every enabled town manufactured ten planks. Two hall sites require six. HallAI counts the third house's unrealised hall as demand even after land is exhausted; batch output rounds the nine-plank estimate to ten. A follow-up should count active projects plus projects that can secure plots. The existing generic plank contract is supported and fixture-tested; the AI did not establish it in these runs.
6. **Currency and construction actually compete.** Twelve hall starts consumed thirty-six influence. New physical contributions and social payment are sunk; a house cannot recover them by spending the same tokens elsewhere. The one unfinished hall demonstrates that reserving land and paying most costs does not guarantee completion.

Suggested next test: fix only the AI's feasible plank-demand estimate, then compare the same six enabled towns. After that, give furniture a small explicit public use and observe recipe selection. Do not add a guild/business phase just to make the hall profitable.

## Verification

- All 6,218 decisions passed resource, source, card, reservation, plot, currency and once-per-round invariants; all twelve journals replayed exactly and all twelve saves restored exactly.
- 56 dedicated checks cover partial sites, zero-payment rejection, exact payments, social consumption, source accounting, round limits, private access, per-house unlocks, finite land, early-sawmill obstruction, automation/cancellation, and saves.
- Existing 47 stockade, 31 partial-project and 22 trade checks pass.
- A forty-round live UI game previewed and executed actions and saved/restored exactly. A separate fixture exercised seven construction/production UI commands, including partial hall construction and manufacturing.
- All 83 archived UI states and the existing selection/preview/manual/AI/save checks passed.
- UI minimum measurements after the layout adjustment: 1525 × 1028 for the live game; 1515 × 1028 for the hall fixture and archive check, within 1920 × 1080.

The new resource initially exceeded the old row width during UI testing. The pile now uses compact two-line labels, and construction choices use a scrollable action list. Sawmill and halls have labelled temporary town markers; planks remain text-only. These are mechanics and layout checks, not a claim of finished artwork.

Reproduce with `tests/hall_checks.gd`, `tests/hall_experiment.gd`, `tests/hall_ui_check.gd` and `tests/contract_ui_check.gd`. Compact results are in `experiments/halls/results.json`; full journals are regenerable and excluded from the source ZIP.

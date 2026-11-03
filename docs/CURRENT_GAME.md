# Medieval Town — current game inventory

Updated 3 November 2026. Executable baseline **v0.909, save schema 18**, published code commit `30514b0228bafc34aa37aaa8d8027db6c207fdb9`. This review changes documentation only. Prices, yields, thresholds and scenario restrictions below are provisional balance values. Design intentions beyond the executable rules are in [the design register](Medieval_Town_Design_Synthesis_and_Next_Test.md); actual policy is in [Player AI](PLAYER_AI.md).

## Purpose and starting town

Three noble/merchant houses—Blue, Red and Gold—develop within one town. The intended appeal is planning what a house can become, arranging dependencies and making consequential choices before rivals take opportunities. Reward frequency and universal AI success are not substitutes for that experience. The designer has not yet substantially evaluated the current playing screen; automated results do not establish human satisfaction.

Each house begins with no property, stored goods, influence, prestige or gold. A store holds three physical tokens in total. Ordinary ownership allows three buildings; each house has a separate unique House Hall allowance, still requiring an urban plot. An industry is an owned built rural/workshop asset; a Hall does not substitute for it. The AI's explicit sequence is owned brick home → owned industry → Hall → remaining opportunities. These milestones are not a final victory condition. Test round limits are not game-ending rules.

The clayless valley begins with five wood, six grain, six urban plots, two forest and two field plots. Three huts and a carpenter occupy four urban plots; the lumber camp and grain farm occupy two rural plots. Two urban and two rural plots are free. The unownable chapel has a separate special site. Marketplace and kiln can fill the two initially vacant urban sites, creating genuine later land pressure.

## Rounds, turns and availability

A round refresh processes automatic supplies and scheduled caravan trade, reveals a shared four-card hand and rotates the starting house. Ordinary manual building activation requires its card in hand, pays inputs, produces goods and discards the card; one manual activation per building per round. Ordinary property claims normally need the card too; automated assets have a separate claim path. Construction/upgrade contributions have their own card-cycling rules. A completed Hall permits one owner-only known workshop action each round, independent of the deck.

Houses alternate normal actions. A pass does not withdraw a house permanently. Three consecutive passes end a round; a non-pass resets that chain. Unused cards enter discard; hand drawing occurs at the next round start, reshuffling discard when necessary. Actions do not refill the hand. The marketplace schedules its first caravan for the following round, then every three rounds. A visit's shared offers remain available during that round.

An ordinary activation of a rival's building costs one influence paid to its owner and retains the acting house's normal turn. Buying access to rival ingredients alone does not make an action free. Reservations expire at their holder's next action, including a pass or that paid activation. Expedition travel is the exception to round-based arrivals: its clock advances on normal town actions; see below.

## Goods, labour and rights

| Physical good | Current roles |
|---|---|
| Wood | Construction, furniture, planks, public works, contract setup/backing/upkeep |
| Grain | Labour production, supply setup/upkeep, expedition provisions |
| Clay | Kiln/Hall brickmaking, legacy or expedition imports |
| Brick | Home improvement, town influence demand, caravan gold order |
| Furniture/chest | Carpenter/Hall product; legacy clay-link setup |
| Minor luxury | Improved-home labour recipe; contract/import/export good |
| Labour (`pop`) | Work input, manufacture capacity, contract commitments, expedition crew |
| Stone | Chapel/Hall construction and rural redevelopment; caravan/expedition import |
| Planks | Sawmill output and Hall construction |

Influence, prestige and gold are separately accounted currencies, outside the three-token store.

| Location/right | Effect |
|---|---|
| Public supply | Available for immediate inputs and eligible collection |
| Own reserved output | One temporarily preferred token from a production/delivery batch |
| Rival reservation | Immediate input use costs one influence per unit to holder |
| Private store | Protected physical stock; rival immediate input use costs two influence per unit |
| Contract backing/crew | Held commitment, unavailable for ordinary input payment |
| Paid project progress | Already consumed, persistent progress; no longer a physical good |
| Incoming finite cargo | Unavailable until its expedition actually returns |

Output beyond the single reserved token is public. Paid access requires an existing token and sufficient influence; it permits immediate use, not moving a rival's bought-through goods into one's own store. There is currently no emergency-proof prerequisite for this legal access. Receipts above the influence cap are lost.

Labour has six total capacity slots. Physical labour, committed labour and unissued capacity account for that pool. Ordinary work consumes a physical token and frees capacity for later housing production. A standing commitment retains capacity. A travelling expedition instead holds a real crew token until return. Neither land expansion nor a Hall increases the labour cap. These tokens are not individually housed residents.

## Buildings and recipes

| Asset | Inputs → outputs | Construction/improvement |
|---|---|---|
| Lumber camp | None → 1 wood; enhanced: 1 labour → 2 wood | Forest gathering; basic mode retained |
| Grain farm | None → 1 grain; enhanced: 1 labour → 2 grain | Field gathering; basic mode retained |
| Hut / brick home | 1 grain → 1 labour; improved mode: 1 grain + 1 luxury → 2 labour | Upgrade: 2 wood + 1 brick + 1 labour; needs free labour capacity |
| Carpenter | 2 wood + 1 labour → 1 furniture | Existing urban workshop |
| Kiln | 1 clay + 1 labour → 1 brick | 2 wood + 1 labour, urban; upgrade disabled here |
| Small sawmill | 1 wood + 1 labour → 2 planks | 2 wood + 1 labour, forest; upgrade disabled here |
| Chapel | None → 2 influence; upgraded output exactly 3 influence | 2 stone + 1 wood + 1 labour; special and unownable |
| Marketplace | Passive gateway to scheduled caravans | 3 wood + 1 labour, urban |
| House Hall | One chosen known workshop recipe per round, paying its usual inputs | 3 planks + 1 stone + 1 labour, urban; separate 3-influence site claim |

Chapel access is limited to houses tied for fewest upgraded homes, a provisional catch-up metric. Halls initially know furniture manufacture; building a kiln unlocks brickmaking globally and permanently. Recipe knowledge is not free input supply. Halls grant one land transport capacity each but are still pre-business headquarters, not businesses or guilds. The live catalogue does not expose arbitrary extra huts or duplicate workshops.

## Social currencies and money

| Action | Current cost/reward |
|---|---|
| Claim ordinary public property | Consume 3 influence |
| Claim a new public construction site | Consume 1 influence; material contribution is a later action |
| Claim own Hall site | Consume 3 influence; material contribution is a later action |
| Eligible first idle pass | +1 influence once that round if the house has done no work yet; later re-entry allowed |
| Bulk surplus exchange | Consume 3 stored physical tokens → 3 influence, fixed goods-order selection |
| Voluntary conversion | 5 influence → 1 prestige, one way |
| Milestones | Marketplace +2 prestige; legacy clay setup +3; completed brick home +5 |
| Town brick demand | 1 brick → 2 influence, currently unlimited testing demand |
| Active stockade delivery | 1 wood → 1 influence while wall needs wood |
| Outer rural claim for town | 1 labour → 1 prestige, at most four |
| Caravan | One shared brick export order → 1 gold per visit; stone costs 1 gold (2 available); prestige costs 2 gold |

Influence cap is ten. Property/priority/development purchases consume social currencies; access fees transfer them. Prestige also pays cancellation, buyout and clearing costs. Gold belongs to houses; no domestic cash market or town treasury exists. The current caravan does not sell bricks; an inherited `bricks_left` field is not an enabled action.

## Local supplies and legacy clay link

Owning a building, establishing its automated supply, and owning recurring output priority are distinct. Generic setup consumes materials; buying its title consumes prestige and influence. Sources must exist and source ownership restricts who can establish them. Upkeep uses public inputs; failure to find them causes missed delivery. The local catalogue currently permits only one contract per resource type. Quantity-based independent bindings remain an implementation gap.

| Supply | Setup consumed | Held capacity/backing | Public upkeep | Delivery |
|---|---|---|---|---|
| Wood | 1 wood + 1 labour | 1 labour capacity | None | Round refresh |
| Grain | 1 wood + 1 labour | 1 labour capacity | None | Round refresh |
| Furniture | 2 wood + 1 labour | 1 labour capacity | 1 wood | Round refresh |
| Labour from owned hut | 1 grain + 1 wood | None | 1 grain + free labour capacity | Round refresh |
| Luxury | 2 wood + 1 labour | 1 labour capacity | 2 wood | Caravan visit |
| Planks | 1 wood + 1 labour | 1 labour capacity | 1 wood | Round refresh |
| Legacy clay import | 1 furniture/chest | 1 wood backing + 1 labour capacity | No recurring wood expenditure | Immediately, then caravan visits |

Clay backing is permanently unavailable for interim use while that link exists. Cancellation releases backing and capacity; it does not refund the setup chest. This supersedes the old recurring-wood implementation and the discussed alternative of interim use. Preset-lumber test variants start with an automatic lumber source and committed capacity; normal manual starts do not.

Local titles begin at 3 prestige plus 2 influence. Each purchase raises the next prestige price by two. The creator gets first scheduled delivery priority; later deliveries use the title holder if any. Priority covers one output until the next holder action. Creator withdrawal of an unowned local contract costs 0 prestige; current title-holder withdrawal costs 1; hostile cancellation retains the elevated formula, max(current title price + 3, underlying cancellation base + 4). A preset link with unknown creator does not imply free withdrawal for anyone.

Automating a source removes ordinary base manual operation. Where a source upgrade is enabled, base automation continues and the returning card consumes only incremental inputs for incremental outputs. This is not universal permission to upgrade every asset. Partial service establishment is absent. Direct local stone/brick standing contracts remain absent; expeditions can supply those goods, so the older statement that they have no standing external route is obsolete.

## Projects, clearing and town land

Home/chapel upgrades accept partial inputs and keep their old function until complete. Marketplace, kiln, sawmill and Hall construction use separate social claim/clear and material-supply actions. A new incomplete site reserves its plot, has no completed function and is protected against further overbuilding. A sponsor must finish its unfinished site before starting another. Contributions consume tokens into progress; contributing a labour token makes its manufacture capacity available again. Public-site assistance and contribution-card circulation follow the executable legal actions.

Eligible completed **unowned**, nonspecial buildings can be cleared. Base cost is 1 prestige for rural and 3 for urban, plus dependent-contract cancellation costs. A force-replacement claim pays that bill and its social claim, reserves the replacement site, then requires full replacement materials on later actions. Old invested materials are not refunded. Existing private property, special sites and ongoing sites are protected. Completed-site bookkeeping is retired on clearance; the old sawmill-demolition defect has been fixed. This is a finite supported-building catalogue, not an arbitrary city editor.

The stockade needs six wood. At round closure the town takes unused unreserved public wood for its remaining wall requirement, then the chapel's missing wood. It does not seize stores, active reservations, backing or progress, and automatic use pays no house reward. This limited task routine is the current town agency.

After the wall, two rural plots may become urban for 1 stone + 1 labour each. Eligible occupied rural conversion also pays clearing and dependent-contract costs. Both conversions unlock four outer rural claims, each costing 1 labour and awarding 1 prestige. Woodland biome claims roll 65% forest / 35% field; no fixed two-and-two guarantee. Aggregate economic capacity becomes urban 8 / rural 6 after all expansion. Cutting woods, draining swamps and additional biome tables are future ideas.

## Expeditions and external routes

A completed Hall supplies one land transport capacity. Launch uses 1 grain and holds a real 1-labour crew token. Outbound travel takes six future normal town actions; paid activations retaining the normal turn do not advance it. Arrival offers two semi-random known non-labour goods to buy/contract and two different goods to sell. Each finite offer has two units. The sponsor can return early; the trading window otherwise counts six sponsor normal actions. Return travel takes six future normal town actions.

Finite purchases spend gold and become cargo, then enter sponsor storage if space exists or public supply upon actual return. Imported physical tokens do not renew themselves. Sales consume legally accessible goods from public/reserved/private sources with normal access fees. Buy prices: wood/grain/clay/stone/planks 1 gold; brick/furniture/luxury 2. Sell offers pay 1 gold per unit.

A standing external route consumes setup gold equal to its unit price plus 1 prestige and retains one transport capacity after crew return. Public output is the default inexpensive option; priority adds 2 influence. Thereafter the payer spends the unit gold price for one output per round, beginning after the expedition returns. No cash means a missed delivery, not free import. One route per trip; separate expeditions may establish independent routes for the same resource.

Public sponsor withdrawal is a normal action costing 0 prestige; priority sponsor withdrawal costs 1. Later sponsor purchase of priority costs 2 influence and affects future deliveries only. Hostile buyout starts at 5 prestige plus 2 influence, rises by two prestige per purchase, and requires returned crew/available replacement transport. Hostile cancellation costs displayed route price + 3 prestige. No transaction teleports crew or cargo. Route `owner` fields identify the paying sponsor even for public output.

A useful clay route can earn the town's one-time 3-prestige expedition reward only after the first actual paid delivery. Signing and cancelling does not earn it. The AI does not treat the possible reward or contested caravan export income as guaranteed startup funding.

## Playing screen and saved town

Godot 4.5.1 standard or newer; import `project.godot`, run F5. F11 toggles fullscreen. This is source, not a packaged native executable. Main workspaces: Town / Goods / Cards. Sidebar: Houses / Buildings. Detail areas: Inspect / Trade / Plans / Log. Select, preview the legal action and Execute. AI stepping/batches and detailed technical records remain in the laboratory.

Goods use individual unit pictures, grouped by public/reserved/private access; numeric counts are exact. Above twelve pictures an explicit overflow count appears. Incoming cargo remains in Trade until usable. Fixed map addresses: U1–U6 urban, F1–F2 forest, D1–D2 field, S1 special chapel, N1–N4 outer wilderness: fifteen positions in a 5×3 scaffold. Terrain/occupancy change in place and are saved. Initially ten economic sites plus chapel are active; outer nature is not free extra land. Placement selects an eligible address automatically; clicking a vacant plot does not implement manual placement or adjacency.

Vegetation clears with site development; roads are atmospheric. One gentle effect per completed building: window, saw, banner or smoke. Timing is cosmetic, capped at twelve updates/second, does not consume game RNG, stops on hidden map tabs and can be disabled. Windows vary by building/cycle; smoke puffs comprise one effect. Hall and sawmill reuse provisional house/carpenter art; kiln uses a drawn placeholder. Decorative trees are not counted timber and some vegetation is baked into art. The published town image is a static design study, not a Godot screenshot.

## Verification and limits

Fresh v0.909 evidence: six 80-round mapped towns, 4,793 exactly replayed actions and all 18 Halls completed; six baseline-policy comparisons, 4,806 identical decisions and candidate scores; 302 controlled cargo/bridge actions; twelve paired public/priority trials, 220 actions. Focused checks cover 82 contract assertions, 41 map/motion checks, eight ownership-value checks and 31 recovered UI checks. Archived native UI exercised 83 states; expedition UI exercised 21 commands. See [recovery evidence](RECOVERY_0_909.md) for seeds, exact scope and reproduction.

The priority competition fixtures produced equal home-completion rounds in all six pairs. They deliberately arrange prerequisites to isolate the mechanism and are not organic-strategy evidence. Headless UI checks establish geometry/interaction, not visual quality or satisfaction. Replaying selected decisions does not cover every legal path or prove optimality/balance.

Absent: general quantity bindings and partial service setup; arbitrary building catalogue; specialists/class/training; sea fleets and wider transport; treasury/general town planner; actual research; privileges; businesses/guilds/institutions; final victory; adaptive learning and general future search. See [issues](ISSUES_AND_QUESTIONS.md) and [handoff](THREAD_HANDOFF.md).

## Source authority

`project.godot` → `ui/interface.tscn` → `play_interface.gd` → `live_interface.gd` → `interface.gd`; `ui/live_session.gd` creates `MappedTownSimulation` and `PlannerAI`, batch 3. Current mechanics extend FlexibleContract → Financing → Expedition → Development → Hall → Stockade → Project → Trade → Capacity → Priority → Contract → Marketplace and earlier foundations. Rules JSON alone is not the live ruleset: subclasses override it. Old scripts remain for regression, not as additional active players.

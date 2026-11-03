# Medieval Town — consolidated design ideas

Updated 3 November 2026. **Executable baseline v0.909 / schema 18**; code commit `30514b0228bafc34aa37aaa8d8027db6c207fdb9`. This is the retained design record, not a claim that every idea works. [Current inventory](CURRENT_GAME.md) describes executable details; [AI](PLAYER_AI.md) describes actual reasoning; [decisions](ISSUES_AND_QUESTIONS.md) preserves all twelve answers and open work.

## Intended experience and status

Noble/merchant houses compete and cooperate in a developing town. A house should establish itself, secure dependencies, gain a recognised headquarters and acquire capabilities that let it become more. Rivals may obtain important opportunities first. The town's interests sometimes align with private development and sometimes compete for goods, labour and land.

The designer is the primary intended player. This is a planner's thinking game: recognise possibilities, arrange a smart consequential plan and understand what the house can become. Immediate rewards, rapid prestige, equal progress or universal AI completion are not automatic improvements. Simulations help expose consequences; personal satisfaction and UI/art direction need actual play.

Cards vary current opportunities while physical resources, ownership, supply commitments, projects and land persist. Owning a source, accessing it, using a current token, reserving a future output and knowing a recipe are distinct advantages. A possible arc is operate → secure → commit → specialise → restructure → achieve; this is not a compulsory identical ladder or a settled victory condition.

**Implemented** means executable in this version, with the inventory's restrictions. **Confirmed direction** means an explicit designer instruction, possibly not fully implemented. **Provisional** marks test prices/yields/restrictions and uncertain interpretations. **Deferred** means recorded for later and not permission to invent the missing system now. Replayed actions establish reproducibility, not strategy or enjoyment.

## Original fifteen ideas — preserved with current status

| Original topic | Status and retained direction |
|---|---|
| 1. Passing and re-entry | Implemented: passing skips an opportunity; consecutive passes close the round. An eligible idle house can collect one influence once a round, then re-enter. |
| 2. Paid access | Implemented: one influence for a rival building/reserved input, two for a stored input; transfers buy immediate use of real goods, never consumed progress or permission to hoard a rival token. |
| 3. Building/card availability | Implemented ordinary shared-hand activation once per round, with explicit automated-source, partial-project and owner-only Hall exceptions. Cards are an opportunity system, not the whole persistent economy. |
| 4. Finite labour | Implemented physical pool and commitments; work frees manufacture capacity. Six is a test cap. Individual residents/demographic growth remain future design. |
| 5. Catch-up chapel | Implemented unownable special asset, currently gated by fewest upgraded homes; output two influence, upgraded three. Single-metric eligibility is provisional. |
| 6. Influence/prestige | Implemented capped influence, one-way conversion, social ownership costs, titles, buyouts, cancellation and clearance. A final victory use/general price schedule is unsettled. |
| 7. Contracts | Partly implemented material setup, recurring supply, labour/backing commitments, priority, public external routes and escalating interference. General local quantity bindings, alternative sources and partial establishment remain gaps. |
| 8. Specialists | Deferred. Class and training are separate and may overlap; enable qualitatively different work. Tokens and ongoing supported roles are possible forms. Specialists may still perform basic work if appropriate. |
| 9. Transportation | Partly implemented: Hall grants one land capacity, expeditions travel with crew and routes retain capacity. Land/sea fleets, broader logistics, visitor conditions and other capacity providers remain deferred. |
| 10. Money and foreign trade | Partly implemented: house gold, finite caravan orders, stone/prestige purchases, random expedition deals, finite cargo and funded routes. Treasury, rotating/themed visitors, wider barter/cities and fleets remain future. |
| 11. Research | Deferred apart from globally permanent recipe-unlock hooks. Local development, network knowledge and sophisticated machinery can be different routes; scholars, merchants, squires and professors may contribute differently. |
| 12. Privileges | Deferred: situational rights/rewards, timed/permanent and transferable/restricted as appropriate. Add a concrete privilege for its purpose, not an arbitrary universal catalogue. |
| 13. Institutions | Deferred: business → guild → institution is a possible trajectory. A Hall is a house's seat before its real business phase; prerequisites, obligations and achievements are unsettled. |
| 14. Town agency | Partly implemented standing brick demand, wall, automatic unused public wood use and shared land expansion. Need assessment, reward escalation, treasury and a general town planner remain future. |
| 15. Overbuilding/restructuring | Implemented for supported eligible unowned sites: consequential social clearance/claim followed by full material construction; occupied rural conversion includes loss/cancellation costs. Broad strategic valuation and arbitrary replacement are not complete. |

The early documents' entirely-future transport, money, cancellation and town-action descriptions are superseded. Working Hall/route demonstrations do not imply specialists, technologies, businesses or a complete logistics network.

## Later additions and the decisions they embody

### Earlier foundation brief — ideas retained beyond the fifteen-topic audit

The original `medieval_town_card_game.md` contains broader examples not fully repeated in the fifteen-topic review. Its historical text is preserved in [the foundation archive](archive/FOUNDATION_DESIGN_2026_10_29.md). Later explicit decisions override its then-open timing/access questions; the illustrative content below remains deferred, not a newly authorised content expansion.

| Foundation idea | Retained meaning/status |
|---|---|
| Inspirations | Cultist Simulator's card/table vocabulary, Dominion's cycling, Colonization's concrete goods/chains/trade; inspiration rather than proprietary assets or copied rules |
| Locale profiles | Climate/geography can vary terrain, amenities, deposits, starting resources, trade and advanced routes between sessions; geography within one climate may differ |
| Illustrative locales | Temperate river valley: clay/wicker/reeds/fish/hemp; northern woodland: fur/resin/wax/timber; Mediterranean hills/coast: olives/grapes/aromatics/resins; humid tropical coast: spices/aromatic woods/fibres. None is an implemented guaranteed resource table |
| Illustrative chains | Clay to pottery/bricks/tiles; fur to clothing/luxury; incense/resins to ceremonial prestige; spices to cuisine/medicine/luxury; wicker to baskets/containers/furnishings; hemp to rope/cloth/sails. Give new goods sensible demand and alternatives |
| Terrain/deposit revelation | Finite landscape/development slots can include hills, riverbanks and deposits; exploration may reveal them. Current fixed scaffold does not implement those additional terrain types |
| Ambiguous gathering capacity | The original example of a camp allowing one wood and an improved camp allowing three was deliberately ambiguous about production/storage/available stock. It is not a current wood cap or approved replacement recipe |
| Foreign trade deck | Northern Fur Merchant, Eastern Spice Caravan, Overseas Building Contract and Permanent Maritime Route were examples of rotating opportunities. Current caravan/expedition rules are not a complete separate trade deck |
| Scarcity safeguards | Bad random draws should not make unavoidable deadlock. Possible costly baseline imports, scouting/diplomacy, substitutes and predictable minimum access remain candidate safeguards; none is universally installed |
| Institution examples | College (knowledge/instruments/manuscripts/engineering), church/temple (legitimacy/ceremonial goods/social services), shipyard (ships/transport/exploration), architects' guild (construction/technical service). Exact prerequisites and output systems remain open |
| Institutional dependence | An institution might have fewer ownership slots than its supply chain requires, fostering dependence on rivals, town supply or imports. Evolution need not be a compulsory strict upgrade |
| Broad achievement paths | Scholarship, exploration, population, influence, conquest and commerce are ideas, not implemented victory conditions |
| Population possibilities | Workers, craftspeople, administrators, scholars, clergy and sailors; housing might create residents, consumption, income or prestige. The current six-token work pool does not implement this demographic model |
| Distinctive imperfect AI | Intelligible biases, rigidity, limited foresight, slight variation/inertia and possible memory are design options. Current colour data and deterministic hashing do not implement the whole personality model |
| Evaluation | Track deadlocks, passes, concentration, unused assets, trade, bottlenecks and pacing; later institution timing/diversity and victory distributions only when those systems exist. Batch play is an instrument, not proof of fun |
| Architecture | Godot 4/GDScript, separate simulation from presentation, data-driven content, seeded RNG, saves/replay and a decision diary are retained. Proposed manager/class names in the foundation were architectural suggestions, not the names of actual current classes |

The initial 2–3-house/8–12-building/3–5-resource milestone and suggested two locales were a scope proposal, not a claim that today's prototype includes two playable locale profiles. Proposed building data fields, owner compensation alternatives and local market pricing variants are historical design possibilities; actual current fields/fees are described by source and the inventory.

### Establishment: a good home, industry, headquarters

Confirmed sequence: **good owned brick home → owned industry → House Hall → remaining opportunities/prestige**. Headquarters is the core unique seat of the player house, one per house outside ordinary ownership slots, using urban land. House Hall is a working name, avoiding a premature claim to manor estate, guild or mature business status. A Hall grants one owner-only off-deck known workshop activity per round, paying its real recipe inputs; no free passive output or prestige is implied.

The small sawmill connects wood and labour to planks for Hall investment. Stone imports connect the Hall and chapel to external trade. The chapel upgrade and unlimited brick-to-influence demand were deliberately introduced as testing sinks and previews of future dependencies. They do not settle the final economy. An industry is not automatically a developed business merely because a house owns it.

### Physical goods and meaningful commitments

Goods should be legible individual physical objects as well as exact counts—a stylistic and planning aid inspired by the designer's old Venice/Prince game recollection. Do not treat that recollection as a verified exact title/reference asset. Reserved supply, private caches, export backing, held crew and consumed progress are economically distinct, and UI should reveal the distinction.

Idle houses can collect varied surplus goods and bulk-exchange three for three influence, then collect prestige. Current selection is deterministic/fixed-order in important places; a fully human-chosen three-good bundle is not yet implemented. Initial social policy should not simply buy everything outright. Acquiring property and priority must consume social currencies and create a reason to replenish them.

A produced batch offers one temporarily preferred output on the holder's next action; take it then or let priority expire. It is not permanent exclusion of the batch. Immediate rival use can pay social access costs. Existing law does not require a last-resort proof before buying through a stored token; expensive destructive/hostile interference has a stronger intended last-ditch strategic justification.

### Contract establishment, title and quantity

Confirmed direction: any physical resource can in principle support a justified contract with appropriate tested prerequisites. Current local services are a restricted catalogue; expedition imports broaden the goods available. Material setup, recurring input/capacity obligations, building ownership and socially purchased priority are different transactions. Priority has an increasing buyout price. Upgrading an automated source retains base supply and returns a card only for extra inputs/outputs.

Q09 requires meaningful **quantities** of supply to be bindable. Three available grain outputs should not become one undifferentiated monopoly title. A binding must respect enabled production chains and theoretical access to upstream inputs. The example of two grain becoming two-or-more bread illustrates processing, not an instruction to add bread now. One local contract per resource is a current limitation, not the desired final rule. Independent same-good expedition routes are only a partial precedent.

Partial supplies/service setup are intended generally but still absent. Exotic arrangements that help establish a future business were discussed as possible later options needing balance/design justification, not unrestricted current exceptions.

### Clay backing and the caravan

The legacy clay link consumes a chest at setup, holds one wood and one labour capacity, then supplies clay immediately and on visits without repeatedly consuming wood. Held wood is unavailable for interim use; cancellation releases backing/capacity. This is the current variant. The thread considered permanent reservation versus interim single-use access when the caravan was absent; do not combine those alternatives or restore recurring public-wood upkeep by accident.

Caravan visits remain round-based and finite: one shared brick-for-gold order, stone for gold and prestige for gold instead of selling bricks in this test. That is distinct from expeditions with their own action-based outbound/return clock and semi-random deals. A missed local recurring input or insufficient external route gold must matter; a contract is not a magical resource generator.

### Finite imports versus a committed investment

Halls grant one land transport capacity. A manned expedition uses provisions, real held crew and time; on arrival the sponsor gets two buy/contract and two sell offers among known goods. Purchased finite goods only become usable on return, going to own store if space permits or public supply otherwise. Sales may use any legally accessible existing goods. Contracts retain transport and ongoing gold obligations after crew returns.

The later revision distinguishes cheap-to-cancel **public supply** from socially purchased priority. Public output still has a sponsor, transport and operating cost. Local ownership consumes prestige plus influence; external public setup consumes prestige and setup gold, priority adds influence. Owner withdrawal should be inexpensive compared with hostile cancellation; overbuying is possible at rising prices. Ownership affects future priority, not public goods already delivered. The initial idea of automatic owned expedition contracts was superseded by this deliberate public/priority choice.

Useful clay imports can receive a town reward, but only on a real paid delivery. Funding cannot count a reward before it occurs or assume a contested export order guarantees income. A temporary bridge needs a bounded budget and exit; small needs can be finite cargo. Current short home fixtures favour public access. A standing investment should gain value from a real repeated plan rather than from artificially forbidding all alternatives.

### Partial work and restructuring

Social clearing/claiming and physical building are separate actions. Paid material contributions consume goods into lasting progress; incomplete construction reserves land but has no completed function. Partial upgrades keep the old function. Ongoing sites are protected against further overbuilding. This later clarification supersedes the earlier tentative exception permitting unfinished sites to be displaced at full price.

Otherwise legal occupied rural plots can become urban; count clearing, cancellation, conversion and lost-function costs. An empty fresh unowned plot is usually best. Combined cancellation during clearance is the explicitly **highly provisional** Q02 choice, to be judged when encountered in consequential tests. Full-price replacement pays the new building's complete materials after social clearance; old progress is not refunded. Private/special/ongoing protection is not waived.

AI direction: pursue a real visible theoretical way out, allowing plausible random supply; if none is deducible, prepare brute force. It must distinguish credible routes from indefinite vague hope. The current bounded route heuristics are not proof that every legal alternative has been searched. The old two-Hall land ceiling and sawmill bookkeeping defect are not current design restrictions.

### Town, biome and appearance

Stockade investment rewards active wood delivery and allows two costly rural-to-urban redevelopments, then four outer rural claims rewarding one prestige each. The town may consume unused unreserved public wood at round end for known tasks. It does not seize all private plans or own a general treasury. Land claims use town-biome probabilities; current woodland is 65% forest/35% field, not an assured two-and-two package. Later cutting woods, draining swamps and terrain transformation need their own costs and consequences.

The first visual scaffold keeps possible plot addresses/positions while terrain and occupants change. Reclaiming nature removes foreground vegetation; decorative roads and a single slow building animation create atmosphere. Current saved map has fifteen fixed positions and no adjacency, pathfinding, travel distance or timber-per-tree economy. Tabbed workspaces reduce information overload. One effect per building, reduced-motion control and a cosmetic clock protect readability and deterministic simulation. Dedicated Hall/sawmill art and human evaluation remain pending; the static map study is not a screenshot.

### Knowledge, specialists and future institutions

All unlocks are **global and permanent for everyone**. Later research might force a choice about helping rivals with an advance unnecessary to one's own win; retain that idea for later, not as an immediate denial mechanic. Recipe hooks are not yet technology research. Local invention, access to wider networks and acquiring advanced machinery are distinct ways to expand plans.

Class and training can overlap; specialists should open qualitative possibilities rather than merely multiply output. Their support and alternate uses should create opportunity costs. Businesses, guilds and institutions might require capabilities, supplies, clientele, status, commitments and achievements; no exact prerequisites are settled. Privileges should serve specific ambitions. The final win condition and mature-house progression remain open.

## Contradictions reconciled and gaps retained

| Apparent contradiction | Resolution |
|---|---|
| Old no-prestige-spending/no-gold/no-town-action text | Historical only; current inventory describes expenditure, trade and limited town tasks |
| Hall optional in prestige phase | Superseded by explicit home → industry → Hall goal |
| Two free urban plots imply only two possible Halls | Not intended; paid restructuring/conversion enables alternatives |
| Demolished sawmill remains completed | Then-real bookkeeping defect fixed in current code, retained in historical evidence |
| Old atomic market/kiln versus universal partial-work wish | Current builds now use staged/partial sites; partial service establishment still missing |
| Fixed outer terrain versus biome roll | Fixed split superseded; transformation remains future |
| Per-house unlock array versus everyone forever | Existing hooks propagate globally/permanently; future tech must preserve that rule |
| General quantity contracts versus one local contract/resource | Genuine implementation gap; do not declare it resolved by unrelated imports |
| Finite cargo versus reusable supply | Finite tokens arrive once; standing routes require recurring payment/capacity |
| Priority contract versus public option | Later explicit access choice supersedes automatic ownership; sponsor and priority holder are distinct concepts |
| Protected ongoing work versus older full-price unfinished overbuild | Later protection answer wins |
| AI consolidation versus strategic intelligence | One inspectable pipeline is implemented; many rules remain narrow heuristics |

## Next discussion and experiment

Read the [decision register](ISSUES_AND_QUESTIONS.md) before asking for more rules. All twelve audit answers are settled as recorded, including Q02 uncertainty. Obtain actual UI feedback, then isolate a repeated private supply need to test when priority is worth its social/exit costs. Quantity bindings are a separate confirmed-direction feature candidate. Preserve the six-test/comment/remark/suggestion rhythm; use matched cases and explicit limits, not perpetual unattended simulation claims. Do not add business, tech, terrain and new demand together merely to increase complexity.

The original unpublished v0.906–v0.908 files were lost; v0.909 reconstructs them from preserved source and the thread. [Recovery report](RECOVERY_0_909.md) records fresh evidence. Original v0.903 references are archived, not erased or silently relabelled as current tests.

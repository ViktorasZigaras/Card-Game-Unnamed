extends SceneTree
var checks = 0
var failures: Array = []
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func fresh() -> StockadeSimulation:
	var s = StockadeSimulation.new()
	s.batch = 3
	s.start(7)
	return s
func act(s: StockadeSimulation,a: Dictionary) -> Dictionary:
	s.state.actor = 0
	return s.apply(a)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var s = fresh()
	s._add_lot("wood",12,"","fixture",0)
	s._add_lot("stone",2,"","fixture",0)
	s.state.project_metrics.stone_bought += 2
	s._add_lot("pop",10,"","fixture",0)
	check({"type":"redevelop_rural","terrain":"forest"} not in s.legal_actions(),"wall gates conversion")
	check({"type":"claim_rural","terrain":"forest"} not in s.legal_actions(),"wall gates outer claims")
	var before = s.house("blue").inventory.influence
	var consumed = s.state.ledger.wood.consumed
	check(act(s,{"type":"supply_wood"}).ok,"voluntary delivery legal")
	check(s.house("blue").inventory.influence == before+1,"delivery pays one influence")
	check(s.state.ledger.wood.consumed == consumed+1 and s.state.town.wall_wood == 1,"delivery consumes physical wood into wall")
	check(s.state.town.automatic_wood == 0,"no sweep during ordinary action")
	for i in range(5): act(s,{"type":"supply_wood"})
	check(s.state.town.wall_complete and s.state.town.wall_wood == 6,"six wood finishes wall")
	check({"type":"supply_wood"} not in s.legal_actions(),"completed wall refuses excess delivery")
	check(s.effective_capacity("urban") == 6 and s.effective_capacity("forest") == 2,"special wall uses no ordinary plot")
	check({"type":"claim_rural","terrain":"forest"} not in s.legal_actions(),"claims wait for two conversions")
	var free_urban = s.state.terrain_free.urban
	check(act(s,{"type":"redevelop_rural","terrain":"forest"}).ok,"vacant forest converts")
	check(s.state.terrain_free.urban == free_urban+1 and s.state.terrain_free.forest == 0,"conversion transfers vacant capacity")
	check(s.state.ledger.stone.consumed == 1,"conversion consumes stone")
	check({"type":"redevelop_rural","terrain":"forest"} not in s.legal_actions(),"occupied forest cannot convert")
	check(act(s,{"type":"redevelop_rural","terrain":"field"}).ok,"second vacant rural plot converts")
	check(s.conversion_count() == 2 and s.effective_capacity("urban") == 8,"two urban plots unlocked")
	check(s.effective_capacity("urban")+s.effective_capacity("forest")+s.effective_capacity("field") == 10,"conversion preserves total plot budget")
	check(not s.legal_actions().any(func(a): return a.type == "redevelop_rural"),"two conversion limit")
	var prestige = s.house("blue").inventory.prestige
	var pop_consumed = s.state.ledger.pop.consumed
	for terrain in ["forest","forest","field","field"]:
		check(act(s,{"type":"claim_rural","terrain":terrain}).ok,"claim outer "+terrain)
	check(s.house("blue").inventory.prestige == prestige+4,"one prestige per claimed plot")
	check(s.state.ledger.pop.consumed == pop_consumed+4,"claims consume four labour tokens")
	check(s.claim_count() == 4 and s.effective_capacity("forest") == 3 and s.effective_capacity("field") == 3,"four shared rural plots added")
	check(not s.legal_actions().any(func(a): return a.type == "claim_rural"),"finite four claims, no prestige loop")
	s._add_lot("pop",2,"","construction_fixture",0)
	var urban_before_builds = s.state.terrain_free.urban
	check(act(s,{"type":"build_market"}).ok and act(s,{"type":"build_kiln"}).ok,"ordinary urban construction works after expansion")
	check(s.state.terrain_free.urban == urban_before_builds-2,"ordinary buildings consume expanded urban budget")
	check(s.violations().is_empty(),"expanded plot and resource invariants")
	var clone = StockadeSimulation.new()
	clone.restore(JSON.parse_string(JSON.stringify(s.snapshot())))
	check(TownSimulation.canonical(s.snapshot()) == TownSimulation.canonical(clone.snapshot()) and clone.violations().is_empty(),"expanded land save/load exact")
	s = fresh()
	s._add_lot("wood",12,"","fixture",0)
	act(s,{"type":"take","resource":"wood"})
	s._add_lot("wood",1,"blue","fixture_reserved",100)
	var protected = s.house("blue").stockpile.wood
	var reserved_id = s.state.lots[-1].id
	var public_before = s.public_plan({"wood":1}).ok
	var influence_before: Array = []
	for h in s.state.houses: influence_before.append(h.inventory.influence)
	var wood_before = s.total_physical("wood")
	s._close_round()
	check(public_before and s.state.town.wall_complete and s.state.town.automatic_wood == 6,"end round collects required public wood")
	check(s.state.town.chapel_automatic_wood == 1 and s.progress("chapel").paid.wood == 1,"surplus supplies known chapel task")
	check(s.total_physical("wood") == wood_before-7,"wood beyond wall and chapel need persists")
	check(s.house("blue").stockpile.wood == protected,"protected stockpile untouched")
	check(s.state.lots.any(func(lot): return lot.id == reserved_id and lot.amount == 1),"active reservation untouched")
	var influence_after: Array = []
	for h in s.state.houses: influence_after.append(h.inventory.influence)
	check(influence_after == influence_before,"town sweep awards no house influence")
	check(s.state.history[-1].consequences.any(func(e): return e.type == "town_end_round"),"automatic collection recorded in journal")
	wood_before = s.total_physical("wood")
	s._close_round()
	check(s.total_physical("wood") == wood_before,"no endless sweep after tasks supplied")
	check(s.state.buildings.chapel.level == 1,"automatic partial wood does not prematurely upgrade chapel")
	check(s.violations().is_empty(),"automatic collection conservation and partial project invariants")
	s = fresh()
	s.rules.town_wood_sweep = false
	s._add_lot("wood",12,"","fixture",0)
	s._close_round()
	check(s.state.town.wall_wood == 0,"voluntary-only control disables sweep")
	s = fresh()
	s.rules.town_wood_sweep = false
	s._add_lot("wood",15,"","fixture",0)
	s._add_lot("pop",5,"","fixture",0)
	s._add_lot("furniture",1,"","fixture",0)
	check(act(s,{"type":"build_market"}).ok,"market setup for export fixture")
	s._close_round()
	check(act(s,{"type":"secure_clay_contract"}).ok,"clay export commitment setup")
	s.state.buildings.hut_1.owner = "blue"
	for pile in [s.state.deck,s.state.discard,s.state.revealed]:
		while "hut_1" in pile: pile.erase("hut_1")
	s.state.revealed.append("hut_1")
	check(act(s,{"type":"contribute_upgrade","building":"hut_1","bundle":{"wood":2}}).ok,"home wood committed to progress")
	s.rules.town_wood_sweep = true
	s._close_round()
	check(s.state.capacity.wood == 1,"town cannot sweep export-backing wood")
	check(s.progress("hut_1").paid.wood == 2,"town cannot sweep consumed house project progress")
	check(s.violations().is_empty(),"committed wood and project conservation after sweep")
	print(JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

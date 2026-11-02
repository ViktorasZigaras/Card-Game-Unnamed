extends SceneTree
var checks = 0
var failures: Array = []
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func fresh() -> HallSimulation:
	var s = HallSimulation.new()
	s.batch = 3
	s.start(7)
	return s
func act(s: HallSimulation,a: Dictionary) -> Dictionary:
	s.state.actor = 0
	return s.apply(a)
func expose(s: HallSimulation,id: String) -> void:
	for pile in [s.state.deck,s.state.discard,s.state.revealed]:
		while id in pile: pile.erase(id)
	s.state.revealed.append(id)
func run() -> void:
	var s = fresh()
	check(s.violations().is_empty(),"initial model invariants")
	check(s._owns("blue") == 0,"unbuilt hall does not occupy ordinary ownership slot")
	check(s.state.houseworks.unlocked.blue == ["furniture"],"only carpentry initially known")
	check(not s.unlock_recipe("blue","unknown_recipe"),"cannot unlock undefined recipe")
	var free_forest = s.state.terrain_free.forest
	check(not act(s,{"type":"start_site","building":"small_sawmill","bundle":{}}).ok and s.state.terrain_free.forest == free_forest,"zero contribution cannot reserve land")
	check(act(s,{"type":"start_site","building":"small_sawmill","bundle":{"wood":1}}).ok,"nonzero partial sawmill start")
	check(s.state.terrain_free.forest == free_forest-1 and not s.state.buildings.small_sawmill.built,"partial site reserves forest, not functional")
	check(s.site_remaining("small_sawmill") == {"wood":1,"pop":1},"paid token consumed once")
	expose(s,"small_sawmill")
	check(not s.legal_actions().any(func(a): return a.type == "activate" and a.building == "small_sawmill"),"unfinished site cannot produce")
	check(not s.legal_actions().any(func(a): return a.type == "claim" and a.building == "small_sawmill"),"unfinished site cannot be claimed")
	check(not s.legal_actions().any(func(a): return a.type == "start_site" and a.building == "hall_blue"),"finish own existing project before starting another")
	s._add_lot("pop",2,"","fixture",0)
	var consumed = s.state.ledger.wood.consumed
	check(act(s,{"type":"supply_site","building":"small_sawmill","bundle":{"wood":1.0,"pop":1.0}}).ok,"saved numeric bundle normalised")
	check(s.state.buildings.small_sawmill.built and s.state.ledger.wood.consumed == consumed+1,"completion consumes only missing wood")
	check((s.state.deck+s.state.discard+s.state.revealed).count("small_sawmill") == 1,"sawmill has one production card")
	expose(s,"small_sawmill")
	check(act(s,{"type":"activate","building":"small_sawmill","mode":"basic"}).ok,"sawmill manufactures planks")
	check(s.state.ledger.planks.created == 2 and s.total_physical("planks") == 2,"one wood and labour yield two planks")
	check(s.state.lots.any(func(lot): return lot.resource == "planks" and lot.reserved_for == "blue" and lot.amount == 1),"one plank reserved for next action")
	check(s.state.houseworks.planks_made == 2 and s.violations().is_empty(),"sawmill resource conservation")
	var hall = "hall_blue"
	check(not s.legal_actions().any(func(a): return a.type == "start_site" and a.building == hall),"hall requires social currency")
	s._gain_influence("blue",3,"fixture",[])
	var urban = s.state.terrain_free.urban
	check(act(s,{"type":"start_site","building":hall,"bundle":{"planks":1}}).ok,"hall start consumes planks and influence")
	check(s.house("blue").inventory.influence == 0 and s.state.houseworks.social_spent == 3,"three influence consumed, not just threshold")
	check(s.state.terrain_free.urban == urban-1 and not s.state.buildings[hall].built,"urban plot held during partial build")
	check(s.total_physical("planks") == 1 and s.state.houseworks.sites[hall].paid.planks == 1,"paid plank leaves supply")
	var clone = HallSimulation.new()
	clone.restore(JSON.parse_string(JSON.stringify(s.snapshot())))
	check(TownSimulation.canonical(s.snapshot()) == TownSimulation.canonical(clone.snapshot()) and clone.violations().is_empty(),"partial site save and plot exact")
	s._add_lot("pop",4,"","fixture",0)
	s._close_round()
	s._add_lot("wood",5,"","fixture",0)
	expose(s,"small_sawmill")
	act(s,{"type":"activate","building":"small_sawmill","mode":"basic"})
	s._add_lot("stone",1,"","fixture",0)
	s.state.project_metrics.stone_bought += 1
	expose(s,hall)
	check(act(s,{"type":"supply_site","building":hall,"bundle":{"planks":2,"stone":1,"pop":1}}).ok,"finish hall with remaining bundle")
	check(s.state.buildings[hall].built and s.state.houseworks.hall_rounds.blue > 0,"completed hall functional")
	check((s.state.deck+s.state.discard+s.state.revealed).count(hall) == 0,"permanent seat independent of shared deck")
	check(s._owns("blue") == 0 and s.industries("blue").is_empty(),"hall is dedicated seat, not ordinary industry or ownership slot")
	check(s.state.terrain_free.urban == urban-1,"completion does not charge plot twice")
	check(s.modes(hall).size() == 1 and s.modes(hall)[0].name == "furniture","hall inspector shows known real recipe")
	s._add_lot("pop",2,"","fixture",0)
	s._add_lot("wood",3,"","fixture",0)
	check(not s.legal_actions().any(func(a): return a.type == "hall_work" and a.recipe == "brick"),"locked brick recipe absent")
	var first_turn = s.house("blue").turns_taken
	var wood_consumed = s.state.ledger.wood.consumed
	var pop_consumed = s.state.ledger.pop.consumed
	check(act(s,{"type":"hall_work","building":hall,"recipe":"furniture"}).ok,"known workshop activity legal without hand card")
	check(s.house("blue").turns_taken == first_turn+1 and s.total_physical("furniture") == 1,"normal action consumes recipe inputs, delivers output")
	check(s.state.ledger.wood.consumed == wood_consumed+2 and s.state.ledger.pop.consumed == pop_consumed+1,"hall carpentry charges exact industry recipe")
	check(not s.legal_actions().any(func(a): return a.type == "hall_work"),"all alternative recipes unavailable after work this round")
	s.state.actor = 1
	check(not s.legal_actions().any(func(a): return a.type == "hall_work" and a.building == hall),"rival cannot operate house seat")
	check(not s.legal_actions().any(func(a): return a.type == "start_site" and a.building == "hall_blue"),"each actor has only its own hall identity")
	check(s.unlock_recipe("blue","brick") and s.unlock_recipe("blue","brick"),"future research unlock hook idempotent")
	check(s.state.houseworks.unlocked.blue.count("brick") == 1,"no duplicate recipe unlock")
	check(s.state.houseworks.unlocked.red == ["furniture"],"per-house research hook does not unlock rivals")
	s.state.actor = 0
	check(not s.legal_actions().any(func(a): return a.type == "hall_work" and a.building == hall),"unlock does not reset round activity limit")
	s._close_round()
	s._add_lot("pop",2,"","fixture",0)
	s._add_lot("clay",1,"","clay_import",0)
	s.state.clay_deliveries += 1
	check(act(s,{"type":"hall_work","building":hall,"recipe":"brick"}).ok,"next round permits different unlocked recipe")
	check(s.state.houseworks.hall_bricks == 1 and s.total_physical("brick") == 1,"hall brick source independently counted")
	check(s.state.houseworks.works.size() == 2,"only one chosen work each of two rounds")
	check(s.total_physical("furniture") == 1,"round refresh grants no passive hall output")
	check(s.violations().is_empty(),"final resources, sites, reservations and recipe invariants")
	clone.restore(JSON.parse_string(JSON.stringify(s.snapshot())))
	check(TownSimulation.canonical(s.snapshot()) == TownSimulation.canonical(clone.snapshot()),"complete hall and unlock save exact")
	s._add_lot("wood",5,"","fixture",0)
	s._add_lot("pop",2,"","fixture",0)
	check(act(s,{"type":"secure_contract","resource":"planks","source":"small_sawmill"}).ok,"new physical resource can have standing supply contract")
	var old_planks = s.total_physical("planks")
	s._close_round()
	check(s.total_physical("planks") == old_planks+1,"plank contract manufactures one reserved token per round")
	check(s.violations().is_empty(),"automated sawmill card and token accounting")
	s._prestige("blue",s.cancel_price("planks"),"fixture",[])
	check(act(s,{"type":"cancel_contract","resource":"planks"}).ok,"plank contract can be cancelled normally")
	check((s.state.deck+s.state.discard+s.state.revealed).count("small_sawmill") == 1 and s.violations().is_empty(),"cancelling returns exactly one completed sawmill card")
	s = fresh()
	s._add_lot("pop",1,"","fixture",0)
	check(act(s,{"type":"build_kiln"}).ok,"town establishes brickmaking workshop")
	check(s.state.houseworks.unlocked.blue.has("brick") and s.state.houseworks.unlocked.red.has("brick"),"existing kiln unlocks known recipe for town houses")
	s = fresh()
	s._add_lot("wood",10,"","fixture",0)
	act(s,{"type":"start_site","building":"small_sawmill","bundle":{"wood":1}})
	for i in range(6): act(s,{"type":"supply_wood"})
	s._add_lot("stone",2,"","fixture",0)
	s.state.project_metrics.stone_bought += 2
	s._add_lot("pop",2,"","fixture",0)
	s.state.actor = 0
	check({"type":"redevelop_rural","terrain":"field"} in s.legal_actions() and {"type":"redevelop_rural","terrain":"forest"} not in s.legal_actions(),"early forest site legally competes with stockade conversion")
	check(s.violations().is_empty(),"blocked expansion is a planning outcome, not bad plot accounting")
	print(JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
func _initialize() -> void: call_deferred("run")

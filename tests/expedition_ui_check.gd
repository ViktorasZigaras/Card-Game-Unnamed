extends SceneTree
var ui
var largest = Vector2.ZERO
var count = 0
func _initialize() -> void: call_deferred("run")
func execute(action: Dictionary,force_blue: bool = true) -> void:
	var s = ui.session.sim
	if force_blue: s.state.actor = 0
	assert(action in s.legal_actions(),"Action not legal: "+str(action))
	var before = TownSimulation.canonical(s.snapshot())
	ui._preview(ui.session.preview(action))
	assert(before == TownSimulation.canonical(s.snapshot()),"Preview mutated simulation")
	ui._execute_pending()
	assert(ui.session.probe.failure == "")
	ui.tab = "Caravan"
	ui._draw()
	await process_frame
	largest = largest.max(ui.root_box.get_minimum_size()+Vector2(32,32))
	assert(largest.x <= 1920 and largest.y <= 1080,"Expedition interface overflow")
	count += 1
func run() -> void:
	root.size = Vector2i(1920,1080)
	ui = load("res://ui/interface.tscn").instantiate()
	root.add_child(ui)
	var s = ui.session.sim
	s.rules.town_wood_sweep = false
	s._gain_influence("blue",3,"fixture",[])
	s._prestige("blue",3,"fixture",[])
	for r in s.tradable_goods():
		s._add_lot(r,4,"","fixture",0)
		if r == "planks": s.state.houseworks.planks_made += 4
		if r == "stone": s.state.project_metrics.stone_bought += 4
		if r == "clay": s.state.clay_deliveries += 4
		if r == "brick": s.state.capacity.kiln_bricks += 4
	s._add_lot("pop",5,"","fixture",0)
	s.house("blue").inventory.gold += 5
	s.state.trade.gold_minted += 5
	await execute({"type":"claim_site","building":"hall_blue","replace":""})
	for pile in [s.state.deck,s.state.discard,s.state.revealed]:
		while "hall_blue" in pile: pile.erase("hall_blue")
	s.state.revealed.append("hall_blue")
	await execute({"type":"supply_site","building":"hall_blue","bundle":s.rules.hall_cost})
	await execute({"type":"launch_expedition"})
	for i in 6: await execute({"type":"pass"},false)
	var trip = s.trip_for("blue")
	assert(trip.status == "trading")
	await execute({"type":"expedition_buy","offer":0})
	await execute({"type":"expedition_sell","offer":0})
	await execute({"type":"expedition_contract","offer":1,"access":"public"})
	await execute({"type":"return_expedition"})
	for i in 6: await execute({"type":"pass"},false)
	assert(trip.status == "home" and s.transport_free("blue") == 0)
	s._gain_influence("blue",2,"fixture",[])
	await execute({"type":"own_route","route":1})
	assert(s.route_by_id(1).access == "priority")
	await execute({"type":"cancel_route","route":1})
	assert(s.transport_free("blue") == 1)
	assert(ui.session.save_game() == OK)
	var saved = TownSimulation.canonical(s.snapshot())
	assert(ui.session.load_game() == OK)
	assert(saved == TownSimulation.canonical(ui.session.sim.snapshot()))
	print(JSON.stringify({"expedition_ui_commands":count,"minimum":str(largest),"save_load":"exact"}))
	quit()

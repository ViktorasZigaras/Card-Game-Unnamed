extends SceneTree
var ui
var largest = Vector2.ZERO
var actions = 0
func _initialize() -> void: call_deferred("run")
func execute(action: Dictionary) -> void:
	var s = ui.session.sim
	s.state.actor = 0
	assert(action in s.legal_actions())
	var entry = ui.session.preview(action)
	var before = TownSimulation.canonical(s.snapshot())
	ui._preview(entry)
	assert(before == TownSimulation.canonical(s.snapshot()),"Preview mutated state")
	ui._execute_pending()
	assert(ui.session.probe.failure == "")
	ui.tab = "Links"
	ui._draw()
	await process_frame
	largest = largest.max(ui.root_box.get_minimum_size()+Vector2(32,32))
	assert(largest.x <= 1920 and largest.y <= 1080,"House hall UI overflow")
	actions += 1
func run() -> void:
	root.size = Vector2i(1920,1080)
	ui = load("res://ui/interface.tscn").instantiate()
	root.add_child(ui)
	var s = ui.session.sim
	s._add_lot("wood",12,"","fixture",0)
	s._add_lot("pop",6,"","fixture",0)
	s._gain_influence("blue",6,"fixture",[])
	s._add_lot("stone",1,"","fixture",0)
	s.state.project_metrics.stone_bought += 1
	await execute({"type":"claim_site","building":"small_sawmill","replace":""})
	expose("small_sawmill")
	await execute({"type":"supply_site","building":"small_sawmill","bundle":{"wood":2,"pop":1}})
	expose("small_sawmill")
	await execute({"type":"activate","building":"small_sawmill","mode":"basic"})
	await execute({"type":"claim_site","building":"hall_blue","replace":""})
	s._close_round()
	s._add_lot("wood",5,"","fixture",0)
	s._add_lot("pop",3,"","fixture",0)
	expose("small_sawmill")
	await execute({"type":"activate","building":"small_sawmill","mode":"basic"})
	expose("hall_blue")
	await execute({"type":"supply_site","building":"hall_blue","bundle":{"planks":3,"stone":1,"pop":1}})
	await execute({"type":"hall_work","building":"hall_blue","recipe":"furniture"})
	ui._select("building","hall_blue")
	await process_frame
	assert(ui.session.save_game() == OK)
	var saved = TownSimulation.canonical(s.snapshot())
	assert(ui.session.load_game() == OK)
	assert(saved == TownSimulation.canonical(ui.session.sim.snapshot()))
	print(JSON.stringify({"hall_ui_actions":actions,"minimum":str(largest),"save_load":"exact"}))
	quit()
func expose(id: String) -> void:
	var s = ui.session.sim
	for pile in [s.state.deck,s.state.discard,s.state.revealed]:
		while id in pile: pile.erase(id)
	s.state.revealed.append(id)
	s.state.used.erase(id)

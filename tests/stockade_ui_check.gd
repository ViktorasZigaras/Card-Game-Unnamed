extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1920,1080)
	var ui = load("res://ui/interface.tscn").instantiate()
	root.add_child(ui)
	var s = ui.session.sim
	s._add_lot("wood",10,"","ui_fixture",0)
	s._add_lot("stone",2,"","ui_fixture",0)
	s.state.project_metrics.stone_bought += 2
	s._add_lot("pop",12,"","ui_fixture",0)
	var actions: Array = []
	for i in range(6): actions.append({"type":"supply_wood"})
	for terrain in ["forest","field"]: actions.append({"type":"redevelop_rural","terrain":terrain})
	for terrain in ["forest","forest","field","field"]: actions.append({"type":"claim_rural"})
	var largest = Vector2.ZERO
	for action in actions:
		s.state.actor = 0
		var entry = ui.session.preview(action)
		var before = TownSimulation.canonical(s.snapshot())
		ui._preview(entry)
		assert(before == TownSimulation.canonical(s.snapshot()))
		ui._execute_pending()
		assert(ui.session.probe.failure == "")
		ui.tab = "Links"
		ui._draw()
		await process_frame
		largest = largest.max(ui.root_box.get_minimum_size()+Vector2(32,32))
		assert(largest.x <= 1920 and largest.y <= 1080)
	assert(s.claim_count() == 4 and s.effective_capacity("urban") == 8)
	assert(ui.session.save_game() == OK)
	var saved = TownSimulation.canonical(s.snapshot())
	assert(ui.session.load_game() == OK)
	assert(saved == TownSimulation.canonical(ui.session.sim.snapshot()))
	print(JSON.stringify({"stockade_ui_actions":actions.size(),"minimum":str(largest),"save_load":"exact"}))
	quit()

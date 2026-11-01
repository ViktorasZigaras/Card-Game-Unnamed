extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1920,1080)
	var ui = load("res://ui/interface.tscn").instantiate()
	root.add_child(ui)
	var kinds: Dictionary = {}
	var biggest = Vector2.ZERO
	while ui.session.sim.state.round <= 40 and ui.session.sim.state.sequence < 1000:
		var sim = ui.session.sim
		var action = ui.session.probe.policy.decide(sim).chosen
		var entry = ui.session.preview(action)
		var before = TownSimulation.canonical(sim.snapshot())
		ui._preview(entry)
		assert(before == TownSimulation.canonical(sim.snapshot()),"Preview changed state")
		ui._execute_pending()
		assert(ui.session.probe.failure == "","UI command failed")
		kinds[action.type] = kinds.get(action.type,0)+1
		ui.tab = "Links"
		ui._draw()
		await process_frame
		biggest = biggest.max(ui.root_box.get_minimum_size()+Vector2(32,32))
		assert(biggest.x <= 1920 and biggest.y <= 1080,"Live contract layout overflow")
	assert(kinds.has("secure_contract") and kinds.has("bulk_exchange"),"New UI actions not exercised")
	assert(ui.session.save_game() == OK)
	var saved = TownSimulation.canonical(ui.session.sim.snapshot())
	assert(ui.session.load_game() == OK)
	assert(saved == TownSimulation.canonical(ui.session.sim.snapshot()),"Contract save/load mismatch")
	print(JSON.stringify({"live_actions":kinds,"minimum":str(biggest),"new_save_load":"exact"}))
	quit()

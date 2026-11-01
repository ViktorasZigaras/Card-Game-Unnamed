extends SceneTree
func _initialize() -> void:
	var sim = MarketplaceSimulation.new()
	sim.start(1)
	sim.state.clay_contract = {"fixture":true}
	sim.state.clay_deliveries = 1
	for i in range(3):
		var id = "hut_%d" % (i+1)
		sim.state.buildings[id].owner = sim.state.houses[i].id
		sim.state.buildings[id].level = 2
		sim._check_end()
		assert(sim.state.ended == (i == 2),"Must wait for all three houses")
	sim.state.ended = false
	sim.state.clay_deliveries = 0
	sim._check_end()
	assert(not sim.state.ended,"All homes still require delivered clay")
	sim.state.clay_deliveries = 1
	sim._check_end()
	assert(sim.state.end_reason == "clay_import_and_every_house")
	assert(sim.legal_actions().is_empty(),"No actions after completion")
	print("Every-house goal: 6 boundary checks passed")
	quit()

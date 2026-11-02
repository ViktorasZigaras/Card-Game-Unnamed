extends SceneTree
var fx = preload("res://tests/flexible_fixture.gd").new()
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var reports: Array = []
	var failed = false
	for seed_value in [1,7,42]:
		for bridge in [false,true]:
			var sim: FlexibleContractSimulation = fx.fixture(seed_value,bridge)
			if bridge: fx.wallet(sim,5,1)
			var folder = "res://experiments/flexible_directed/seed_%d_%s" % [seed_value,"public_bridge" if bridge else "cargo"]
			var probe = GameProbe.new()
			probe.policy = PlannerAI.new()
			probe.attach(sim,folder+"/decisions.jsonl")
			var steps = 0
			while steps < 200 and probe.failure == "":
				if sim.current_house().id == "blue": probe.step()
				else: probe.step({"type":"pass"})
				steps += 1
				if bridge:
					if not sim.state.exploration.routes.is_empty() and not sim.state.exploration.routes[0].active: break
				elif sim.trip_for("blue").is_empty(): break
			var clone = FlexibleContractSimulation.new()
			clone.restore(JSON.parse_string(JSON.stringify(sim.snapshot())))
			var r = {"seed":seed_value,"bridge":bridge,"steps":steps,"failure":probe.failure,"imports":sim.state.exploration.imports,"routes":sim.state.exploration.routes,"free_land":sim.transport_free("blue"),"replay":GameProbe.replay_journal(folder+"/decisions.jsonl"),"save_exact":TownSimulation.canonical(clone.snapshot()) == TownSimulation.canonical(sim.snapshot())}
			r.goal_met = steps < 200 and r.free_land == 1 and (sim.state.exploration.imports.clay == 4 and sim.state.exploration.routes[0].misses == 0 and sim.state.exploration.routes[0].access == "public" if bridge else sim.state.exploration.imports.clay == 2 and sim.state.exploration.routes.is_empty())
			failed = failed or probe.failure != "" or not r.replay.ok or not r.save_exact or not r.goal_met
			reports.append(r)
			print(JSON.stringify({"seed":seed_value,"bridge":bridge,"steps":steps,"goal_met":r.goal_met,"replay":r.replay}))
	DirAccess.make_dir_recursive_absolute("res://experiments/flexible_directed")
	FileAccess.open("res://experiments/flexible_directed/results.json",FileAccess.WRITE).store_string(JSON.stringify(reports,"\t"))
	quit(1 if failed else 0)

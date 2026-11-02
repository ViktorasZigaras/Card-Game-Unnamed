extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var reports: Array = []
	var failed = false
	for seed_value in [1,7,42]:
		for linked in [false,true]:
			var sim = MappedTownSimulation.new()
			sim.batch = 3
			sim.scenario_lumber_link = linked
			sim.start(seed_value)
			var folder = "res://experiments/mapped/seed_%d_%s" % [seed_value,"linked" if linked else "manual"]
			var probe = GameProbe.new()
			probe.policy = PlannerAI.new()
			probe.attach(sim,folder+"/decisions.jsonl")
			while sim.state.round <= 80 and probe.failure == "" and sim.state.sequence < 1800:
				if not probe.step().ok: break
			probe.save_game(folder+"/save.json")
			var clone = MappedTownSimulation.new()
			clone.restore(JSON.parse_string(FileAccess.get_file_as_string(folder+"/save.json")))
			var report = {"seed":seed_value,"linked":linked,"steps":sim.state.sequence,"failure":probe.failure,"halls":sim.state.houseworks.hall_rounds.size(),"all_goals_round":sim.state.trade.all_goals_round,"all_halls_round":sim.state.exploration.get("all_halls_round",0),"imports":sim.state.exploration.imports,"routes":sim.state.exploration.routes,"town_map":sim.state.town_map,"trips":sim.state.exploration.trips.size(),"actions":probe.metrics.actions,"replay":GameProbe.replay_journal(folder+"/decisions.jsonl"),"save_exact":TownSimulation.canonical(sim.snapshot()) == TownSimulation.canonical(clone.snapshot())}
			failed = failed or probe.failure != "" or not report.replay.ok or not report.save_exact or sim.state.sequence >= 1800
			reports.append(report)
			print(JSON.stringify({"seed":seed_value,"linked":linked,"steps":report.steps,"halls":report.halls,"failure":report.failure,"replay":report.replay}))
	DirAccess.make_dir_recursive_absolute("res://experiments/mapped")
	FileAccess.open("res://experiments/mapped/results.json",FileAccess.WRITE).store_string(JSON.stringify(reports,"\t"))
	quit(1 if failed else 0)

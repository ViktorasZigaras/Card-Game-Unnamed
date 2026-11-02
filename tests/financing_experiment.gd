extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var reports: Array = []
	var failed = false
	for seed_value in [1,7,42]:
		for linked in [false,true]:
			for funded in [false,true]:
				var sim = FinancingSimulation.new()
				sim.batch = 3
				sim.scenario_lumber_link = linked
				sim.start(seed_value)
				var folder = "res://experiments/financing/seed_%d_%s_%s" % [seed_value,"linked" if linked else "manual","funded" if funded else "baseline"]
				var probe = GameProbe.new()
				probe.policy = FinancingAI.new() if funded else ExpeditionAI.new()
				probe.attach(sim,folder+"/decisions.jsonl")
				while sim.state.round <= 80 and probe.failure == "" and sim.state.sequence < 1800:
					if not probe.step().ok: break
				probe.save_game(folder+"/save.json")
				var clone = FinancingSimulation.new()
				clone.restore(JSON.parse_string(FileAccess.get_file_as_string(folder+"/save.json")))
				var report = probe.summary()
				report.linked = linked
				report.funded_policy = funded
				report.exploration = sim.state.exploration
				report.development = sim.state.development
				report.houseworks = sim.state.houseworks
				report.trade = sim.state.trade
				report.projects = sim.state.projects
				report.project_metrics = sim.state.project_metrics
				report.replay = GameProbe.replay_journal(folder+"/decisions.jsonl")
				report.save_exact = TownSimulation.canonical(sim.snapshot()) == TownSimulation.canonical(clone.snapshot())
				failed = failed or probe.failure != "" or not report.replay.ok or not report.save_exact or sim.state.sequence >= 1800
				reports.append(report)
				print(JSON.stringify({"seed":seed_value,"linked":linked,"funded":funded,"halls":sim.state.houseworks.hall_rounds.size(),"trips":sim.state.exploration.trips.size(),"routes":sim.state.exploration.routes.size(),"failure":probe.failure,"replay":report.replay}))
	FileAccess.open("res://experiments/financing/results.json",FileAccess.WRITE).store_string(JSON.stringify(reports,"\t"))
	quit(1 if failed else 0)

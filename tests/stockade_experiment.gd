extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var reports: Array = []
	var failed = false
	for seed_value in [1,7,42]:
		for linked in [false,true]:
			for sweep in [false,true]:
				var sim = StockadeSimulation.new()
				sim.batch = 3
				sim.scenario_lumber_link = linked
				sim.rules.town_wood_sweep = sweep
				sim.start(seed_value)
				var folder = "res://experiments/stockade/seed_%d_%s_%s" % [seed_value,"linked" if linked else "manual","sweep" if sweep else "voluntary"]
				var probe = GameProbe.new()
				probe.policy = StockadeAI.new()
				probe.attach(sim,folder+"/decisions.jsonl")
				while sim.state.round <= 40 and probe.failure == "" and sim.state.sequence < 5000:
					if not probe.step().ok: break
				probe.save_game(folder+"/save.json")
				var clone = StockadeSimulation.new()
				clone.restore(JSON.parse_string(FileAccess.get_file_as_string(folder+"/save.json")))
				var report = probe.summary()
				report.linked = linked
				report.sweep = sweep
				report.town = sim.state.town
				report.terrain_free = sim.state.terrain_free
				report.trade = sim.state.trade
				report.projects = sim.state.projects
				report.project_metrics = sim.state.project_metrics
				report.economy = sim.state.economy
				report.replay = GameProbe.replay_journal(folder+"/decisions.jsonl")
				report.save_exact = TownSimulation.canonical(sim.snapshot()) == TownSimulation.canonical(clone.snapshot())
				failed = failed or probe.failure != "" or not report.replay.ok or not report.save_exact or sim.state.sequence >= 5000
				reports.append(report)
				print(JSON.stringify({"seed":seed_value,"linked":linked,"sweep":sweep,"goals":sim.state.trade.all_goals_round,"town":sim.state.town,"failure":probe.failure,"replay":report.replay}))
	var f = FileAccess.open("res://experiments/stockade/results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(reports,"\t"))
	quit(1 if failed else 0)

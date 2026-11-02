extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var reports: Array = []
	var enabled_only = "--enabled-only" in OS.get_cmdline_user_args()
	if enabled_only:
		for old in JSON.parse_string(FileAccess.get_file_as_string("res://experiments/expeditions/results.json")):
			if not old.expeditions_enabled: reports.append(old)
	var failed = false
	for seed_value in [1,7,42]:
		for linked in [false,true]:
			for enabled in ([true] if enabled_only else [false,true]):
				var sim = ExpeditionSimulation.new()
				sim.batch = 3
				sim.scenario_lumber_link = linked
				sim.rules.expeditions_enabled = enabled
				sim.start(seed_value)
				var folder = "res://experiments/expeditions/seed_%d_%s_%s" % [seed_value,"linked" if linked else "manual","expeditions" if enabled else "control"]
				var probe = GameProbe.new()
				probe.policy = ExpeditionAI.new()
				probe.attach(sim,folder+"/decisions.jsonl")
				while sim.state.round <= 80 and probe.failure == "" and sim.state.sequence < 1800:
					if not probe.step().ok: break
				probe.save_game(folder+"/save.json")
				var clone = ExpeditionSimulation.new()
				clone.restore(JSON.parse_string(FileAccess.get_file_as_string(folder+"/save.json")))
				var report = probe.summary()
				report.linked = linked
				report.expeditions_enabled = enabled
				report.exploration = sim.state.exploration
				report.development = sim.state.development
				report.houseworks = sim.state.houseworks
				report.town = sim.state.town
				report.terrain_free = sim.state.terrain_free
				report.trade = sim.state.trade
				report.projects = sim.state.projects
				report.project_metrics = sim.state.project_metrics
				report.economy = sim.state.economy
				report.replay = GameProbe.replay_journal(folder+"/decisions.jsonl")
				report.save_exact = TownSimulation.canonical(sim.snapshot()) == TownSimulation.canonical(clone.snapshot())
				failed = failed or probe.failure != "" or not report.replay.ok or not report.save_exact or sim.state.sequence >= 1800
				reports.append(report)
				print(JSON.stringify({"seed":seed_value,"linked":linked,"expeditions":enabled,"goals":sim.state.trade.all_goals_round,"halls":sim.state.houseworks.hall_rounds,"trips":sim.state.exploration.trips.size(),"routes":sim.state.exploration.routes.size(),"clearances":sim.state.development.clearances.size(),"failure":probe.failure,"replay":report.replay}))
	var f = FileAccess.open("res://experiments/expeditions/results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(reports,"\t"))
	quit(1 if failed else 0)

extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var batch = 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--batch="): batch = int(arg.split("=")[1])
	var reports: Array = []
	var failed = false
	for seed_value in [1,7,42]:
		for kiln in [false,true]:
			var sim = CapacitySimulation.new()
			sim.batch = batch
			sim.scenario_lumber_link = false
			sim.scenario_kiln = kiln
			sim.start(seed_value)
			var folder = "res://experiments/kiln/batch_%d/seed_%d_%s" % [batch,seed_value,"kiln" if kiln else "control"]
			var probe = GameProbe.new()
			probe.policy = KilnAI.new()
			probe.attach(sim,folder+"/decisions.jsonl")
			var min_reserve = 6
			var timeline: Array = []
			while sim.state.round <= 40 and probe.failure == "" and sim.state.sequence < 5000:
				min_reserve = mini(min_reserve,sim.free_pop_tokens())
				var result = probe.step()
				if not result.ok: break
				if result.round_closed: timeline.append({"round":sim.state.round,"stock":sim.state.market.duplicate(true),"contracts":sim.state.contracts.duplicate(true),"committed":sim.state.committed_pops})
			probe.save_game(folder+"/save.json")
			var checkpoint = CapacitySimulation.new()
			checkpoint.restore(JSON.parse_string(FileAccess.get_file_as_string(folder+"/save.json")))
			var stable = TownSimulation.canonical(checkpoint.snapshot()) == TownSimulation.canonical(sim.snapshot())
			var report = probe.summary()
			report.kiln_enabled = kiln
			report.economy = sim.state.economy
			report.access = sim.state.access_metrics
			report.priority = sim.state.priority_metrics
			report.titles = sim.state.titles
			report.capacity = sim.state.capacity
			report.clay_deliveries = sim.state.clay_deliveries
			report.milestones = sim.state.milestones
			report.contracts = sim.state.contracts
			report.timeline = timeline
			report.min_reserve = min_reserve
			report.save_restore_exact = stable
			report.replay = GameProbe.replay_journal(folder+"/decisions.jsonl")
			failed = failed or probe.failure != "" or not report.replay.ok or not stable or sim.state.sequence >= 5000
			reports.append(report)
			print(JSON.stringify({"batch":batch,"seed":seed_value,"kiln":kiln,"goal":sim.state.economy.goal_round,"upgrades":sim.state.houses.map(func(h): return h.first_upgrade_round),"economy":sim.state.economy,"failure":probe.failure,"replay":report.replay,"decisions":sim.state.sequence,"min_reserve":min_reserve}))
	var f = FileAccess.open("res://experiments/kiln/batch_%d/results.json" % batch,FileAccess.WRITE)
	f.store_string(JSON.stringify(reports,"\t"))
	quit(1 if failed else 0)

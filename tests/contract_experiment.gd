extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var batch = 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--batch="): batch = int(arg.split("=")[1])
	var reports: Array = []
	var failed = false
	for seed_value in [1,7,42]:
		for linked in [false,true]:
			var sim = ContractSimulation.new()
			sim.batch = batch
			sim.scenario_lumber_link = linked
			sim.start(seed_value)
			var folder = "res://experiments/contracts/batch_%d/seed_%d_%s" % [batch,seed_value,"linked" if linked else "manual"]
			var probe = GameProbe.new()
			probe.policy = ContractAI.new()
			probe.attach(sim,folder+"/decisions.jsonl")
			var min_reserve = 6
			var timeline: Array = []
			while sim.state.round <= 40 and probe.failure == "" and sim.state.sequence < 5000:
				min_reserve = mini(min_reserve,sim.free_pop_tokens())
				var result = probe.step()
				if not result.ok: break
				if result.round_closed: timeline.append({"round":sim.state.round,"stock":sim.state.market.duplicate(true),"contracts":sim.state.contracts.duplicate(true),"committed":sim.state.committed_pops})
			probe.save_game(folder+"/save.json")
			var checkpoint = ContractSimulation.new()
			checkpoint.restore(sim.snapshot())
			var stable = TownSimulation.canonical(checkpoint.snapshot()) == TownSimulation.canonical(sim.snapshot())
			var report = probe.summary()
			report.linked = linked
			report.economy = sim.state.economy
			report.access = sim.state.access_metrics
			report.milestones = sim.state.milestones
			report.contracts = sim.state.contracts
			report.timeline = timeline
			report.min_reserve = min_reserve
			report.save_restore_exact = stable
			report.replay = GameProbe.replay_journal(folder+"/decisions.jsonl")
			failed = failed or probe.failure != "" or not report.replay.ok or not stable or sim.state.sequence >= 5000
			reports.append(report)
			print(JSON.stringify({"batch":batch,"seed":seed_value,"linked":linked,"goal":sim.state.economy.goal_round,"upgrades":sim.state.houses.map(func(h): return h.first_upgrade_round),"economy":sim.state.economy,"failure":probe.failure,"replay":report.replay,"decisions":sim.state.sequence,"min_reserve":min_reserve}))
	var f = FileAccess.open("res://experiments/contracts/batch_%d/results.json" % batch,FileAccess.WRITE)
	f.store_string(JSON.stringify(reports,"\t"))
	quit(1 if failed else 0)

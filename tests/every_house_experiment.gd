extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var reports: Array = []
	for seed_value in [1,7,42]:
		for linked in [false,true]:
			var sim = MarketplaceSimulation.new()
			sim.scenario_lumber_link = linked
			sim.start(seed_value)
			var folder = "res://experiments/every_house/seed_%d_%s" % [seed_value,"linked" if linked else "manual"]
			var probe = GameProbe.new()
			probe.policy = MarketplaceAI.new()
			probe.attach(sim,folder+"/decisions.jsonl")
			var diagnostics: Dictionary = {}
			for h in sim.state.houses: diagnostics[h.id] = {"no_free_pop":0,"carpenter_visible":0,"carpenter_legal":0,"upgrade_legal":0,"actions":{}}
			while not sim.state.ended and sim.state.round <= 40 and probe.failure == "" and sim.state.sequence < 12000:
				var h = sim.current_house()
				var d: Dictionary = diagnostics[h.id]
				if sim.free_pop_tokens() == 0: d.no_free_pop += 1
				if "carpenter" in sim.state.revealed: d.carpenter_visible += 1
				for a in sim.legal_actions():
					if a.type == "activate" and a.building == "carpenter": d.carpenter_legal += 1
					if a.type == "upgrade": d.upgrade_legal += 1
				var result = probe.step()
				var kind = probe.last_decision.chosen.type
				d.actions[kind] = d.actions.get(kind,0)+1
				if not result.ok: break
			probe.save_game(folder+"/save.json")
			var report = probe.summary()
			report.linked = linked
			report.ended = sim.state.ended
			report.milestones = sim.state.milestones
			report.access = sim.state.access_metrics
			report.diagnostics = diagnostics
			report.clay_deliveries = sim.state.clay_deliveries
			report.pop_reserve = sim.free_pop_tokens()
			report.replay = GameProbe.replay_journal(folder+"/decisions.jsonl")
			reports.append(report)
			print(JSON.stringify({"seed":seed_value,"linked":linked,"ended":report.ended,"round":report.round,"houses":report.houses,"replay":report.replay,"failure":report.failure}))
	var f = FileAccess.open("res://experiments/every_house/results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(reports,"\t"))
	quit()

extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var reports: Array = []
	var old = FinancingAI.new()
	var planner = PlannerAI.new()
	var failed = false
	for seed_value in [1,7,42]:
		for linked in [false,true]:
			var s = FinancingSimulation.new()
			s.batch = 3
			s.scenario_lumber_link = linked
			s.start(seed_value)
			var checked = 0
			var error = ""
			while s.state.round <= 80 and checked < 1800:
				var before = TownSimulation.canonical(s.snapshot())
				var a = old.decide(s)
				var b = planner.decide(s)
				if a.chosen != b.chosen or a.score != b.score: error = "chosen action mismatch"
				if a.candidates.size() != b.candidates.size(): error = "candidate count mismatch"
				for i in a.candidates.size():
					if a.candidates[i].action != b.candidates[i].action or a.candidates[i].score != b.candidates[i].score: error = "candidate score mismatch"
				if before != TownSimulation.canonical(s.snapshot()): error = "inspection changed state or RNG"
				if error != "": break
				var result = s.apply(b.chosen)
				if not result.ok or not s.violations().is_empty():
					error = "illegal action or invariant: "+str(s.violations())
					break
				checked += 1
			var r = {"seed":seed_value,"linked":linked,"checked":checked,"error":error,"round":s.state.round}
			reports.append(r)
			print(JSON.stringify(r))
			failed = failed or error != "" or checked >= 1800
	DirAccess.make_dir_recursive_absolute("res://experiments/planner_equivalence")
	FileAccess.open("res://experiments/planner_equivalence/results.json",FileAccess.WRITE).store_string(JSON.stringify(reports,"\t"))
	quit(1 if failed else 0)

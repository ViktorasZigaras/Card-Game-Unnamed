extends SceneTree
class Inspector extends RetrySimulation:
	var trace: Array = []
	func _after_action(event: Dictionary) -> void:
		var before_failed = int(state.retry.failed)
		super._after_action(event)
		if int(state.retry.failed) > before_failed:
			var reserved = 0
			var stored = 0
			for lot in state.lots:
				if lot.resource == "wood" and lot.reserved_for != "": reserved += int(lot.amount)
			for h in state.houses: stored += int(h.stockpile.wood)
			trace.append({"round":state.round,"reserved":reserved,"stockpiled":stored,"total":total_physical("wood")})
func _initialize() -> void:
	var reports: Array = []
	for seed_value in [1,7,42]:
		for linked in [false,true]:
			var path = "res://experiments/retry/batch_3/seed_%d_%s/decisions.jsonl" % [seed_value,"linked" if linked else "manual"]
			var f = FileAccess.open(path,FileAccess.READ)
			var sim = Inspector.new()
			sim.restore(JSON.parse_string(f.get_line()).snapshot)
			while not f.eof_reached():
				var line = f.get_line()
				if line.is_empty(): continue
				var record = JSON.parse_string(line)
				assert(sim.apply(record.decision.chosen).ok)
				assert(TownSimulation.canonical(sim.snapshot()) == TownSimulation.canonical(record.snapshot))
			reports.append({"seed":seed_value,"linked":linked,"failed_retries":sim.trace})
	var out = FileAccess.open("res://experiments/retry/batch_3/retry_diagnostics.json",FileAccess.WRITE)
	out.store_string(JSON.stringify(reports,"\t"))
	print(JSON.stringify(reports))
	quit()

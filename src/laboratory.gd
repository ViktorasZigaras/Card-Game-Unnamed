extends Node
## Main scene is deliberately only a simulation host. No Control nodes or art.
func _ready() -> void:
	var options = {"experiment":"marketplace","seed":42,"rounds":30,"locale":"","output":"user://runs/default","lumber_link":false}
	for arg in OS.get_cmdline_user_args():
		var parts = arg.trim_prefix("--").split("=", true, 1)
		if parts.size() == 2 and options.has(parts[0]):
			if parts[0] == "lumber_link": options[parts[0]] = parts[1] in ["true","1"]
			else: options[parts[0]] = int(parts[1]) if parts[0] in ["seed","rounds"] else parts[1]
	if options.locale == "": options.locale = "clayless_valley" if options.experiment == "marketplace" else "river_valley"
	if options.experiment not in ["marketplace", "commons", "reservations", "housing", "cash"] or not options.locale in ["clayless_valley","river_valley","northern_woodland"] or int(options.rounds) < 1:
		push_error("Invalid locale or rounds")
		get_tree().quit(2)
		return
	var sim: TownSimulation
	match options.experiment:
		"marketplace": sim = MarketplaceSimulation.new()
		"commons": sim = CommonsSimulation.new()
		"reservations": sim = ReservationSimulation.new()
		"housing": sim = HousingSimulation.new()
		_: sim = TownSimulation.new()
	if not sim.rules.locales.has(options.locale):
		push_error("Locale is not defined for this experiment")
		get_tree().quit(2)
		return
	if options.experiment == "marketplace": (sim as MarketplaceSimulation).scenario_lumber_link = options.lumber_link
	sim.start(int(options.seed), options.locale)
	var probe = GameProbe.new()
	if options.experiment == "marketplace":
		probe.policy = MarketplaceAI.new()
	elif options.experiment == "commons":
		probe.policy = CommonsAI.new()
	elif options.experiment == "reservations":
		probe.policy = ReservationAI.new()
	elif options.experiment == "housing":
		probe.policy = HousingAI.new()
	probe.attach(sim, options.output + "/decisions.jsonl")
	var summary: Dictionary
	if options.experiment == "marketplace":
		var end_round = int(sim.state.round)+int(options.rounds)
		while not sim.state.ended and sim.state.round < end_round and probe.failure == "":
			probe.step()
		summary = probe.summary()
		summary.scenario_ended = sim.state.ended
		summary.end_reason = sim.state.end_reason
	else:
		summary = probe.run_rounds(int(options.rounds))
	probe.save_game(options.output + "/save.json")
	var report = FileAccess.open(options.output + "/summary.json", FileAccess.WRITE)
	if report == null:
		push_error("Could not write summary")
		get_tree().quit(2)
		return
	report.store_string(JSON.stringify(summary, "\t"))
	report.close()
	print(JSON.stringify(summary))
	get_tree().quit(0 if summary.failure == "" else 1)

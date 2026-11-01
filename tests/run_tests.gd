extends SceneTree
var checks = 0
var failures: Array = []
func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var sim = TownSimulation.new()
	sim.start(42)
	check(sim.violations().is_empty(), "initial invariants")
	var before = JSON.stringify(sim.snapshot())
	check(not sim.apply({"type":"activate","building":"bakery"}).ok, "illegal command rejected")
	check(JSON.stringify(sim.snapshot()) == before, "illegal command does not mutate state")
	# Known owner compensation and once-per-round activation fixture.
	sim.state.actor = 0
	var id: String = sim.state.revealed[0]
	# Use a raw producer so starting inventory can always pay.
	for card in sim.state.revealed:
		if sim.definitions[card].inputs.is_empty():
			id = card
			break
	check(sim.apply({"type":"buy_building","building":id}).ok, "acquire revealed building")
	var owner_coin = int(sim.house("blue").inventory.coin)
	var activator_coin = int(sim.current_house().inventory.coin)
	var activator_id: String = sim.current_house().id
	check(sim.apply({"type":"activate","building":id}).ok, "other house activates owned building")
	check(sim.house("blue").inventory.coin == owner_coin + 1, "owner receives one coin")
	check(sim.house(activator_id).inventory.coin == activator_coin - 1, "activator pays one coin")
	check(not {"type":"activate","building":id} in sim.legal_actions(), "building usable once per round")
	check(sim.violations().is_empty(), "fee fixture conserves resources")
	# Contract escrow, delivery, persistence and cancellation on unfunded renewal.
	var c = TownSimulation.new()
	c.start(11)
	var c_house: String = c.current_house().id
	var c_coins = int(c.current_house().inventory.coin)
	check(c.apply({"type":"contract"}).ok, "accept trade contract")
	check(c.house(c_house).inventory.grain == 0 and c.state.contracts.size() == 1, "contract reserves grain")
	while c.state.round == 1:
		c.apply({"type":"pass"})
	check(c.house(c_house).inventory.coin == c_coins + 4, "delivery pays reserved coins")
	check(c.state.contracts.is_empty(), "unfunded renewal terminates")
	check(c.violations().is_empty(), "contract escrow accounted")
	# Live journal, reload through actual JSON file, exact continuation and replay.
	var original = TownSimulation.new()
	original.start(907)
	var probe = GameProbe.new()
	probe.attach(original, "user://tests/decisions.jsonl")
	probe.run_rounds(8)
	check(probe.save_game("user://tests/save.json") == OK, "save file")
	var restored = TownSimulation.new()
	var restored_probe = GameProbe.new()
	restored_probe.attach(restored)
	check(restored_probe.load_game("user://tests/save.json") == OK, "load JSON save")
	for i in range(100):
		var a = probe.policy.decide(original)
		var b = restored_probe.policy.decide(restored)
		check(a.chosen == b.chosen, "save continuation decision %d" % i)
		probe.step()
		restored_probe.step()
		check(TownSimulation.canonical(original.snapshot()) == TownSimulation.canonical(restored.snapshot()), "save continuation state %d" % i)
	var replay = GameProbe.replay_journal("user://tests/decisions.jsonl")
	check(replay.ok, "full journal replay: " + JSON.stringify(replay))
	# Batch simulations test both geographies with deterministic independent seeds.
	var aggregate: Dictionary = {}
	var batch: Array = []
	for locale in ["river_valley","northern_woodland"]:
		for seed_value in range(20):
			var s = TownSimulation.new()
			s.start(seed_value, locale)
			var p = GameProbe.new()
			p.attach(s)
			var summary = p.run_rounds(60)
			check(summary.failure == "", "%s seed %d invariants" % [locale, seed_value])
			check(s.state.round == 61, "round progress")
			for action_type in p.metrics.actions:
				aggregate[action_type] = aggregate.get(action_type, 0) + p.metrics.actions[action_type]
			batch.append(summary)
	for required in ["activate","buy_building","sell_building","upgrade","construct","market_buy","market_sell","contract","work","pass"]:
		check(aggregate.get(required, 0) > 0, "batch action coverage: " + required)
	var output = {"checks":checks,"failures":failures,"games":batch.size(),"rounds_per_game":60,"action_counts":aggregate,"games_detail":batch}
	var file = FileAccess.open("user://tests/batch_results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "\t"))
	print(JSON.stringify({"checks":checks,"failures":failures,"games":batch.size(),"action_counts":aggregate,"report":ProjectSettings.globalize_path("user://tests/batch_results.json")}))
	quit(0 if failures.is_empty() else 1)

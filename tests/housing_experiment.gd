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

func expose(sim: HousingSimulation, ids: Array) -> void:
	sim.state.deck = sim.state.deck + sim.state.discard + sim.state.revealed
	sim.state.discard = []
	sim.state.revealed = []
	for id in ids:
		sim.state.deck.erase(id)
		sim.state.revealed.append(id)

func fixture_checks() -> void:
	var sim = HousingSimulation.new()
	sim.start(1)
	expose(sim, ["hut_1","lumber_camp","grain_farm","brick_kiln"])
	sim.state.actor = 0
	check(not sim.state.has("bank") and not sim.rules.resources.has("coin"), "cash is absent")
	check(sim.population("blue") == 2 and sim.house("blue").labour == 2, "residents supply initial labour")
	check(sim.violations().is_empty(), "initial housing accounting")
	var before = TownSimulation.canonical(sim.snapshot())
	check(not sim.apply({"type":"upgrade","building":"hut_1"}).ok, "cannot upgrade public unfunded hut")
	check(before == TownSimulation.canonical(sim.snapshot()), "invalid housing action atomic")
	check(sim.apply({"type":"claim","building":"hut_1"}).ok, "claim public hut")
	check(sim.house("blue").labour == 1 and sim.house("blue").inventory.influence == 0, "claim spends influence and labour")
	check(sim.state.buildings.hut_1.owner == "blue", "ownership persists")
	# Fund only this fixture's upgrade, recording the source in the ledger.
	for pair in [["wood",1],["brick",1],["influence",2]]:
		sim._create(sim.house("blue").inventory, pair[0], pair[1])
	sim.state.actor = 0
	check(not {"type":"upgrade","building":"hut_1"} in sim.legal_actions(), "labour limits upgrade despite sufficient goods")
	while sim.state.round == 1:
		sim.apply({"type":"pass"})
	expose(sim, ["hut_1","lumber_camp","grain_farm","brick_kiln"])
	sim.state.actor = 0
	check(sim.apply({"type":"upgrade","building":"hut_1"}).ok, "upgrade after labour refresh")
	check(sim.capacity("hut_1") == 4 and sim.occupancy("hut_1") == 2, "upgrade adds beds, not instant people")
	check(sim.house("blue").labour == 0, "upgrade costs two labour")
	while sim.state.round == 2:
		sim.apply({"type":"pass"})
	check(sim.population("blue") == 3 and sim.house("blue").labour == 3, "grain-funded arrival supplies next-round labour")
	check(sim.house("blue").inventory.grain == 1, "arrival consumes one grain")
	check(sim.house("blue").inventory.influence == 1, "inhabited upgraded hut earns influence")
	check(sim.violations().is_empty(), "growth and labour accounting")
	# New construction must consume a real plot.
	sim.state.actor = 0
	sim._create(sim.house("blue").inventory, "wood", 2)
	sim._create(sim.house("blue").inventory, "influence", 1)
	var free_before = sim.available_plots()
	var plot = str(free_before[0])
	var available_count = int(sim.state.terrain_free[plot])
	check(sim.apply({"type":"construct_hut","plot":plot}).ok, "construct additional home")
	check(sim.state.terrain_free[plot] == available_count - 1 and sim.state.buildings.hut_4.plot == plot, "housing occupies competing plot")
	check(sim.violations().is_empty(), "construction conservation")
	# Save reload preserves resident allegiance, labour, objective, and deck state.
	var loaded = HousingSimulation.new()
	loaded.restore(JSON.parse_string(JSON.stringify(sim.snapshot())))
	check(TownSimulation.canonical(sim.snapshot()) == TownSimulation.canonical(loaded.snapshot()), "housing snapshot round trip")
	var policy = HousingAI.new()
	check(policy.decide(sim).chosen == policy.decide(loaded).chosen, "housing AI round trip")
	var processing = HousingSimulation.new()
	processing.start(99)
	expose(processing, ["brick_kiln","hut_1","clay_pit","grain_farm"])
	processing.state.actor = 0
	processing.state.buildings.hut_1.owner = "blue"
	processing._create(processing.house("blue").inventory, "wood", 2)
	processing._create(processing.house("blue").inventory, "clay", 1)
	processing.state.market.brick = 0
	processing.state.ledger.brick.created -= 1
	var choice = policy.decide(processing)
	check(choice.chosen == {"type":"activate","building":"brick_kiln"}, "planner consumes intermediates to make needed bricks")
	check(not choice.chosen.type in ["claim","construct_hut"], "planner finishes first upgrade before expanding")

func run() -> void:
	fixture_checks()
	var games: Array = []
	var total_decisions = 0
	for locale in ["river_valley","northern_woodland"]:
		for seed_value in [1,42]:
			var sim = HousingSimulation.new()
			sim.start(seed_value, locale)
			var probe = GameProbe.new()
			probe.policy = HousingAI.new()
			var output = "res://experiments/housing/evidence/%s_%d" % [locale,seed_value]
			probe.attach(sim, output + "/decisions.jsonl")
			var rounds: Array = []
			var load_verified = false
			while sim.state.round <= 40 and probe.failure == "":
				var result = probe.step()
				if result.get("round_closed", false):
					rounds.append(status(sim, int(sim.state.round) - 1))
					if not load_verified and sim.state.round == 11:
						check(probe.save_game(output + "/checkpoint.json") == OK, "housing save game")
						var restored = HousingSimulation.new()
						var restored_probe = GameProbe.new()
						restored_probe.policy = HousingAI.new()
						restored_probe.attach(restored)
						check(restored_probe.load_game(output + "/checkpoint.json") == OK, "housing load game")
						check(probe.policy.decide(sim).chosen == restored_probe.policy.decide(restored).chosen, "housing loaded next decision")
						# A shadow step checks continuation; original run continues unchanged.
						var predicted: Dictionary = restored_probe.policy.decide(restored).chosen
						restored.apply(predicted)
						var clone = HousingSimulation.new()
						clone.restore(sim.snapshot())
						clone.apply(predicted)
						check(TownSimulation.canonical(clone.snapshot()) == TownSimulation.canonical(restored.snapshot()), "housing loaded next state")
						load_verified = true
			var summary = probe.summary()
			summary.housing = status(sim, 40)
			summary.round_history = rounds
			var summary_file = FileAccess.open(output + "/summary.json", FileAccess.WRITE)
			summary_file.store_string(JSON.stringify(summary, "\t"))
			summary_file.close()
			probe.save_game(output + "/save.json")
			check(probe.failure == "", "%s seed %d no invariant errors" % [locale,seed_value])
			check(sim.state.round == 41, "forty rounds complete")
			var replay = GameProbe.replay_journal(output + "/decisions.jsonl")
			check(replay.ok, "housing full replay: " + JSON.stringify(replay))
			total_decisions += int(sim.state.sequence)
			games.append(summary)
	var report = {"experiment":"housing_influence_labour_v1","rounds_per_game":40,"games":games,"checks":checks,"failures":failures,"total_decisions":total_decisions}
	var file = FileAccess.open("res://experiments/housing/results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print(JSON.stringify({"games":games.size(),"rounds_per_game":40,"checks":checks,"failures":failures,"total_decisions":total_decisions}))
	quit(0 if failures.is_empty() else 1)

func status(sim: HousingSimulation, completed_round: int) -> Dictionary:
	var houses: Array = []
	for h in sim.state.houses:
		houses.append({"id":h.id,"population":sim.population(h.id),"owned_huts":sim.owned_huts(h.id).size(),"upgraded_huts":sim.owned_huts(h.id,true).size(),
			"first_claim_round":h.first_claim_round,"first_upgrade_round":h.first_upgrade_round,"inventory":h.inventory.duplicate(true),"labour":h.labour})
	var built_industry: Array = []
	var huts: Array = []
	for id in sim._sorted_keys(sim.state.buildings):
		if sim.state.buildings[id].built:
			if sim.is_housing(id):
				huts.append(id)
			else:
				built_industry.append(id)
	return {"completed_round":completed_round,"houses":houses,"terrain_free":sim.state.terrain_free.duplicate(true),"built_industry":built_industry,"hut_count":huts.size(),"deck_size":sim.state.deck.size()+sim.state.discard.size()+sim.state.revealed.size(),"arrivals":sim.state.population_events.duplicate(true)}

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

func expose(sim: ReservationSimulation, ids: Array) -> void:
	sim.state.deck = sim.state.deck + sim.state.discard + sim.state.revealed
	sim.state.discard = []
	sim.state.revealed = []
	for id in ids:
		sim.state.deck.erase(id)
		sim.state.revealed.append(id)

func give_influence(sim: ReservationSimulation, id: String, amount: int) -> void:
	sim.house(id).inventory.influence += amount
	sim.state.ledger.influence.created += amount

func fixtures() -> void:
	var sim = ReservationSimulation.new()
	sim.start(0)
	expose(sim, ["hut_1","grain_farm","brick_kiln","pottery_workshop"])
	sim.state.actor = 0
	check(sim.violations().is_empty(), "initial shared stock accounting")
	check(sim.state.market.pop == 0 and not sim.state.has("bank"), "no free permanent workers or bank")
	var grain = int(sim.state.market.grain)
	check(sim.apply({"type":"activate","building":"hut_1"}).ok, "feed hut")
	check(sim.state.market.grain == grain - 1 and sim.state.market.pop == 1, "hut converts one grain to one pop")
	check(sim.available("blue").pop == 1 and sim.available("red").pop == 0, "producer has exclusive pop reservation")
	var unchanged = TownSimulation.canonical(sim.snapshot())
	check(not sim.apply({"type":"activate","building":"grain_farm"}).ok, "opponent cannot use reserved worker")
	check(unchanged == TownSimulation.canonical(sim.snapshot()), "reservation rejection is atomic")
	var restored = ReservationSimulation.new()
	restored.restore(JSON.parse_string(JSON.stringify(sim.snapshot())))
	check(TownSimulation.canonical(sim.snapshot()) == TownSimulation.canonical(restored.snapshot()), "reservation deadline survives JSON save")
	check(sim.apply({"type":"pass"}).ok and sim.house("red").inventory.influence == 1, "pass grants one influence")
	sim.apply({"type":"pass"})
	check(sim.apply({"type":"activate","building":"grain_farm"}).ok, "producer can spend pop on its next action")
	check(sim.state.market.pop == 0 and sim.available("blue").grain > sim.available("red").grain, "farm output receives new reservation")
	sim.apply({"type":"pass"})
	check(sim.state.round == 2 and sim.available("blue") == sim.available("red"), "pass releases output before next round")
	check(sim.house("blue").inventory.influence == 1 and sim.house("gold").inventory.influence == 1, "one pass per house per round")
	check(sim.violations().is_empty(), "production and pass accounting")
	# An upgraded hut uses luxury, yields two pops, and releases its unspent second pop.
	var up = ReservationSimulation.new()
	up.start(0)
	up.state.buildings.hut_1.level = 2
	expose(up, ["hut_1","grain_farm","clay_pit","pottery_workshop"])
	up.state.actor = 0
	give_influence(up,"red",3)
	give_influence(up,"gold",3)
	var luxury = int(up.state.market.luxury)
	check(up.apply({"type":"activate","building":"hut_1"}).ok, "activate upgraded hut")
	check(up.state.market.pop == 2 and up.state.market.luxury == luxury - 1, "luxury plus grain funds two pops")
	check(up.available("red").pop == 0, "two pops remain reserved through opponents' actions")
	up.apply({"type":"claim","building":"grain_farm"})
	up.apply({"type":"claim","building":"clay_pit"})
	check(up.house("red").inventory.influence == 0 and up.house("gold").inventory.influence == 0, "industry claims also cost exactly three influence")
	up.apply({"type":"activate","building":"grain_farm"})
	check(up.available("red").pop == 1, "unspent second pop releases after producer's next action")
	check(up.apply({"type":"activate","building":"pottery_workshop"}).ok, "rival can use released worker")
	check(up.state.market.pop == 0 and up.state.pop_worked == 2, "shared activity spends both regenerated pops")
	check(up.house("red").inventory.influence == 0, "activation and ownership do not mint influence")
	check(up.violations().is_empty(), "released worker and luxury accounting")
	# Housing is urban, construction public, claiming separate, and unused pops expire.
	var build = ReservationSimulation.new()
	build.start(0)
	build.state.actor = 0
	build._add_lot("pop",1,"","fixture",0)
	var rural_before = int(build.state.terrain_free.field)
	check(not build.apply({"type":"construct_hut","plot":"forest"}).ok, "cannot build housing on resource land")
	check(build.apply({"type":"construct_hut"}).ok, "construct on available urban plot")
	check(build.state.terrain_free.urban == 0 and build.state.terrain_free.field == rural_before, "urban construction preserves rural plots")
	check(build.state.buildings.hut_4.owner == "", "construction creates public asset, not a free claim")
	build._add_lot("pop",2,"","fixture",0)
	while build.state.round == 1:
		build.apply({"type":"pass"})
	check(build.state.market.pop == 0 and build.state.reservation_metrics.expired_pops == 2, "unused pops expire rather than accumulate")
	check(build.violations().is_empty(), "plot/pop expiry accounting")
	# No grain and no pops means no artificial fallback production.
	var empty = ReservationSimulation.new()
	empty.start(0)
	var events: Array = []
	empty._consume_stock("blue", {"grain":empty.state.market.grain}, "fixture", events)
	expose(empty,["hut_1","grain_farm","brick_kiln","pottery_workshop"])
	check(empty.legal_actions() == [{"type":"pass"}], "grain/pop bootstrap deadlock is exposed")
	check(empty.violations().is_empty(), "depleted stock still accounts")

func run() -> void:
	fixtures()
	if "--fixtures-only" in OS.get_cmdline_user_args():
		print(JSON.stringify({"fixtures":checks,"failures":failures}))
		quit(0 if failures.is_empty() else 1)
		return
	if "--verify-existing" in OS.get_cmdline_user_args():
		verify_existing()
		return
	var games: Array = []
	var total_decisions = 0
	for locale in ["river_valley","northern_woodland"]:
		for seed_value in [1,7,42]:
			var sim = ReservationSimulation.new()
			sim.start(seed_value,locale)
			var probe = GameProbe.new()
			probe.policy = ReservationAI.new()
			var folder = "res://experiments/reservations/evidence/%s_%d" % [locale,seed_value]
			probe.attach(sim,folder + "/decisions.jsonl")
			var timeline: Array = []
			var economics_this_round = 0
			var foreign_hut_uses = 0
			var unused_influence_sources = true
			while sim.state.round <= 40 and probe.failure == "":
				var action: Dictionary = probe.policy.decide(sim).chosen
				if action.type == "activate" and sim.is_housing(action.building) and sim.state.buildings[action.building].owner not in ["",sim.current_house().id]:
					foreign_hut_uses += 1
				if action.type not in ["pass","claim"]:
					economics_this_round += 1
				var result = probe.step()
				if result.get("round_closed", false):
					var row = status(sim)
					row.completed_round = int(sim.state.round) - 1
					row.economic_actions = economics_this_round
					timeline.append(row)
					economics_this_round = 0
					if sim.state.round == 11:
						check(probe.save_game(folder + "/checkpoint.json") == OK, "save reservation run")
						var loaded = ReservationSimulation.new()
						var loader = GameProbe.new()
						loader.policy = ReservationAI.new()
						loader.attach(loaded)
						check(loader.load_game(folder + "/checkpoint.json") == OK, "load reservation run")
						check(probe.policy.decide(sim).chosen == loader.policy.decide(loaded).chosen, "loaded decision matches")
						var copy = ReservationSimulation.new()
						copy.restore(sim.snapshot())
						var choice: Dictionary = loader.policy.decide(loaded).chosen
						copy.apply(choice)
						loaded.apply(choice)
						check(TownSimulation.canonical(copy.snapshot()) == TownSimulation.canonical(loaded.snapshot()), "loaded next state matches")
			var summary = probe.summary()
			summary.town = status(sim)
			summary.timeline = timeline
			summary.reservations = sim.state.reservation_metrics.duplicate(true)
			summary.pop_granted = sim.state.pop_granted
			summary.pop_worked = sim.state.pop_worked
			summary.foreign_hut_uses = foreign_hut_uses
			var file = FileAccess.open(folder + "/summary.json",FileAccess.WRITE)
			file.store_string(JSON.stringify(summary,"\t"))
			file.close()
			probe.save_game(folder + "/save.json")
			check(probe.failure == "" and sim.state.round == 41, "forty rounds without invariant failures")
			check(GameProbe.replay_journal(folder + "/decisions.jsonl").ok, "full reservation journal replay")
			var pass_count = int(probe.metrics.actions.get("pass",0))
			check(sim.state.ledger.influence.created == pass_count, "passes are the only influence source")
			check(sim.state.ledger.influence.consumed == int(probe.metrics.actions.get("claim",0)) * 3, "every claim costs three influence")
			total_decisions += int(sim.state.sequence)
			games.append(summary)
	var report = {"experiment":"urban_rural_reservations_v1","rounds_per_game":40,"games":games,"checks":checks,"failures":failures,"total_decisions":total_decisions}
	var file = FileAccess.open("res://experiments/reservations/results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print(JSON.stringify({"games":games.size(),"rounds_per_game":40,"checks":checks,"failures":failures,"total_decisions":total_decisions}))
	quit(0 if failures.is_empty() else 1)

func status(sim: ReservationSimulation) -> Dictionary:
	var houses: Array = []
	var built: Array = []
	for h in sim.state.houses:
		houses.append({"id":h.id,"owned_huts":sim.owned_huts(h.id).size(),"upgraded_huts":sim.owned_huts(h.id,true).size(),"influence":h.inventory.influence,"first_claim_round":h.first_claim_round,"first_upgrade_round":h.first_upgrade_round})
	for id in sim._sorted_keys(sim.state.buildings):
		if sim.state.buildings[id].built:
			built.append({"id":id,"owner":sim.state.buildings[id].owner,"level":sim.state.buildings[id].level,"plot":sim.state.buildings[id].plot})
	return {"houses":houses,"stock":sim.state.market.duplicate(true),"terrain_free":sim.state.terrain_free.duplicate(true),"built":built,"deck_size":sim.state.deck.size()+sim.state.discard.size()+sim.state.revealed.size()}

func verify_existing() -> void:
	var report = JSON.parse_string(FileAccess.get_file_as_string("res://experiments/reservations/results.json"))
	for game in report.games:
		var folder = "res://experiments/reservations/evidence/%s_%d" % [game.locale,int(game.seed)]
		check(FileAccess.file_exists(folder + "/checkpoint.json"), "checkpoint was written")
		var sim = ReservationSimulation.new()
		var probe = GameProbe.new()
		probe.policy = ReservationAI.new()
		probe.attach(sim)
		check(probe.load_game(folder + "/checkpoint.json") == OK, "checkpoint loads")
		var checkpoint_sequence = int(sim.state.sequence)
		var expected: Dictionary = {}
		var journal = FileAccess.open(folder + "/decisions.jsonl",FileAccess.READ)
		while not journal.eof_reached():
			var line = journal.get_line()
			if line.is_empty(): continue
			var record = JSON.parse_string(line)
			if record.kind == "decision" and int(record.sequence) == checkpoint_sequence + 1:
				expected = record
				break
		check(probe.policy.decide(sim).chosen == expected.decision.chosen, "saved next decision agrees with recorded game")
		sim.apply(expected.decision.chosen)
		check(TownSimulation.canonical(sim.snapshot()) == TownSimulation.canonical(expected.snapshot), "saved next state agrees with recorded game")
		sim.restore(JSON.parse_string(FileAccess.get_file_as_string(folder + "/save.json")))
		check(sim.violations().is_empty() and sim.state.round == 41, "final state invariant check")
		check(GameProbe.replay_journal(folder + "/decisions.jsonl").ok, "recorded full game replays")
		check(sim.state.ledger.influence.created == game.metrics.actions.get("pass",0), "influence source is pass only")
		check(sim.state.ledger.influence.consumed == game.metrics.actions.get("claim",0) * 3, "claim influence expenditure")
	if not report.failures.is_empty():
		report.initial_verification_failures = report.failures.duplicate()
	report.failures = failures
	report.checks = checks
	report.verification_note = "Simultaneous input consumption now uses a stable resource order, preserving original logs through JSON key sorting. Six journals and checkpoints reverified without rerunning AI games."
	var output = FileAccess.open("res://experiments/reservations/results.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t"))
	output.close()
	print(JSON.stringify({"checks":checks,"failures":failures,"games_replayed":report.games.size(),"additional_ai_games":0}))
	quit(0 if failures.is_empty() else 1)

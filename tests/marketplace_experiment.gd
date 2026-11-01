extends SceneTree
var checks = 0
var failures: Array = []
func check(condition: bool,label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error(label)
func _initialize() -> void: call_deferred("run")
func expose(sim: MarketplaceSimulation,ids: Array) -> void:
	sim.state.deck = sim.state.deck+sim.state.discard+sim.state.revealed
	sim.state.discard = []
	sim.state.revealed = []
	for id in ids:
		sim.state.deck.erase(id)
		sim.state.revealed.append(id)
func fund(sim: MarketplaceSimulation,id: String,amount: int) -> void:
	var events: Array = []
	sim._gain_influence(id,amount,"fixture",events)
func fresh(link: bool = false) -> MarketplaceSimulation:
	var sim = MarketplaceSimulation.new()
	sim.rules.all_houses_goal = false
	sim.scenario_lumber_link = link
	sim.start(1)
	return sim
func fixtures() -> void:
	var sim = fresh()
	check(sim.violations().is_empty(),"initial latest-core invariants")
	check(sim.state.market.clay == 0 and sim.state.market.brick == 0 and not sim.definitions.has("clay_pit"),"no local clay or initial bricks")
	var plot_count = 0
	for count in sim.rules.locales.clayless_valley.terrain.values(): plot_count += int(count)
	check(plot_count == 10 and sim.state.buildings.chapel.plot == "special","ten ordinary plots plus free chapel")
	fund(sim,"blue",3)
	expose(sim,["chapel","lumber_camp","grain_farm","hut_1"])
	sim.state.actor = 0
	check(not {"type":"claim","building":"chapel"} in sim.legal_actions(),"chapel unownable")
	var start_inf = int(sim.house("blue").inventory.influence)
	sim.apply({"type":"pass"})
	sim.apply({"type":"activate","building":"grain_farm","mode":"basic"})
	check("grain_farm" not in sim.state.revealed and "grain_farm" in sim.state.discard,"activation immediately discards card")
	sim.apply({"type":"pass"})
	check(sim.state.round == 1 and sim.current_house().id == "blue","passing skips and permits re-entry")
	sim.apply({"type":"activate","building":"lumber_camp","mode":"basic"})
	check(sim.state.consecutive_passes == 0 and sim.state.access_metrics.reentries == 1,"an action resets consecutive pass chain")
	while sim.state.round == 1: sim.apply({"type":"pass"})
	check(sim.house("blue").inventory.influence == start_inf+1,"one eligible idle reward per round, no second reward after acting")
	check(sim.violations().is_empty(),"new pass/card timing conserves state")
	var finite = fresh()
	finite._add_lot("pop",6,"","fixture",0)
	check(finite.free_pop_tokens() == 0,"finite pop supply exhausted")
	expose(finite,["hut_1","chapel","grain_farm","carpenter"])
	finite.state.actor = 0
	check(not {"type":"activate","building":"hut_1","mode":"basic"} in finite.legal_actions(),"hut cannot create seventh token")
	finite.apply({"type":"take","resource":"pop"})
	check(finite.free_pop_tokens() == 0,"protected pop still counts toward local cap")
	finite._consume_plan("blue",finite.payment_plan("blue",{"pop":1}),[])
	check(finite.free_pop_tokens() == 1,"spent token returns to unissued reserve")
	finite.state.buildings.hut_1.level = 2
	finite.state.actor = 0
	check({"type":"activate","building":"hut_1","mode":"basic"} in finite.legal_actions(),"upgraded hut retains lower-output option")
	finite.apply({"type":"activate","building":"hut_1","mode":"basic"})
	check(finite.free_pop_tokens() == 0 and finite.violations().is_empty(),"housing regenerates without exceeding token cap")
	var access = fresh()
	access._add_lot("furniture",1,"","fixture",0)
	access.state.actor = 0
	access.apply({"type":"take","resource":"furniture"})
	fund(access,"red",1)
	check(not access.payment_plan("red",{"furniture":1}).ok,"blocked stock requires two influence")
	fund(access,"red",1)
	var payment = access.payment_plan("red",{"furniture":1})
	check(payment.ok and payment.total_influence == 2 and payment.emergency_units == 1,"emergency use reaches protected stockpile at two influence")
	access._pay("red",payment,[])
	access._consume_plan("red",payment,[])
	check(access.house("blue").inventory.influence == 2 and access.house("blue").stockpile.furniture == 0,"override pays holder and uses token outright")
	check(access.violations().is_empty(),"override accounting")
	var conversion = fresh()
	fund(conversion,"blue",5)
	conversion.state.actor = 0
	check(conversion.apply({"type":"convert_prestige"}).ok,"voluntary one-way prestige conversion")
	check(conversion.house("blue").inventory.prestige == 1 and conversion.house("blue").inventory.influence == 0,"five influence becomes one prestige")
	var before = TownSimulation.canonical(conversion.snapshot())
	check(not conversion.apply({"type":"convert_influence"}).ok and before == TownSimulation.canonical(conversion.snapshot()),"reverse conversion does not exist and rejects atomically")
	# Scripted prerequisite chain tests the scenario; fixture resources are ledgered.
	var goal = fresh()
	expose(goal,["hut_1","carpenter","lumber_camp","chapel"])
	goal.state.actor = 0
	fund(goal,"blue",3)
	goal.apply({"type":"claim","building":"hut_1"})
	goal.state.actor = 0
	goal.apply({"type":"activate","building":"hut_1","mode":"basic"})
	goal.state.actor = 0
	check(goal.apply({"type":"build_market"}).ok,"wood-only market bootstrap requires no brick")
	check(goal.house("blue").inventory.prestige == 2 and not goal.state.caravan.present,"market reward and no premature caravan")
	goal._close_round()
	check(goal.state.caravan.present and goal.state.round == 2,"caravan first arrives at next hand refresh")
	goal._add_lot("wood",3,"","fixture",0)
	goal._add_lot("pop",2,"","fixture",0)
	expose(goal,["hut_1","carpenter","lumber_camp","chapel"])
	goal.state.actor = 0
	check(goal.apply({"type":"activate","building":"carpenter","mode":"basic"}).ok,"carpenter makes wooden chest")
	goal.state.actor = 0
	check(goal.apply({"type":"secure_clay_contract"}).ok,"visiting caravan establishes clay link")
	check(goal.state.clay_deliveries == 1 and goal.state.committed_pops == 1 and goal.house("blue").inventory.prestige == 5,"first clay, labour commitment and contract prestige")
	check(not goal.state.ended,"import alone is not town completion")
	# Contract continuation is automatic when a future caravan can take public wood.
	var continuation = MarketplaceSimulation.new()
	continuation.restore(goal.snapshot())
	continuation._add_lot("wood",2,"","fixture",0)
	for i in range(3): continuation._close_round()
	check(continuation.state.round == 5 and continuation.state.clay_deliveries == 2,"future caravan performs automatic wood-for-clay shipment")
	check(continuation.violations().is_empty(),"automatic contract accounts for imports and exports")
	goal._add_lot("furniture",1,"","fixture",0)
	goal._add_lot("wood",2,"","fixture",0)
	goal._add_lot("pop",1,"","fixture",0)
	goal.state.actor = 0
	check(goal.apply({"type":"buy_brick"}).ok,"brick purchased by chest barter")
	goal.state.actor = 0
	check(goal.apply({"type":"upgrade","building":"hut_1"}).ok,"imported brick creates upgraded house")
	check(goal.state.ended and goal.state.end_reason == "clay_import_and_brick_house","town goal ends scenario immediately")
	check(goal.house("blue").inventory.prestige == 10 and goal.legal_actions().is_empty(),"three milestone rewards and no moves after terminal state")
	check(goal.violations().is_empty(),"final scenario invariants")
	var stopped_probe = GameProbe.new()
	stopped_probe.policy = MarketplaceAI.new()
	stopped_probe.attach(goal)
	stopped_probe.run_rounds(1)
	check(stopped_probe.metrics.decisions == 0 and stopped_probe.failure == "", "probe also stops at scenario terminal condition")
	var linked = fresh(true)
	check(linked.state.linked_assets == ["lumber_camp"] and linked.free_pop_tokens() == 5,"preset lumber link commits one of six tokens")
	check("lumber_camp" not in linked.state.deck+linked.state.revealed+linked.state.discard,"linked source removed from manual rotation")
	check(linked.state.access_metrics.lumber_delivered == 1 and linked.violations().is_empty(),"lumber automatic supply and card identity")
	var free_use = fresh()
	expose(free_use,["hut_1","grain_farm","chapel","carpenter"])
	free_use.state.actor = 1
	free_use.state.buildings.grain_farm.owner = "blue"
	fund(free_use,"red",1)
	var turns = int(free_use.house("red").turns_taken)
	var used = free_use.apply({"type":"activate","building":"grain_farm","mode":"basic"})
	check(used.ok and used.free_action and free_use.current_house().id == "red", "latest core paid use retains normal turn")
	check(free_use.house("red").turns_taken == turns and free_use.house("blue").inventory.influence == 1, "free use transfers payment without advancing reservation timer")
	check("grain_farm" not in free_use.state.revealed, "paid free activation also discards its card")
	free_use.apply({"type":"pass"})
	check(free_use.house("red").inventory.influence == 0, "free-action-only house gets no idle-pass reward")
	free_use.state.buildings.hut_1.owner = "blue"
	free_use.state.buildings.hut_1.level = 2
	check(not free_use.chapel_eligible("blue") and free_use.chapel_eligible("red"), "chapel catches up houses with fewer upgraded huts")
	check(free_use.violations().is_empty(), "paid action and catch-up eligibility accounting")
func run() -> void:
	fixtures()
	if "--fixtures-only" in OS.get_cmdline_user_args():
		print(JSON.stringify({"checks":checks,"failures":failures}))
		quit(0 if failures.is_empty() else 1)
		return
	var games: Array = []
	var total_decisions = 0
	for seed_value in [1,7,42]:
		for link in [false,true]:
			var sim = MarketplaceSimulation.new()
			sim.rules.all_houses_goal = false
			sim.scenario_lumber_link = link
			sim.start(seed_value)
			var probe = GameProbe.new()
			probe.policy = MarketplaceAI.new()
			var folder = "res://experiments/marketplace/evidence/seed_%d_%s" % [seed_value,"linked" if link else "manual"]
			probe.attach(sim,folder+"/decisions.jsonl")
			var timeline: Array = []
			var saved_checkpoint = false
			while not sim.state.ended and sim.state.round <= rules_max_rounds(sim) and probe.failure == "":
				if sim.state.sequence > 12000:
					probe.failure = "diagnostic watchdog: excessive actions, no forced completion"
					break
				var result = probe.step()
				if result.get("round_closed",false): timeline.append(status(sim))
				if not saved_checkpoint and sim.state.sequence >= 12 and not sim.state.ended:
					check(probe.save_game(folder+"/checkpoint.json") == OK,"scenario checkpoint written")
					var restored = MarketplaceSimulation.new()
					var loader = GameProbe.new()
					loader.policy = MarketplaceAI.new()
					loader.attach(restored)
					check(loader.load_game(folder+"/checkpoint.json") == OK,"scenario checkpoint loaded")
					var choice: Dictionary = probe.policy.decide(sim).chosen
					check(choice == loader.policy.decide(restored).chosen,"saved scenario next decision")
					var clone = MarketplaceSimulation.new()
					clone.restore(sim.snapshot())
					clone.apply(choice)
					restored.apply(choice)
					check(TownSimulation.canonical(clone.snapshot()) == TownSimulation.canonical(restored.snapshot()),"saved scenario next state")
					saved_checkpoint = true
			var summary = probe.summary()
			summary.scenario = status(sim)
			summary.timeline = timeline
			summary.access = sim.state.access_metrics.duplicate(true)
			summary.milestones = sim.state.milestones.duplicate(true)
			summary.result = "completed" if sim.state.ended else "round_limit"
			var output = FileAccess.open(folder+"/summary.json",FileAccess.WRITE)
			output.store_string(JSON.stringify(summary,"\t"))
			output.close()
			probe.save_game(folder+"/save.json")
			check(probe.failure == "","scenario invariants through run")
			check(GameProbe.replay_journal(folder+"/decisions.jsonl").ok,"scenario full journal replay")
			total_decisions += int(sim.state.sequence)
			games.append(summary)
	var report = {"experiment":"marketplace_scenario_v1","max_rounds":40,"games":games,"checks":checks,"failures":failures,"total_decisions":total_decisions}
	var file = FileAccess.open("res://experiments/marketplace/results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print(JSON.stringify({"games":games.size(),"checks":checks,"failures":failures,"total_decisions":total_decisions}))
	quit(0 if failures.is_empty() else 1)
func rules_max_rounds(sim: MarketplaceSimulation) -> int: return int(sim.rules.max_rounds)
func status(sim: MarketplaceSimulation) -> Dictionary:
	return {"round":sim.state.round,"sequence":sim.state.sequence,"ended":sim.state.ended,"end_reason":sim.state.end_reason,"lumber_link":sim.state.lumber_link,"market_round":sim.state.market_round,"caravan":sim.state.caravan.duplicate(true),"clay_deliveries":sim.state.clay_deliveries,"committed_pops":sim.state.committed_pops,"pop_reserve":sim.free_pop_tokens(),"public_stock":sim.state.market.duplicate(true),"houses":sim.state.houses.duplicate(true),"milestones":sim.state.milestones.duplicate(true)}

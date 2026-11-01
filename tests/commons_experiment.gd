extends SceneTree
var checks = 0
var failures: Array = []
func check(condition: bool,label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error(label)
func _initialize() -> void:
	call_deferred("run")
func expose(sim: CommonsSimulation,ids: Array) -> void:
	sim.state.deck = sim.state.deck + sim.state.discard + sim.state.revealed
	sim.state.discard = []
	sim.state.revealed = []
	for id in ids:
		sim.state.deck.erase(id)
		sim.state.revealed.append(id)
func fund(sim: CommonsSimulation,id: String,n: int) -> void:
	var events: Array = []
	sim._gain_influence(id,n,"fixture",events)
func fixtures() -> void:
	var sim = CommonsSimulation.new()
	sim.start(0)
	expose(sim,["hut_1","grain_farm","chapel","brick_kiln"])
	sim.state.actor = 0
	check(sim.violations().is_empty(),"initial commons accounting")
	check(sim.state.buildings.chapel.built and sim.state.terrain_free.urban == 0,"bonus chapel occupies urban plot")
	sim.state.buildings.hut_1.level = 2
	var events: Array = []
	sim._consume_plan("blue",sim.payment_plan("blue",{"luxury":2}),events)
	check({"type":"activate","building":"hut_1","mode":"basic"} in sim.legal_actions(),"upgraded hut offers grain-only fallback")
	check(not {"type":"activate","building":"hut_1","mode":"enhanced"} in sim.legal_actions(),"missing luxury prevents enhanced hut recipe")
	sim.apply({"type":"activate","building":"hut_1","mode":"basic"})
	check(sim.state.market.pop == 1 and sim.state.access_metrics.hut_fallbacks == 1,"fallback provides one pop")
	fund(sim,"red",3)
	check(not {"type":"take","resource":"pop"} in sim.legal_actions(),"cannot pay to hoard rival reserved output")
	var result = sim.apply({"type":"activate","building":"brick_kiln","mode":"basic"})
	check(result.ok and sim.house("blue").inventory.influence == 1 and sim.house("red").inventory.influence == 2,"reserved pop used outright with direct influence transfer")
	check(sim.state.access_metrics.reserved_units_used == 1 and sim.state.market.pop == 0,"paid input immediately consumed")
	# Paid building activation is a free action; no competing bid or revocation exists.
	sim.state.buildings.grain_farm.owner = "blue"
	sim.state.actor = 1
	var turns = int(sim.house("red").turns_taken)
	result = sim.apply({"type":"activate","building":"grain_farm","mode":"basic"})
	check(result.ok and result.free_action and sim.current_house().id == "red","paid activation retains normal turn")
	check(sim.house("red").turns_taken == turns and sim.house("blue").inventory.influence == 2,"free use transfers influence without advancing normal-action reservation clock")
	check(not {"type":"activate","building":"grain_farm","mode":"basic"} in sim.legal_actions(),"owned building cannot activate twice in same round")
	var before = int(sim.house("red").inventory.influence)
	sim.apply({"type":"pass"})
	check(sim.house("red").inventory.influence == before,"working or free-acting house gets no pass influence")
	sim.apply({"type":"pass"})
	check(sim.house("gold").inventory.influence == 1,"idle pass earns one influence")
	sim.apply({"type":"pass"})
	check(sim.state.round == 2 and sim.state.market.brick == 3,"unspent resources persist across hand refresh")
	check(sim.violations().is_empty(),"access transfers and persistence conserve stocks")
	var farm = CommonsSimulation.new()
	farm.start(0)
	expose(farm,["grain_farm","hut_1","chapel","clay_pit"])
	farm.state.actor = 0
	var grain = int(farm.state.market.grain)
	farm.apply({"type":"activate","building":"grain_farm","mode":"basic"})
	check(farm.state.market.grain == grain+1 and farm.state.pop_worked == 0,"level-one rural yields one with no pop")
	farm.state.buildings.clay_pit.level = 2
	farm.state.actor = 0
	check({"type":"activate","building":"clay_pit","mode":"basic"} in farm.legal_actions(),"upgraded rural retains free basic output")
	check(not {"type":"activate","building":"clay_pit","mode":"enhanced"} in farm.legal_actions(),"enhanced rural requires one pop")
	farm._add_lot("pop",1,"","fixture",0)
	var clay = int(farm.state.market.clay)
	farm.apply({"type":"activate","building":"clay_pit","mode":"enhanced"})
	check(farm.state.market.clay == clay+2 and farm.state.market.pop == 0,"one pop enhances rural output to two")
	farm._add_lot("pop",2,"","fixture",0)
	while farm.state.round == 1: farm.apply({"type":"pass"})
	check(farm.state.market.pop == 2 and farm.state.reservation_metrics.expired_pops == 0,"pops also remain in general pile")
	var cap = CommonsSimulation.new()
	cap.start(0)
	expose(cap,["chapel","hut_1","grain_farm","clay_pit"])
	cap.state.actor = 0
	fund(cap,"blue",9)
	cap.apply({"type":"activate","building":"chapel","mode":"basic"})
	check(cap.house("blue").inventory.influence == 10 and cap.state.access_metrics.cap_overflow == 1,"chapel gives two with cap at ten")
	check(cap.violations().is_empty(),"cap overflow accounted")
	var safe = CommonsSimulation.new()
	safe.start(0)
	expose(safe,["hut_1","grain_farm","chapel","brick_kiln"])
	for resource in ["brick","wood","grain"]:
		safe.state.actor = 0
		check(safe.apply({"type":"take","resource":resource}).ok,"safekeeping action: "+resource)
	check(safe.pile_size("blue") == 3,"stockpile capacity is three total tokens")
	safe.state.actor = 0
	check(not {"type":"take","resource":"wood"} in safe.legal_actions(),"fourth stockpile token rejected")
	fund(safe,"red",10)
	check(not safe.payment_plan("red",{"brick":1}).ok,"influence cannot buy or seize protected stock")
	safe.state.actor = 1
	check(not {"type":"take","resource":"brick"} in safe.legal_actions(),"protected token is absent from rival take actions")
	safe.state.actor = 0
	safe.state.buildings.hut_1.owner = "blue"
	safe._add_lot("pop",1,"","fixture",0)
	check(safe.apply({"type":"upgrade","building":"hut_1"}).ok and safe.house("blue").stockpile.brick == 0,"owner may use own protected input")
	check(safe.violations().is_empty(),"protected goods and consumption conserve resources")
	# Restart from no grain/no pops using the level-one public farm.
	var restart = CommonsSimulation.new()
	restart.start(0)
	expose(restart,["grain_farm","hut_1","chapel","clay_pit"])
	restart.state.actor = 0
	restart._consume_plan("blue",restart.payment_plan("blue",{"grain":restart.state.market.grain}),[])
	check(restart.apply({"type":"activate","building":"grain_farm","mode":"basic"}).ok,"zero-pop zero-grain farm restart")
	check(restart.state.market.grain == 1,"restart produces grain without a labour prerequisite")
func run() -> void:
	fixtures()
	if "--fixtures-only" in OS.get_cmdline_user_args():
		print(JSON.stringify({"checks":checks,"failures":failures}))
		quit(0 if failures.is_empty() else 1)
		return
	var games: Array = []
	var decisions = 0
	for locale in ["river_valley","northern_woodland"]:
		for seed_value in [1,7,42]:
			var sim = CommonsSimulation.new()
			sim.start(seed_value,locale)
			var probe = GameProbe.new()
			probe.policy = CommonsAI.new()
			var folder = "res://experiments/commons/evidence/%s_%d" % [locale,seed_value]
			probe.attach(sim,folder+"/decisions.jsonl")
			var timeline: Array = []
			var economic = 0
			while sim.state.round <= 40 and probe.failure == "":
				if sim.state.sequence > 40000:
					probe.failure = "diagnostic watchdog: no round progress; no forced pass applied"
					break
				var result = probe.step()
				if result.get("ok",false) and result.event.action.type not in ["pass","claim","take","return"]: economic += 1
				if result.get("round_closed",false):
					var row = status(sim)
					row.completed_round = int(sim.state.round)-1
					row.economic_actions = economic
					economic = 0
					timeline.append(row)
					if sim.state.round == 11:
						check(probe.save_game(folder+"/checkpoint.json") == OK,"commons checkpoint written")
						var loaded = CommonsSimulation.new()
						var loader = GameProbe.new()
						loader.policy = CommonsAI.new()
						loader.attach(loaded)
						check(loader.load_game(folder+"/checkpoint.json") == OK,"commons checkpoint loads")
						var choice: Dictionary = probe.policy.decide(sim).chosen
						check(choice == loader.policy.decide(loaded).chosen,"loaded commons decision matches")
						var clone = CommonsSimulation.new()
						clone.restore(sim.snapshot())
						clone.apply(choice)
						loaded.apply(choice)
						check(TownSimulation.canonical(clone.snapshot()) == TownSimulation.canonical(loaded.snapshot()),"loaded commons next state matches")
			var summary = probe.summary()
			summary.town = status(sim)
			summary.timeline = timeline
			summary.access = sim.state.access_metrics.duplicate(true)
			summary.reservations = sim.state.reservation_metrics.duplicate(true)
			summary.pop_granted = sim.state.pop_granted
			summary.pop_worked = sim.state.pop_worked
			var out = FileAccess.open(folder+"/summary.json",FileAccess.WRITE)
			out.store_string(JSON.stringify(summary,"\t"))
			out.close()
			probe.save_game(folder+"/save.json")
			check(probe.failure == "" and sim.state.round == 41,"commons forty rounds with invariant checks")
			check(GameProbe.replay_journal(folder+"/decisions.jsonl").ok,"commons full journal replay")
			decisions += int(sim.state.sequence)
			games.append(summary)
	var report = {"experiment":"commons_access_v1","rounds_per_game":40,"games":games,"checks":checks,"failures":failures,"total_decisions":decisions}
	var output = FileAccess.open("res://experiments/commons/results.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t"))
	output.close()
	print(JSON.stringify({"games":games.size(),"checks":checks,"failures":failures,"total_decisions":decisions}))
	quit(0 if failures.is_empty() else 1)
func status(sim: CommonsSimulation) -> Dictionary:
	var houses: Array = []
	var built: Array = []
	for h in sim.state.houses:
		houses.append({"id":h.id,"owned_huts":sim.owned_huts(h.id).size(),"upgraded_huts":sim.owned_huts(h.id,true).size(),"influence":h.inventory.influence,"stockpile":h.stockpile.duplicate(true),"first_claim_round":h.first_claim_round,"first_upgrade_round":h.first_upgrade_round})
	for id in sim._sorted_keys(sim.state.buildings):
		if sim.state.buildings[id].built: built.append({"id":id,"owner":sim.state.buildings[id].owner,"level":sim.state.buildings[id].level,"plot":sim.state.buildings[id].plot})
	return {"houses":houses,"stock":sim.state.market.duplicate(true),"terrain_free":sim.state.terrain_free.duplicate(true),"built":built}

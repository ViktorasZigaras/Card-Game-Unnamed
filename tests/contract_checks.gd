extends SceneTree
var checks = 0
var failures: Array = []
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func fresh() -> ContractSimulation:
	var sim = ContractSimulation.new()
	sim.start(1)
	sim._add_lot("wood",20,"","fixture",0)
	sim._add_lot("grain",10,"","fixture",0)
	sim._add_lot("furniture",5,"","fixture",0)
	sim._add_lot("pop",4,"","fixture",0)
	sim.state.actor = 0
	sim.apply({"type":"build_market"})
	sim._close_round()
	sim.state.actor = 0
	sim._prestige("blue",20,"fixture",[])
	return sim
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for resource in ["wood","grain","furniture","pop","brick","luxury","clay"]:
		var sim = fresh()
		if resource == "pop": sim.state.buildings.hut_1.owner = "blue"
		var action = {"type":"secure_clay_contract"} if resource == "clay" else {"type":"secure_contract","resource":resource,"source":sim.source_for(resource,"blue")}
		var before = sim.total_physical(resource)
		check(sim.apply(action).ok,resource+" setup legal")
		check(not sim.contract_for(resource).is_empty(),resource+" contract present")
		check(sim.violations().is_empty(),resource+" setup accounting")
		var delivered_before = sim.state.economy.deliveries.get(resource,0)
		for i in range(3): sim._close_round()
		check(sim.state.economy.deliveries.get(resource,0) > delivered_before if resource != "clay" else sim.state.clay_deliveries > 1,resource+" automatic delivery")
		sim.state.actor = 0
		var commitment = sim.state.committed_pops
		var price = sim.cancel_price(resource)
		var prestige = sim.house("blue").inventory.prestige
		check(sim.apply({"type":"cancel_contract","resource":resource}).ok,resource+" cancellation legal")
		check(sim.contract_for(resource).is_empty() and sim.house("blue").inventory.prestige == prestige-price,resource+" paid removal")
		check(sim.state.committed_pops <= commitment and sim.violations().is_empty(),resource+" cancellation accounting")
	var sim = fresh()
	sim.state.buildings.hut_1.owner = "blue"
	check({"type":"demolish","building":"hut_1"} not in sim.legal_actions(),"owned building protected")
	check({"type":"demolish","building":"chapel"} not in sim.legal_actions(),"special chapel protected")
	for id in ["grain_farm","hut_2"]:
		sim.state.actor = 0
		var plot = sim.state.buildings[id].plot
		var space = sim.state.terrain_free[plot]
		var prestige = sim.house("blue").inventory.prestige
		check(sim.apply({"type":"demolish","building":id}).ok,"remove public "+id)
		check(not sim.state.buildings[id].built and sim.state.terrain_free[plot] == space+1,"plot reclaimed "+id)
		check(prestige-sim.house("blue").inventory.prestige == (1 if id == "grain_farm" else 3),"rural/urban cost "+id)
	check(sim.violations().is_empty(),"demolition accounting")
	sim = fresh()
	sim.house("blue").stockpile.grain = 3
	# Move fixture grain from public supply into stockpile rather than minting it.
	var plan = sim.public_plan({"grain":3})
	sim._consume_plan("blue",plan,[])
	sim.state.ledger.grain.consumed -= 3
	check(sim.apply({"type":"bulk_exchange"}).ok,"three-token exchange")
	check(sim.house("blue").stockpile.grain == 0 and sim.house("blue").inventory.influence == 3,"three goods for three influence")
	check(sim.violations().is_empty(),"bulk accounting")
	sim = fresh()
	var action = {"type":"secure_contract","resource":"furniture","source":"carpenter"}
	sim.apply(action)
	var plan2 = sim.public_plan({"wood":int(sim.state.market.wood)})
	sim._consume_plan("blue",plan2,[])
	var delivered = sim.state.economy.deliveries.get("furniture",0)
	sim._close_round()
	check(sim.state.economy.deliveries.get("furniture",0) == delivered and sim.state.economy.misses.furniture == 1,"missing upkeep pauses contract")
	check(sim.violations().is_empty(),"paused contract accounting")
	var snapshot = TownSimulation.canonical(sim.snapshot())
	check(not sim.apply({"type":"demolish","building":"carpenter"}).ok and snapshot == TownSimulation.canonical(sim.snapshot()),"active source removal rejected atomically")
	var denied = ContractSimulation.new()
	denied.start(1)
	check({"type":"secure_contract","resource":"brick","source":"marketplace"} not in denied.legal_actions(),"no imports before marketplace/caravan")
	var efficient = ContractSimulation.new()
	efficient.batch = 3
	efficient.start(7)
	check(efficient.rules.contract_specs.furniture.upkeep == {"wood":1},"batch three discounted workshop recipe")
	print(JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

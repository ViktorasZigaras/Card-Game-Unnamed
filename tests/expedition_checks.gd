extends SceneTree
var checks = 0
var failures: Array = []
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func fresh(seed_value: int = 7) -> ExpeditionSimulation:
	var s = ExpeditionSimulation.new()
	s.batch = 3
	s.rules.town_wood_sweep = false
	s.start(seed_value)
	return s
func act(s: ExpeditionSimulation,a: Dictionary,actor: int = 0) -> Dictionary:
	s.state.actor = actor
	return s.apply(a)
func expose(s: ExpeditionSimulation,id: String) -> void:
	for pile in [s.state.deck,s.state.discard,s.state.revealed]:
		while id in pile: pile.erase(id)
	s.state.revealed.append(id)
	s.state.used.erase(id)
func fund(s: ExpeditionSimulation,r: String,n: int) -> void:
	s._add_lot(r,n,"","test_fixture",0)
	if r == "planks": s.state.houseworks.planks_made += n
	if r == "stone": s.state.project_metrics.stone_bought += n
	if r == "clay": s.state.clay_deliveries += n
	if r == "brick": s.state.capacity.kiln_bricks += n
func gold(s: ExpeditionSimulation,id: String,n: int) -> void:
	s.house(id).inventory.gold += n
	s.state.trade.gold_minted += n
func build(s: ExpeditionSimulation,id: String,actor: int = 0) -> void:
	var h: Dictionary = s.state.houses[actor]
	s._gain_influence(h.id,3,"test_fixture",[])
	for r in s.site_cost(id): fund(s,r,int(s.site_cost(id)[r]))
	check(act(s,{"type":"claim_site","building":id,"replace":""},actor).ok,"claim "+id)
	expose(s,id)
	check(act(s,{"type":"supply_site","building":id,"bundle":s.site_cost(id)},actor).ok,"build "+id)
func tick(s: ExpeditionSimulation,n: int) -> void:
	for i in n: s.apply({"type":"pass"})
func exact(s: ExpeditionSimulation,label: String) -> void:
	var clone = ExpeditionSimulation.new()
	clone.restore(JSON.parse_string(JSON.stringify(s.snapshot())))
	check(TownSimulation.canonical(s.snapshot()) == TownSimulation.canonical(clone.snapshot()) and clone.violations().is_empty(),label)
func market_fixture(s: ExpeditionSimulation) -> void:
	var t = s.trip_for("blue")
	t.buy = [{"resource":"clay","price":1,"left":2,"contracted":false},{"resource":"stone","price":1,"left":2,"contracted":false}]
	t.sell = [{"resource":"wood","price":1,"left":2},{"resource":"grain","price":1,"left":2}]
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var s = fresh()
	check(s.violations().is_empty(),"fresh schema15 invariants")
	check(s.transport_free("blue") == 0 and {"type":"launch_expedition"} not in s.legal_actions(),"hall required for land transport")
	s._gain_influence("blue",3,"test_fixture",[])
	var free_before = s.state.terrain_free.urban
	var wood_before = s.total_physical("wood")
	check(act(s,{"type":"claim_site","building":"marketplace","replace":""}).ok,"social site claim before materials")
	check(not s.state.buildings.marketplace.built and s.state.houseworks.sites.marketplace.paid.is_empty(),"claim does not build or consume construction materials")
	check(s.total_physical("wood") == wood_before and s.state.terrain_free.urban == free_before-1,"social action reserves plot only")
	s._prestige("red",20,"test_fixture",[])
	s.state.actor = 1
	check(not s.legal_actions().any(func(a): return a.get("replace","") == "marketplace" or (a.type == "demolish" and a.building == "marketplace")),"ongoing site protected from overbuilding and demolition")
	exact(s,"reserved empty site exact save")
	fund(s,"pop",1)
	expose(s,"marketplace")
	check(act(s,{"type":"supply_site","building":"marketplace","bundle":s.rules.market_cost}).ok,"separate physical marketplace construction")
	check(s.state.buildings.marketplace.built and s.violations().is_empty(),"partial-market passive card accounting")
	s = fresh()
	build(s,"small_sawmill")
	s._prestige("blue",1,"test_fixture",[])
	var a = s.legal_actions().filter(func(x): return x.type == "demolish" and str(x.building) == "small_sawmill")
	s.state.actor = 0
	a = s.legal_actions().filter(func(x): return x.type == "demolish" and str(x.building) == "small_sawmill")
	check(not a.is_empty() and s.apply(a[0]).ok,"completed public sawmill can be demolished")
	check(not s.state.houseworks.sites.has("small_sawmill") and s.violations().is_empty(),"demolition removes stale completed record, preserves accounting")
	s._gain_influence("blue",1,"test_fixture",[])
	s.state.actor = 0
	check(s.legal_actions().any(func(x): return x.type == "claim_site" and x.building == "small_sawmill" and x.replace == ""),"demolished sawmill can be rebuilt")
	s = fresh()
	build(s,"hall_blue")
	build(s,"hall_red",1)
	s._gain_influence("gold",3,"test_fixture",[])
	s._prestige("gold",3,"test_fixture",[])
	s.state.buildings.hut_3.owner = "gold"
	s.state.buildings.hut_3.level = 2
	s.state.buildings.grain_farm.owner = "gold"
	s.state.actor = 2
	var future_plan = DevelopmentAI.new().development_plan(s)
	check(future_plan.route == "town expansion","prefer still-available expansion before brute urban clearance")
	check(act(s,{"type":"claim_site","building":"hall_gold","replace":"carpenter"},2).ok,"third hall obtains occupied unowned urban site")
	check(not s.state.buildings.carpenter.built and not s.state.buildings.hall_gold.built,"replacement clears first; no instant new building")
	check(s.house("gold").inventory.prestige == 0 and s.house("gold").inventory.influence == 0,"social clearing and claim costs consumed")
	check(s.violations().is_empty(),"replacement plot and sunk progress accounting")
	fund(s,"wood",4);fund(s,"pop",2)
	s.state.actor = 0
	check(s.unlock_recipe("blue","brick") and s.state.houseworks.unlocked.gold.has("brick"),"recipe unlock global and permanent")
	s = fresh()
	fund(s,"wood",8);fund(s,"pop",2)
	act(s,{"type":"secure_contract","resource":"wood","source":"lumber_camp"})
	for i in range(6): act(s,{"type":"supply_wood"})
	fund(s,"stone",1);fund(s,"pop",1)
	var fee = s.clear_price("lumber_camp")
	s._prestige("blue",fee,"test_fixture",[])
	check(act(s,{"type":"redevelop_occupied","building":"lumber_camp"}).ok,"occupied contracted rural plot may convert at combined price")
	check(not s.state.buildings.lumber_camp.built and s.contract_for("wood").is_empty(),"combined clearing cancels dependent contract")
	check(s.state.committed_pops == 0 and s.conversion_count() == 1 and s.violations().is_empty(),"cancellation releases capacity and conversion balances")
	s = fresh()
	build(s,"hall_blue")
	check(s.transport_free("blue") == 1,"completed hall gives one land capacity")
	fund(s,"pop",3)
	act(s,{"type":"take","resource":"grain"});act(s,{"type":"take","resource":"grain"})
	var pop_before = s.total_physical("pop")
	var pop_consumed = s.state.ledger.pop.consumed
	check(act(s,{"type":"launch_expedition"}).ok,"launch uses provisions and manned transport")
	var trip = s.trip_for("blue")
	check(trip.status == "outbound" and trip.buy.is_empty(),"no trade before arrival")
	check(s.total_physical("pop") == pop_before-1 and s.state.ledger.pop.consumed == pop_consumed,"crew held, not destroyed as work")
	check(s.state.exploration.crew == 1 and s.transport_free("blue") == 0,"crew and transport unavailable during journey")
	s.state.actor = 0
	check({"type":"launch_expedition"} not in s.legal_actions(),"cannot double-book transport")
	exact(s,"outbound save/load exact")
	tick(s,5)
	check(trip.status == "outbound","outbound journey requires all six future normal actions")
	tick(s,1)
	check(trip.status == "trading" and trip.buy.size() == 2 and trip.sell.size() == 2,"arrival creates two buying and two selling offers")
	var resources: Array = []
	for offer in trip.buy+trip.sell: resources.append(offer.resource)
	check(resources.size() == 4 and resources.duplicate().filter(func(r): return resources.count(r) == 1).size() == 4,"four distinct known material offers")
	var before = TownSimulation.canonical(s.snapshot())
	s.legal_actions();s.legal_actions()
	check(before == TownSimulation.canonical(s.snapshot()),"inspection does not reroll offers or advance time")
	market_fixture(s)
	gold(s,"blue",3)
	var public_wood = 0
	for lot in s.state.lots:
		if lot.resource == "wood" and lot.reserved_for == "": public_wood += int(lot.amount)
	if public_wood > 0: s._consume_plan("town",s.public_plan({"wood":public_wood}),[])
	fund(s,"wood",1)
	act(s,{"type":"take","resource":"wood"},1)
	s._gain_influence("blue",2,"test_fixture",[])
	var red_inf = s.house("red").inventory.influence
	check(act(s,{"type":"expedition_sell","offer":0}).ok,"expedition may sell rival-stored input through paid access")
	check(s.house("red").stockpile.wood == 0 and s.house("red").inventory.influence == red_inf+2,"sale pays holder, immediately consumes its token")
	check(act(s,{"type":"expedition_buy","offer":0}).ok and act(s,{"type":"expedition_buy","offer":1}).ok,"finite goods purchases at destination")
	check(trip.cargo == {"clay":1,"stone":1} and s.state.exploration.imports.clay == 0,"purchases held as cargo until home")
	exact(s,"trading cargo save exact")
	check(act(s,{"type":"return_expedition"}).ok,"return can be ordered explicitly")
	tick(s,5)
	check(trip.status == "returning" and s.transport_free("blue") == 0,"return takes time; capacity not released early")
	tick(s,1)
	check(trip.status == "home" and trip.cargo.is_empty() and s.state.exploration.crew == 0,"return delivers cargo and returns crew")
	check(s.house("blue").stockpile.clay == 1 and s.pile_size("blue") == 3,"purchases fill available private storage")
	check(s.state.lots.any(func(l): return l.resource == "stone" and l.source == "expedition_purchase" and l.reserved_for == ""),"purchase overflow goes to unreserved public pile")
	check(s.transport_free("blue") == 1 and s.violations().is_empty(),"uncontracted trip releases land capacity and conserves tokens")
	exact(s,"home cargo and crew save exact")
	s = fresh()
	build(s,"hall_blue")
	build(s,"hall_red",1)
	fund(s,"pop",3)
	gold(s,"blue",2)
	s._prestige("blue",3,"test_fixture",[])
	act(s,{"type":"launch_expedition"})
	tick(s,6)
	market_fixture(s)
	trip = s.trip_for("blue")
	s.state.actor = 0
	check(ExpeditionAI.new().decide(s).chosen == {"type":"expedition_contract","offer":0},"AI attempts funded needed clay contract when offered")
	check(act(s,{"type":"expedition_contract","offer":0.0}).ok,"secure owned clay supply; saved numeric offer accepted")
	var route: Dictionary = s.state.exploration.routes[0]
	var old_actor = s.state.actor
	s.state.actor = 0
	s.state.buildings.hut_1.owner = "blue"
	s.state.buildings.hut_1.level = 2
	s.state.buildings.lumber_camp.owner = "blue"
	s.state.caravan.present = true
	gold(s,"blue",1)
	var policy = ExpeditionAI.new().decide(s)
	check(policy.candidates.any(func(c): return c.action.type == "buy_prestige" and c.score < 0),"AI protects route operating gold from prestige purchase")
	s.house("blue").inventory.gold -= 1
	s.state.trade.gold_minted -= 1
	s.state.caravan.present = false
	s.state.actor = old_actor
	check(route.owner == "blue" and route.active and route.next_round == -1,"contract owned immediately; delivery waits for return")
	check(s.state.exploration.clay_rewarded and s.state.exploration.clay_reward_events.size() == 1,"town rewards needed clay contract once")
	check(s.transport_used("blue") == 1,"trip and its route share one capacity, not two")
	act(s,{"type":"return_expedition"})
	tick(s,6)
	check(s.state.exploration.crew == 0 and s.transport_free("blue") == 0,"crew returns but standing contract keeps transport bound")
	var clay_before = s.total_physical("clay")-int(route.delivered)
	if route.delivered == 0: s._close_round()
	check(route.delivered == 1 and s.total_physical("clay") == clay_before+1,"standing route imports a real unit at next refresh")
	check(s.state.lots.any(func(l): return l.resource == "clay" and l.source == "expedition_route" and l.reserved_for == "blue"),"owned contract has automatic one-token priority")
	s._close_round()
	check(route.misses > 0 and route.delivered == 1,"unfunded recurring import misses rather than creates free supply")
	s._prestige("red",int(route.price),"test_fixture",[])
	check(act(s,{"type":"buy_route","route":int(route.id)},1).ok,"standing route can be bought out for rising prestige price")
	check(route.owner == "red" and s.transport_free("red") == 0 and s.transport_free("blue") == 1,"buyout transfers transport obligation and output priority")
	s._prestige("blue",int(route.price)+3,"test_fixture",[])
	check(act(s,{"type":"cancel_route","route":int(route.id)}).ok,"costly route cancellation")
	check(s.transport_free("red") == 1 and not route.active,"cancellation releases standing transport")
	check(s.violations().is_empty(),"trade gold, crew, transport and ownership invariants")
	exact(s,"routes and cancellation exact save")
	s = fresh()
	build(s,"hall_blue")
	fund(s,"pop",3);fund(s,"wood",3)
	s.state.buildings.carpenter.owner = "red"
	s._gain_influence("blue",2,"test_fixture",[])
	act(s,{"type":"launch_expedition"})
	expose(s,"carpenter")
	var clock = s.state.exploration.clock
	check(act(s,{"type":"activate","building":"carpenter","mode":"basic"}).ok,"paid rival activation remains free action")
	check(s.state.exploration.clock == clock,"free activation does not accelerate travel")
	tick(s,6)
	trip = s.trip_for("blue")
	check(trip.status == "trading","arrival after six actual normal actions")
	s.state.actor = 1
	check(not s.legal_actions().any(func(x): return x.type in ["expedition_buy","expedition_sell","expedition_contract"]),"offers are sponsor-specific")
	market_fixture(s)
	gold(s,"blue",3)
	act(s,{"type":"expedition_buy","offer":0})
	var left = trip.buy[0].left
	s._close_round()
	check(trip.buy[0].left == left,"round refresh does not renew finite offers")
	act(s,{"type":"expedition_buy","offer":0})
	s.state.actor = 0
	check({"type":"expedition_buy","offer":0} not in s.legal_actions(),"sold-out direct purchase cannot repeat")
	var actions_left = int(s.rules.expedition_trade_actions)-int(trip.market_actions)
	for i in actions_left: act(s,{"type":"pass"})
	check(trip.status == "returning","finite sponsor-action window automatically starts return")
	tick(s,6)
	check(trip.status == "home" and s.violations().is_empty(),"automatic return delivers finite cargo and crew")
	s = fresh()
	build(s,"hall_blue");build(s,"hall_red",1)
	for actor in [0,1]:
		var id: String = s.state.houses[actor].id
		fund(s,"pop",2);gold(s,id,3)
		s._prestige(id,3,"test_fixture",[])
		act(s,{"type":"launch_expedition"},actor)
		tick(s,6)
		var t = s.trip_for(id)
		t.buy = [{"resource":"clay","price":1,"left":2,"contracted":false},{"resource":"stone","price":1,"left":2,"contracted":false}]
		check(act(s,{"type":"expedition_contract","offer":0},actor).ok,"independent clay quantity binding "+id)
		act(s,{"type":"return_expedition"},actor)
		tick(s,6)
	check(s.state.exploration.routes.size() == 2 and s.state.exploration.routes.all(func(r): return r.active and r.resource == "clay"),"two independent sources may bind the same resource")
	check(s.transport_used("blue") == 1 and s.transport_used("red") == 1,"each quantity binding uses its owner's transport")
	check(s.state.exploration.clay_reward_events.size() == 1,"repeat clay contract does not farm town setup reward")
	check(s.violations().is_empty(),"multiple quantity routes remain conserved")
	exact(s,"multiple same-resource routes exact save")
	print(JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

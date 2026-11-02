extends SceneTree
var checks = 0
var failures: Array = []
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func fund(s: FinancingSimulation,r: String,n: int) -> void:
	s._add_lot(r,n,"","fixture",0)
	if r == "planks": s.state.houseworks.planks_made += n
	if r == "stone": s.state.project_metrics.stone_bought += n
	if r == "brick": s.state.capacity.kiln_bricks += n
func expose(s: FinancingSimulation,id: String) -> void:
	for pile in [s.state.deck,s.state.discard,s.state.revealed]:
		while id in pile: pile.erase(id)
	s.state.revealed.append(id)
	s.state.used.erase(id)
func act(s: FinancingSimulation,a: Dictionary,actor: int = 0) -> Dictionary:
	s.state.actor = actor
	return s.apply(a)
func build(s: FinancingSimulation,id: String) -> void:
	s._gain_influence("blue",3,"fixture",[])
	for r in s.site_cost(id): fund(s,r,int(s.site_cost(id)[r]))
	assert(act(s,{"type":"claim_site","building":id,"replace":""}).ok)
	expose(s,id)
	assert(act(s,{"type":"supply_site","building":id,"bundle":s.site_cost(id)}).ok)
func home(s: FinancingSimulation,actor: int) -> void:
	var h: Dictionary = s.state.houses[actor]
	var id = "hut_%d" % (actor+1)
	s._gain_influence(h.id,3,"fixture",[])
	expose(s,id)
	assert(act(s,{"type":"claim","building":id},actor).ok)
	for r in s.rules.housing_upgrade_cost: fund(s,r,int(s.rules.housing_upgrade_cost[r]))
	expose(s,id)
	assert(act(s,{"type":"upgrade","building":id},actor).ok)
func wallet(s: FinancingSimulation,cash: int,prestige: int) -> void:
	var h = s.house("blue")
	var delta = cash-int(h.inventory.gold)
	h.inventory.gold = cash
	s.state.trade.gold_minted += delta
	delta = prestige-int(h.inventory.prestige)
	if delta > 0: s._prestige("blue",delta,"fixture",[])
	elif delta < 0:
		h.inventory.prestige += delta
		s.state.ledger.prestige.consumed -= delta
func fixture(seed_value: int,bridge: bool) -> FinancingSimulation:
	var s = FinancingSimulation.new()
	s.batch = 3
	s.rules.town_wood_sweep = false
	s.start(seed_value)
	build(s,"marketplace")
	build(s,"hall_blue")
	home(s,0)
	if not bridge:
		home(s,1)
		home(s,2)
	s._gain_influence("blue",3,"fixture",[])
	expose(s,"lumber_camp")
	assert(act(s,{"type":"claim","building":"lumber_camp"}).ok)
	s.unlock_recipe("blue","brick")
	fund(s,"pop",3)
	wallet(s,5 if bridge else 3,8 if bridge else 12)
	assert(act(s,{"type":"launch_expedition"}).ok)
	for i in 6: s.apply({"type":"pass"})
	var t = s.trip_for("blue")
	assert(t.status == "trading")
	t.buy = [{"resource":"clay","price":1,"left":2,"contracted":false},{"resource":"stone","price":1,"left":2,"contracted":false}]
	t.sell = [{"resource":"wood","price":1,"left":0},{"resource":"grain","price":1,"left":0}]
	s.state.actor = 0
	assert(s.violations().is_empty(),str(s.violations()))
	return s
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var ai = FinancingAI.new()
	var s = fixture(7,true)
	var offer: Dictionary = s.trip_for("blue").buy[0]
	var before = TownSimulation.canonical(s.snapshot())
	var f = ai.assess_offer(s,offer)
	check(before == TownSimulation.canonical(s.snapshot()),"funding inspection leaves state and RNG unchanged")
	check(f.needed_units == 4 and f.operating_gold == 4 and f.forecast_rounds == 4,"goal-based bounded demand and payment forecast")
	check(f.guaranteed_recurring_gold == 0 and f.shared_export_upper_bound <= 2,"shared orders are not promised private income")
	check(f.optimistic_operating_balance < 0 and not f.recurring_sustainable,"current permanent route has negative operating ceiling")
	check(f.prefunded_bridge and f.exit_prestige == 8,"prepaid finite route is allowed with cancellation budget")
	check(ai.decide(s).chosen == {"type":"expedition_contract","offer":0},"choose real funded route over insufficient finite pair")
	wallet(s,3,8)
	check({"type":"expedition_contract","offer":0} in s.legal_actions(),"financing veto is advice/policy, not a changed contract rule")
	f = ai.assess_offer(s,offer)
	check(not f.prefunded_bridge and f.cash_shortfall == 2,"reject operating-cash shortfall despite affordable setup")
	wallet(s,5,3)
	f = ai.assess_offer(s,offer)
	check(not f.prefunded_bridge and f.exit_prestige_shortfall == 5,"reject route without real exit budget")
	wallet(s,5,8)
	s.state.exploration.clay_rewarded = true
	check(not ai.assess_offer(s,offer).prefunded_bridge,"do not assume clay reward repeats")
	s.state.exploration.clay_rewarded = false
	assert(act(s,{"type":"expedition_contract","offer":0}).ok)
	var route: Dictionary = s.state.exploration.routes[0]
	var budget = ai.route_budget(s,route)
	check(budget.target_units == 4 and budget.operating_reserve == 4 and budget.exit_reserve == 8,"funding and original goal observation persist on owned route")
	s.state.caravan.present = true
	s.state.caravan.stone_left = 2
	s.state.actor = 0
	var d = ai.decide(s)
	check(d.candidates.any(func(c): return c.action.type == "buy_prestige" and c.score < 0),"do not convert earmarked gold into prestige")
	check(d.candidates.any(func(c): return c.action.type == "buy_stone" and c.score < 0),"do not use operating money for discretionary stone")
	check(d.candidates.any(func(c): return c.action.type == "expedition_buy" and c.score < 0),"do not spend operating money on an extra cargo purchase")
	var clone = FinancingSimulation.new()
	clone.restore(JSON.parse_string(JSON.stringify(s.snapshot())))
	check(TownSimulation.canonical(budget) == TownSimulation.canonical(ai.route_budget(clone,clone.state.exploration.routes[0])),"same funding plan after save/load without hidden AI memory")
	wallet(s,0,8)
	check(ai.decide(s).chosen == {"type":"cancel_route","route":int(route.id)},"cancel own unfunded route before accumulating missed shipments")
	wallet(s,0,0)
	check(not ai.route_budget(s,route).exit_affordable,"cannot invent prestige for cancellation")
	s = fixture(7,false)
	offer = s.trip_for("blue").buy[0]
	f = ai.assess_offer(s,offer)
	check(f.needed_units == 2 and not f.prefunded_bridge,"finite offer covers bounded need; no transport binding")
	check(ai.decide(s).chosen == {"type":"expedition_buy","offer":0},"prefer finite cargo when sufficient")
	assert(act(s,{"type":"expedition_buy","offer":0}).ok)
	check(ai.needed_units(s,"clay") == 1,"count cargo already paid for but not yet returned")
	assert(act(s,{"type":"expedition_buy","offer":0}).ok)
	check(ai.needed_units(s,"clay") == 0,"do not buy beyond outstanding need")
	s.trip_for("blue").buy[1].left = 0
	s.state.actor = 0
	var departure = ai.decide(s)
	check(departure.candidates.any(func(c): return c.action.type == "return_expedition" and c.score > 0),"departure remains useful when financing rejects unavailable trades")
	var reports: Array = []
	for seed_value in [1,7,42]:
		for bridge in [false,true]:
			s = fixture(seed_value,bridge)
			var probe = GameProbe.new()
			probe.policy = FinancingAI.new()
			var folder = "res://experiments/financing_directed/seed_%d_%s" % [seed_value,"bridge" if bridge else "cargo"]
			probe.attach(s,folder+"/decisions.jsonl")
			var steps = 0
			while steps < 200 and probe.failure == "":
				if s.current_house().id == "blue": probe.step()
				else: probe.step({"type":"pass"})
				steps += 1
				if bridge:
					if not s.state.exploration.routes.is_empty() and not s.state.exploration.routes[0].active: break
				elif s.trip_for("blue").is_empty(): break
			check(probe.failure == "" and steps < 200,"directed case completed: %d %s" % [seed_value,bridge])
			var replay = GameProbe.replay_journal(folder+"/decisions.jsonl")
			check(replay.ok,"directed case exact replay")
			probe.save_game(folder+"/save.json")
			clone.restore(JSON.parse_string(FileAccess.get_file_as_string(folder+"/save.json")))
			check(TownSimulation.canonical(s.snapshot()) == TownSimulation.canonical(clone.snapshot()),"directed case exact save")
			if bridge:
				route = s.state.exploration.routes[0]
				check(route.delivered == 4 and route.misses == 0 and not route.active,"deliver bounded four-unit bridge then pay for exit")
				check(s.transport_free("blue") == 1,"bridge exit releases transport")
			else:
				check(s.state.exploration.routes.is_empty() and s.state.exploration.imports.clay == 2,"finite cargo without persistent obligations")
				check(s.transport_free("blue") == 1,"cargo return releases transport")
			reports.append({"seed":seed_value,"bridge":bridge,"steps":steps,"failure":probe.failure,"replay":replay,"imports":s.state.exploration.imports,"routes":s.state.exploration.routes,"free_land":s.transport_free("blue")})
	DirAccess.make_dir_recursive_absolute("res://experiments/financing_directed")
	FileAccess.open("res://experiments/financing_directed/results.json",FileAccess.WRITE).store_string(JSON.stringify(reports,"\t"))
	print(JSON.stringify({"checks":checks,"failures":failures,"directed":reports}))
	quit(0 if failures.is_empty() else 1)

extends SceneTree
var fx = preload("res://tests/flexible_fixture.gd").new()
func _initialize() -> void: call_deferred("run")
func setup(seed_value: int) -> FlexibleContractSimulation:
	var s: FlexibleContractSimulation = fx.fixture(seed_value,true,false)
	fx.build(s,"hall_red")
	s._gain_influence("blue",10,"fixture",[])
	s._gain_influence("red",10,"fixture",[])
	fx.wallet(s,12,12)
	fx.fund(s,"wood",2)
	fx.fund(s,"pop",5)
	fx.expose(s,"hut_1")
	assert(fx.act(s,{"type":"claim","building":"hut_1"}).ok)
	s.state.actor = 0
	assert(s.violations().is_empty(),str(s.violations()))
	return s
func sponsor(s: FlexibleContractSimulation) -> Dictionary:
	var legal = s.legal_actions()
	for a in legal:
		if a.type == "upgrade" and a.building == "hut_1": return a
	if s.owned_huts("blue",true).is_empty() and s.total_physical("brick") == 0:
		var work = {"type":"hall_work","building":"hall_blue","recipe":"brick"}
		if work in legal: return work
	if not s.state.exploration.routes.is_empty():
		var route: Dictionary = s.route_by_id(1)
		if route.active and (not s.owned_huts("blue",true).is_empty() or route.delivered >= 4):
			var cancel = {"type":"cancel_route","route":1}
			if cancel in legal: return cancel
	return {"type":"pass"}
func competitor(s: FlexibleContractSimulation,style: String) -> Dictionary:
	var action = {"type":"take","resource":"clay"} if style == "store" else {"type":"hall_work","building":"hall_red","recipe":"brick"}
	return action if action in s.legal_actions() else {"type":"pass"}
func trial(initial: Dictionary,access: String,style: String,seed_value: int) -> Dictionary:
	var s = FlexibleContractSimulation.new()
	s.restore(initial)
	var folder = "res://experiments/priority_competition/seed_%d_%s_%s" % [seed_value,style,access]
	var recommendation = PlannerAI.new().decide(s)
	var probe = GameProbe.new()
	probe.attach(s,folder+"/decisions.jsonl")
	assert(probe.step({"type":"expedition_contract","offer":0,"access":access}).ok)
	var home_round = 0
	var first_delivery = 0
	var start_round = int(s.state.round)
	var steps = 1
	var payments: Array = []
	while steps < 300 and probe.failure == "" and int(s.state.round) < start_round+12:
		var action = {"type":"pass"}
		if s.current_house().id == "blue":
			var trip = s.trip_for("blue")
			if not trip.is_empty() and trip.status == "trading": action = {"type":"return_expedition"}
			else: action = sponsor(s)
		elif s.current_house().id == "red": action = competitor(s,style)
		if not probe.step(action).ok: break
		steps += 1
		for event in probe.last_result.event.consequences:
			if event.type == "direct_use_payment": payments.append(event.duplicate(true))
		if s.route_by_id(1).delivered > 0 and first_delivery == 0: first_delivery = s.state.round
		if not s.owned_huts("blue",true).is_empty() and home_round == 0: home_round = s.state.round
		if not s.route_by_id(1).active and (home_round > 0 or s.state.round >= first_delivery+6): break
	var r = {"seed":seed_value,"style":style,"access":access,"planner_recommendation":recommendation.chosen,"steps":steps,"first_delivery_round":first_delivery,"home_round":home_round,"red_stored_clay":s.house("red").stockpile.clay,"route":s.route_by_id(1).duplicate(true),"gold_spent":s.state.exploration.gold_spent,"failure":probe.failure,"replay":GameProbe.replay_journal(folder+"/decisions.jsonl"),"payments":payments,"blue_access_paid":0,"blue_access_received":0,"invariants":s.violations()}
	for payment in payments:
		if payment.from == "blue": r.blue_access_paid += int(payment.amount)
		if payment.to == "blue": r.blue_access_received += int(payment.credited)
	var clone = FlexibleContractSimulation.new()
	clone.restore(JSON.parse_string(JSON.stringify(s.snapshot())))
	r.save_exact = TownSimulation.canonical(s.snapshot()) == TownSimulation.canonical(clone.snapshot())
	return r
func run() -> void:
	var reports: Array = []
	var failed = false
	for seed_value in [1,7,42]:
		for style in ["store","process"]:
			var initial = setup(seed_value).snapshot()
			var pair: Array = []
			for access in ["public","priority"]:
				var r = trial(initial,access,style,seed_value)
				failed = failed or r.failure != "" or not r.replay.ok or not r.save_exact or not r.invariants.is_empty() or r.steps >= 300 or r.home_round <= 0
				pair.append(r)
				reports.append(r)
			print(JSON.stringify({"seed":seed_value,"style":style,"public_home":pair[0].home_round,"priority_home":pair[1].home_round,"ok":not failed}))
	DirAccess.make_dir_recursive_absolute("res://experiments/priority_competition")
	FileAccess.open("res://experiments/priority_competition/results.json",FileAccess.WRITE).store_string(JSON.stringify(reports,"\t"))
	quit(1 if failed else 0)

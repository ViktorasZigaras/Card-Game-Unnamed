extends SceneTree
var fx = preload("res://tests/flexible_fixture.gd").new()
var checks = 0
var failures: Array = []
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var ai = PlannerAI.new()
	var s: FlexibleContractSimulation = fx.fixture(7,true,false)
	fx.wallet(s,12,12)
	s._gain_influence("blue",5,"fixture",[])
	var before = TownSimulation.canonical(s.snapshot())
	var value = ai.priority_value(s,"clay")
	check(ai.needed_units(s,"clay") > value.private_units and value.private_units == 1,"private and town-wide needs are distinct")
	check(value.access_cost_upper_influence == 2 and not value.justified,"one private input does not repay ownership and exit")
	check(value.delay_benefit_assumed == 0,"no invented timing or exclusivity")
	check(before == TownSimulation.canonical(s.snapshot()),"cost inspection is pure")
	check(ai.decide(s).chosen == {"type":"expedition_contract","offer":0,"access":"public"},"choose public bridge for this short private goal")
	assert(fx.act(s,{"type":"expedition_buy","offer":0}).ok)
	s.state.actor = 0
	check(ai.priority_value(s,"clay").private_units == 0,"paid incoming cargo counts toward private need")
	s = fx.fixture(7,true,false)
	var amount = int(s.state.market.wood)
	if amount > 0: s._consume_plan("town",s.public_plan({"wood":amount}),[])
	var h = s.house("blue")
	var delta = int(h.inventory.influence)-2
	h.inventory.influence = 2
	s.state.ledger.influence.consumed += delta
	value = ai.priority_value(s,"wood")
	check(value.private_units == 2 and value.access_liquidity_risk and value.justified,"several private access charges can exceed available influence")
	check(s.violations().is_empty(),"liquidity fixture conserves physical and social currencies")
	var out = {"checks":checks,"failures":failures}
	DirAccess.make_dir_recursive_absolute("res://experiments/priority_value")
	FileAccess.open("res://experiments/priority_value/results.json",FileAccess.WRITE).store_string(JSON.stringify(out,"\t"))
	print(JSON.stringify(out))
	quit(0 if failures.is_empty() else 1)

extends SceneTree
var checks = 0
var failures: Array = []
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func act(sim: PrioritySimulation,a: Dictionary,actor: int = 0) -> Dictionary:
	sim.state.actor = actor
	return sim.apply(a)
func expose(sim: PrioritySimulation,id: String) -> void:
	for pile in [sim.state.deck,sim.state.discard,sim.state.revealed]: pile.erase(id)
	sim.state.revealed.append(id)
	sim.state.used.erase(id)
func fresh() -> PrioritySimulation:
	var s = PrioritySimulation.new()
	s.batch = 3
	s.start(1)
	s._add_lot("wood",30,"","fixture",0)
	s._add_lot("grain",20,"","fixture",0)
	s._add_lot("furniture",10,"","fixture",0)
	s._add_lot("pop",4,"","fixture",0)
	act(s,{"type":"build_market"})
	s._close_round()
	for h in s.state.houses: s._prestige(h.id,20,"fixture",[])
	return s
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var s = fresh()
	s.state.buildings.lumber_camp.level = 2
	s._consume_plan("blue",s.public_plan({"wood":s.state.market.wood}),[])
	expose(s,"lumber_camp")
	check(act(s,{"type":"activate","building":"lumber_camp","mode":"enhanced"}).ok,"enhanced activation")
	var held = 0
	for lot in s.state.lots:
		if lot.resource == "wood" and lot.reserved_for == "blue": held += int(lot.amount)
	check(held == 1 and s.public_plan({"wood":1}).ok,"only one of two outputs reserved")
	act(s,{"type":"pass"})
	check(s.public_plan({"wood":2}).ok,"next-action pass releases priority")
	check(s.violations().is_empty(),"activation accounting")
	s = fresh()
	check(act(s,{"type":"secure_contract","resource":"grain","source":"grain_farm"}).ok,"create contract")
	check(s.title("grain").owner == "" and s.title("grain").first_pending,"creation grants no ownership")
	s._close_round()
	check(not s.title("grain").first_pending,"creator priority granted on first delivery")
	check(s.state.lots[-1].reserved_for == "blue","first delivered token belongs to creator temporarily")
	act(s,{"type":"pass"})
	check(s.state.lots[-1].reserved_for == "","creator next-action pass releases token")
	var red_before = s.house("red").inventory.prestige
	var initial_prestige = s.house("blue").inventory.prestige
	check(act(s,{"type":"buy_contract","resource":"grain"}).ok,"initial ownership purchase")
	check(s.house("blue").inventory.prestige == initial_prestige-3 and s.title("grain").price == 5,"three prestige consumed, next price five")
	s._close_round()
	check(s.state.lots[-1].reserved_for == "blue","owned link reserves each delivery")
	# Clear public grain so another house must pay for the reserved token.
	var free_grain = int(s.state.market.grain)-1
	s._consume_plan("red",s.public_plan({"grain":free_grain}),[])
	s._gain_influence("red",1,"fixture",[])
	expose(s,"hut_2")
	var blue_influence = s.house("blue").inventory.influence
	check(act(s,{"type":"activate","building":"hut_2","mode":"basic"},1).ok,"influence buys reserved contract input")
	check(s.house("blue").inventory.influence == blue_influence+1,"access fee transferred to reservation holder")
	var blue_prestige = s.house("blue").inventory.prestige
	check(act(s,{"type":"buy_contract","resource":"grain"},1).ok,"forced contract takeover")
	check(s.house("red").inventory.prestige == red_before-5 and s.house("blue").inventory.prestige == blue_prestige,"takeover burns five, no compensation")
	check(s.title("grain").owner == "red" and s.title("grain").price == 7,"title transferred and next buyout seven")
	check(s.cancel_price("grain") > s.title("grain").price,"cancellation exceeds takeover cost")
	check(s.violations().is_empty(),"ownership and access accounting")
	s = fresh()
	s.state.buildings.hut_1.owner = "blue"
	check(act(s,{"type":"secure_contract","resource":"pop","source":"hut_1"}).ok,"contract an owned basic hut")
	check("hut_1" not in s.state.deck+s.state.discard+s.state.revealed,"base card removed")
	check(act(s,{"type":"buy_brick"}).ok,"obtain upgrade brick")
	s.state.actor = 0
	check({"type":"upgrade","building":"hut_1"} in s.legal_actions(),"contracted hut upgrade legal off-card")
	check(act(s,{"type":"upgrade","building":"hut_1"}).ok,"upgrade contracted hut")
	check((s.state.deck+s.state.discard+s.state.revealed).count("hut_1") == 1,"one incremental card restored")
	check(s.modes("hut_1") == [{"name":"incremental","inputs":{"luxury":1},"outputs":{"pop":1}}],"upgrade recipe charges only extra luxury for extra labour")
	s._add_lot("luxury",1,"","fixture",0)
	expose(s,"hut_1")
	var grain_before = s.total_physical("grain")
	var pop_before = s.total_physical("pop")
	check(act(s,{"type":"activate","building":"hut_1","mode":"incremental"}).ok,"activate incremental hut")
	check(s.total_physical("grain") == grain_before and s.total_physical("pop") == pop_before+1,"no repeated base charge or double output")
	check(s.violations().is_empty(),"incremental recipe invariants")
	check(act(s,{"type":"cancel_contract","resource":"pop"}).ok,"cancel upgraded link")
	check((s.state.deck+s.state.discard+s.state.revealed).count("hut_1") == 1 and s.modes("hut_1").size() == 2,"cancellation restores full recipes without duplicating card")
	check(s.violations().is_empty(),"upgraded cancellation accounting")
	# Real capacity-lock fixture: all six tokens committed, zero physical labour.
	s = fresh()
	s._add_lot("pop",s.free_pop_tokens(),"","fixture",0)
	s.state.buildings.hut_1.owner = "blue"
	for r in ["wood","grain","furniture","brick","luxury"]:
		check(act(s,{"type":"secure_contract","resource":r,"source":s.source_for(r,"blue")}).ok,"lock fixture "+r)
	check(act(s,{"type":"secure_clay_contract"}).ok,"lock fixture clay")
	check(s.state.committed_pops == 6 and s.total_physical("pop") == 0,"complete commitment lock")
	s.state.actor = 0
	var before = TownSimulation.canonical(s.snapshot())
	var choice = PriorityAI.new().decide(s)
	check(before == TownSimulation.canonical(s.snapshot()),"AI counterfactuals do not mutate game")
	check(choice.chosen.type == "cancel_contract","last resort cancellation selected for genuine capacity lock")
	check(s.apply(choice.chosen).ok and s.free_pop_tokens() == 1,"chosen cancellation actually releases labour capacity")
	check(s.violations().is_empty(),"capacity rescue accounting")
	s = fresh()
	act(s,{"type":"secure_contract","resource":"grain","source":"grain_farm"})
	s.state.actor = 0
	var ordinary = PriorityAI.new().decide(s)
	check(ordinary.chosen.type != "cancel_contract","ordinary shortage does not justify cancellation")
	s = fresh()
	s._add_lot("wood",1,"blue","priority_fixture",int(s.house("blue").turns_taken))
	s.state.buildings.grain_farm.owner = "red"
	s._gain_influence("blue",1,"fixture",[])
	expose(s,"grain_farm")
	var free_result = act(s,{"type":"activate","building":"grain_farm","mode":"basic"})
	check(free_result.ok and free_result.free_action and s.current_house().id == "blue","paid activation retains normal turn")
	var old_held = false
	var new_held = false
	for lot in s.state.lots:
		if lot.source == "priority_fixture" and lot.reserved_for != "": old_held = true
		if lot.source == "grain_farm" and lot.reserved_for == "blue": new_held = true
	check(not old_held and new_held,"free action expires previous priority but preserves its own new output")
	check(s.violations().is_empty(),"free-action priority accounting")
	print(JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

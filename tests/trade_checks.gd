extends SceneTree
var checks = 0
var failures: Array = []
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func act(s: TradeSimulation,a: Dictionary,actor: int = 0) -> Dictionary:
	s.state.actor = actor
	return s.apply(a)
func brick_fixture(s: TradeSimulation,n: int) -> void:
	s._add_lot("brick",n,"","fixture",0)
	s.state.capacity.kiln_bricks += n
func fresh() -> TradeSimulation:
	var s = TradeSimulation.new()
	s.batch = 3
	s.start(1)
	s._add_lot("wood",10,"","fixture",0)
	s._add_lot("pop",4,"","fixture",0)
	s._add_lot("furniture",2,"","fixture",0)
	act(s,{"type":"build_market"})
	s._close_round()
	act(s,{"type":"secure_clay_contract"})
	act(s,{"type":"build_kiln"})
	brick_fixture(s,4)
	return s
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var s = fresh()
	check(s.house("blue").inventory.gold == 0,"zero initial gold")
	check(s.legal_actions().all(func(a): return a.type != "buy_brick" and not (a.type == "secure_contract" and a.resource == "brick")),"no caravan brick sales or import loophole")
	var bricks = s.total_physical("brick")
	check(act(s,{"type":"supply_town"}).ok,"town accepts brick")
	check(s.total_physical("brick") == bricks-1 and s.house("blue").inventory.influence == 2,"town consumes one brick and awards two influence")
	check(act(s,{"type":"export_brick"}).ok,"caravan buys brick")
	check(s.house("blue").inventory.gold == 1 and s.state.trade.exported_bricks == 1,"one brick pays one gold")
	s.state.actor = 1
	check({"type":"export_brick"} not in s.legal_actions(),"one shared order, not one per house")
	s.state.actor = 0
	check({"type":"buy_prestige"} not in s.legal_actions(),"one gold insufficient")
	for i in range(3): s._close_round()
	check(s.state.caravan.present and s.state.caravan.brick_order_open,"next visit renews order")
	check(act(s,{"type":"export_brick"}).ok,"second visit export")
	var prestige = s.house("blue").inventory.prestige
	check(act(s,{"type":"buy_prestige"}).ok,"caravan sells prestige")
	check(s.house("blue").inventory.gold == 0 and s.house("blue").inventory.prestige == prestige+1,"two coins consumed for one prestige")
	check(s.state.trade.gold_minted == 2 and s.state.trade.gold_spent == 2,"gold source/sink ledger")
	s._gain_influence("blue",7,"fixture",[])
	var overflow = int(s.state.access_metrics.cap_overflow)
	check(act(s,{"type":"supply_town"}).ok,"standing town demand accepts another brick")
	check(s.house("blue").inventory.influence == 10 and s.state.access_metrics.cap_overflow == overflow+1,"town award respects cap and records excess")
	check(s.violations().is_empty(),"trade conservation")
	s = fresh()
	act(s,{"type":"secure_contract","resource":"grain","source":"grain_farm"})
	s._gain_influence("blue",3,"fixture",[])
	s.state.actor = 0
	check("grain_farm" not in s.state.deck+s.state.discard+s.state.revealed,"automated industry card absent")
	check({"type":"claim","building":"grain_farm"} in s.legal_actions(),"automated public industry remains claimable")
	check(act(s,{"type":"claim","building":"grain_farm"}).ok,"claim automated industry")
	check(s.industries("blue") == ["grain_farm"] and s.house("blue").inventory.influence == 0,"industry ownership costs three influence")
	s.state.actor = 1
	s._gain_influence("red",3,"fixture",[])
	check({"type":"claim","building":"grain_farm"} not in s.legal_actions(),"no forced building takeover")
	check(s.violations().is_empty(),"industry claim invariants")
	print(JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

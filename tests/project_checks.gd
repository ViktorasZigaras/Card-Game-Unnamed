extends SceneTree
var checks = 0
var failures: Array = []
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func act(s: ProjectSimulation,a: Dictionary) -> Dictionary:
	s.state.actor = 0
	return s.apply(a)
func expose(s: ProjectSimulation,id: String) -> void:
	for pile in [s.state.deck,s.state.discard,s.state.revealed]:
		while id in pile: pile.erase(id)
	s.state.revealed.append(id)
	s.state.used.erase(id)
func fresh() -> ProjectSimulation:
	var s = ProjectSimulation.new()
	s.batch = 3
	s.start(1)
	s._add_lot("wood",10,"","fixture",0)
	s._add_lot("pop",4,"","fixture",0)
	s._add_lot("furniture",2,"","fixture",0)
	act(s,{"type":"build_market"})
	s._close_round()
	act(s,{"type":"secure_clay_contract"})
	act(s,{"type":"build_kiln"})
	s.state.buildings.hut_1.owner = "blue"
	return s
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var s = fresh()
	expose(s,"kiln")
	act(s,{"type":"activate","building":"kiln","mode":"basic"})
	expose(s,"hut_1")
	check(act(s,{"type":"contribute_upgrade","building":"hut_1","bundle":{"brick":1.0}}).ok,"fraction-normalised saved action accepted")
	check(s.total_physical("brick") == 0 and s.progress("hut_1").paid.brick == 1,"brick consumed into persistent progress")
	check(s.state.buildings.hut_1.level == 1,"partial home not upgraded early")
	check(s.modes("hut_1").size() == 1 and s.modes("hut_1")[0].outputs.pop == 1,"basic home functionality retained")
	check("hut_1" in s.state.discard and "hut_1" not in s.state.revealed,"project card cycles after contribution")
	s._gain_influence("red",10,"fixture",[])
	check(not s.payment_plan("red",{"brick":1}).ok,"paid access cannot seize consumed progress")
	check(s.remaining("hut_1") == {"wood":2,"pop":1},"remaining cost excludes paid brick")
	var clone = ProjectSimulation.new()
	clone.restore(JSON.parse_string(JSON.stringify(s.snapshot())))
	check(TownSimulation.canonical(s.snapshot()) == TownSimulation.canonical(clone.snapshot()),"project survives serialisation exactly")
	s._add_lot("pop",1,"","fixture",0)
	expose(s,"hut_1")
	var consumed_bricks = s.state.ledger.brick.consumed
	check(act(s,{"type":"upgrade","building":"hut_1"}).ok,"finish by paying remaining bundle")
	check(s.state.buildings.hut_1.level == 2 and s.remaining("hut_1").is_empty(),"full functionality unlocked only on completion")
	check(s.state.ledger.brick.consumed == consumed_bricks,"no repeated payment of committed brick")
	check(s.state.project_metrics.partial_home_completions == 1,"partial completion tracked")
	check(s.violations().is_empty(),"home progress accounting")
	s = fresh()
	s.house("blue").inventory.gold = 3
	s.state.trade.gold_minted += 3
	check(act(s,{"type":"buy_stone"}).ok,"caravan stone purchase")
	check(s.house("blue").inventory.gold == 2 and s.state.caravan.stone_left == 1,"one gold per stone, visit stock reduced")
	expose(s,"chapel")
	check(act(s,{"type":"contribute_upgrade","building":"chapel","bundle":{"stone":1}}).ok,"partial chapel contribution")
	check(s.state.buildings.chapel.level == 1 and s.modes("chapel")[0].outputs.influence == 2,"incomplete chapel still produces two")
	expose(s,"chapel")
	act(s,{"type":"activate","building":"chapel","mode":"basic"})
	check(s.house("blue").inventory.influence == 2,"old output actually delivered during construction")
	act(s,{"type":"buy_stone"})
	s.state.actor = 0
	check({"type":"buy_stone"} not in s.legal_actions(),"two-stone stock is shared and finite per visit")
	expose(s,"chapel")
	check(act(s,{"type":"upgrade","building":"chapel"}).ok,"chapel completed from remaining stone wood and labour")
	check(s.state.buildings.chapel.level == 2 and s.state.buildings.chapel.owner == "" and s.state.buildings.chapel.plot == "special","upgraded chapel remains special and unownable")
	check(s.modes("chapel") == [{"name":"enhanced","inputs":{},"outputs":{"influence":3}}],"chapel output exactly three, not four or five")
	expose(s,"chapel")
	act(s,{"type":"activate","building":"chapel","mode":"enhanced"})
	check(s.house("blue").inventory.influence == 5,"upgraded output actually delivered")
	check(s.state.trade.gold_spent == 2 and s.state.project_metrics.stone_gold_spent == 2,"stone gold sink separately accounted")
	check(s.violations().is_empty(),"chapel gold stone and project invariants")
	s = fresh()
	expose(s,"hut_1")
	act(s,{"type":"contribute_upgrade","building":"hut_1","bundle":{"wood":1}})
	check(act(s,{"type":"secure_contract","resource":"pop","source":"hut_1"}).ok,"automate existing partially upgraded home")
	check((s.state.deck+s.state.discard+s.state.revealed).count("hut_1") == 1,"automation preserves partial upgrade card")
	check(s.violations().is_empty(),"partial automated card accounting")
	s._prestige("blue",20,"fixture",[])
	check(act(s,{"type":"cancel_contract","resource":"pop"}).ok,"cancel automation without discarding upgrade work")
	check((s.state.deck+s.state.discard+s.state.revealed).count("hut_1") == 1 and s.progress("hut_1").paid.wood == 1,"one card and retained progress after cancellation")
	check(s.violations().is_empty(),"partial cancellation invariants")
	print(JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

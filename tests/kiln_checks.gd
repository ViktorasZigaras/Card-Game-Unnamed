extends SceneTree
var checks = 0
var failures: Array = []
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func act(s: CapacitySimulation,a: Dictionary,actor: int = 0) -> Dictionary:
	s.state.actor = actor
	return s.apply(a)
func expose(s: CapacitySimulation,id: String) -> void:
	for pile in [s.state.deck,s.state.discard,s.state.revealed]: pile.erase(id)
	s.state.revealed.append(id)
	s.state.used.erase(id)
func fresh(enabled: bool = true) -> CapacitySimulation:
	var s = CapacitySimulation.new()
	s.batch = 3
	s.scenario_kiln = enabled
	s.start(1)
	s._add_lot("wood",10,"","fixture",0)
	s._add_lot("pop",4,"","fixture",0)
	s._add_lot("furniture",3,"","fixture",0)
	act(s,{"type":"build_market"})
	s._close_round()
	return s
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var s = fresh()
	var consumed = int(s.state.ledger.wood.consumed)
	var wood = s.total_physical("wood")
	check(act(s,{"type":"secure_clay_contract"}).ok,"setup legal")
	check(s.state.capacity.wood == 1 and s.total_physical("wood") == wood-1,"wood moved out of circulation into commitment")
	check(s.state.ledger.wood.consumed == consumed,"committed wood is not consumed")
	check(s.state.committed_pops == 1 and s.state.clay_deliveries == 1,"existing artisan commitment and first delivery retained")
	check(s.violations().is_empty(),"initial committed-token accounting")
	# Spend every circulating wood token, leaving only the committed one.
	s._consume_plan("blue",s.public_plan({"wood":s.state.market.wood}),[])
	check(s.total_physical("wood") == 0 and not s.payment_plan("red",{"wood":1}).ok,"influence cannot buy committed wood")
	for i in range(6): s._close_round()
	check(s.state.clay_deliveries == 3 and s.state.capacity.wood == 1,"two later visits succeed without more wood")
	check(s.state.access_metrics.missed_clay_shipments == 0,"no periodic wood payment remains")
	s._prestige("blue",20,"fixture",[])
	check(act(s,{"type":"cancel_contract","resource":"clay"}).ok,"cancel import link")
	check(s.state.capacity.wood == 0 and s.total_physical("wood") == 1 and s.state.committed_pops == 0,"cancellation returns exact wood and frees artisan")
	check(s.violations().is_empty(),"released wood conservation")
	s.state.actor = 0
	var before = TownSimulation.canonical(s.snapshot())
	check(not act(s,{"type":"cancel_contract","resource":"clay"}).ok and before == TownSimulation.canonical(s.snapshot()),"cannot release commitment twice")
	s = fresh()
	act(s,{"type":"secure_clay_contract"})
	var space = int(s.state.terrain_free.urban)
	check(space == 1,"one spare urban plot before kiln")
	check(act(s,{"type":"build_kiln"}).ok,"kiln built without bricks")
	check(s.state.terrain_free.urban == space-1 and s.state.buildings.kiln.built,"kiln occupies last urban plot")
	check((s.state.deck+s.state.discard+s.state.revealed).count("kiln") == 1,"kiln has exactly one cycling card")
	check(s.state.capacity.construction_spent == {"wood":2,"pop":1},"construction cost recorded")
	expose(s,"kiln")
	var clay = s.total_physical("clay")
	var pop = s.total_physical("pop")
	var brick = s.total_physical("brick")
	check(act(s,{"type":"activate","building":"kiln","mode":"basic"}).ok,"local brick production legal")
	check(s.total_physical("clay") == clay-1 and s.total_physical("pop") == pop-1 and s.total_physical("brick") == brick+1,"kiln consumes clay and labour for one brick")
	check(s.state.capacity.kiln_bricks == 1 and s.state.access_metrics.bricks_bartered == 0,"local/imported provenance distinct")
	check("kiln" in s.state.discard and "kiln" not in s.state.revealed,"kiln used once and discarded")
	check(s.violations().is_empty(),"manufacturing source/sink accounting")
	check(act(s,{"type":"buy_brick"}).ok and s.state.access_metrics.bricks_bartered == 1,"direct brick barter still available")
	check(s.violations().is_empty(),"mixed brick sources conserved")
	s = fresh(false)
	s.state.actor = 0
	check({"type":"build_kiln"} not in s.legal_actions(),"control cannot build kiln")
	print(JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

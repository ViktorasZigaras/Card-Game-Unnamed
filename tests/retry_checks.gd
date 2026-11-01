extends SceneTree
var checks = 0
var failures: Array = []
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func command(s: RetrySimulation,a: Dictionary,actor: int) -> Dictionary:
	s.state.actor = actor
	return s.apply(a)
func fresh() -> RetrySimulation:
	var s = RetrySimulation.new()
	s.batch = 3
	s.start(1)
	s._add_lot("wood",10,"","fixture",0)
	s._add_lot("pop",2,"","fixture",0)
	s._add_lot("furniture",1,"","fixture",0)
	command(s,{"type":"build_market"},0)
	s._close_round()
	command(s,{"type":"secure_clay_contract"},0)
	s._prestige("gold",3,"fixture",[])
	command(s,{"type":"buy_contract","resource":"clay"},2)
	return s
func empty_wood(s: RetrySimulation) -> void:
	s._consume_plan("blue",s.public_plan({"wood":s.state.market.wood}),[])
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var s = fresh()
	empty_wood(s)
	for i in range(3): s._close_round()
	check(s.state.retry.window.pending,"blocked visit opens retry window")
	check(s.state.retry.initially_blocked == 1 and s.state.clay_deliveries == 1,"initial failure does not mint clay")
	s._add_lot("wood",1,"blue","fixture_priority",int(s.house("blue").turns_taken))
	command(s,{"type":"pass"},0)
	check(s.state.retry.attempts == 0,"one house is not sufficient")
	command(s,{"type":"pass"},1)
	check(s.state.retry.attempts == 0,"two houses are not sufficient")
	command(s,{"type":"pass"},2)
	check(s.state.retry.attempts == 1 and s.state.retry.rescued == 1,"third first action retries before round closes")
	check(s.state.clay_deliveries == 2 and s.state.access_metrics.missed_clay_shipments == 0,"exactly one recovered shipment, failed count corrected")
	check(s.state.retry.by_visit["2"] == 1 and s.state.market.wood == 0,"one wood paid, one clay delivered this visit")
	var reserved: Dictionary = s.state.lots[-1]
	check(reserved.resource == "clay" and reserved.reserved_for == "gold","retry output retains contract priority")
	check(reserved.expires_after_action == s.house("gold").turns_taken+1,"late output lasts precisely one future action")
	command(s,{"type":"pass"},2)
	check(reserved.reserved_for == "","owner's next pass expires late-delivery reservation")
	check(s.state.retry.attempts == 1,"no repeated retry during same visit")
	check(s.violations().is_empty(),"recovered shipment invariants")
	s = fresh()
	for i in range(3): s._close_round()
	check(s.state.clay_deliveries == 2 and not s.state.retry.window.pending,"upfront success never opens second delivery")
	for actor in [0,1,2]: command(s,{"type":"pass"},actor)
	check(s.state.clay_deliveries == 2 and s.state.retry.attempts == 0,"successful visit never double delivers")
	check(s.violations().is_empty(),"upfront shipment invariants")
	s = fresh()
	empty_wood(s)
	for i in range(3): s._close_round()
	for actor in [0,1,2]: command(s,{"type":"pass"},actor)
	check(s.state.retry.failed == 1 and s.state.clay_deliveries == 1,"retry without public input fails without free goods")
	check(s.state.access_metrics.missed_clay_shipments == 1,"unrecovered shipment remains missed")
	check(s.violations().is_empty(),"failed retry invariants")
	s = fresh()
	s._prestige("blue",20,"fixture",[])
	command(s,{"type":"cancel_contract","resource":"clay"},0)
	s.state.actor = 0
	check({"type":"secure_clay_contract"} not in s.legal_actions(),"cannot cancel and recreate to double-deliver in same visit")
	check(s.violations().is_empty(),"cancelled visit accounting")
	print(JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

class_name RetrySimulation
extends PrioritySimulation
func _init() -> void:
	super._init()
	rules.schema_version = 8
	rules.experiment = "caravan_retry_window"
func ensure_retry() -> void:
	if not state.has("retry"):
		state.retry = {"initially_blocked":0,"attempts":0,"rescued":0,"failed":0,"by_visit":{},"window":{}}
func _add_lot(resource: String,amount: int,producer: String,source: String,turn_no: int) -> void:
	super._add_lot(resource,amount,producer,source,turn_no)
	if resource == "clay" and source == "clay_import" and amount > 0:
		ensure_retry()
		var key = str(int(state.caravan.visits))
		state.retry.by_visit[key] = state.retry.by_visit.get(key,0)+amount
func _new_round() -> void:
	var before_misses = int(state.access_metrics.missed_clay_shipments)
	super._new_round()
	ensure_retry()
	state.schema_version = 8
	var blocked = int(state.access_metrics.missed_clay_shipments) > before_misses
	if blocked: state.retry.initially_blocked += 1
	state.retry.window = {"round":state.round,"visit":state.caravan.visits,"pending":blocked,"seen":[]}
func _after_action(event: Dictionary) -> void:
	super._after_action(event)
	ensure_retry()
	var w: Dictionary = state.retry.window
	if not w.get("pending",false) or w.round != state.round: return
	if event.house not in w.seen: w.seen.append(event.house)
	if w.seen.size() < state.houses.size(): return
	w.pending = false
	if not state.caravan.present or state.clay_contract.is_empty(): return
	state.retry.attempts += 1
	var plan = public_plan({"wood":1})
	if plan.ok:
		_consume_plan(state.clay_contract.sponsor,plan,event.consequences)
		# This output arrives after the action, so its reservation expires on the holder's next action.
		var previous_context = action_context
		action_context = {}
		_add_lot("clay",1,"","clay_import",0)
		action_context = previous_context
		state.clay_deliveries += 1
		state.access_metrics.missed_clay_shipments -= 1
		state.retry.rescued += 1
		event.consequences.append({"type":"caravan_retry","visit":w.visit,"success":true,"wood_exported":1,"clay_delivered":1})
	else:
		state.retry.failed += 1
		event.consequences.append({"type":"caravan_retry","visit":w.visit,"success":false,"reason":"no unreserved public wood after first actions"})
func legal_actions() -> Array:
	var actions = super.legal_actions()
	if state.has("retry") and int(state.retry.by_visit.get(str(int(state.caravan.visits)),0)) >= 1:
		actions = actions.filter(func(a): return a.type != "secure_clay_contract")
	return actions
func _experimental_action(action: Dictionary,h: Dictionary,events: Array) -> void:
	super._experimental_action(action,h,events)
	if action.type == "cancel_contract" and action.resource == "clay" and state.has("retry"): state.retry.window.pending = false
func violations() -> Array:
	var errors = super.violations()
	if state.has("retry"):
		var accounted_deliveries = 0
		for count in state.retry.by_visit.values():
			accounted_deliveries += int(count)
			if count > 1: errors.append("more than one clay delivery per caravan visit")
		if accounted_deliveries != state.clay_deliveries: errors.append("per-visit clay accounting")
		if state.retry.attempts != state.retry.rescued+state.retry.failed: errors.append("retry attempt accounting")
	return errors

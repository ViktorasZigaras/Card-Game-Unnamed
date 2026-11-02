class_name FinancingSimulation
extends ExpeditionSimulation
## Audit metadata only; prices, legal moves and resolution are inherited unchanged.
func _init() -> void:
	super._init()
	rules.schema_version = 16
	rules.experiment = "route_financing_comparison"
func _new_round() -> void:
	super._new_round()
	state.schema_version = 16
func funding_observation(resource: String) -> Dictionary:
	var missing = 0
	for h in state.houses:
		if owned_huts(h.id,true).is_empty(): missing += 1
	var cargo = 0
	for t in state.exploration.trips: cargo += int(t.cargo.get(resource,0))
	return {"missing_homes":missing,"physical_resource":total_physical(resource),"physical_brick":total_physical("brick"),"cargo_resource":cargo}
func _experimental_action(action: Dictionary,h: Dictionary,events: Array) -> void:
	var observed: Dictionary = {}
	if action.type == "expedition_contract":
		observed = funding_observation(trip_for(h.id).buy[int(action.offer)].resource)
	elif action.type == "buy_route": observed = funding_observation(route_by_id(int(action.route)).resource)
	super._experimental_action(action,h,events)
	if action.type in ["expedition_contract","buy_route"]:
		var route: Dictionary = state.exploration.routes[-1] if action.type == "expedition_contract" else route_by_id(int(action.route))
		route.financial_origin = {"owner":h.id,"cash":int(h.inventory.gold),"delivered":int(route.delivered),"round":int(state.round),"observation":observed}
		events.append({"type":"route_finance_observed","route":route.id,"observation":route.financial_origin.duplicate(true)})

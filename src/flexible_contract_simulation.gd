class_name FlexibleContractSimulation
extends FinancingSimulation
## Public means shared output, not free delivery or spare transport.
func _init() -> void:
	super._init()
	rules.schema_version = 17
	rules.experiment = "flexible_contracts"
	rules.public_route_prestige = 1
	rules.route_priority_influence = 2
	rules.own_route_cancel = 1
	rules.public_route_cancel = 0
func _new_round() -> void:
	super._new_round()
	state.schema_version = 17
	# Iterate a snapshot because paying the town reward adds another round event.
	for event in state.round_events.duplicate():
		if event.type != "route_delivery": continue
		var route = route_by_id(int(event.route))
		event.reserved = 0 if route.get("access","priority") == "public" else 1
		event.access = route.get("access","priority")
		if route.get("town_reward_eligible",false) and not state.exploration.clay_rewarded:
			state.exploration.clay_rewarded = true
			_prestige(route.owner,int(rules.expedition_clay_reward),"town_expedition_clay",state.round_events)
			state.exploration.clay_reward_events.append({"owner":route.owner,"route":route.id,"round":state.round,"prestige":rules.expedition_clay_reward})
func route_cancel_price(route: Dictionary,actor: String) -> int:
	if route.owner != actor: return int(route.price)+3
	return int(rules.public_route_cancel) if route.get("access","priority") == "public" else int(rules.own_route_cancel)
func cancel_price(resource: String) -> int:
	var t = title(resource)
	if t.owner == current_house().id: return int(rules.own_route_cancel)
	var sponsor = str(contract_for(resource).get("sponsor",""))
	if resource == "clay": sponsor = str(state.clay_contract.get("sponsor",sponsor))
	if t.owner == "" and sponsor == current_house().id: return int(rules.public_route_cancel)
	return super.cancel_price(resource)
func foreign_unit(resource: String,owner: String,source: String,to_store: bool) -> void:
	var public_access = source == "expedition_route" and state.exploration.routes.any(func(r): return r.active and r.owner == owner and r.resource == resource and r.get("access","priority") == "public")
	if public_access and not to_store:
		_add_lot(resource,1,"",source,0)
		state.exploration.imports[resource] += 1
	else: super.foreign_unit(resource,owner,source,to_store)
func legal_actions() -> Array:
	var actions = super.legal_actions().filter(func(a): return a.type not in ["expedition_contract","cancel_route","buy_route","buy_contract"])
	if state.ended: return actions
	var h = current_house()
	var trip = trip_for(h.id)
	if not trip.is_empty() and trip.status == "trading":
		var bound = state.exploration.routes.any(func(r): return r.active and r.trip == trip.id)
		for i in trip.buy.size():
			var offer: Dictionary = trip.buy[i]
			if bound or offer.contracted or h.inventory.gold < offer.price or h.inventory.prestige < rules.public_route_prestige: continue
			actions.append({"type":"expedition_contract","offer":i,"access":"public"})
			if h.inventory.influence >= rules.route_priority_influence: actions.append({"type":"expedition_contract","offer":i,"access":"priority"})
	for resource in rules.goods:
		if contract_for(resource).is_empty(): continue
		var t = title(resource)
		if t.owner != h.id and h.inventory.prestige >= t.price and h.inventory.influence >= rules.route_priority_influence:
			actions.append({"type":"buy_contract","resource":resource})
	for route in state.exploration.routes:
		if not route.active: continue
		if h.inventory.prestige >= route_cancel_price(route,h.id): actions.append({"type":"cancel_route","route":int(route.id)})
		if route.owner == h.id and route.get("access","priority") == "public" and h.inventory.influence >= rules.route_priority_influence:
			actions.append({"type":"own_route","route":int(route.id)})
		if route.owner != h.id and trip_by_id(route.trip).status == "home" and transport_free(h.id) > 0 and h.inventory.prestige >= route.price and h.inventory.influence >= rules.route_priority_influence:
			actions.append({"type":"buy_route","route":int(route.id)})
	return actions
func _experimental_action(action: Dictionary,h: Dictionary,events: Array) -> void:
	if action.type == "expedition_contract":
		var trip = trip_for(h.id)
		var offer: Dictionary = trip.buy[int(action.offer)]
		var observation = funding_observation(offer.resource)
		var access: String = action.access
		h.inventory.gold -= int(offer.price)
		state.trade.gold_spent += int(offer.price)
		state.exploration.gold_spent += int(offer.price)
		h.inventory.prestige -= int(rules.public_route_prestige)
		state.ledger.prestige.consumed += int(rules.public_route_prestige)
		if access == "priority":
			h.inventory.influence -= int(rules.route_priority_influence)
			state.ledger.influence.consumed += int(rules.route_priority_influence)
		offer.contracted = true
		var route = {"id":int(state.exploration.next_route),"trip":trip.id,"owner":h.id,"sponsor":h.id,"access":access,"town_reward_eligible":offer.resource == "clay" and clay_needed() and not state.exploration.clay_rewarded,"resource":offer.resource,"quantity":1,"unit_price":int(offer.price),"price":int(rules.expedition_contract_prestige)+2,"active":true,"next_round":-1,"delivered":0,"misses":0,"financial_origin":{"owner":h.id,"cash":int(h.inventory.gold),"delivered":0,"round":int(state.round),"observation":observation}}
		state.exploration.next_route += 1
		state.exploration.routes.append(route)
		events.append({"type":"expedition_route_secured","route":route.duplicate(true),"owned_priority":access == "priority","transport_committed":1,"setup_prestige":rules.public_route_prestige,"priority_influence":rules.route_priority_influence if access == "priority" else 0})
		return
	if action.type == "cancel_route":
		var route = route_by_id(int(action.route))
		var price = route_cancel_price(route,h.id)
		h.inventory.prestige -= price
		state.ledger.prestige.consumed += price
		route.active = false
		events.append({"type":"route_cancelled","route":route.id,"prestige":price,"own":route.owner == h.id})
		return
	if action.type == "own_route":
		var route = route_by_id(int(action.route))
		h.inventory.influence -= int(rules.route_priority_influence)
		state.ledger.influence.consumed += int(rules.route_priority_influence)
		route.access = "priority"
		events.append({"type":"route_priority_purchased","route":route.id,"influence":rules.route_priority_influence,"effective":"future deliveries"})
		return
	super._experimental_action(action,h,events)
	if action.type in ["buy_route","buy_contract"]:
		h.inventory.influence -= int(rules.route_priority_influence)
		state.ledger.influence.consumed += int(rules.route_priority_influence)
		if action.type == "buy_route": route_by_id(int(action.route)).access = "priority"
		events.append({"type":"priority_influence_paid","target":action.get("route",action.get("resource","")),"influence":rules.route_priority_influence})
func violations() -> Array:
	var errors = super.violations()
	for route in state.exploration.routes:
		if route.get("access","priority") not in ["public","priority"]: errors.append("unknown route access")
		if route.active and route.get("access","") == "public":
			for lot in state.lots:
				if lot.source == "expedition_route" and lot.resource == route.resource and lot.reserved_for == route.owner: errors.append("public route output reserved")
	return errors

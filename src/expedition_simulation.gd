class_name ExpeditionSimulation
extends DevelopmentSimulation
func _init() -> void:
	super._init()
	rules.schema_version = 15
	rules.experiment = "land_expeditions_and_protected_development"
	rules.expeditions_enabled = true
	rules.expedition_cost = {"grain":1,"pop":1}
	rules.expedition_travel_actions = 6
	rules.expedition_trade_actions = 6
	rules.expedition_offer_stock = 2
	rules.expedition_contract_prestige = 3
	rules.expedition_clay_reward = 3
	rules.expedition_prices = {"wood":1,"grain":1,"clay":1,"brick":2,"furniture":2,"luxury":2,"stone":1,"planks":1}
func ensure_exploration() -> void:
	if state.has("exploration"): return
	state.exploration = {"clock":0,"next_trip":1,"next_route":1,"trips":[],"routes":[],"imports":{},"gold_spent":0,"gold_earned":0,"crew":0,"clay_rewarded":false,"clay_reward_events":[],"events":[]}
	for r in rules.goods: state.exploration.imports[r] = 0
func _new_round() -> void:
	ensure_exploration()
	super._new_round()
	state.schema_version = 15
	for route in state.exploration.routes:
		if not route.active or int(route.next_round) < 0 or state.round < route.next_round: continue
		var h = house(route.owner)
		if h.inventory.gold < route.unit_price:
			route.misses += 1
			state.round_events.append({"type":"route_missed","route":route.id,"reason":"owner lacks gold"})
			continue
		h.inventory.gold -= route.unit_price
		state.trade.gold_spent += route.unit_price
		state.exploration.gold_spent += route.unit_price
		foreign_unit(route.resource,h.id,"expedition_route",false)
		route.delivered += 1
		route.next_round = int(state.round)+1
		state.round_events.append({"type":"route_delivery","route":route.id,"owner":h.id,"resource":route.resource,"gold":route.unit_price,"reserved":1})
func trip_for(house_id: String) -> Dictionary:
	for trip in state.exploration.trips:
		if trip.owner == house_id and trip.status != "home": return trip
	return {}
func route_by_id(id: int) -> Dictionary:
	for route in state.exploration.routes:
		if int(route.id) == id: return route
	return {}
func trip_by_id(id: int) -> Dictionary:
	for trip in state.exploration.trips:
		if int(trip.id) == id: return trip
	return {}
func transport_used(house_id: String) -> int:
	var used = 0
	for route in state.exploration.routes:
		if route.active and route.owner == house_id: used += 1
	var trip = trip_for(house_id)
	if not trip.is_empty():
		var shared = false
		for route in state.exploration.routes:
			if route.active and route.owner == house_id and route.trip == trip.id: shared = true
		if not shared: used += 1
	return used
func transport_free(house_id: String) -> int:
	return (1 if state.buildings[hall_id(house_id)].built else 0)-transport_used(house_id)
func clay_needed() -> bool:
	var unfinished = 0
	for h in state.houses:
		if owned_huts(h.id,true).is_empty(): unfinished += 1
	var brick_capability = state.buildings.kiln.built or state.houses.any(func(h): return state.buildings[hall_id(h.id)].built and "brick" in state.houseworks.unlocked[h.id])
	var industry_need = 1 if brick_capability and total_physical("brick") < 2 else 0
	return unfinished+industry_need > total_physical("clay")
func tradable_goods() -> Array:
	# Labour is manpower, not a commodity offered by this expedition model.
	return rules.goods.filter(func(r): return r != "pop" and rules.expedition_prices.has(r))
func make_offers(trip: Dictionary,events: Array) -> void:
	var goods = tradable_goods().duplicate()
	_shuffle(goods)
	trip.buy = []
	trip.sell = []
	for i in range(2):
		var r: String = goods[i]
		trip.buy.append({"resource":r,"price":int(rules.expedition_prices[r]),"left":int(rules.expedition_offer_stock),"contracted":false})
	for i in range(2,4): trip.sell.append({"resource":goods[i],"price":1,"left":int(rules.expedition_offer_stock)})
	events.append({"type":"expedition_arrived","trip":trip.id,"owner":trip.owner,"buy":trip.buy.duplicate(true),"sell":trip.sell.duplicate(true)})
func foreign_unit(resource: String,owner: String,source: String,to_store: bool) -> void:
	var before = int(state.next_lot)
	_add_lot(resource,1,"" if to_store else owner,source,int(house(owner).turns_taken))
	state.exploration.imports[resource] += 1
	if to_store and pile_size(owner) < int(rules.stockpile_capacity):
		for lot in state.lots:
			if lot.id == before:
				lot.amount -= 1
				state.market[resource] -= 1
				house(owner).stockpile[resource] += 1
				break
		state.lots = state.lots.filter(func(lot): return lot.amount > 0)
func legal_actions() -> Array:
	var actions = super.legal_actions()
	if not rules.expeditions_enabled or state.ended: return actions
	var h = current_house()
	var trip = trip_for(h.id)
	if trip.is_empty() and transport_free(h.id) > 0 and payment_plan(h.id,rules.expedition_cost).ok: actions.append({"type":"launch_expedition"})
	if not trip.is_empty() and trip.status == "trading":
		actions.append({"type":"return_expedition"})
		for i in trip.buy.size():
			var offer: Dictionary = trip.buy[i]
			if offer.left > 0 and h.inventory.gold >= offer.price: actions.append({"type":"expedition_buy","offer":i})
			if not offer.contracted and h.inventory.gold >= offer.price and h.inventory.prestige >= rules.expedition_contract_prestige:
				var bound = state.exploration.routes.any(func(r): return r.active and r.trip == trip.id)
				if not bound: actions.append({"type":"expedition_contract","offer":i})
		for i in trip.sell.size():
			var offer: Dictionary = trip.sell[i]
			if offer.left > 0 and payment_plan(h.id,{offer.resource:1}).ok: actions.append({"type":"expedition_sell","offer":i})
	for route in state.exploration.routes:
		if not route.active: continue
		if h.inventory.prestige >= int(route.price)+3: actions.append({"type":"cancel_route","route":int(route.id)})
		if route.owner != h.id and trip_by_id(route.trip).status == "home" and transport_free(h.id) > 0 and h.inventory.prestige >= route.price: actions.append({"type":"buy_route","route":int(route.id)})
	return actions
func _experimental_action(action: Dictionary,h: Dictionary,events: Array) -> void:
	match action.type:
		"launch_expedition":
			var plan = payment_plan(h.id,rules.expedition_cost)
			_pay(h.id,plan,events)
			_consume_plan(h.id,plan,events)
			# The crew token is held, not spent as ordinary work.
			state.ledger.pop.consumed -= 1
			state.pop_worked -= 1
			state.committed_pops += 1
			state.exploration.crew += 1
			var trip = {"id":int(state.exploration.next_trip),"owner":h.id,"status":"outbound","due":int(state.exploration.clock)+1+int(rules.expedition_travel_actions),"started_round":int(state.round),"buy":[],"sell":[],"cargo":{},"market_actions":0,"home_round":0}
			state.exploration.next_trip += 1
			state.exploration.trips.append(trip)
			events.append({"type":"expedition_launched","trip":trip.id,"owner":h.id,"crew":1,"land_transport":1,"due":trip.due})
		"expedition_sell":
			var trip = trip_for(h.id)
			var offer: Dictionary = trip.sell[int(action.offer)]
			var plan = payment_plan(h.id,{offer.resource:1})
			_pay(h.id,plan,events)
			_consume_plan(h.id,plan,events)
			offer.left -= 1
			h.inventory.gold += int(offer.price)
			state.trade.gold_minted += int(offer.price)
			state.exploration.gold_earned += int(offer.price)
			events.append({"type":"expedition_export","trip":trip.id,"resource":offer.resource,"gold":offer.price})
		"expedition_buy", "expedition_contract":
			var trip = trip_for(h.id)
			var offer: Dictionary = trip.buy[int(action.offer)]
			h.inventory.gold -= int(offer.price)
			state.trade.gold_spent += int(offer.price)
			state.exploration.gold_spent += int(offer.price)
			if action.type == "expedition_buy":
				offer.left -= 1
				trip.cargo[offer.resource] = int(trip.cargo.get(offer.resource,0))+1
				events.append({"type":"expedition_purchase","trip":trip.id,"resource":offer.resource,"gold":offer.price,"destination":"cargo until return"})
			else:
				h.inventory.prestige -= int(rules.expedition_contract_prestige)
				state.ledger.prestige.consumed += int(rules.expedition_contract_prestige)
				offer.contracted = true
				var route = {"id":int(state.exploration.next_route),"trip":trip.id,"owner":h.id,"sponsor":h.id,"resource":offer.resource,"quantity":1,"unit_price":int(offer.price),"price":int(rules.expedition_contract_prestige)+2,"active":true,"next_round":-1,"delivered":0,"misses":0}
				state.exploration.next_route += 1
				state.exploration.routes.append(route)
				events.append({"type":"expedition_route_secured","route":route.duplicate(true),"owned_priority":true,"transport_committed":1})
				if offer.resource == "clay" and clay_needed() and not state.exploration.clay_rewarded:
					state.exploration.clay_rewarded = true
					_prestige(h.id,int(rules.expedition_clay_reward),"town_expedition_clay",events)
					state.exploration.clay_reward_events.append({"owner":h.id,"route":route.id,"round":state.round,"prestige":rules.expedition_clay_reward})
		"return_expedition":
			var trip = trip_for(h.id)
			trip.status = "returning"
			trip.due = int(state.exploration.clock)+1+int(rules.expedition_travel_actions)
			events.append({"type":"expedition_departed","trip":trip.id,"due":trip.due})
		"buy_route":
			var route = route_by_id(int(action.route))
			var previous: String = route.owner
			var price = int(route.price)
			h.inventory.prestige -= price
			state.ledger.prestige.consumed += price
			route.owner = h.id
			route.price += 2
			events.append({"type":"route_bought_out","route":route.id,"previous":previous,"owner":h.id,"prestige":price,"transport_transferred":1})
		"cancel_route":
			var route = route_by_id(int(action.route))
			var price = int(route.price)+3
			h.inventory.prestige -= price
			state.ledger.prestige.consumed += price
			route.active = false
			events.append({"type":"route_cancelled","route":route.id,"prestige":price})
		_: super._experimental_action(action,h,events)
func apply(action: Dictionary) -> Dictionary:
	var normalised = action.duplicate(true)
	for key in ["offer","route"]:
		if normalised.has(key): normalised[key] = int(normalised[key])
	return super.apply(normalised)
func _after_action(event: Dictionary) -> void:
	super._after_action(event)
	if event.free_action: return
	state.exploration.clock += 1
	var events: Array = event.consequences
	for trip in state.exploration.trips:
		if trip.status == "outbound" and state.exploration.clock >= trip.due:
			trip.status = "trading"
			make_offers(trip,events)
		elif trip.status == "trading" and event.house == trip.owner:
			trip.market_actions += 1
			if trip.market_actions >= int(rules.expedition_trade_actions):
				trip.status = "returning"
				trip.due = int(state.exploration.clock)+int(rules.expedition_travel_actions)
				events.append({"type":"expedition_auto_departed","trip":trip.id,"due":trip.due})
		elif trip.status == "returning" and state.exploration.clock >= trip.due:
			trip.status = "home"
			trip.home_round = state.round
			state.committed_pops -= 1
			state.exploration.crew -= 1
			_add_lot("pop",1,"","returned_expedition_crew",0)
			state.ledger.pop.created -= 1
			state.pop_granted -= 1
			for r in _sorted_keys(trip.cargo):
				for i in int(trip.cargo[r]): foreign_unit(r,trip.owner,"expedition_purchase",true)
			events.append({"type":"expedition_home","trip":trip.id,"owner":trip.owner,"cargo":trip.cargo.duplicate(true),"crew_returned":1})
			trip.cargo.clear()
			for route in state.exploration.routes:
				if route.active and route.trip == trip.id: route.next_round = int(state.round)+1
func _check_end() -> void:
	super._check_end()
	if not state.has("exploration"): return
	var done = state.clay_deliveries > 0 or int(state.exploration.imports.get("clay",0)) > 0
	for h in state.houses:
		if owned_huts(h.id,true).is_empty() or industries(h.id).is_empty(): done = false
	if done and state.trade.all_goals_round == 0: state.trade.all_goals_round = state.round
	var halls = true
	for h in state.houses:
		if not state.buildings[hall_id(h.id)].built: halls = false
	if halls and not state.exploration.has("all_halls_round"): state.exploration.all_halls_round = state.round
func violations() -> Array:
	var errors = super.violations().filter(func(e): return e not in ["source/sink accounting: pop","persistent pop accounting","generic contract commitment identity","clay must originate exclusively from imports","kiln and hall brick accounting","stone import accounting","plank manufacture accounting","stone and prestige gold accounting"])
	var x: Dictionary = state.exploration
	var expected = (1 if state.lumber_link else 0)+(1 if not state.clay_contract.is_empty() else 0)+int(x.crew)
	for c in state.contracts:
		if c.has("resource"): expected += int(c.committed_pop)
	if expected != state.committed_pops: errors.append("crew and contract labour commitments")
	if total_physical("pop")+int(x.crew) != state.ledger.pop.created-state.ledger.pop.consumed: errors.append("held expedition crew conservation")
	if state.pop_granted != state.pop_worked+total_physical("pop")+int(x.crew): errors.append("crew token lifecycle")
	if state.ledger.clay.created != state.clay_deliveries+x.imports.clay: errors.append("caravan and expedition clay sources")
	if state.ledger.brick.created != state.access_metrics.bricks_bartered+state.capacity.kiln_bricks+state.houseworks.hall_bricks+x.imports.brick: errors.append("all brick sources")
	if state.ledger.stone.created != state.project_metrics.stone_bought+x.imports.stone: errors.append("all stone sources")
	if state.ledger.planks.created != state.houseworks.planks_made+x.imports.planks: errors.append("all plank sources")
	if state.trade.gold_spent != state.trade.prestige_bought*int(rules.prestige_gold_price)+state.project_metrics.stone_gold_spent+x.gold_spent: errors.append("all gold expenditure")
	var crews = 0
	for h in state.houses:
		if transport_free(h.id) < 0: errors.append("land transport overcommitted")
		var active = 0
		for trip in x.trips:
			if trip.owner == h.id and trip.status != "home": active += 1
		if active > 1: errors.append("duplicate active expedition")
		crews += active
	if crews != x.crew: errors.append("crew and expedition count")
	for trip in x.trips:
		if trip.status == "home" and not trip.cargo.is_empty(): errors.append("returned cargo not delivered")
		if trip.buy.size() not in [0,2] or trip.sell.size() not in [0,2]: errors.append("expedition offer pairs")
		for offer in trip.buy+trip.sell:
			if offer.left < 0 or offer.left > int(rules.expedition_offer_stock) or offer.resource not in tradable_goods(): errors.append("finite known expedition offers")
	for route in x.routes:
		if route.quantity != 1 or not state.buildings[hall_id(route.owner)].built: errors.append("route quantity and headquarters")
	if x.clay_reward_events.size() > 1: errors.append("clay expedition reward duplicated")
	return errors

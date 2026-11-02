class_name FinancingAI
extends ExpeditionAI
const FORECAST_ROUNDS = 6
const MIN_BRIDGE_UNITS = 3
func needed_units(sim: ExpeditionSimulation,resource: String,observation: Dictionary = {}) -> int:
	var o = observation
	if o.is_empty():
		var missing = 0
		for h in sim.state.houses:
			if sim.owned_huts(h.id,true).is_empty(): missing += 1
		var cargo = 0
		for trip in sim.state.exploration.trips: cargo += int(trip.cargo.get(resource,0))
		o = {"missing_homes":missing,"physical_resource":sim.total_physical(resource),"physical_brick":sim.total_physical("brick"),"cargo_resource":cargo}
	if resource == "clay":
		# Two-unit working buffer is a policy target, not a new town demand rule.
		return maxi(0,int(o.missing_homes)+2-int(o.physical_brick)-int(o.physical_resource)-int(o.cargo_resource))
	if resource == "stone":
		var need = int(sim.remaining("chapel").get("stone",0))
		for h in sim.state.houses:
			if not sim.state.buildings[sim.hall_id(h.id)].built: need += int(sim.site_remaining(sim.hall_id(h.id)).get("stone",0))
		return maxi(0,need-int(o.physical_resource)-int(o.cargo_resource))
	if resource in ["grain","wood"]: return maxi(0,2-int(o.physical_resource)-int(o.cargo_resource))
	return 0
func caravan_opportunities(sim: ExpeditionSimulation,horizon: int) -> int:
	if not sim.state.buildings.marketplace.built: return 0
	var count = 0
	for future in range(int(sim.state.round)+1,int(sim.state.round)+horizon+1):
		if future >= int(sim.state.caravan.first_round) and (future-int(sim.state.caravan.first_round)) % int(sim.rules.caravan_interval) == 0: count += 1
	return count
func assess_offer(sim: ExpeditionSimulation,offer: Dictionary) -> Dictionary:
	var h = sim.current_house()
	var price = int(offer.price)
	var need = mini(FORECAST_ROUNDS,needed_units(sim,offer.resource))
	var horizon = maxi(MIN_BRIDGE_UNITS,need)
	var upkeep = horizon*price
	var setup = price
	var social = int(sim.rules.expedition_contract_prestige)
	var exit_price = social+2+3
	var reward = int(sim.rules.expedition_clay_reward) if offer.resource == "clay" and sim.clay_needed() and not sim.state.exploration.clay_rewarded else 0
	var opportunities = caravan_opportunities(sim,horizon)
	var direct_units = mini(int(offer.left),need)
	var bridge = need >= MIN_BRIDGE_UNITS and need > direct_units and h.inventory.gold >= setup+upkeep and h.inventory.prestige >= maxi(social,social+exit_price-reward)
	return {"resource":offer.resource,"needed_units":need,"forecast_rounds":horizon,"setup_gold":setup,"operating_gold":upkeep,"cash_now":int(h.inventory.gold),"cash_shortfall":maxi(0,setup+upkeep-int(h.inventory.gold)),"guaranteed_recurring_gold":0,"shared_export_upper_bound":opportunities,"optimistic_operating_balance":opportunities-upkeep,"social_setup":social,"expected_town_prestige":reward,"exit_prestige":exit_price,"exit_prestige_shortfall":maxi(0,social+exit_price-reward-int(h.inventory.prestige)),"finite_units_available":direct_units,"finite_gold_cost":direct_units*price,"recurring_sustainable":false,"prefunded_bridge":bridge,"choice":"prefunded limited bridge" if bridge else "finite cargo or wait","reason":"Shared caravan income is an upper bound, not secured income; a binding must carry its own operating and exit budget"}
func route_budget(sim: ExpeditionSimulation,route: Dictionary) -> Dictionary:
	var h = sim.house(route.owner)
	var price = int(route.unit_price)
	var origin: Dictionary = route.get("financial_origin",{})
	var start_delivered = int(origin.get("delivered",route.delivered))
	var target = mini(FORECAST_ROUNDS,needed_units(sim,route.resource,origin.get("observation",{})))
	var supplied = maxi(0,int(route.delivered)-start_delivered)
	var remaining = maxi(0,target-supplied)
	var exit_price = int(route.price)+3
	var reserve = remaining*price
	var exhausted = remaining == 0 or h.inventory.gold < price
	return {"route":int(route.id),"target_units":target,"supplied_units":supplied,"remaining_units":remaining,"operating_reserve":reserve,"exit_reserve":exit_price,"cash":int(h.inventory.gold),"exit_affordable":h.inventory.prestige >= exit_price,"stop":exhausted,"reason":"Finite import goal reached" if remaining == 0 else "Next delivery unfunded" if h.inventory.gold < price else "Protect remaining prefunded deliveries and exit cost"}
func decide(simulation: TownSimulation) -> Dictionary:
	var sim = simulation as ExpeditionSimulation
	var d = super.decide(sim)
	var h = sim.current_house()
	var trip = sim.trip_for(h.id)
	var assessments: Dictionary = {}
	if not trip.is_empty() and trip.status == "trading":
		for i in trip.buy.size(): assessments[str(i)] = assess_offer(sim,trip.buy[i])
	var budgets: Array = []
	var gold_reserve = 0
	var prestige_reserve = 0
	for route in sim.state.exploration.routes:
		if route.active and route.owner == h.id:
			var b = route_budget(sim,route)
			budgets.append(b)
			gold_reserve += int(b.operating_reserve)
			prestige_reserve += int(b.exit_reserve)
	for c in d.candidates:
		var a: Dictionary = c.action
		if a.type == "expedition_contract":
			var f: Dictionary = assessments[str(int(a.offer))]
			c.score = 260 if f.prefunded_bridge else -1
			if sim.state.exploration.routes.any(func(r): return r.active and r.resource == f.resource): c.score = -1
			c.financing = f
			c.reasons = [f.reason,"Import flow is not accepted as an indefinitely affordable entitlement"]
		if a.type == "expedition_buy":
			var offer: Dictionary = trip.buy[int(a.offer)]
			var need = needed_units(sim,offer.resource)
			c.score = 210 if need > 0 and h.inventory.gold-int(offer.price) >= gold_reserve else -1
			c.reasons = ["Buy only outstanding material need after counting physical supply and cargo already returning"]
		if a.type == "buy_prestige" and h.inventory.gold-int(sim.rules.prestige_gold_price) < gold_reserve: c.score = -1
		if a.type == "buy_stone" and h.inventory.gold-int(sim.rules.stone_gold_price) < gold_reserve: c.score = -1
		if a.type == "buy_contract" and h.inventory.prestige-int(sim.title(a.resource).price) < prestige_reserve: c.score = -1
		if a.type == "demolish" and h.inventory.prestige-sim.clear_price(a.building) < prestige_reserve: c.score = -1
		if a.type == "cancel_route":
			var route = sim.route_by_id(int(a.route))
			c.score = -1
			if route.owner == h.id:
				var b = route_budget(sim,route)
				if b.stop and b.exit_affordable: c.score = 280
				c.financing = b
				c.reasons = [b.reason+"; release transport by paying the real cancellation cost"]
		c.components.total = c.score
	# Re-evaluate departure after all financing vetoes; do not wait on a rejected trade.
	var useful = d.candidates.any(func(c): return c.action.type in ["expedition_buy","expedition_sell","expedition_contract"] and c.score > 0)
	for c in d.candidates:
		if c.action.type == "return_expedition":
			c.score = -1 if useful else 190
			c.components.total = c.score
	var best: Dictionary = d.candidates[0]
	for c in d.candidates:
		if c.score > best.score: best = c
	d.chosen = best.action.duplicate(true)
	d.score = best.score
	d.policy_version = "route_financing_1"
	d.financing = {"offers":assessments,"routes":budgets,"reserved_gold":gold_reserve,"reserved_prestige":prestige_reserve,"horizon_limit":FORECAST_ROUNDS}
	return d

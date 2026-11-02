class_name ExpeditionAI
extends DevelopmentAI
func decide(simulation: TownSimulation) -> Dictionary:
	var sim = simulation as ExpeditionSimulation
	var d = super.decide(sim)
	var h = sim.current_house()
	var trip = sim.trip_for(h.id)
	var useful_trade = false
	var operating_reserve = 0
	for route in sim.state.exploration.routes:
		if route.active and route.owner == h.id: operating_reserve += int(route.unit_price)
	for c in d.candidates:
		var a: Dictionary = c.action
		if a.type == "launch_expedition":
			c.score = 115 if d.house_objective == "leftovers" and sim.total_physical("grain") > 1 and sim.total_physical("pop") >= 2 else -1
			c.reasons = ["Use available land transport and hold a real crew; seek finite sponsor-specific offers"]
		if a.type == "expedition_sell":
			var offer: Dictionary = trip.sell[int(a.offer)]
			var plan = sim.payment_plan(h.id,{offer.resource:1})
			var reserve = 2 if offer.resource in ["grain","wood","pop"] else 1 if offer.resource in ["stone","planks"] else 0
			c.score = 205 if sim.total_physical(offer.resource) > reserve and plan.total_influence <= 1 else -1
			if c.score > 0: useful_trade = true
			c.reasons = ["Sell legally accessible surplus; access fees still pay rival holders"]
		if a.type == "expedition_contract":
			var offer: Dictionary = trip.buy[int(a.offer)]
			c.score = 260 if offer.resource == "clay" and sim.clay_needed() and h.inventory.gold >= int(offer.price)+1 else -1
			if sim.state.exploration.routes.any(func(r): return r.active and r.resource == offer.resource): c.score = -1
			if c.score > 0: useful_trade = true
			c.reasons = ["Secure useful missing clay with owned priority; permanently commit transport, pay recurring gold"]
		if a.type == "expedition_buy":
			var offer: Dictionary = trip.buy[int(a.offer)]
			var need = (offer.resource == "clay" and sim.clay_needed()) or (offer.resource == "stone" and sim.remaining("chapel").has("stone")) or (offer.resource == "wood" and sim.total_physical("wood") < 2) or (offer.resource == "grain" and sim.total_physical("grain") < 2)
			c.score = 200 if need and h.inventory.gold >= offer.price else -1
			if c.score > 0: useful_trade = true
			c.reasons = ["Purchase a finite cargo unit; it is unavailable until the expedition returns"]
		if a.type == "return_expedition": c.score = -1
		if a.type in ["buy_route","cancel_route"]: c.score = -1
		if a.type == "buy_prestige" and h.inventory.gold-int(sim.rules.prestige_gold_price) < operating_reserve: c.score = -1
		if a.type == "buy_stone" and h.inventory.gold-int(sim.rules.stone_gold_price) < operating_reserve: c.score = -1
		if a.type == "expedition_buy" and h.inventory.gold-int(trip.buy[int(a.offer)].price) < operating_reserve: c.score = -1
		if a.type == "cancel_route":
			var route = sim.route_by_id(int(a.route))
			if route.owner == h.id and route.misses >= 3 and h.inventory.gold < route.unit_price: c.score = 185
			c.reasons = ["Withdraw an owned repeatedly unfunded route to recover scarce transport; cancellation still consumes prestige"]
		c.components.total = c.score
	for c in d.candidates:
		if c.action.type == "return_expedition" and not useful_trade:
			c.score = 190
			c.components.total = 190
	var best: Dictionary = d.candidates[0]
	for c in d.candidates:
		if c.score > best.score: best = c
	d.chosen = best.action.duplicate(true)
	d.score = best.score
	d.policy_version = "land_expeditions_1"
	d.transport = {"free":sim.transport_free(h.id),"used":sim.transport_used(h.id),"trip":trip.get("status","none")}
	return d

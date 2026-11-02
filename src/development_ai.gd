class_name DevelopmentAI
extends HallAI
func development_plan(sim: DevelopmentSimulation) -> Dictionary:
	var h = sim.current_house()
	var phase = "home" if sim.owned_huts(h.id,true).is_empty() else "industry" if sim.industries(h.id).is_empty() else "hall" if not sim.state.buildings[sim.hall_id(h.id)].built else "leftovers"
	var p = {"objective":phase,"route":"ordinary development","target":"","clear_price":0,"reason":"","alternatives":[]}
	if phase != "hall": return p
	if sim.state.houseworks.sites.has(sim.hall_id(h.id)):
		p.route = "finish protected site"
		p.reason = "Land secured; acquire and pay the remaining physical inputs"
	elif sim.state.terrain_free.urban > 0:
		p.route = "vacant plot"
		p.reason = "Vacant land avoids destroying a function or cancelling a right"
	elif sim.conversion_count() < 2:
		p.route = "town expansion"
		p.reason = "A visible stockade conversion route remains; do not destroy urban production first"
	else:
		p.route = "blocked"
		var best = 100000
		for key in sim.state.buildings:
			var id = str(key)
			if not sim.eligible_clear(id) or sim.state.buildings[id].plot != "urban": continue
			var loss = 0 if id == "carpenter" and not sim.state.clay_contract.is_empty() else 30 if id == "kiln" else 100 if id == "marketplace" else 500
			var safe = true
			if id == "marketplace":
				# Acquire the physical construction bundle before retiring the stone/caravan gateway.
				safe = true
				if sim is ExpeditionSimulation and not sim.state.clay_contract.is_empty():
					safe = safe and sim.state.exploration.routes.any(func(r): return r.active and r.resource == "clay" and r.delivered > 0)
			var price = sim.clear_price(id)
			p.alternatives.append({"building":id,"prestige":price,"lost_function_penalty":loss,"safe":safe,"materials_ready":sim.payment_plan(h.id,sim.site_cost(sim.hall_id(h.id))).ok})
			if safe and price+loss < best:
				best = price+loss
				p.target = id
				p.clear_price = price
		if p.target != "":
			p.route = "prepare replacement"
			p.reason = "Vacant land and conversion allowances exhausted; pay social clearance, then construct separately"
		else: p.reason = "No safe currently visible clearance route; retain inputs and observe other trade/production opportunities"
	return p
func decide(simulation: TownSimulation) -> Dictionary:
	var sim = simulation as DevelopmentSimulation
	var d = super.decide(sim)
	var h = sim.current_house()
	var p = development_plan(sim)
	var hall = sim.hall_id(h.id)
	var advanced = p.objective in ["hall","leftovers"]
	var plank_need = 0
	var prospective = int(sim.state.terrain_free.urban)
	for other in sim.state.houses:
		var id = sim.hall_id(other.id)
		if sim.protected_site(id): plank_need += int(sim.site_remaining(id).get("planks",0))
		elif not sim.state.buildings[id].built and prospective > 0:
			plank_need += 3
			prospective -= 1
	if p.route == "prepare replacement" and not sim.state.houseworks.sites.has(hall): plank_need += 3
	for c in d.candidates:
		var a: Dictionary = c.action
		if a.type == "claim_site":
			c.score = -1
			if a.building == "marketplace" and a.replace == "": c.score = 185
			if a.building == "kiln" and not sim.state.clay_contract.is_empty() and a.replace == "": c.score = 160
			if a.building == "small_sawmill" and advanced and sim.claim_count() > 0 and a.replace == "": c.score = 236
			if a.building == hall and advanced and sim.state.buildings.small_sawmill.built and sim.total_physical("planks") > 0:
				if a.replace == "" and p.route == "vacant plot": c.score = 255
				elif a.replace == p.target and p.route == "prepare replacement" and sim.payment_plan(h.id,sim.site_cost(hall)).ok: c.score = 235
			c.reasons = [p.reason if a.building == hall else "Social action reserves a protected site; materials require a later action"]
		if a.type == "supply_site":
			var units = 0
			for n in a.bundle.values(): units += int(n)
			c.score = (245 if a.building == hall else 238 if a.building == "small_sawmill" else 180 if a.building == "marketplace" else 165)+units
		if a.type == "activate" and a.building == "small_sawmill": c.score = 216 if advanced and sim.total_physical("planks") < plank_need else -1
		if a.type == "redevelop_occupied": c.score = 140 if advanced and p.route == "town expansion" else -1
		if a.type == "claim_rural": c.score = 181 if advanced else -1
		if a.type == "buy_stone" and p.objective == "hall" and sim.site_remaining(hall).has("stone") and sim.total_physical("stone") < 1: c.score = 226
		if a.type == "activate" and a.building == "chapel" and p.objective == "hall" and h.inventory.influence < 8: c.score = maxf(c.score,142)
		if a.type in ["buy_prestige","buy_contract","demolish"] and p.objective != "leftovers": c.score = -1
		if a.type == "convert_prestige" and p.objective == "hall":
			c.score = 145 if p.route == "prepare replacement" and h.inventory.prestige < p.clear_price and h.inventory.influence >= 8 else -1
		if a.type in ["take","return"] and c.score <= 20:
			for e in sim.state.history:
				if e.house == h.id and int(e.round) == int(sim.state.round) and e.action.get("resource","") == a.resource and e.action.type in ["take","return"]:
					if e.action.type != a.type: c.score = -1
		c.components.total = c.score
	var best: Dictionary = d.candidates[0]
	for c in d.candidates:
		if c.score > best.score: best = c
	d.chosen = best.action.duplicate(true)
	d.score = best.score
	d.house_objective = p.objective
	d.development_plan = p
	d.feasible_plank_demand = plank_need
	d.policy_version = "protected_development_1"
	return d

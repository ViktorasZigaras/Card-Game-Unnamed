class_name HallAI
extends StockadeAI
func decide(simulation: TownSimulation) -> Dictionary:
	var sim = simulation as HallSimulation
	var decision = super.decide(sim)
	if not sim.rules.halls_enabled: return decision
	var h = sim.current_house()
	var settled = decision.house_objective == "prestige"
	var hall = sim.hall_id(h.id)
	var needs_hall = not sim.state.buildings[hall].built
	var mill_ready = sim.state.buildings.small_sawmill.built
	var hall_route = mill_ready and (sim.state.terrain_free.urban > 0 or sim.state.houseworks.sites.has(hall))
	var plank_need = 0
	for other in sim.state.houses:
		var id = sim.hall_id(other.id)
		if not sim.state.buildings[id].built: plank_need += int(sim.site_remaining(id).get("planks",0))
	for c in decision.candidates:
		var a: Dictionary = c.action
		if a.type in ["start_site","supply_site"]:
			var units = 0
			for n in a.bundle.values(): units += int(n)
			c.score = -1
			if settled:
				if a.type == "supply_site": c.score = 240+units
				elif a.building == "small_sawmill" and sim.claim_count() > 0: c.score = 235+units
				elif a.building == hall and mill_ready and a.bundle.has("planks"): c.score = 245+units
			c.reasons.append("Reserve genuine paid construction progress; keep the two original vacant rural plots for conversion")
		if a.type == "hall_work":
			c.score = -1
			if a.recipe == "brick" and sim.total_physical("brick") < (decision.unfinished_houses+2): c.score = 150
			if a.recipe == "furniture" and sim.state.clay_contract.is_empty() and sim.total_physical("furniture") < 1: c.score = 150
			c.reasons.append("One chosen unlocked workshop recipe; inputs consumed, output priority lasts only until the next action")
		if a.type == "activate":
			if a.building == "small_sawmill": c.score = 215 if settled and sim.total_physical("planks") < plank_need else -1
			if settled and sim.is_housing(a.building) and sim.total_physical("pop") < 2 and (needs_hall or not mill_ready): c.score = maxf(c.score,130)
			if settled and a.building == "chapel" and needs_hall and hall_route and h.inventory.influence < 3: c.score = maxf(c.score,140)
		if a.type == "buy_stone" and settled and needs_hall and hall_route and sim.site_remaining(hall).has("stone") and sim.total_physical("stone") < 1: c.score = 225
		if a.type == "convert_prestige" and needs_hall and hall_route and h.inventory.influence < 8: c.score = -1
		if a.type == "bulk_exchange" and needs_hall:
			if h.stockpile.planks > 0 or h.stockpile.stone > 0: c.score = -1
		if a.type == "take" and a.resource == "planks": c.score = -1
		c.components.total = c.score
	var best: Dictionary = decision.candidates[0]
	for c in decision.candidates:
		if c.score > best.score: best = c
	decision.chosen = best.action.duplicate(true)
	decision.score = best.score
	decision.policy_version = "house_halls_1"
	return decision

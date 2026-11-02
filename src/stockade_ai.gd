class_name StockadeAI
extends ProjectAI
func decide(simulation: TownSimulation) -> Dictionary:
	var sim = simulation as StockadeSimulation
	var decision = super.decide(sim)
	var h = sim.current_house()
	var settled = decision.house_objective == "prestige"
	for c in decision.candidates:
		var a: Dictionary = c.action
		if a.type == "supply_wood":
			c.score = -1
			if settled and h.inventory.influence <= 9: c.score = 75
			elif h.inventory.influence < 3 and sim.available(h.id).wood > 2: c.score = 110
		if a.type == "redevelop_rural": c.score = 155 if settled else -1
		if a.type == "claim_rural": c.score = 180 if settled else -1
		if a.type == "buy_stone" and settled and sim.state.town.wall_complete:
			var stone_need = int(sim.remaining("chapel").get("stone",0))+2-sim.conversion_count()
			if stone_need > sim.total_physical("stone"): c.score = 207
		c.components.total = c.score
	var best: Dictionary = decision.candidates[0]
	for c in decision.candidates:
		if c.score > best.score: best = c
	decision.chosen = best.action.duplicate(true)
	decision.score = best.score
	decision.policy_version = "stockade_1"
	return decision

class_name TradeAI
extends KilnAI
func decide(simulation: TownSimulation) -> Dictionary:
	var sim = simulation as TradeSimulation
	var decision = super.decide(sim)
	var h = sim.current_house()
	var home = not sim.owned_huts(h.id,true).is_empty()
	var industry = not sim.industries(h.id).is_empty()
	var phase = "home" if not home else "industry" if not industry else "prestige"
	for c in decision.candidates:
		var a: Dictionary = c.action
		if a.type == "claim" and not sim.is_housing(a.building): c.score = 185 if home and not industry else -1
		if a.type in ["convert_prestige","buy_contract","bulk_exchange"] and phase != "prestige": c.score = -1
		if a.type == "buy_prestige": c.score = 200 if phase == "prestige" else -1
		if a.type == "export_brick": c.score = 170 if phase == "prestige" else -1
		if a.type == "supply_town":
			c.score = -1
			if home and h.inventory.influence <= 8: c.score = 130 if industry else 175 if h.inventory.influence < 3 else -1
		if a.type == "activate" and a.building == "kiln" and home:
			if sim.total_physical("brick") < 2: c.score = 120-float(sim.payment_plan(h.id,{"clay":1,"pop":1},"kiln").total_influence)
		if a.type == "activate" and sim.is_housing(a.building) and home and sim.total_physical("pop") < 2 and sim.total_physical("clay") > 0: c.score = 90
		if a.type == "activate" and a.building == "chapel" and phase == "industry" and h.inventory.influence < 3: c.score = 110
		if a.type == "take" and phase == "prestige" and a.resource == "brick": c.score = 40 if h.stockpile.brick < 1 else -1
		c.components.total = c.score
	if int(sim.rules.get("trade_policy_version",1)) >= 2:
		for c in decision.candidates:
			var a: Dictionary = c.action
			if not sim.state.clay_contract.is_empty():
				if a.type == "activate" and a.building == "carpenter": c.score = -1
				if a.type == "secure_contract" and a.resource == "furniture": c.score = -1
				if a.type == "take" and a.resource == "furniture" and phase != "prestige": c.score = -1
				if a.type == "return" and a.resource == "furniture" and phase != "prestige": c.score = 180
			if a.type == "take" and a.resource == "brick" and not home and h.stockpile.brick < 1: c.score = 165
			c.components.total = c.score
	var best: Dictionary = decision.candidates[0]
	for c in decision.candidates:
		if c.score > best.score: best = c
	decision.chosen = best.action.duplicate(true)
	decision.score = best.score
	decision.policy_version = "trade_%d" % int(sim.rules.get("trade_policy_version",1))
	decision.house_objective = phase
	return decision

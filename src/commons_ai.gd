class_name CommonsAI
extends HouseAI
func objective(sim: CommonsSimulation) -> Dictionary:
	var h = sim.current_house()
	var first = sim.owned_huts(h.id,true).is_empty()
	for id in sim.owned_huts(h.id):
		if sim.state.buildings[id].level == 1: return {"step":"upgrade","building":id,"first":first}
	if sim._owns(h.id) < sim.rules.ownership_slots:
		for id in sim._sorted_keys(sim.state.buildings):
			if sim.state.buildings[id].built and sim.is_housing(id) and sim.state.buildings[id].owner == "": return {"step":"claim","building":id,"first":first}
		if sim.state.terrain_free.urban > 0: return {"step":"construct_hut","first":first}
	return {"step":"maintain","first":first}

func value(sim: CommonsSimulation, resource: String, stock: Dictionary, goal: Dictionary) -> float:
	match resource:
		"grain": return 20.0 if sim.state.market.grain < 3 else (7.0 if sim.state.market.grain < 6 else 0.1)
		"wood":
			if stock.wood < 2 and goal.step in ["upgrade","construct_hut"]: return 12.0
			return 5.0 if sim.state.market.wood < 3 else 0.1
		"brick":
			if stock.brick < 1 and goal.step in ["upgrade","construct_hut"]: return 22.0
			return 7.0 if sim.state.market.brick < 2 else 0.1
		"clay": return 7.0 if sim.state.market.clay < 2 else 0.1
		"luxury": return 11.0 if sim.state.market.luxury < 2 else 0.1
		"pop":
			if stock.pop < 1 and goal.step in ["upgrade","construct_hut"]: return 18.0
			return 7.0 if sim.state.market.pop < 2 else 0.1
	return 0.0

func decide(simulation: TownSimulation) -> Dictionary:
	var sim = simulation as CommonsSimulation
	var h = sim.current_house()
	var goal = objective(sim)
	var stock = sim.available(h.id)
	var candidates: Array = []
	for action in sim.legal_actions():
		var score = -1.0
		var components: Dictionary = {}
		var reasons: Array = []
		match action.type:
			"pass":
				score = 10.0 if not h.did_something and h.inventory.influence < 3 and goal.step == "claim" else 0.0
				reasons.append("Influence only if no action was taken this round")
			"claim":
				if sim.is_housing(action.building) and goal.step == "claim": score = 100.0 if goal.first else 40.0
				elif action.building == "chapel" and h.inventory.influence >= 6: score = 6.0
				elif not goal.first:
					if sim.definition(action.building).kind == "rural" and sim.outputs(action.building).has("grain") and sim.state.market.grain < 6: score = 30.0
					elif h.inventory.influence >= 7: score = 3.0 * float(h.bias.ownership)
				reasons.append("Claim at uniform cost; ownership controls upgrades and paid use income")
			"upgrade":
				score = (120.0 if goal.first else 45.0) if sim.is_housing(action.building) else (20.0 * float(h.bias.production) if not goal.first else -1.0)
				score -= sim.payment_plan(h.id,sim.rules.housing_upgrade_cost).total_influence
				reasons.append("Improve capacity while preserving the basic recipe")
			"construct_hut":
				if goal.step == "construct_hut": score = 70.0
				reasons.append("Create additional public urban housing")
			"construct":
				if not goal.first:
					for r in sim.definition(action.building).outputs:
						score = maxf(score,value(sim,r,stock,goal)*2.0-5.0)
				reasons.append("Expand production in a compatible plot")
			"take":
				if goal.step == "upgrade" and action.resource in ["wood","brick"]:
					var target = 2 if action.resource == "wood" else 1
					if h.stockpile[action.resource] < target: score = 16.0 if action.resource == "brick" else 13.0
				elif not goal.first and action.resource in ["grain","luxury","pop"] and h.stockpile[action.resource] == 0:
					score = 2.0
				reasons.append("Secure one token within the protected three-token capacity")
			"return":
				if goal.step == "upgrade" and action.resource not in ["wood","brick"] and sim.pile_size(h.id) == 3: score = 4.0
				reasons.append("Return an unneeded protected token to make space for a concrete plan")
			"activate":
				var recipe = sim.recipe(action)
				var plan = sim.payment_plan(h.id,recipe.inputs,action.building)
				if action.building == "chapel":
					var gain = mini(10,int(h.inventory.influence)-int(plan.total_influence)+2)-int(h.inventory.influence)
					score = float(gain)*14.0 if gain > 0 else -1.0
					components.net_influence = gain
				else:
					var gain = 0.0
					var cost = 0.0
					var projected: Dictionary = stock.duplicate(true)
					for r in sim._sorted_keys(recipe.outputs):
						for i in range(int(recipe.outputs[r])):
							gain += value(sim,r,projected,goal)
							projected[r] += 1
					for r in sim._sorted_keys(recipe.inputs):
						# Preserve genuinely scarce final inputs while spending intermediate supplies.
						cost += int(recipe.inputs[r]) * 0.4 * value(sim,r,stock,goal)
					score = (gain-cost)*float(h.bias.production) - float(plan.total_influence)
					if plan.building_fee > 0 and score > 0: score += 1.0
					components.output_value = gain
					components.input_opportunity_cost = -cost
					components.influence_payment = -plan.total_influence
				reasons.append("Choose basic/enhanced output and pay for direct rival access when worthwhile")
		if action.type != "pass" and score < 0.5: score = -1.0
		components.total = snappedf(score,0.001)
		candidates.append({"action":action.duplicate(true),"score":components.total,"components":components,"reasons":reasons})
	var best: Dictionary = candidates[0]
	for candidate in candidates:
		if candidate.score > best.score: best = candidate
	return {"house":h.id,"round":sim.state.round,"policy_version":"commons_1","objective":goal,"accessible_stock":stock,"protected_stock":h.stockpile.duplicate(true),"candidates":candidates,"chosen":best.action.duplicate(true),"score":best.score}

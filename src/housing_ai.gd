class_name HousingAI
extends HouseAI
## Explicit durable objective; explains the next step and required resources.
func plan(sim: HousingSimulation) -> Dictionary:
	var h = sim.current_house()
	var first = sim.owned_huts(h.id, true).is_empty()
	var goal = "first_upgraded_hut" if first else "additional_upgraded_huts"
	if not sim.owned_huts(h.id).is_empty():
		for id in sim.owned_huts(h.id):
			if sim.state.buildings[id].level == 1:
				return {"goal":goal,"step":"upgrade","building":id,"cost":sim.rules.housing_upgrade_cost,"first":first}
	for id in sim._sorted_keys(sim.state.buildings):
		var b: Dictionary = sim.state.buildings[id]
		if b.built and sim.is_housing(id) and b.owner == "" and sim._owns(h.id) < sim.rules.ownership_slots:
			return {"goal":goal,"step":"claim","building":id,"cost":sim.rules.housing_claim_cost,"first":first}
	if sim._owns(h.id) < sim.rules.ownership_slots and not sim.available_plots().is_empty():
		return {"goal":goal,"step":"construct_hut","cost":sim.rules.housing_build_cost,"first":first}
	return {"goal":goal,"step":"blocked_or_complete","cost":{},"first":first}

func value(sim: HousingSimulation, resource: String, inventory: Dictionary, objective: Dictionary, include_recipe: bool = true) -> float:
	var needed = int(objective.cost.get(resource, 0))
	# Plan one recipe step ahead when market bricks are absent.
	if include_recipe and int(objective.cost.get("brick", 0)) > inventory.brick and sim.state.market.brick == 0:
		if resource == "clay":
			needed = maxi(needed, 2)
		if resource == "wood":
			needed += 1
	if inventory[resource] < needed:
		return 12.0 if objective.first else 8.0
	if resource == "grain":
		for id in sim.owned_huts(sim.current_house().id):
			if sim.occupancy(id) < sim.capacity(id) and inventory.grain < 2:
				return 7.0
		return 0.5 if inventory.grain < 2 else 0.0
	return 0.2 if inventory[resource] < 3 else 0.0

func decide(simulation: TownSimulation) -> Dictionary:
	var sim = simulation as HousingSimulation
	var h = sim.current_house()
	var objective = plan(sim)
	var candidates: Array = []
	for action in sim.legal_actions():
		var score = -2.0
		var components: Dictionary = {}
		var reasons: Array = []
		match action.type:
			"pass":
				score = 0.0
				reasons.append("Preserve goods when no useful affordable step remains")
			"claim":
				if sim.is_housing(action.building):
					score = 80.0 if objective.first else 25.0 * float(h.bias.ownership)
					if sim.state.buildings[action.building].residents.get(h.id, 0) > 0:
						score += 5.0
					if objective.step != "claim":
						score = -1.0
					reasons.append("Secure housing ownership; finish existing home before another claim")
				else:
					score = -1.0 if objective.first else 1.0 * float(h.bias.ownership)
					reasons.append("Secondary productive investment after first home")
			"upgrade":
				if sim.is_housing(action.building):
					score = 100.0 if objective.first else 40.0 * float(h.bias.ownership)
					reasons.append("Complete upgraded-home objective")
				else:
					score = -1.0 if objective.first else 3.0 * float(h.bias.production)
					reasons.append("Secondary production upgrade")
			"construct_hut":
				score = 70.0 if objective.first else 24.0 * float(h.bias.ownership)
					# Spatial foresight: prefer slots with fewer unbuilt industrial alternatives.
				var opportunity = 0
				for id in sim.state.buildings:
					if not sim.state.buildings[id].built and sim.definition(id).terrain == action.plot:
						opportunity += 1
				components.plot_opportunity_cost = -2.0 * opportunity
				score += components.plot_opportunity_cost
				if objective.step != "construct_hut":
					score = -1.0
				reasons.append("Build another home, accounting for displaced industry opportunities")
			"construct":
				score = -1.0 if objective.first else 20.0 * float(h.bias.production)
				reasons.append("Competing productive use of a limited plot")
			"rally_support":
				var deficit = int(objective.cost.get("influence", 0)) - int(h.inventory.influence)
				score = 8.0 if deficit > 0 else -1.0
				reasons.append("Spend resident labour to obtain missing influence")
			"activate":
				var d = sim.definition(action.building)
				var outputs = 0.0
				var costs = 0.0
				for r in d.outputs:
					var temp: Dictionary = h.inventory.duplicate()
					for i in range(int(d.outputs[r]) * int(sim.state.buildings[action.building].level)):
						outputs += value(sim, r, temp, objective)
						temp[r] += 1
				for r in d.inputs:
					var temp: Dictionary = h.inventory.duplicate()
					for i in range(int(d.inputs[r])):
						temp[r] -= 1
						costs += value(sim, r, temp, objective, false)
				components.output_value = outputs
				components.input_opportunity_cost = -costs
				score = (outputs - costs) * float(h.bias.production)
				reasons.append("Produce goods or influence toward next housing step")
			"barter":
				var give_inv: Dictionary = h.inventory.duplicate()
				give_inv[action.give] -= 1
				var take_value = value(sim, action.take, h.inventory, objective)
				var give_value = value(sim, action.give, give_inv, objective)
				components.take_value = take_value
				components.give_opportunity_cost = -give_value
				score = (take_value - give_value) * float(h.bias.trade) - 0.1
				reasons.append("Barter less-needed goods for the current plan")
		# A very small score is not worth spending a person's labour.
		if action.type != "pass" and score < 0.5:
			score = -1.0
		components.total = snappedf(score, 0.001)
		candidates.append({"action":action.duplicate(true),"score":components.total,"components":components,"reasons":reasons})
	var best: Dictionary = candidates[0]
	for candidate in candidates:
		if candidate.score > best.score:
			best = candidate
	return {"house":h.id,"round":sim.state.round,"policy_version":"housing_2","objective":objective,
		"population":sim.population(h.id),"labour_available":h.labour,"candidates":candidates,"chosen":best.action.duplicate(true),"score":best.score}

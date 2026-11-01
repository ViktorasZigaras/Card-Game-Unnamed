class_name ReservationAI
extends HouseAI
## Small shared-economy planner. No hidden cash or permanent resident growth.
func objective(sim: ReservationSimulation) -> Dictionary:
	var h = sim.current_house()
	var first = sim.owned_huts(h.id, true).is_empty()
	for id in sim.owned_huts(h.id):
		if sim.state.buildings[id].level == 1:
			return {"goal":"first_upgraded_home" if first else "more_upgraded_homes","step":"upgrade","building":id,"first":first}
	if sim._owns(h.id) < sim.rules.ownership_slots:
		for id in sim._sorted_keys(sim.state.buildings):
			if sim.state.buildings[id].built and sim.is_housing(id) and sim.state.buildings[id].owner == "":
				return {"goal":"first_upgraded_home" if first else "more_upgraded_homes","step":"claim","building":id,"first":first}
		if sim.state.terrain_free.urban > 0:
			return {"goal":"first_upgraded_home" if first else "more_upgraded_homes","step":"construct_hut","first":first}
	return {"goal":"maintain_shared_production","step":"blocked_or_complete","first":first}

func resource_value(sim: ReservationSimulation, resource: String, stock: Dictionary, goal: Dictionary) -> float:
	match resource:
		"grain":
			if sim.state.market.grain < 4: return 30.0
			if sim.state.market.grain < 8: return 16.0
			return 2.0
		"brick":
			if stock.brick < 1 and goal.step in ["upgrade","construct_hut"]: return 24.0
			return 4.0 if sim.state.market.brick < 2 else 0.5
		"wood":
			if stock.wood < 3 and goal.step in ["upgrade","construct_hut"]: return 12.0
			return 3.0 if sim.state.market.wood < 4 else 0.5
		"clay":
			return 6.0 if sim.state.market.clay < 2 else 0.5
		"luxury":
			var upgraded = false
			for id in sim.state.buildings:
				if sim.is_housing(id) and sim.state.buildings[id].level == 2:
					upgraded = true
			return 14.0 if upgraded and sim.state.market.luxury < 3 else 0.5
		"pop": return 3.0
	return 0.0

func work_score(sim: ReservationSimulation, id: String, stock: Dictionary, goal: Dictionary) -> Dictionary:
	var gain = 0.0
	var cost = 0.0
	var projected: Dictionary = stock.duplicate()
	for r in sim.outputs(id):
		for i in range(int(sim.outputs(id)[r])):
			gain += resource_value(sim, r, projected, goal)
			projected[r] += 1
	for r in sim.inputs(id):
		cost += float(sim.inputs(id)[r]) * (3.0 if r == "pop" else 0.25 * resource_value(sim, r, stock, goal))
	return {"output_value":gain,"input_cost":-cost,"total":gain - cost}

func best_use_for_pop(sim: ReservationSimulation, stock: Dictionary, goal: Dictionary) -> float:
	var score = 0.0
	var with_pop: Dictionary = stock.duplicate()
	with_pop.pop += 1
	for id in sim.state.revealed:
		if not sim.is_housing(id) and id not in sim.state.used and sim._can_pay(with_pop, sim.inputs(id)):
			score = maxf(score, work_score(sim, id, with_pop, goal).total)
		if id == goal.get("building", "") and goal.step == "upgrade" and sim._can_pay(with_pop, sim.rules.housing_upgrade_cost):
			score = maxf(score, 110.0 if goal.first else 45.0)
	if sim._can_pay(with_pop, sim.rules.construct_cost):
		if goal.step == "construct_hut":
			score = maxf(score, 50.0)
		if sim.state.terrain_free.get("field", 0) > 0 and sim.state.market.grain < 8:
			score = maxf(score, 50.0)
	return score

func decide(simulation: TownSimulation) -> Dictionary:
	var sim = simulation as ReservationSimulation
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
				score = 10.0 if h.inventory.influence < 3 and goal.step == "claim" else 0.0
				reasons.append("End round participation and gain one influence")
			"claim":
				if sim.is_housing(action.building) and goal.step == "claim":
					score = 100.0 if goal.first else 35.0 * float(h.bias.ownership)
					reasons.append("Three influence secures a home claim")
				elif not goal.first and not sim.is_housing(action.building):
					if sim.outputs(action.building).has("grain") and sim.state.market.grain < 8:
						score = 40.0
					else:
						score = 1.0 if h.inventory.influence >= 6 else -1.0
					reasons.append("Claim industry to enable its later upgrade")
			"upgrade":
				if sim.is_housing(action.building):
					score = 120.0 if goal.first else 45.0 * float(h.bias.ownership)
					reasons.append("Upgrade existing urban footprint to two-pop output")
				else:
					score = 50.0 if sim.outputs(action.building).has("grain") and sim.state.market.grain < 8 else (8.0 if not goal.first else -1.0)
					reasons.append("Increase shared production capacity")
			"construct_hut":
				if goal.step == "construct_hut":
					score = 65.0 if goal.first else 28.0 * float(h.bias.ownership)
					reasons.append("Build a public hut on an urban plot; ownership requires a separate claim")
			"construct":
				var output: Dictionary = sim.definition(action.building).outputs
				if output.has("grain"):
					score = 70.0 if sim.state.market.grain < 4 else (40.0 if sim.state.market.grain < 8 else -1.0)
				elif not goal.first:
					for r in output:
						score = maxf(score, resource_value(sim, r, stock, goal) - 4.0)
				reasons.append("Develop an appropriate urban workshop or rural resource plot")
			"activate":
				if sim.is_housing(action.building):
					var use = best_use_for_pop(sim, stock, goal)
					if stock.pop == 0 and use > 0.5:
						score = use * 0.8 + 5.0 + (1.0 if sim.state.buildings[action.building].level == 2 else 0.0)
					components.planned_pop_use = use
					reasons.append("Feed housing to reserve pops for a concrete next activity")
				else:
					components = work_score(sim, action.building, stock, goal)
					score = float(components.total) * float(h.bias.production)
					reasons.append("Spend one available pop and inputs; reserve output until next personal action ends")
		if action.type != "pass" and score < 0.5:
			score = -1.0
		components.total = snappedf(score, 0.001)
		candidates.append({"action":action.duplicate(true),"score":components.total,"components":components,"reasons":reasons})
	var best: Dictionary = candidates[0]
	for candidate in candidates:
		if candidate.score > best.score:
			best = candidate
	return {"house":h.id,"round":sim.state.round,"policy_version":"reservations_1","objective":goal,"accessible_stock":stock,
		"candidates":candidates,"chosen":best.action.duplicate(true),"score":best.score}

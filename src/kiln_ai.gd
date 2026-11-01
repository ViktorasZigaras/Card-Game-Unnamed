class_name KilnAI
extends PriorityAI
func decide(simulation: TownSimulation) -> Dictionary:
	var sim = simulation as CapacitySimulation
	var decision = super.decide(sim)
	var unfinished = int(decision.unfinished_houses)
	var local_route = sim.state.buildings.kiln.built and sim.total_physical("clay") > 0
	for c in decision.candidates:
		var a: Dictionary = c.action
		if a.type == "build_kiln":
			c.score = 155 if unfinished > 0 and not sim.state.clay_contract.is_empty() and sim.total_physical("brick") < unfinished else -1
			c.reasons.append("Invest two wood and labour in a shared clay-to-brick route for unfinished homes")
		if a.type == "activate" and a.building == "kiln":
			c.score = 150-float(sim.payment_plan(sim.current_house().id,{"clay":1,"pop":1},"kiln").total_influence) if unfinished > 0 and sim.total_physical("brick") < unfinished else -1
			c.reasons.append("Make an upgrade brick locally from imported clay and labour")
		if local_route and a.type == "buy_brick" and c.score > 0: c.score = 100
		if local_route and a.type == "activate" and a.building == "carpenter" and c.score > 0: c.score = 45
		c.components.total = c.score
	var best: Dictionary = decision.candidates[0]
	for c in decision.candidates:
		if c.score > best.score: best = c
	decision.chosen = best.action.duplicate(true)
	decision.score = best.score
	decision.policy_version = "kiln_comparison_1"
	decision.local_brick_route = local_route
	return decision

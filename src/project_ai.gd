class_name ProjectAI
extends TradeAI
func decide(simulation: TownSimulation) -> Dictionary:
	var sim = simulation as ProjectSimulation
	var decision = super.decide(sim)
	var h = sim.current_house()
	var settled = decision.house_objective == "prestige"
	var chapel_need: Dictionary = sim.remaining("chapel")
	for c in decision.candidates:
		var a: Dictionary = c.action
		if a.type == "upgrade" and sim.is_housing(a.building): c.score = 300
		if a.type == "upgrade" and a.building == "chapel": c.score = 210 if settled else -1
		if a.type == "contribute_upgrade":
			var quantity = 0
			for n in a.bundle.values(): quantity += int(n)
			c.score = 200+10*quantity+(20 if a.bundle.has("brick") else 0) if sim.is_housing(a.building) else 190+quantity if settled else -1
			c.reasons.append("Consume goods into persistent upgrade progress; they cannot be bought away later")
		if a.type == "buy_stone":
			c.score = 205 if settled and sim.state.buildings.chapel.level == 1 and int(chapel_need.get("stone",0)) > sim.total_physical("stone") else -1
		if a.type == "take" and sim.owned_huts(h.id,true).is_empty():
			for id in sim.owned_huts(h.id):
				if sim.remaining(id).get(a.resource,0) == 0: c.score = -1
		c.components.total = c.score
	var best: Dictionary = decision.candidates[0]
	for c in decision.candidates:
		if c.score > best.score: best = c
	decision.chosen = best.action.duplicate(true)
	decision.score = best.score
	decision.policy_version = "partial_projects_1"
	return decision

class_name PriorityAI
extends ContractAI
func cancellation_assessment(sim: PrioritySimulation,action: Dictionary) -> Dictionary:
	var h = sim.current_house()
	var incomplete = sim.owned_huts(h.id,true).is_empty()
	var locked = incomplete and sim.free_pop_tokens() == 0 and sim.total_physical("pop") == 0
	var report = {"objective":"finish own brick home" if incomplete else "no blocked housing objective","resource":"pop","physical_pop":sim.total_physical("pop"),"committed_pop":sim.state.committed_pops,"alternatives":{},"justified":false}
	report.alternatives.paid_access = "no physical labour token exists to buy" if locked else "existing physical labour or free capacity remains; cancellation not justified"
	report.alternatives.imports = "current caravan does not import labour; other imports do not release committed tokens"
	report.alternatives.upgrade = "extra labour still needs a free token below the local cap"
	report.alternatives.production = "all token capacity is committed" if locked else "ordinary supply routes remain possible"
	if not locked: return report
	var clone: PrioritySimulation = sim.get_script().new()
	clone.restore(sim.snapshot())
	var result = clone.apply(action)
	var route = false
	if result.ok and clone.free_pop_tokens() > 0:
		for id in clone.state.buildings:
			if not clone.state.buildings[id].built: continue
			for mode in clone.modes(id):
				if mode.outputs.get("pop",0) > 0 and clone.payment_plan(h.id,mode.inputs,id).ok: route = true
	report.justified = route
	report.counterfactual = {"free_pop_after_cancel":clone.free_pop_tokens(),"housing_recipe_fundable":route,"wait_for_card_may_be_needed":true}
	return report
func decide(simulation: TownSimulation) -> Dictionary:
	var sim = simulation as PrioritySimulation
	var decision = super.decide(sim)
	var h = sim.current_house()
	var done = not sim.owned_huts(h.id,true).is_empty()
	var unfinished = int(decision.unfinished_houses)
	var reviews: Array = []
	for c in decision.candidates:
		var a: Dictionary = c.action
		if a.type == "cancel_contract":
			var assessment = cancellation_assessment(sim,a)
			c.cancellation_assessment = assessment
			reviews.append({"resource":a.resource,"assessment":assessment})
			c.score = 145 if assessment.justified else -1
		if a.type == "buy_contract":
			var t = sim.title(a.resource)
			c.score = -1
			var scarce = not sim.public_plan({a.resource:1}).ok
			var need = a.resource in ["wood","pop","brick","furniture"] if not done else a.resource in ["wood","grain","clay"]
			if need and (scarce or t.owner == ""):
				c.score = (72 if not done else 38)-int(t.price)*2
				c.reasons.append("Buy one-token recurring priority; prestige is consumed and future buyout price increases")
		if a.type == "upgrade" and not sim.is_housing(a.building):
			c.score = -1
			if done and unfinished > 0 and sim.total_physical("brick") > unfinished and a.building in ["lumber_camp","grain_farm"]: c.score = 75
		if a.type == "secure_contract" and a.resource == "pop" and not done:
			# Linked housing can now be upgraded off-card; allow it when labour is actually scarce.
			if sim.total_physical("pop") < 1 and sim.free_pop_tokens() >= 2: c.score = 85
		c.components.total = c.score
	var best: Dictionary = decision.candidates[0]
	for c in decision.candidates:
		if c.score > best.score: best = c
	decision.chosen = best.action.duplicate(true)
	decision.score = best.score
	decision.policy_version = "priority_1"
	decision.cancellation_reviews = reviews
	return decision

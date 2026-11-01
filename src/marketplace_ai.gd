class_name MarketplaceAI
extends HouseAI
## Goal-driven scenario policy: supply the town milestone chain, then improve a home.
func phase(sim: MarketplaceSimulation) -> String:
	if not sim.state.buildings.marketplace.built: return "wooden_market"
	if sim.state.clay_contract.is_empty(): return "clay_import"
	return "brick_house"

func decide(simulation: TownSimulation) -> Dictionary:
	var sim = simulation as MarketplaceSimulation
	var h = sim.current_house()
	var stage = phase(sim)
	var stock = sim.available(h.id)
	var need_furniture = 1 if stage != "wooden_market" and (sim.state.clay_contract.is_empty() or sim.total_physical("brick") == 0) else 0
	var candidates: Array = []
	for action in sim.legal_actions():
		var score = -1.0
		var components: Dictionary = {}
		var reasons: Array = []
		match action.type:
			"pass":
				score = 0.0
				reasons.append("Wait; re-enter if other houses make useful goods available")
			"build_market":
				score = 180.0 - sim.payment_plan(h.id,sim.rules.market_cost).total_influence
				reasons.append("Town needs a wooden marketplace to attract the caravan; earn two prestige")
			"secure_clay_contract":
				score = 180.0 - sim.payment_plan(h.id,sim.rules.clay_setup_cost).total_influence
				reasons.append("Commit chest and artisan capacity to the standing export line; import clay and earn three prestige")
			"buy_brick":
				if sim.total_physical("brick") < 1: score = 140.0 - sim.payment_plan(h.id,sim.rules.brick_price).total_influence
				reasons.append("Barter one wooden chest for the otherwise unavailable brick")
			"claim":
				if sim.is_housing(action.building) and sim.owned_huts(h.id).is_empty(): score = 100.0
				reasons.append("Secure a home that can be improved once imported brick is available")
			"upgrade":
				score = 220.0 - sim.payment_plan(h.id,sim.rules.housing_upgrade_cost).total_influence
				reasons.append("Build a decent brick home and earn five prestige")
			"convert_prestige":
				if h.inventory.influence >= 8 and not sim.owned_huts(h.id).is_empty(): score = 2.0
				reasons.append("Use surplus influence in the one-way prestige conversion")
			"take":
				var target = 0
				if action.resource == "furniture" and need_furniture > 0: target = 1
				if action.resource == "brick" and not sim.owned_huts(h.id).is_empty(): target = 1
				if action.resource == "pop" and stage != "wooden_market": target = 1
				if action.resource == "wood" and stage == "brick_house": target = 1
				if target > h.stockpile[action.resource]: score = 12.0
				reasons.append("Save a specific input for a forthcoming caravan or house improvement")
			"return":
				if sim.pile_size(h.id) == 3 and action.resource in ["grain","clay","luxury"]: score = 3.0
				reasons.append("Release an unneeded cache token to make room for a milestone input")
			"activate":
				var recipe = sim.recipe(action)
				var payment = sim.payment_plan(h.id,recipe.inputs,action.building)
				match action.building:
					"chapel":
						if h.inventory.influence < 3 and sim.owned_huts(h.id).is_empty(): score = 95.0
						elif h.inventory.influence < 5: score = 25.0
					"lumber_camp":
						var target = 3 if stage == "wooden_market" else 6
						if stock.wood < target: score = 65.0 * float(h.bias.production)
					"grain_farm":
						if sim.state.market.grain < 3: score = 70.0 * float(h.bias.production)
					"carpenter":
						if need_furniture > 0 and sim.total_physical("furniture") < 2: score = 115.0 * float(h.bias.production)
					_:
						if sim.is_housing(action.building) and stock.pop < 1:
							var needs_pop = stage == "wooden_market" or need_furniture > 0 or sim.total_physical("brick") > 0 or (sim.state.caravan.present and sim.state.clay_contract.is_empty())
							if needs_pop: score = 80.0
				score -= float(payment.total_influence)
				components.access_cost = -payment.total_influence
				reasons.append("Produce an input for the current town milestone")
		if action.type != "pass" and score < 0.5: score = -1.0
		components.total = snappedf(score,0.001)
		candidates.append({"action":action.duplicate(true),"score":components.total,"components":components,"reasons":reasons})
	var best: Dictionary = candidates[0]
	for candidate in candidates:
		if candidate.score > best.score: best = candidate
	return {"house":h.id,"round":sim.state.round,"policy_version":"marketplace_1","town_objective":stage,"accessible_stock":stock,"pop_reserve":sim.free_pop_tokens(),"committed_pops":sim.state.committed_pops,"caravan":sim.state.caravan.duplicate(true),"candidates":candidates,"chosen":best.action.duplicate(true),"score":best.score}

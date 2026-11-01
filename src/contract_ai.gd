class_name ContractAI
extends MarketplaceAI
func decide(simulation: TownSimulation) -> Dictionary:
	var sim = simulation as ContractSimulation
	var decision = super.decide(sim)
	var h = sim.current_house()
	var done = not sim.owned_huts(h.id,true).is_empty()
	var unfinished = 0
	for other in sim.state.houses:
		if sim.owned_huts(other.id,true).is_empty(): unfinished += 1
	var max_work = 0.0
	for c in decision.candidates:
		var a: Dictionary = c.action
		var score = float(c.score)
		if done:
			if a.type in ["take","claim","upgrade"]: score = -1
			if a.type == "activate":
				score = -1
				if a.building == "lumber_camp" and sim.state.market.wood < (6 if unfinished else 3): score = 65
				if a.building == "grain_farm" and sim.state.market.grain < 3: score = 70
				if a.building == "carpenter" and unfinished > 0 and sim.total_physical("brick") < unfinished and sim.total_physical("furniture") < 2: score = 90
				if sim.is_housing(a.building) and sim.total_physical("pop") < (2 if unfinished else 1): score = 75
				if a.building == "chapel" and h.inventory.influence < 5: score = 25
			if a.type == "buy_brick" and unfinished == 0: score = -1
		if a.type == "convert_prestige" and h.inventory.influence >= 5: score = 45 if done else score
		if a.type == "secure_contract":
			match a.resource:
				"wood": score = 130 if sim.total_physical("wood") < 8 else -1
				"grain": score = 110 if sim.total_physical("grain") < 5 else -1
				"furniture": score = 105 if unfinished > 0 and sim.total_physical("furniture") < 2 else -1
				"pop": score = 95 if sim.total_physical("pop") < 3 else -1
				"brick": score = 115 if unfinished > 0 and sim.total_physical("brick") < unfinished else -1
				"luxury": score = 35 if done and sim.total_physical("luxury") < 3 else -1
		if a.type == "cancel_contract":
			var contract = sim.contract_for(a.resource)
			score = 80 if sim.total_physical(a.resource) > 8 or contract.streak >= 3 else -1
			if a.resource == "clay": score = -1
		if a.type == "demolish":
			score = -1
			if unfinished == 0 and a.building in ["lumber_camp","grain_farm"]:
				var resource = "wood" if a.building == "lumber_camp" else "grain"
				if sim.total_physical(resource) > 12: score = 20
		if a.type == "bulk_exchange": score = 30 if h.inventory.influence <= 7 else -1
		c.score = score
		if a.type not in ["pass","take","return","bulk_exchange","convert_prestige"]: max_work = maxf(max_work,score)
	# Idle collecting is deterministic but varied; deciding/previews do not advance the RNG.
	for c in decision.candidates:
		if c.action.type == "take" and max_work < 1 and (done or h.first_claim_round > 0):
			c.score = 10 + posmod(hash("%s:%s:%s:%s" % [sim.state.seed,h.id,sim.state.round,c.action.resource]),7)
	if int(sim.rules.contract_batch) >= 2:
		var reserves = {"wood":2*unfinished+1,"grain":3,"pop":unfinished+1,"brick":unfinished,"furniture":unfinished+(1 if sim.state.clay_contract.is_empty() else 0),"clay":0,"luxury":0}
		for c in decision.candidates:
			var a: Dictionary = c.action
			if a.type == "secure_contract":
				if a.resource == "pop" and not done: c.score = -1
				if a.resource == "furniture" and sim.state.market.wood < 8: c.score = -1
				if a.resource == "brick" and sim.total_physical("furniture") < 2: c.score = -1
			if a.type == "cancel_contract":
				c.score = -1
				if a.resource in ["brick","furniture"] and unfinished == 0: c.score = 60
				if a.resource == "luxury" and sim.total_physical("luxury") >= 4: c.score = 40
			if a.type == "take":
				var r = str(a.resource)
				if done or max_work < 1:
					c.score = -1
					if sim.total_physical(r) > reserves.get(r,0)+1 and int(sim.state.market[r]) > reserves.get(r,0):
						c.score = 10+posmod(hash("%s:%s:%s:%s" % [sim.state.seed,h.id,sim.state.round,r]),7)
			if a.type == "return" and done and h.stockpile[a.resource] > 0 and sim.state.market[a.resource] < reserves.get(a.resource,0): c.score = 120
			if a.type == "bulk_exchange":
				for r in sim.rules.goods:
					if h.stockpile[r] > 0 and sim.total_physical(r)-h.stockpile[r] < reserves.get(r,0): c.score = -1
	if int(sim.rules.contract_batch) >= 3:
		for c in decision.candidates:
			var a: Dictionary = c.action
			if a.type == "secure_contract":
				if a.resource == "furniture": c.score = 105 if unfinished > 0 and sim.state.market.wood >= 4 else -1
				if a.resource == "pop" and (unfinished == 0 or sim.free_pop_tokens() < 2): c.score = -1
				if a.resource == "luxury" and (sim.state.market.wood < 6 or sim.free_pop_tokens() < 2): c.score = -1
			if a.type == "cancel_contract" and unfinished == 0:
				if a.resource == "pop" and sim.contract_for("pop").streak >= 4: c.score = 65
				if a.resource == "luxury" and sim.total_physical("luxury") >= 3: c.score = 55
	for c in decision.candidates:
		c.components.total = c.score
		c.reasons.append("Contract economy batch %d; score includes shared demand, completed-home support and idle surplus rules" % sim.rules.contract_batch)
	var best: Dictionary = decision.candidates[0]
	for c in decision.candidates:
		if c.score > best.score: best = c
	decision.chosen = best.action.duplicate(true)
	decision.score = best.score
	decision.policy_version = "contract_batch_%d" % sim.rules.contract_batch
	decision.completed_home = done
	decision.unfinished_houses = unfinished
	return decision

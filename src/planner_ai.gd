class_name PlannerAI
extends HouseAI
## Explicit and inspectable control flow; legacy policies are regression references.
const FORECAST_ROUNDS = 6
const MIN_BRIDGE_UNITS = 3
func phase(sim: MarketplaceSimulation) -> String:
	if not sim.state.buildings.marketplace.built: return "wooden_market"
	if sim.state.clay_contract.is_empty(): return "clay_import"
	return "brick_house"

func seed_candidates(simulation: TownSimulation) -> Dictionary:
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
	return {"house":h.id,"round":sim.state.round,"policy_version":"marketplace_1","town_objective":stage,"accessible_stock":stock,"pop_reserve":sim.free_pop_tokens(),"committed_pops":sim.state.committed_pops,"caravan":sim.state.caravan.duplicate(true),"candidates":candidates,"chosen":{},"score":-1}

# CONTRACT POLICY
func score_contract(simulation: TownSimulation, decision: Dictionary) -> void:
	var sim = simulation as ContractSimulation
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
	decision.completed_home = done
	decision.unfinished_houses = unfinished
	return

# PRIORITY POLICY
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
func score_priority(simulation: TownSimulation, decision: Dictionary) -> void:
	var sim = simulation as PrioritySimulation
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
	decision.cancellation_reviews = reviews
	return

# KILN POLICY
func score_kiln(simulation: TownSimulation, decision: Dictionary) -> void:
	var sim = simulation as CapacitySimulation
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
	decision.local_brick_route = local_route
	return

# TRADE POLICY
func score_trade(simulation: TownSimulation, decision: Dictionary) -> void:
	var sim = simulation as TradeSimulation
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
	decision.house_objective = phase
	return

# PROJECT POLICY
func score_project(simulation: TownSimulation, decision: Dictionary) -> void:
	var sim = simulation as ProjectSimulation
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
	return

# STOCKADE POLICY
func score_stockade(simulation: TownSimulation, decision: Dictionary) -> void:
	var sim = simulation as StockadeSimulation
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
	return

# HALL POLICY
func score_hall(simulation: TownSimulation, decision: Dictionary) -> void:
	var sim = simulation as HallSimulation
	if not sim.rules.halls_enabled: return
	var h = sim.current_house()
	var settled = decision.house_objective == "prestige"
	var hall = sim.hall_id(h.id)
	var needs_hall = not sim.state.buildings[hall].built
	var mill_ready = sim.state.buildings.small_sawmill.built
	var hall_route = mill_ready and (sim.state.terrain_free.urban > 0 or sim.state.houseworks.sites.has(hall))
	var plank_need = 0
	for other in sim.state.houses:
		var id = sim.hall_id(other.id)
		if not sim.state.buildings[id].built: plank_need += int(sim.site_remaining(id).get("planks",0))
	for c in decision.candidates:
		var a: Dictionary = c.action
		if a.type in ["start_site","supply_site"]:
			var units = 0
			for n in a.bundle.values(): units += int(n)
			c.score = -1
			if settled:
				if a.type == "supply_site": c.score = 240+units
				elif a.building == "small_sawmill" and sim.claim_count() > 0: c.score = 235+units
				elif a.building == hall and mill_ready and a.bundle.has("planks"): c.score = 245+units
			c.reasons.append("Reserve genuine paid construction progress; keep the two original vacant rural plots for conversion")
		if a.type == "hall_work":
			c.score = -1
			if a.recipe == "brick" and sim.total_physical("brick") < (decision.unfinished_houses+2): c.score = 150
			if a.recipe == "furniture" and sim.state.clay_contract.is_empty() and sim.total_physical("furniture") < 1: c.score = 150
			c.reasons.append("One chosen unlocked workshop recipe; inputs consumed, output priority lasts only until the next action")
		if a.type == "activate":
			if a.building == "small_sawmill": c.score = 215 if settled and sim.total_physical("planks") < plank_need else -1
			if settled and sim.is_housing(a.building) and sim.total_physical("pop") < 2 and (needs_hall or not mill_ready): c.score = maxf(c.score,130)
			if settled and a.building == "chapel" and needs_hall and hall_route and h.inventory.influence < 3: c.score = maxf(c.score,140)
		if a.type == "buy_stone" and settled and needs_hall and hall_route and sim.site_remaining(hall).has("stone") and sim.total_physical("stone") < 1: c.score = 225
		if a.type == "convert_prestige" and needs_hall and hall_route and h.inventory.influence < 8: c.score = -1
		if a.type == "bulk_exchange" and needs_hall:
			if h.stockpile.planks > 0 or h.stockpile.stone > 0: c.score = -1
		if a.type == "take" and a.resource == "planks": c.score = -1
		c.components.total = c.score
	return

# DEVELOPMENT POLICY
func development_plan(sim: DevelopmentSimulation) -> Dictionary:
	var h = sim.current_house()
	var phase = "home" if sim.owned_huts(h.id,true).is_empty() else "industry" if sim.industries(h.id).is_empty() else "hall" if not sim.state.buildings[sim.hall_id(h.id)].built else "leftovers"
	var p = {"objective":phase,"route":"ordinary development","target":"","clear_price":0,"reason":"","alternatives":[]}
	if phase != "hall": return p
	if sim.state.houseworks.sites.has(sim.hall_id(h.id)):
		p.route = "finish protected site"
		p.reason = "Land secured; acquire and pay the remaining physical inputs"
	elif sim.state.terrain_free.urban > 0:
		p.route = "vacant plot"
		p.reason = "Vacant land avoids destroying a function or cancelling a right"
	elif sim.conversion_count() < 2:
		p.route = "town expansion"
		p.reason = "A visible stockade conversion route remains; do not destroy urban production first"
	else:
		p.route = "blocked"
		var best = 100000
		for key in sim.state.buildings:
			var id = str(key)
			if not sim.eligible_clear(id) or sim.state.buildings[id].plot != "urban": continue
			var loss = 0 if id == "carpenter" and not sim.state.clay_contract.is_empty() else 30 if id == "kiln" else 100 if id == "marketplace" else 500
			var safe = true
			if id == "marketplace":
				# Acquire the physical construction bundle before retiring the stone/caravan gateway.
				safe = true
				if sim is ExpeditionSimulation and not sim.state.clay_contract.is_empty():
					safe = safe and sim.state.exploration.routes.any(func(r): return r.active and r.resource == "clay" and r.delivered > 0)
			var price = sim.clear_price(id)
			p.alternatives.append({"building":id,"prestige":price,"lost_function_penalty":loss,"safe":safe,"materials_ready":sim.payment_plan(h.id,sim.site_cost(sim.hall_id(h.id))).ok})
			if safe and price+loss < best:
				best = price+loss
				p.target = id
				p.clear_price = price
		if p.target != "":
			p.route = "prepare replacement"
			p.reason = "Vacant land and conversion allowances exhausted; pay social clearance, then construct separately"
		else: p.reason = "No safe currently visible clearance route; retain inputs and observe other trade/production opportunities"
	return p
func score_development(simulation: TownSimulation, d: Dictionary) -> void:
	var sim = simulation as DevelopmentSimulation
	var h = sim.current_house()
	var p = development_plan(sim)
	var hall = sim.hall_id(h.id)
	var advanced = p.objective in ["hall","leftovers"]
	var plank_need = 0
	var prospective = int(sim.state.terrain_free.urban)
	for other in sim.state.houses:
		var id = sim.hall_id(other.id)
		if sim.protected_site(id): plank_need += int(sim.site_remaining(id).get("planks",0))
		elif not sim.state.buildings[id].built and prospective > 0:
			plank_need += 3
			prospective -= 1
	if p.route == "prepare replacement" and not sim.state.houseworks.sites.has(hall): plank_need += 3
	for c in d.candidates:
		var a: Dictionary = c.action
		if a.type == "claim_site":
			c.score = -1
			if a.building == "marketplace" and a.replace == "": c.score = 185
			if a.building == "kiln" and not sim.state.clay_contract.is_empty() and a.replace == "": c.score = 160
			if a.building == "small_sawmill" and advanced and sim.claim_count() > 0 and a.replace == "": c.score = 236
			if a.building == hall and advanced and sim.state.buildings.small_sawmill.built and sim.total_physical("planks") > 0:
				if a.replace == "" and p.route == "vacant plot": c.score = 255
				elif a.replace == p.target and p.route == "prepare replacement" and sim.payment_plan(h.id,sim.site_cost(hall)).ok: c.score = 235
			c.reasons = [p.reason if a.building == hall else "Social action reserves a protected site; materials require a later action"]
		if a.type == "supply_site":
			var units = 0
			for n in a.bundle.values(): units += int(n)
			c.score = (245 if a.building == hall else 238 if a.building == "small_sawmill" else 180 if a.building == "marketplace" else 165)+units
		if a.type == "activate" and a.building == "small_sawmill": c.score = 216 if advanced and sim.total_physical("planks") < plank_need else -1
		if a.type == "redevelop_occupied": c.score = 140 if advanced and p.route == "town expansion" else -1
		if a.type == "claim_rural": c.score = 181 if advanced else -1
		if a.type == "buy_stone" and p.objective == "hall" and sim.site_remaining(hall).has("stone") and sim.total_physical("stone") < 1: c.score = 226
		if a.type == "activate" and a.building == "chapel" and p.objective == "hall" and h.inventory.influence < 8: c.score = maxf(c.score,142)
		if a.type in ["buy_prestige","buy_contract","demolish"] and p.objective != "leftovers": c.score = -1
		if a.type == "convert_prestige" and p.objective == "hall":
			c.score = 145 if p.route == "prepare replacement" and h.inventory.prestige < p.clear_price and h.inventory.influence >= 8 else -1
		if a.type in ["take","return"] and c.score <= 20:
			for e in sim.state.history:
				if e.house == h.id and int(e.round) == int(sim.state.round) and e.action.get("resource","") == a.resource and e.action.type in ["take","return"]:
					if e.action.type != a.type: c.score = -1
		c.components.total = c.score
	d.house_objective = p.objective
	d.development_plan = p
	d.feasible_plank_demand = plank_need
	return

# EXPEDITION POLICY
func score_expedition(simulation: TownSimulation, d: Dictionary) -> void:
	var sim = simulation as ExpeditionSimulation
	var h = sim.current_house()
	var trip = sim.trip_for(h.id)
	var useful_trade = false
	var operating_reserve = 0
	for route in sim.state.exploration.routes:
		if route.active and route.owner == h.id: operating_reserve += int(route.unit_price)
	for c in d.candidates:
		var a: Dictionary = c.action
		if a.type == "launch_expedition":
			c.score = 115 if d.house_objective == "leftovers" and sim.total_physical("grain") > 1 and sim.total_physical("pop") >= 2 else -1
			c.reasons = ["Use available land transport and hold a real crew; seek finite sponsor-specific offers"]
		if a.type == "expedition_sell":
			var offer: Dictionary = trip.sell[int(a.offer)]
			var plan = sim.payment_plan(h.id,{offer.resource:1})
			var reserve = 2 if offer.resource in ["grain","wood","pop"] else 1 if offer.resource in ["stone","planks"] else 0
			c.score = 205 if sim.total_physical(offer.resource) > reserve and plan.total_influence <= 1 else -1
			if c.score > 0: useful_trade = true
			c.reasons = ["Sell legally accessible surplus; access fees still pay rival holders"]
		if a.type == "expedition_contract":
			var offer: Dictionary = trip.buy[int(a.offer)]
			c.score = 260 if offer.resource == "clay" and sim.clay_needed() and h.inventory.gold >= int(offer.price)+1 else -1
			if sim.state.exploration.routes.any(func(r): return r.active and r.resource == offer.resource): c.score = -1
			if c.score > 0: useful_trade = true
			c.reasons = ["Secure useful missing clay with owned priority; permanently commit transport, pay recurring gold"]
		if a.type == "expedition_buy":
			var offer: Dictionary = trip.buy[int(a.offer)]
			var need = (offer.resource == "clay" and sim.clay_needed()) or (offer.resource == "stone" and sim.remaining("chapel").has("stone")) or (offer.resource == "wood" and sim.total_physical("wood") < 2) or (offer.resource == "grain" and sim.total_physical("grain") < 2)
			c.score = 200 if need and h.inventory.gold >= offer.price else -1
			if c.score > 0: useful_trade = true
			c.reasons = ["Purchase a finite cargo unit; it is unavailable until the expedition returns"]
		if a.type == "return_expedition": c.score = -1
		if a.type in ["buy_route","cancel_route"]: c.score = -1
		if a.type == "buy_prestige" and h.inventory.gold-int(sim.rules.prestige_gold_price) < operating_reserve: c.score = -1
		if a.type == "buy_stone" and h.inventory.gold-int(sim.rules.stone_gold_price) < operating_reserve: c.score = -1
		if a.type == "expedition_buy" and h.inventory.gold-int(trip.buy[int(a.offer)].price) < operating_reserve: c.score = -1
		if a.type == "cancel_route":
			var route = sim.route_by_id(int(a.route))
			if route.owner == h.id and route.misses >= 3 and h.inventory.gold < route.unit_price: c.score = 185
			c.reasons = ["Withdraw an owned repeatedly unfunded route to recover scarce transport; cancellation still consumes prestige"]
		c.components.total = c.score
	for c in d.candidates:
		if c.action.type == "return_expedition" and not useful_trade:
			c.score = 190
			c.components.total = 190
	d.transport = {"free":sim.transport_free(h.id),"used":sim.transport_used(h.id),"trip":trip.get("status","none")}
	return

# FINANCING POLICY
func needed_units(sim: ExpeditionSimulation,resource: String,observation: Dictionary = {}) -> int:
	var o = observation
	if o.is_empty():
		var missing = 0
		for h in sim.state.houses:
			if sim.owned_huts(h.id,true).is_empty(): missing += 1
		var cargo = 0
		for trip in sim.state.exploration.trips: cargo += int(trip.cargo.get(resource,0))
		o = {"missing_homes":missing,"physical_resource":sim.total_physical(resource),"physical_brick":sim.total_physical("brick"),"cargo_resource":cargo}
	if resource == "clay":
		# Two-unit working buffer is a policy target, not a new town demand rule.
		return maxi(0,int(o.missing_homes)+2-int(o.physical_brick)-int(o.physical_resource)-int(o.cargo_resource))
	if resource == "stone":
		var need = int(sim.remaining("chapel").get("stone",0))
		for h in sim.state.houses:
			if not sim.state.buildings[sim.hall_id(h.id)].built: need += int(sim.site_remaining(sim.hall_id(h.id)).get("stone",0))
		return maxi(0,need-int(o.physical_resource)-int(o.cargo_resource))
	if resource in ["grain","wood"]: return maxi(0,2-int(o.physical_resource)-int(o.cargo_resource))
	return 0
func caravan_opportunities(sim: ExpeditionSimulation,horizon: int) -> int:
	if not sim.state.buildings.marketplace.built: return 0
	var count = 0
	for future in range(int(sim.state.round)+1,int(sim.state.round)+horizon+1):
		if future >= int(sim.state.caravan.first_round) and (future-int(sim.state.caravan.first_round)) % int(sim.rules.caravan_interval) == 0: count += 1
	return count
func assess_offer(sim: ExpeditionSimulation,offer: Dictionary) -> Dictionary:
	var h = sim.current_house()
	var price = int(offer.price)
	var need = mini(FORECAST_ROUNDS,needed_units(sim,offer.resource))
	var horizon = maxi(MIN_BRIDGE_UNITS,need)
	var upkeep = horizon*price
	var setup = price
	var social = int(sim.rules.expedition_contract_prestige)
	var exit_price = social+2+3
	var reward = int(sim.rules.expedition_clay_reward) if offer.resource == "clay" and sim.clay_needed() and not sim.state.exploration.clay_rewarded else 0
	var opportunities = caravan_opportunities(sim,horizon)
	var direct_units = mini(int(offer.left),need)
	var bridge = need >= MIN_BRIDGE_UNITS and need > direct_units and h.inventory.gold >= setup+upkeep and h.inventory.prestige >= maxi(social,social+exit_price-reward)
	return {"resource":offer.resource,"needed_units":need,"forecast_rounds":horizon,"setup_gold":setup,"operating_gold":upkeep,"cash_now":int(h.inventory.gold),"cash_shortfall":maxi(0,setup+upkeep-int(h.inventory.gold)),"guaranteed_recurring_gold":0,"shared_export_upper_bound":opportunities,"optimistic_operating_balance":opportunities-upkeep,"social_setup":social,"expected_town_prestige":reward,"exit_prestige":exit_price,"exit_prestige_shortfall":maxi(0,social+exit_price-reward-int(h.inventory.prestige)),"finite_units_available":direct_units,"finite_gold_cost":direct_units*price,"recurring_sustainable":false,"prefunded_bridge":bridge,"choice":"prefunded limited bridge" if bridge else "finite cargo or wait","reason":"Shared caravan income is an upper bound, not secured income; a binding must carry its own operating and exit budget"}
func route_budget(sim: ExpeditionSimulation,route: Dictionary) -> Dictionary:
	var h = sim.house(route.owner)
	var price = int(route.unit_price)
	var origin: Dictionary = route.get("financial_origin",{})
	var start_delivered = int(origin.get("delivered",route.delivered))
	var target = mini(FORECAST_ROUNDS,needed_units(sim,route.resource,origin.get("observation",{})))
	var supplied = maxi(0,int(route.delivered)-start_delivered)
	var remaining = maxi(0,target-supplied)
	var exit_price = int(route.price)+3
	var reserve = remaining*price
	var exhausted = remaining == 0 or h.inventory.gold < price
	return {"route":int(route.id),"target_units":target,"supplied_units":supplied,"remaining_units":remaining,"operating_reserve":reserve,"exit_reserve":exit_price,"cash":int(h.inventory.gold),"exit_affordable":h.inventory.prestige >= exit_price,"stop":exhausted,"reason":"Finite import goal reached" if remaining == 0 else "Next delivery unfunded" if h.inventory.gold < price else "Protect remaining prefunded deliveries and exit cost"}
func score_financing(simulation: TownSimulation, d: Dictionary) -> void:
	var sim = simulation as ExpeditionSimulation
	var h = sim.current_house()
	var trip = sim.trip_for(h.id)
	var assessments: Dictionary = {}
	if not trip.is_empty() and trip.status == "trading":
		for i in trip.buy.size(): assessments[str(i)] = assess_offer(sim,trip.buy[i])
	var budgets: Array = []
	var gold_reserve = 0
	var prestige_reserve = 0
	for route in sim.state.exploration.routes:
		if route.active and route.owner == h.id:
			var b = route_budget(sim,route)
			budgets.append(b)
			gold_reserve += int(b.operating_reserve)
			prestige_reserve += int(b.exit_reserve)
	for c in d.candidates:
		var a: Dictionary = c.action
		if a.type == "expedition_contract":
			var f: Dictionary = assessments[str(int(a.offer))]
			c.score = 260 if f.prefunded_bridge else -1
			if sim.state.exploration.routes.any(func(r): return r.active and r.resource == f.resource): c.score = -1
			c.financing = f
			c.reasons = [f.reason,"Import flow is not accepted as an indefinitely affordable entitlement"]
		if a.type == "expedition_buy":
			var offer: Dictionary = trip.buy[int(a.offer)]
			var need = needed_units(sim,offer.resource)
			c.score = 210 if need > 0 and h.inventory.gold-int(offer.price) >= gold_reserve else -1
			c.reasons = ["Buy only outstanding material need after counting physical supply and cargo already returning"]
		if a.type == "buy_prestige" and h.inventory.gold-int(sim.rules.prestige_gold_price) < gold_reserve: c.score = -1
		if a.type == "buy_stone" and h.inventory.gold-int(sim.rules.stone_gold_price) < gold_reserve: c.score = -1
		if a.type == "buy_contract" and h.inventory.prestige-int(sim.title(a.resource).price) < prestige_reserve: c.score = -1
		if a.type == "demolish" and h.inventory.prestige-sim.clear_price(a.building) < prestige_reserve: c.score = -1
		if a.type == "cancel_route":
			var route = sim.route_by_id(int(a.route))
			c.score = -1
			if route.owner == h.id:
				var b = route_budget(sim,route)
				if b.stop and b.exit_affordable: c.score = 280
				c.financing = b
				c.reasons = [b.reason+"; release transport by paying the real cancellation cost"]
		c.components.total = c.score
	# Re-evaluate departure after all financing vetoes; do not wait on a rejected trade.
	var useful = d.candidates.any(func(c): return c.action.type in ["expedition_buy","expedition_sell","expedition_contract"] and c.score > 0)
	for c in d.candidates:
		if c.action.type == "return_expedition":
			c.score = -1 if useful else 190
			c.components.total = c.score
	d.financing = {"offers":assessments,"routes":budgets,"reserved_gold":gold_reserve,"reserved_prestige":prestige_reserve,"horizon_limit":FORECAST_ROUNDS}
	return

func decide(simulation: TownSimulation) -> Dictionary:
	var sim = simulation as ExpeditionSimulation
	var d = seed_candidates(sim)
	var plan = development_plan(sim)
	d.plan = {"goal":plan.objective,"land_route":plan,"alternatives":[],"budget":{},"next_action":{}}
	var groups = [
		{"name":"town and household needs","steps":[score_contract,score_priority,score_kiln,score_trade]},
		{"name":"development routes","steps":[score_project,score_stockade,score_hall,score_development]},
		{"name":"external opportunities","steps":[score_expedition]},
		{"name":"budget and exit commitments","steps":[score_financing]}]
	for c in d.candidates: c.score_trace = [{"stage":"base town needs","score":c.score}]
	for group in groups:
		for step in group.steps: step.call(sim,d)
		for c in d.candidates: c.score_trace.append({"stage":group.name,"score":c.score})
	var best: Dictionary = d.candidates[0]
	for c in d.candidates:
		if c.score > best.score: best = c
	d.chosen = best.action.duplicate(true)
	d.score = best.score
	d.policy_version = "consolidated_planner_recovery_1"
	d.plan.budget = d.financing.duplicate(true)
	d.plan.next_action = {"action":best.action.duplicate(true),"score":best.score,"reasons":best.reasons.duplicate(),"score_trace":best.score_trace.duplicate(true)}
	for c in d.candidates:
		if c.action.type in ["expedition_buy","expedition_contract","buy_route","own_route","cancel_route"]:
			d.plan.alternatives.append({"action":c.action.duplicate(true),"score":c.score,"assessment":c.get("financing",{}).duplicate(true),"priority_value":c.get("priority_value",{}).duplicate(true),"reasons":c.reasons.duplicate()})
	return d

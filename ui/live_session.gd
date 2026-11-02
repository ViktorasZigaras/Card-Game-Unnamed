extends RefCounted
## Presentation adapter. Commands and previews use the existing authoritative simulation.
var sim: FinancingSimulation
var probe: GameProbe
var frames: Array = []
var run_path := ""

func start(seed_value: int = 7, linked: bool = false) -> void:
	sim = MappedTownSimulation.new()
	sim.batch = 3
	sim.scenario_lumber_link = linked
	sim.start(seed_value)
	_attach("new")

func _attach(reason: String) -> void:
	probe = GameProbe.new()
	probe.policy = PlannerAI.new()
	run_path = "user://runs/ui_%s_%s_%d" % [reason,Time.get_datetime_string_from_system().replace(":","-"),Time.get_ticks_usec()]
	probe.attach(sim,run_path+"/decisions.jsonl")
	frames = [project()]

func step(action: Dictionary = {}) -> Dictionary:
	if sim.state.ended: return {"ok":false,"error":"Scenario complete"}
	if not action.is_empty() and action not in sim.legal_actions(): return {"ok":false,"error":"Action is no longer legal"}
	var result := probe.step(action)
	if result.ok: frames.append(project())
	return result

func save_game() -> Error:
	DirAccess.make_dir_recursive_absolute("user://saves")
	return probe.save_game("user://saves/manual.json")

func load_game() -> Error:
	var error := probe.load_game("user://saves/manual.json")
	if error == OK: _attach("loaded")
	return error

func preview(action: Dictionary) -> Dictionary:
	var p := {"action":action.duplicate(true),"inputs":{},"outputs":{},"free":false,"plan":{},"prestige":0}
	match action.type:
		"activate":
			var recipe = sim.recipe(action)
			p.inputs = recipe.inputs
			p.outputs = recipe.outputs
			p.plan = sim.payment_plan(sim.current_house().id,p.inputs,action.building)
			p.free = p.plan.building_fee > 0
		"upgrade", "build_market", "secure_clay_contract", "buy_brick":
			var costs := {"upgrade":"housing_upgrade_cost","build_market":"market_cost","secure_clay_contract":"clay_setup_cost","buy_brick":"brick_price"}
			p.inputs = sim.remaining(action.building) if action.type == "upgrade" and (action.building == "chapel" or sim.is_housing(action.building)) else sim.rules[costs[action.type]]
			p.plan = sim.payment_plan(sim.current_house().id,p.inputs)
			if action.type == "buy_brick": p.outputs = {"brick":1}
			else:
				var milestone := {"upgrade":"brick_house","build_market":"market","secure_clay_contract":"clay_contract"}
				p.prestige = sim.rules.milestone_rewards[milestone[action.type]]
				if action.type == "upgrade" and not sim.is_housing(action.building): p.prestige = 0
		"contribute_upgrade":
			p.inputs = action.bundle.duplicate(true)
			p.plan = sim.payment_plan(sim.current_house().id,p.inputs)
		"claim_site":
			p.inputs = {"influence":sim.site_social(action.building)}
			if action.replace != "": p.inputs.prestige = sim.clear_price(action.replace)
			p.timing = "Social claim reserves a protected site; physical construction is a separate later action."
		"redevelop_occupied":
			p.inputs = sim.rules.redevelopment_cost.duplicate(true)
			p.plan = sim.payment_plan(sim.current_house().id,p.inputs)
			p.inputs.prestige = sim.clear_price(action.building)
		"launch_expedition":
			p.inputs = sim.rules.expedition_cost.duplicate(true)
			p.plan = sim.payment_plan(sim.current_house().id,p.inputs)
			p.commitments = {"pop":1,"land_transport":1}
			p.timing = "One grain consumed; one crew held until return. Outbound and return each take six future normal town actions."
		"expedition_buy", "expedition_sell", "expedition_contract":
			var trip = sim.trip_for(sim.current_house().id)
			var offer: Dictionary = trip.sell[int(action.offer)] if action.type == "expedition_sell" else trip.buy[int(action.offer)]
			if action.type == "expedition_sell":
				p.inputs = {offer.resource:1}
				p.outputs = {"gold":offer.price}
				p.plan = sim.payment_plan(sim.current_house().id,p.inputs)
			else:
				p.inputs = {"gold":offer.price}
				if action.type == "expedition_buy":
					p.outputs = {offer.resource:1}
					p.timing = "Purchased cargo arrives on return: private store if space, otherwise public supply."
				else:
					p.inputs.prestige = sim.rules.public_route_prestige
					if action.get("access","priority") == "priority": p.inputs.influence = sim.rules.route_priority_influence
					p.commitments = {"land_transport":1}
					p.timing = "Useful first clay supply earns its town reward on the first real delivery, not signing."
					p.recurring = {"resource":offer.resource,"quantity":1,"gold_each_round":offer.price,"owned_priority":action.get("access","priority") == "priority","first_delivery":"refresh after return"}
					var f = PlannerAI.new().assess_offer(sim,offer,action.get("access","priority"))
					p.financing_note = "AI funding assessment: %s. %d-round operation: %d gold; setup: %d gold; cancellation: %d prestige. Shared caravan orders are uncertain income, not guaranteed funding." % [f.choice,f.forecast_rounds,f.operating_gold,f.setup_gold,f.exit_prestige]
		"return_expedition": p.timing = "Return takes six future normal town actions. Crew and finite cargo arrive at home; any standing route keeps transport committed."
		"buy_route", "cancel_route", "own_route":
			var route = sim.route_by_id(int(action.route))
			if action.type == "own_route": p.inputs = {"influence":sim.rules.route_priority_influence}
			elif action.type == "cancel_route": p.inputs = {"prestige":sim.route_cancel_price(route,sim.current_house().id)}
			else: p.inputs = {"prestige":int(route.price),"influence":sim.rules.route_priority_influence}
			p.timing = "Buyout transfers the route's land-transport obligation and output priority." if action.type == "buy_route" else "Influence buys future priority; existing public goods remain public." if action.type == "own_route" else "Release route transport; a travelling expedition still has to return."
		"start_site", "supply_site":
			p.inputs = action.bundle.duplicate(true)
			p.plan = sim.payment_plan(sim.current_house().id,p.inputs)
			if action.type == "start_site" and action.building.begins_with("hall_"): p.inputs.influence = sim.rules.hall_influence_cost
		"hall_work":
			p.inputs = sim.rules.hall_recipes[action.recipe].inputs
			p.outputs = sim.rules.hall_recipes[action.recipe].outputs
			p.plan = sim.payment_plan(sim.current_house().id,p.inputs)
		"buy_stone":
			p.inputs = {"gold":sim.rules.stone_gold_price}
			p.outputs = {"stone":1}
		"supply_wood", "redevelop_rural", "claim_rural":
			p.inputs = {"wood":1} if action.type == "supply_wood" else sim.rules.redevelopment_cost if action.type == "redevelop_rural" else sim.rules.rural_claim_cost
			p.plan = sim.payment_plan(sim.current_house().id,p.inputs)
			if action.type == "supply_wood": p.outputs = {"influence":1}
			if action.type == "claim_rural": p.prestige = 1
		"supply_town", "export_brick":
			p.inputs = {"brick":1}
			p.plan = sim.payment_plan(sim.current_house().id,p.inputs)
			p.outputs = {"influence":sim.rules.town_brick_influence} if action.type == "supply_town" else {"gold":1}
		"buy_prestige":
			p.inputs = {"gold":sim.rules.prestige_gold_price}
			p.outputs = {"prestige":1}
		"build_kiln":
			p.inputs = sim.rules.kiln_cost
			p.plan = sim.payment_plan(sim.current_house().id,p.inputs)
		"secure_contract":
			var spec: Dictionary = sim.rules.contract_specs[action.resource]
			p.inputs = spec.setup
			p.plan = sim.payment_plan(sim.current_house().id,p.inputs)
			p.recurring = spec.duplicate(true)
		"buy_contract": p.inputs = {"prestige":int(sim.title(action.resource).price),"influence":sim.rules.route_priority_influence}
		"cancel_contract": p.inputs = {"prestige":sim.cancel_price(action.resource)}
		"demolish": p.inputs = {"prestige":1 if sim.state.buildings[action.building].plot in ["field","forest"] else 3}
		"bulk_exchange":
			p.inputs = sim.current_house().stockpile.duplicate(true)
			p.outputs = {"influence":3}
		"claim": p.inputs = {"influence":sim.rules.claim_cost}
		"convert_prestige":
			p.inputs = {"influence":5}
			p.outputs = {"prestige":1}
		"take": p.outputs = {action.resource:1}
		"return": p.inputs = {action.resource:1}
		"pass":
			var h = sim.current_house()
			if not h.did_something and not h.idle_rewarded: p.outputs = {"influence":1}
	if action.type == "secure_clay_contract": p.commitments = {"wood":1,"pop":1}
	return p

func project() -> Dictionary:
	var legal: Array = []
	for action in sim.legal_actions(): legal.append(preview(action))
	var modes: Dictionary = {}
	for id in sim.state.buildings:
		if sim.state.buildings[id].built: modes[id] = sim.modes(id)
	return {"state":sim.state.duplicate(true),"modes":modes,"legal":legal,"decision":probe.last_decision.duplicate(true),"event":probe.last_result.get("event",{}).duplicate(true)}

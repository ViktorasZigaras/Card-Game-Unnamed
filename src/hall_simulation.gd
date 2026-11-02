class_name HallSimulation
extends StockadeSimulation
func _init() -> void:
	super._init()
	rules.schema_version = 13
	rules.experiment = "house_halls_and_small_sawmill"
	rules.halls_enabled = true
	rules.resources.append("planks")
	rules.goods.append("planks")
	rules.hall_cost = {"planks":3,"stone":1,"pop":1}
	rules.hall_influence_cost = 3
	rules.sawmill_cost = {"wood":2,"pop":1}
	rules.contract_specs["planks"] = {"setup":{"wood":1,"pop":1},"upkeep":{"wood":1},"source":"small_sawmill","commit":1,"cadence":"round","cancel":1}
	rules.hall_recipes = {"furniture":{"inputs":{"wood":2,"pop":1},"outputs":{"furniture":1}},"brick":{"inputs":{"clay":1,"pop":1},"outputs":{"brick":1}}}
	var sawmill = {"id":"small_sawmill","kind":"rural","terrain":"forest","inputs":{"wood":1,"pop":1},"outputs":{"planks":2}}
	var hall = {"id":"house_hall","kind":"house_seat","terrain":"urban","inputs":{},"outputs":{}}
	for d in [sawmill,hall]:
		rules.buildings.append(d)
		definitions[d.id] = d
func ensure_halls() -> void:
	if state.has("houseworks"): return
	state.houseworks = {"sites":{},"unlocked":{},"last_work":{},"works":[],"hall_rounds":{},"planks_made":0,"hall_bricks":0,"social_spent":0,"sawmill_round":0}
	state.buildings.small_sawmill = {"definition":"small_sawmill","built":false,"owner":"","level":1,"plot":""}
	for h in state.houses:
		state.buildings[hall_id(h.id)] = {"definition":"house_hall","built":false,"owner":h.id,"level":1,"plot":""}
		state.houseworks.unlocked[h.id] = ["furniture"]
func _new_round() -> void:
	ensure_halls()
	super._new_round()
	state.schema_version = 13
	learn_existing_recipes()
func hall_id(house_id: String) -> String: return "hall_"+house_id
func _owns(house_id: String) -> int:
	var count = super._owns(house_id)
	if state.buildings.has(hall_id(house_id)): count -= 1
	return count
func unlock_recipe(house_id: String,recipe_id: String) -> bool:
	if not rules.hall_recipes.has(recipe_id) or not state.houseworks.unlocked.has(house_id): return false
	if recipe_id not in state.houseworks.unlocked[house_id]: state.houseworks.unlocked[house_id].append(recipe_id)
	return true
func learn_existing_recipes() -> void:
	# Provisional shared knowledge; future research can call unlock_recipe per house.
	if state.buildings.kiln.built:
		for h in state.houses: unlock_recipe(h.id,"brick")
func site_cost(id: String) -> Dictionary:
	return rules.sawmill_cost if id == "small_sawmill" else rules.hall_cost
func site_remaining(id: String) -> Dictionary:
	var paid: Dictionary = state.houseworks.sites.get(id,{}).get("paid",{})
	var need = {}
	for r in site_cost(id):
		var amount = int(site_cost(id)[r])-int(paid.get(r,0))
		if amount > 0: need[r] = amount
	return need
func has_unfinished_site(house_id: String) -> bool:
	for site in state.houseworks.sites.values():
		if site.sponsor == house_id and not site.completed: return true
	return false
func contribution_options(house_id: String,need: Dictionary,social: int = 0) -> Array:
	var options: Array = []
	var combined = {}
	for r in need:
		for amount in range(1,int(need[r])+1):
			var bundle = {r:amount}
			var plan = payment_plan(house_id,bundle)
			if plan.ok and house(house_id).inventory.influence >= plan.total_influence+social:
				options.append(bundle)
				var attempt = combined.duplicate(true)
				attempt[r] = amount
				var combined_plan = payment_plan(house_id,attempt)
				if combined_plan.ok and house(house_id).inventory.influence >= combined_plan.total_influence+social: combined = attempt
	if not combined.is_empty() and combined not in options: options.append(combined)
	return options
func modes(id: String) -> Array:
	if state.houseworks.sites.has(id) and not state.buildings[id].built: return []
	if state.buildings[id].definition == "house_hall":
		var result: Array = []
		for recipe_id in state.houseworks.unlocked[state.buildings[id].owner]:
			var recipe: Dictionary = rules.hall_recipes[recipe_id]
			result.append({"name":recipe_id,"inputs":recipe.inputs,"outputs":recipe.outputs})
		return result
	return super.modes(id)
func legal_actions() -> Array:
	var actions = super.legal_actions().filter(func(a):
		var id = str(a.get("building",""))
		if state.buildings.has(id) and state.buildings[id].definition == "house_hall": return false
		if state.houseworks.sites.has(id) and not state.houseworks.sites[id].completed: return false
		return not (id == "small_sawmill" and a.type == "upgrade"))
	if not rules.halls_enabled or state.ended: return actions
	var h = current_house()
	for id in ["small_sawmill",hall_id(h.id)]:
		var b: Dictionary = state.buildings[id]
		if b.built: continue
		if not state.houseworks.sites.has(id):
			if has_unfinished_site(h.id) or state.terrain_free[definition(id).terrain] <= 0: continue
			var social = int(rules.hall_influence_cost) if id != "small_sawmill" else 0
			for bundle in contribution_options(h.id,site_remaining(id),social): actions.append({"type":"start_site","building":id,"bundle":bundle})
		elif id in state.revealed:
			for bundle in contribution_options(h.id,site_remaining(id)): actions.append({"type":"supply_site","building":id,"bundle":bundle})
	var id = hall_id(h.id)
	if state.buildings[id].built and int(state.houseworks.last_work.get(h.id,0)) != int(state.round):
		for recipe_id in state.houseworks.unlocked[h.id]:
			if payment_plan(h.id,rules.hall_recipes[recipe_id].inputs).ok: actions.append({"type":"hall_work","building":id,"recipe":recipe_id})
	return actions
func supply_site(id: String,bundle: Dictionary,h: Dictionary,events: Array) -> void:
	var plan = payment_plan(h.id,bundle)
	_pay(h.id,plan,events)
	_consume_plan(h.id,plan,events)
	var site: Dictionary = state.houseworks.sites[id]
	for r in bundle: site.paid[r] = int(site.paid.get(r,0))+int(bundle[r])
	site.contributions += 1
	cycle_project_card(id)
	events.append({"type":"site_supplied","building":id,"house":h.id,"consumed":bundle,"remaining":site_remaining(id)})
	if site_remaining(id).is_empty():
		site.completed = true
		state.buildings[id].built = true
		if id == "small_sawmill": state.houseworks.sawmill_round = state.round
		else:
			state.houseworks.hall_rounds[h.id] = state.round
			for pile in [state.deck,state.discard,state.revealed]:
				while id in pile: pile.erase(id)
		events.append({"type":"site_completed","building":id,"round":state.round})
func _experimental_action(action: Dictionary,h: Dictionary,events: Array) -> void:
	match action.type:
		"start_site":
			var id: String = action.building
			var terrain: String = definition(id).terrain
			state.terrain_free[terrain] -= 1
			state.buildings[id].plot = terrain
			var social = int(rules.hall_influence_cost) if id != "small_sawmill" else 0
			h.inventory.influence -= social
			state.ledger.influence.consumed += social
			state.houseworks.social_spent += social
			state.houseworks.sites[id] = {"sponsor":h.id,"paid":{},"completed":false,"contributions":0,"started":state.round,"social":social}
			events.append({"type":"site_started","building":id,"plot":terrain,"social_consumed":social})
			supply_site(id,action.bundle,h,events)
		"supply_site": supply_site(action.building,action.bundle,h,events)
		"hall_work":
			var recipe: Dictionary = rules.hall_recipes[action.recipe]
			var plan = payment_plan(h.id,recipe.inputs)
			_pay(h.id,plan,events)
			_consume_plan(h.id,plan,events)
			for r in recipe.outputs: _add_lot(r,int(recipe.outputs[r]),h.id,"house_hall",int(h.turns_taken)+1)
			if action.recipe == "brick": state.houseworks.hall_bricks += 1
			state.houseworks.last_work[h.id] = state.round
			var e = {"type":"hall_manufactured","house":h.id,"recipe":action.recipe,"round":state.round,"inputs":recipe.inputs,"outputs":recipe.outputs}
			state.houseworks.works.append(e)
			events.append(e)
		_: super._experimental_action(action,h,events)
func _after_action(event: Dictionary) -> void:
	super._after_action(event)
	if event.action.type == "build_kiln": learn_existing_recipes()
func _add_lot(resource: String,amount: int,producer: String,source: String,turn_no: int) -> void:
	super._add_lot(resource,amount,producer,source,turn_no)
	if resource == "planks" and source in ["small_sawmill","contract_planks"]: state.houseworks.planks_made += amount
func violations() -> Array:
	var errors = super.violations().filter(func(e): return not str(e).begins_with("expanded town plot accounting:") and e != "imported and manufactured brick accounting")
	var cards: Array = state.deck+state.discard+state.revealed
	for terrain in ["urban","forest","field"]:
		var occupied = 0
		for id in state.buildings:
			var b: Dictionary = state.buildings[id]
			if b.plot == terrain and (b.built or state.houseworks.sites.has(id)): occupied += 1
		if state.terrain_free[terrain] < 0 or occupied+int(state.terrain_free[terrain]) != effective_capacity(terrain): errors.append("site and built plot accounting: "+terrain)
	for id in state.houseworks.sites:
		var site: Dictionary = state.houseworks.sites[id]
		errors.erase("scenario card identity: "+id)
		var expected = 0 if (site.completed and id.begins_with("hall_")) or id in state.linked_assets else 1
		if cards.count(id) != expected: errors.append("construction card identity: "+id)
		if site.completed != state.buildings[id].built or site.completed != site_remaining(id).is_empty(): errors.append("construction functionality: "+id)
		for r in site.paid:
			if site.paid[r] < 0 or site.paid[r] > site_cost(id)[r]: errors.append("excess construction payment")
	if state.ledger.planks.created != state.houseworks.planks_made: errors.append("plank manufacture accounting")
	if state.ledger.brick.created != state.access_metrics.bricks_bartered+state.capacity.kiln_bricks+state.houseworks.hall_bricks: errors.append("kiln and hall brick accounting")
	var social = 0
	for site in state.houseworks.sites.values(): social += int(site.social)
	if social != state.houseworks.social_spent: errors.append("construction social sink accounting")
	var seen: Array = []
	for e in state.houseworks.works:
		var key = e.house+":"+str(int(e.round))
		if key in seen: errors.append("hall used twice in round")
		seen.append(key)
	return errors

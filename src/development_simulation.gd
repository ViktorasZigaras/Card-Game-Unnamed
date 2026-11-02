class_name DevelopmentSimulation
extends HallSimulation
func _init() -> void:
	super._init()
	rules.schema_version = 14
	rules.experiment = "protected_development"
	rules.public_site_influence = 1
	rules.town_biome = "woodland"
	rules.biome_weights = {"forest":65,"field":35}
func ensure_development() -> void:
	if not state.has("development"):
		state.development = {"retired_sites":[],"clearances":[],"global_unlocked":["furniture"],"land_rolls":[]}
func _new_round() -> void:
	ensure_development()
	super._new_round()
	state.schema_version = 14
func unlock_recipe(_house_id: String,recipe_id: String) -> bool:
	if not rules.hall_recipes.has(recipe_id): return false
	if recipe_id not in state.development.global_unlocked: state.development.global_unlocked.append(recipe_id)
	for h in state.houses:
		if recipe_id not in state.houseworks.unlocked[h.id]: state.houseworks.unlocked[h.id].append(recipe_id)
	return true
func site_cost(id: String) -> Dictionary:
	if id == "marketplace": return rules.market_cost
	if id == "kiln": return rules.kiln_cost
	return super.site_cost(id)
func site_social(id: String) -> int:
	return int(rules.hall_influence_cost) if id.begins_with("hall_") else int(rules.public_site_influence)
func protected_site(id: String) -> bool:
	return state.houseworks.sites.has(id) and not state.houseworks.sites[id].completed
func source_contracts(id: String) -> Array:
	var resources: Array = []
	for c in state.contracts:
		if c.get("source","") == id and c.has("resource"): resources.append(str(c.resource))
	if id == "lumber_camp" and state.lumber_link: resources.append("wood")
	if id == "marketplace" and not state.clay_contract.is_empty(): resources.append("clay")
	return resources
func clear_price(id: String) -> int:
	var price = 1 if state.buildings[id].plot in ["forest","field"] else 3
	for r in source_contracts(id): price += cancel_price(r)
	return price
func eligible_clear(id: String) -> bool:
	var b: Dictionary = state.buildings[id]
	return b.built and b.owner == "" and b.plot != "special" and not protected_site(id)
func legal_actions() -> Array:
	var actions = super.legal_actions().filter(func(a): return a.type not in ["start_site","build_market","build_kiln","claim_rural"])
	var h = current_house()
	if state.ended: return []
	if not has_unfinished_site(h.id):
		for target in ["marketplace","kiln","small_sawmill",hall_id(h.id)]:
			if state.buildings[target].built or state.houseworks.sites.has(target) or h.inventory.influence < site_social(target): continue
			var terrain = str(definition(target).terrain)
			if state.terrain_free[terrain] > 0: actions.append({"type":"claim_site","building":target,"replace":""})
			for key in state.buildings:
				var old = str(key)
				if old != target and eligible_clear(old) and state.buildings[old].plot == terrain and h.inventory.prestige >= clear_price(old): actions.append({"type":"claim_site","building":target,"replace":old})
	# Hall's earlier site list only covers two building types.
	for target in ["marketplace","kiln"]:
		if protected_site(target) and target in state.revealed:
			for bundle in contribution_options(h.id,site_remaining(target)): actions.append({"type":"supply_site","building":target,"bundle":bundle})
	if state.town.wall_complete and conversion_count() < 2 and payment_plan(h.id,rules.redevelopment_cost).ok:
		for key in state.buildings:
			var id = str(key)
			if eligible_clear(id) and state.buildings[id].plot in ["forest","field"] and h.inventory.prestige >= clear_price(id): actions.append({"type":"redevelop_occupied","building":id})
	if state.town.wall_complete and conversion_count() == 2 and claim_count() < 4 and payment_plan(h.id,rules.rural_claim_cost).ok: actions.append({"type":"claim_rural"})
	return actions
func remove_site_record(id: String) -> void:
	if state.houseworks.sites.has(id):
		state.development.retired_sites.append({"building":id,"site":state.houseworks.sites[id].duplicate(true),"round":state.round})
		state.houseworks.sites.erase(id)
func clear_building(id: String,h: Dictionary,events: Array) -> void:
	var price = clear_price(id)
	for r in source_contracts(id): super._experimental_action({"type":"cancel_contract","resource":r},h,events)
	var base = 1 if state.buildings[id].plot in ["forest","field"] else 3
	h.inventory.prestige -= base
	state.ledger.prestige.consumed += base
	state.terrain_free[state.buildings[id].plot] += 1
	state.buildings[id].built = false
	state.buildings[id].plot = ""
	remove_site_record(id)
	for pile in [state.deck,state.discard,state.revealed,state.passive_assets,state.used]:
		while id in pile: pile.erase(id)
	if id == "marketplace":
		state.market_round = 0
		state.caravan.present = false
	state.economy.demolitions += 1
	var e = {"type":"site_cleared","building":id,"house":h.id,"prestige":price,"round":state.round}
	state.development.clearances.append(e)
	events.append(e)
func supply_site(id: String,bundle: Dictionary,h: Dictionary,events: Array) -> void:
	var plan = payment_plan(h.id,bundle)
	_pay(h.id,plan,events)
	_consume_plan(h.id,plan,events)
	var site: Dictionary = state.houseworks.sites[id]
	for r in bundle: site.paid[r] = int(site.paid.get(r,0))+int(bundle[r])
	site.contributions += 1
	cycle_project_card(id)
	events.append({"type":"site_supplied","building":id,"house":h.id,"consumed":bundle,"remaining":site_remaining(id)})
	if not site_remaining(id).is_empty(): return
	site.completed = true
	state.buildings[id].built = true
	if id == "marketplace":
		state.passive_assets.append(id)
		state.market_round = state.round
		state.caravan.first_round = int(state.round)+1
		_milestone("market",h.id,events)
	if id == "kiln":
		state.capacity.kiln_built_round = state.round
		state.capacity.kiln_builder = h.id
		state.capacity.construction_spent = rules.kiln_cost.duplicate(true)
		learn_existing_recipes()
	if id == "small_sawmill": state.houseworks.sawmill_round = state.round
	if id.begins_with("hall_"): state.houseworks.hall_rounds[h.id] = state.round
	if id == "marketplace" or id.begins_with("hall_"):
		for pile in [state.deck,state.discard,state.revealed]:
			while id in pile: pile.erase(id)
	events.append({"type":"site_completed","building":id,"round":state.round})
func _experimental_action(action: Dictionary,h: Dictionary,events: Array) -> void:
	match action.type:
		"claim_site":
			var id: String = action.building
			if action.replace != "": clear_building(action.replace,h,events)
			var social = site_social(id)
			h.inventory.influence -= social
			state.ledger.influence.consumed += social
			state.houseworks.social_spent += social
			var terrain: String = definition(id).terrain
			state.terrain_free[terrain] -= 1
			state.buildings[id].plot = terrain
			state.houseworks.sites[id] = {"sponsor":h.id,"paid":{},"completed":false,"contributions":0,"started":state.round,"social":social,"replaced":action.replace}
			cycle_project_card(id)
			events.append({"type":"site_claimed","building":id,"house":h.id,"influence":social,"protected":true,"construction_requires_later_action":true})
		"demolish": clear_building(action.building,h,events)
		"redevelop_occupied":
			var terrain: String = state.buildings[action.building].plot
			clear_building(action.building,h,events)
			var plan = payment_plan(h.id,rules.redevelopment_cost)
			_pay(h.id,plan,events)
			_consume_plan(h.id,plan,events)
			state.terrain_free[terrain] -= 1
			state.terrain_free.urban += 1
			state.town.converted[terrain] += 1
			var e = {"type":"occupied_rural_redeveloped","building":action.building,"house":h.id,"from":terrain,"round":state.round}
			state.town.land_events.append(e)
			events.append(e)
		"claim_rural":
			var plan = payment_plan(h.id,rules.rural_claim_cost)
			_pay(h.id,plan,events)
			_consume_plan(h.id,plan,events)
			var roll = rng.randi_range(1,100)
			var terrain = "forest" if roll <= int(rules.biome_weights.forest) else "field"
			state.town.claimed[terrain] += 1
			state.terrain_free[terrain] += 1
			state.town.claimants[h.id] = state.town.claimants.get(h.id,0)+1
			_prestige(h.id,1,"town_rural_claim",events)
			var e = {"type":"biome_land_claimed","house":h.id,"terrain":terrain,"roll":roll,"round":state.round,"biome":rules.town_biome}
			state.development.land_rolls.append(e)
			state.town.land_events.append(e)
			events.append(e)
			if claim_count() == 4: state.town.all_land_round = state.round
		_: super._experimental_action(action,h,events)
func violations() -> Array:
	var errors = super.violations().filter(func(e): return e not in ["outer plot claim limit","construction social sink accounting"])
	if state.buildings.marketplace.built:
		errors.erase("construction card identity: marketplace")
		if (state.deck+state.discard+state.revealed).count("marketplace") != 0: errors.append("passive market card identity")
	var social = 0
	for site in state.houseworks.sites.values(): social += int(site.social)
	for entry in state.development.retired_sites: social += int(entry.site.social)
	if social != state.houseworks.social_spent: errors.append("active and retired site social accounting")
	if claim_count() > 4: errors.append("four outer claims maximum")
	for h in state.houses:
		if state.houseworks.unlocked[h.id] != state.development.global_unlocked: errors.append("shared permanent recipe knowledge")
	return errors

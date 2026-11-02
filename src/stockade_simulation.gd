class_name StockadeSimulation
extends ProjectSimulation
func _init() -> void:
	super._init()
	rules.schema_version = 12
	rules.experiment = "stockade_and_town_land_expansion"
	rules.stockade_wood = 6
	rules.stockade_influence_per_wood = 1
	rules.redevelopment_cost = {"stone":1,"pop":1}
	rules.rural_claim_cost = {"pop":1}
	rules.town_wood_sweep = true
func ensure_town() -> void:
	if not state.has("town"):
		state.town = {"wall_wood":0,"wall_complete":false,"wall_round":0,"voluntary_wood":0,"automatic_wood":0,"chapel_automatic_wood":0,"deliveries":{},"converted":{"forest":0,"field":0},"claimed":{"forest":0,"field":0},"claimants":{},"land_events":[],"all_land_round":0}
func _new_round() -> void:
	ensure_town()
	super._new_round()
	state.schema_version = 12
func conversion_count() -> int:
	return int(state.town.converted.forest)+int(state.town.converted.field)
func claim_count() -> int:
	return int(state.town.claimed.forest)+int(state.town.claimed.field)
func effective_capacity(terrain: String) -> int:
	var base = int(rules.locales[state.locale].terrain[terrain])
	return base+conversion_count() if terrain == "urban" else base-int(state.town.converted[terrain])+int(state.town.claimed[terrain])
func wall_contribution(amount: int,events: Array) -> void:
	state.town.wall_wood += amount
	if state.town.wall_wood == int(rules.stockade_wood) and not state.town.wall_complete:
		state.town.wall_complete = true
		state.town.wall_round = state.round
		events.append({"type":"stockade_completed","round":state.round,"special":true})
func legal_actions() -> Array:
	var actions = super.legal_actions()
	var h = current_house()
	if not state.town.wall_complete and payment_plan(h.id,{"wood":1}).ok: actions.append({"type":"supply_wood"})
	if state.town.wall_complete and conversion_count() < 2 and payment_plan(h.id,rules.redevelopment_cost).ok:
		for terrain in ["forest","field"]:
			if state.terrain_free[terrain] > 0: actions.append({"type":"redevelop_rural","terrain":terrain})
	if state.town.wall_complete and conversion_count() == 2 and payment_plan(h.id,rules.rural_claim_cost).ok:
		for terrain in ["forest","field"]:
			if state.town.claimed[terrain] < 2: actions.append({"type":"claim_rural","terrain":terrain})
	return actions
func _experimental_action(action: Dictionary,h: Dictionary,events: Array) -> void:
	match action.type:
		"supply_wood":
			var plan = payment_plan(h.id,{"wood":1})
			_pay(h.id,plan,events)
			_consume_plan(h.id,plan,events)
			_gain_influence(h.id,int(rules.stockade_influence_per_wood),"stockade_delivery",events)
			state.town.voluntary_wood += 1
			state.town.deliveries[h.id] = state.town.deliveries.get(h.id,0)+1
			wall_contribution(1,events)
			events.append({"type":"stockade_wood_delivery","house":h.id,"wood":1,"influence":rules.stockade_influence_per_wood})
		"redevelop_rural":
			var plan = payment_plan(h.id,rules.redevelopment_cost)
			_pay(h.id,plan,events)
			_consume_plan(h.id,plan,events)
			state.terrain_free[action.terrain] -= 1
			state.terrain_free.urban += 1
			state.town.converted[action.terrain] += 1
			var e = {"type":"rural_redeveloped","house":h.id,"from":action.terrain,"to":"urban","round":state.round,"cost":rules.redevelopment_cost}
			state.town.land_events.append(e)
			events.append(e)
		"claim_rural":
			var plan = payment_plan(h.id,rules.rural_claim_cost)
			_pay(h.id,plan,events)
			_consume_plan(h.id,plan,events)
			state.town.claimed[action.terrain] += 1
			state.terrain_free[action.terrain] += 1
			state.town.claimants[h.id] = state.town.claimants.get(h.id,0)+1
			_prestige(h.id,1,"town_rural_claim",events)
			var e = {"type":"rural_claimed_for_town","house":h.id,"terrain":action.terrain,"prestige":1,"round":state.round}
			state.town.land_events.append(e)
			events.append(e)
			if claim_count() == 4: state.town.all_land_round = state.round
		_: super._experimental_action(action,h,events)
func _close_round() -> void:
	if rules.town_wood_sweep:
		var events: Array = []
		var wood = 0
		for lot in state.lots:
			if lot.resource == "wood" and lot.reserved_for == "": wood += int(lot.amount)
		var needed = int(rules.stockade_wood)-int(state.town.wall_wood)
		var used = mini(wood,needed)
		if used > 0:
			_consume_plan("town",public_plan({"wood":used}),events)
			state.town.automatic_wood += used
			wall_contribution(used,events)
			events.append({"type":"town_wood_collected","wood":used,"project":"stockade","reward":0})
			wood -= used
		# The chapel is the other existing public wood-consuming task; unused wood is not discarded.
		if wood > 0 and state.buildings.chapel.level == 1 and remaining("chapel").get("wood",0) > 0:
			_consume_plan("town",public_plan({"wood":1}),events)
			var project = progress("chapel").duplicate(true)
			project.paid.wood = int(project.paid.get("wood",0))+1
			project.contributions += 1
			state.projects.chapel = project
			state.project_metrics.contributions += 1
			state.town.chapel_automatic_wood += 1
			cycle_project_card("chapel")
			events.append({"type":"town_wood_collected","wood":1,"project":"chapel","reward":0})
			if remaining("chapel").is_empty(): finish_project("chapel",{},events)
		if not events.is_empty() and not state.history.is_empty(): state.history[-1].consequences.append({"type":"town_end_round","actor":"town","round":state.round,"events":events})
	super._close_round()
func violations() -> Array:
	var errors = super.violations().filter(func(e): return e not in ["plot accounting: urban","plot accounting: forest","plot accounting: field"])
	for terrain in ["urban","forest","field"]:
		var occupied = 0
		for b in state.buildings.values():
			if b.built and b.plot == terrain: occupied += 1
		if state.terrain_free[terrain] < 0 or occupied+int(state.terrain_free[terrain]) != effective_capacity(terrain): errors.append("expanded town plot accounting: "+terrain)
	if state.town.wall_wood < 0 or state.town.wall_wood > rules.stockade_wood or state.town.wall_complete != (state.town.wall_wood == rules.stockade_wood): errors.append("stockade progress accounting")
	if state.town.voluntary_wood+state.town.automatic_wood != state.town.wall_wood: errors.append("stockade contribution sources")
	if conversion_count() > 2 or (conversion_count() > 0 and not state.town.wall_complete): errors.append("stockade conversion prerequisites")
	if claim_count() > 0 and conversion_count() != 2: errors.append("outer land unlock prerequisite")
	for terrain in ["forest","field"]:
		if state.town.claimed[terrain] < 0 or state.town.claimed[terrain] > 2: errors.append("outer plot claim limit")
	return errors

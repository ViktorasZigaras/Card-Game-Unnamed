class_name ProjectSimulation
extends TradeSimulation
func _init() -> void:
	super._init()
	rules.schema_version = 11
	rules.experiment = "partial_upgrades_and_stone_chapel"
	rules.partial_home_upgrades = true
	rules.resources.append("stone")
	rules.goods.append("stone")
	rules.stone_gold_price = 1
	rules.stone_per_visit = 2
	rules.chapel_upgrade_cost = {"stone":2,"wood":1,"pop":1}
	for d in rules.buildings:
		if d.id == "chapel":
			d.upgraded_inputs = {}
			d.upgraded_outputs = {"influence":3}
	definitions.chapel.upgraded_inputs = {}
	definitions.chapel.upgraded_outputs = {"influence":3}
func _new_round() -> void:
	if not state.has("projects"):
		state.projects = {}
		state.project_metrics = {"contributions":0,"partial_home_completions":0,"chapel_round":0,"stone_bought":0,"stone_gold_spent":0,"chapel_contributors":{}}
	super._new_round()
	state.schema_version = 11
	state.caravan.stone_left = int(rules.stone_per_visit) if state.caravan.present else 0
func cost_for(id: String) -> Dictionary:
	return rules.chapel_upgrade_cost if id == "chapel" else rules.housing_upgrade_cost
func progress(id: String) -> Dictionary:
	return state.projects.get(id,{"building":id,"paid":{},"completed":false,"contributions":0})
func remaining(id: String) -> Dictionary:
	var result = {}
	var paid: Dictionary = progress(id).paid
	for r in cost_for(id):
		var amount = int(cost_for(id)[r])-int(paid.get(r,0))
		if amount > 0: result[r] = amount
	return result
func modes(id: String) -> Array:
	if id == "chapel" and int(state.buildings[id].level) == 2:
		return [{"name":"enhanced","inputs":{},"outputs":{"influence":3}}]
	return super.modes(id)
func eligible(id: String) -> bool:
	var b: Dictionary = state.buildings[id]
	if not b.built or b.level != 1: return false
	if id != "chapel" and b.owner != current_house().id: return false
	# An automated source may begin an off-card upgrade; later contributions follow its project card.
	return id in state.revealed or (not linked_contract(id).is_empty() and progress(id).contributions == 0)
func legal_actions() -> Array:
	var actions = super.legal_actions().filter(func(a): return not (a.type == "upgrade" and (a.building == "chapel" or is_housing(a.building))))
	var h = current_house()
	if state.caravan.present and state.caravan.stone_left > 0 and h.inventory.gold >= rules.stone_gold_price: actions.append({"type":"buy_stone"})
	for id in state.buildings:
		if id != "chapel" and not is_housing(id): continue
		if not eligible(id): continue
		var need = remaining(id)
		if payment_plan(h.id,need).ok: actions.append({"type":"upgrade","building":id})
		if id != "chapel" and not rules.partial_home_upgrades: continue
		var combined = {}
		for r in need:
			for amount in range(1,int(need[r])+1):
				var bundle = {r:amount}
				if payment_plan(h.id,bundle).ok:
					if bundle != need: actions.append({"type":"contribute_upgrade","building":id,"bundle":bundle})
					var attempt = combined.duplicate(true)
					attempt[r] = amount
					if payment_plan(h.id,attempt).ok: combined = attempt
		if combined.size() > 1 and combined != need: actions.append({"type":"contribute_upgrade","building":id,"bundle":combined})
	return actions
func cycle_project_card(id: String) -> void:
	for pile in [state.deck,state.discard,state.revealed]:
		while id in pile: pile.erase(id)
	state.discard.append(id)
func record_contribution(id: String,bundle: Dictionary,h: Dictionary,events: Array) -> void:
	var p = progress(id).duplicate(true)
	var plan = payment_plan(h.id,bundle)
	_pay(h.id,plan,events)
	_consume_plan(h.id,plan,events)
	for r in bundle: p.paid[r] = int(p.paid.get(r,0))+int(bundle[r])
	p.contributions += 1
	state.projects[id] = p
	state.project_metrics.contributions += 1
	if id == "chapel": state.project_metrics.chapel_contributors[h.id] = state.project_metrics.chapel_contributors.get(h.id,0)+1
	events.append({"type":"upgrade_contribution","building":id,"house":h.id,"consumed":bundle,"remaining":remaining(id)})
	cycle_project_card(id)
func finish_project(id: String,h: Dictionary,events: Array) -> void:
	if id == "chapel":
		state.buildings.chapel.level = 2
		state.project_metrics.chapel_round = state.round
		events.append({"type":"chapel_upgraded","influence_output":3})
	else:
		_finish_upgrade({"type":"upgrade","building":id},h,events)
		if state.projects[id].contributions > 1: state.project_metrics.partial_home_completions += 1
	state.projects[id].completed = true
	cycle_project_card(id)
func _upgrade_building(action: Dictionary,h: Dictionary,events: Array) -> void:
	if action.building != "chapel" and not is_housing(action.building):
		super._upgrade_building(action,h,events)
		return
	record_contribution(action.building,remaining(action.building),h,events)
	finish_project(action.building,h,events)
func _experimental_action(action: Dictionary,h: Dictionary,events: Array) -> void:
	match action.type:
		"buy_stone":
			h.inventory.gold -= int(rules.stone_gold_price)
			state.trade.gold_spent += int(rules.stone_gold_price)
			state.project_metrics.stone_gold_spent += int(rules.stone_gold_price)
			state.project_metrics.stone_bought += 1
			state.caravan.stone_left -= 1
			_add_lot("stone",1,h.id,"caravan_stone",int(h.turns_taken)+1)
			events.append({"type":"stone_purchase","house":h.id,"gold":rules.stone_gold_price,"stone":1})
		"contribute_upgrade":
			record_contribution(action.building,action.bundle,h,events)
			if remaining(action.building).is_empty(): finish_project(action.building,h,events)
		_:
			var affected = ""
			if action.type == "secure_contract": affected = str(action.source)
			if action.type == "cancel_contract": affected = str(contract_for(action.resource).source)
			super._experimental_action(action,h,events)
			if affected != "" and state.projects.has(affected) and not state.projects[affected].completed:
				cycle_project_card(affected)
func apply(action: Dictionary) -> Dictionary:
	var normalised = action.duplicate(true)
	if normalised.has("bundle"):
		for r in normalised.bundle: normalised.bundle[r] = int(normalised.bundle[r])
	return super.apply(normalised)
func violations() -> Array:
	var errors = super.violations().filter(func(e): return e != "prestige gold price accounting")
	if state.trade.gold_spent != state.trade.prestige_bought*int(rules.prestige_gold_price)+state.project_metrics.stone_gold_spent: errors.append("stone and prestige gold accounting")
	if state.ledger.stone.created != state.project_metrics.stone_bought: errors.append("stone import accounting")
	for id in state.projects:
		var p: Dictionary = state.projects[id]
		for r in p.paid:
			if p.paid[r] < 0 or p.paid[r] > cost_for(id)[r]: errors.append("excess project contribution")
		if p.completed != (state.buildings[id].level == 2): errors.append("project completion functionality mismatch")
		if not p.completed and not linked_contract(id).is_empty():
			errors.erase("scenario card identity: "+id)
			if (state.deck+state.discard+state.revealed).count(id) != 1: errors.append("partial linked project card identity")
	return errors

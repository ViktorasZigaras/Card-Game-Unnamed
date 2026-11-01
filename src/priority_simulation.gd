class_name PrioritySimulation
extends ContractSimulation
var action_context: Dictionary = {}
var action_reservations: Array = []
func _init() -> void:
	super._init()
	rules.schema_version = 7
	rules.experiment = "priority_contract_economy"
	rules.contract_start_price = 3
	rules.contract_price_step = 2
	rules.cancel_surcharge = 3
func _ensure_priority() -> void:
	if not state.has("titles"): state.titles = {}
	if not state.has("priority_metrics"):
		state.priority_metrics = {"purchases":0,"takeovers":0,"prestige_spent":0,"reserved_deliveries":0,"creator_first_deliveries":0,"incremental_activations":0,"upgraded_links":0,"last_progress_round":0}
func title(resource: String) -> Dictionary:
	_ensure_priority()
	if not state.titles.has(resource):
		var sponsor = ""
		for c in state.contracts:
			if c.get("resource","") == resource or c.id == ("preset_lumber" if resource == "wood" else "clay_import" if resource == "clay" else ""):
				sponsor = c.get("sponsor","")
		if resource == "clay": sponsor = state.clay_contract.get("sponsor",sponsor)
		state.titles[resource] = {"owner":"","price":int(rules.contract_start_price),"purchases":0,"creator":sponsor,"first_pending":sponsor != ""}
	return state.titles[resource]
func _process_links() -> void:
	_ensure_priority()
	super._process_links()
	state.schema_version = 7
func _add_lot(resource: String,amount: int,producer: String,source: String,turn_no: int) -> void:
	_ensure_priority()
	var holder = producer
	var timer = turn_no
	var delivery = source.begins_with("contract_") or source in ["lumber_link","clay_import"]
	if delivery and not contract_for(resource).is_empty():
		var t = title(resource)
		holder = t.creator if t.first_pending else t.owner
		if t.first_pending:
			state.priority_metrics.creator_first_deliveries += 1
			t.first_pending = false
		if holder != "":
			timer = int(house(holder).turns_taken)
			if not action_context.is_empty() and current_house().id == holder: timer += 1
			state.priority_metrics.reserved_deliveries += 1
	if holder != "" and amount > 0:
		# Reserve a single token, not the complete batch.
		super._add_lot(resource,1,holder,source,timer)
		if amount > 1: super._add_lot(resource,amount-1,"",source,0)
	else: super._add_lot(resource,amount,"",source,0)
func cancel_price(resource: String) -> int:
	return maxi(int(title(resource).price)+int(rules.cancel_surcharge),super.cancel_price(resource)+4)
func linked_contract(id: String) -> Dictionary:
	for c in state.contracts:
		if c.get("source","") == id and c.get("cadence","") == "round": return c
	if id == "lumber_camp" and state.lumber_link: return {"id":"preset_lumber"}
	return {}
func modes(id: String) -> Array:
	var all_modes = super.modes(id)
	if linked_contract(id).is_empty(): return all_modes
	if int(state.buildings[id].level) == 1: return []
	var base: Dictionary = all_modes[0]
	var enhanced: Dictionary = all_modes[-1]
	var extra_inputs = {}
	var extra_outputs = {}
	for r in enhanced.inputs:
		var amount = int(enhanced.inputs[r])-int(base.inputs.get(r,0))
		if amount > 0: extra_inputs[r] = amount
	for r in enhanced.outputs:
		var amount = int(enhanced.outputs[r])-int(base.outputs.get(r,0))
		if amount > 0: extra_outputs[r] = amount
	return [{"name":"incremental","inputs":extra_inputs,"outputs":extra_outputs}]
func legal_actions() -> Array:
	var actions = super.legal_actions()
	var h = current_house()
	for r in rules.goods:
		if not contract_for(r).is_empty():
			var t = title(r)
			if t.owner != h.id and h.inventory.prestige >= t.price: actions.append({"type":"buy_contract","resource":r})
	for id in state.buildings:
		var b: Dictionary = state.buildings[id]
		if not b.built or b.level != 1 or id in ["chapel","marketplace"] or b.owner not in ["",h.id]: continue
		if is_housing(id) and b.owner != h.id: continue
		if linked_contract(id).is_empty() and id not in state.revealed: continue
		var a = {"type":"upgrade","building":id}
		if a not in actions and payment_plan(h.id,rules.housing_upgrade_cost).ok: actions.append(a)
	return actions
func _upgrade_building(action: Dictionary,h: Dictionary,events: Array) -> void:
	var plan = payment_plan(h.id,rules.housing_upgrade_cost)
	_pay(h.id,plan,events)
	_consume_plan(h.id,plan,events)
	_finish_upgrade(action,h,events)

func _finish_upgrade(action: Dictionary,h: Dictionary,events: Array) -> void:
	state.buildings[action.building].level = 2
	if not linked_contract(action.building).is_empty():
		state.discard.append(action.building)
		state.priority_metrics.upgraded_links += 1
	if is_housing(action.building):
		if h.first_upgrade_round == 0: h.first_upgrade_round = state.round
		_milestone("brick_house",h.id,events)
	events.append({"type":"building_upgraded","building":action.building,"incremental":not linked_contract(action.building).is_empty()})
func _experimental_action(action: Dictionary,h: Dictionary,events: Array) -> void:
	if action.type == "buy_contract":
		var t = title(action.resource)
		var paid = int(t.price)
		var previous = str(t.owner)
		h.inventory.prestige -= paid
		state.ledger.prestige.consumed += paid
		t.owner = h.id
		t.price += int(rules.contract_price_step)
		t.purchases += 1
		state.priority_metrics.purchases += 1
		state.priority_metrics.prestige_spent += paid
		if previous != "": state.priority_metrics.takeovers += 1
		events.append({"type":"contract_purchased","resource":action.resource,"previous":previous,"owner":h.id,"consumed_prestige":paid,"next_price":t.price})
		return
	var upgraded_source = false
	if action.type == "cancel_contract":
		var c = contract_for(action.resource)
		upgraded_source = not linked_contract(c.source).is_empty() and state.buildings[c.source].level == 2
	super._experimental_action(action,h,events)
	if action.type == "secure_contract":
		title(action.resource)
		if state.buildings[action.source].level == 2 and action.source in state.linked_assets: state.discard.append(action.source)
	if action.type == "cancel_contract":
		if upgraded_source: state.discard.pop_back() # Existing incremental card becomes the full manual card.
		state.titles.erase(action.resource)
func apply(action: Dictionary) -> Dictionary:
	# Capture context only during a command, so automatic deliveries get the correct expiry.
	action_reservations = []
	var actor = current_house().id
	for lot in state.lots:
		if lot.reserved_for == actor: action_reservations.append(lot.id)
	action_context = action.duplicate(true)
	var result = super.apply(action)
	action_context = {}
	if result.ok:
		if action.type == "activate" and action.get("mode","") == "incremental": state.priority_metrics.incremental_activations += 1
		if action.type in ["upgrade","buy_brick","secure_clay_contract"]: state.priority_metrics.last_progress_round = state.round
	return result
func _after_action(event: Dictionary) -> void:
	if event.get("free_action",false):
		for lot in state.lots:
			if lot.id in action_reservations and lot.reserved_for == event.house:
				state.reservation_metrics.released_units += int(lot.amount)
				lot.reserved_for = ""
				lot.expires_after_action = 0
				lot.released = true
				event.consequences.append({"type":"priority_expired","lot":lot.id,"reason":"next action was paid activation"})

func violations() -> Array:
	var errors = super.violations()
	for id in state.buildings:
		if not linked_contract(id).is_empty() and state.buildings[id].level == 2:
			errors.erase("scenario card identity: "+id)
			if (state.deck+state.discard+state.revealed).count(id) != 1: errors.append("incremental card identity: "+id)
	for r in state.get("titles",{}):
		var t: Dictionary = state.titles[r]
		if contract_for(r).is_empty(): errors.append("ownership without contract")
		if t.owner != "" and house(t.owner).is_empty(): errors.append("unknown contract owner")
		if t.price != int(rules.contract_start_price)+int(t.purchases)*int(rules.contract_price_step): errors.append("takeover price accounting")
	return errors

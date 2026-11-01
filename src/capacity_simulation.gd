class_name CapacitySimulation
extends PrioritySimulation
var scenario_kiln = true
func _init() -> void:
	super._init()
	rules.schema_version = 9
	rules.experiment = "committed_export_capacity_and_kiln"
	rules.kiln_cost = {"wood":2,"pop":1}
	var kiln = {"id":"kiln","kind":"workshop","terrain":"urban","inputs":{"clay":1,"pop":1},"outputs":{"brick":1}}
	rules.buildings.append(kiln)
	definitions.kiln = kiln
func start(seed_value: int,locale: String = "clayless_valley",house_count: int = 3) -> void:
	rules.kiln_enabled = scenario_kiln
	super.start(seed_value,locale,house_count)
func ensure_capacity() -> void:
	if not state.has("capacity"):
		state.capacity = {"wood":0,"kiln_built_round":0,"kiln_builder":"","kiln_bricks":0,"kiln_activations":0,"construction_spent":{}}
		state.buildings.kiln = {"definition":"kiln","built":false,"owner":"","level":1,"plot":""}
func _new_round() -> void:
	ensure_capacity()
	super._new_round()
	state.schema_version = 9
func _clay_upkeep() -> Dictionary:
	return {} # One permanently committed wood backs the standing export line.
func _add_lot(resource: String,amount: int,producer: String,source: String,turn_no: int) -> void:
	super._add_lot(resource,amount,producer,source,turn_no)
	if resource == "brick" and source == "kiln": state.capacity.kiln_bricks += amount
func legal_actions() -> Array:
	var actions = super.legal_actions()
	if rules.get("kiln_enabled",false) and not state.buildings.kiln.built and state.terrain_free.urban > 0 and payment_plan(current_house().id,rules.kiln_cost).ok:
		actions.append({"type":"build_kiln"})
	# Keep the new workshop at its baseline recipe in this experiment.
	return actions.filter(func(a): return not (a.type == "upgrade" and a.building == "kiln"))
func _experimental_action(action: Dictionary,h: Dictionary,events: Array) -> void:
	if action.type == "build_kiln":
		var plan = payment_plan(h.id,rules.kiln_cost)
		_pay(h.id,plan,events)
		_consume_plan(h.id,plan,events)
		_build_on("kiln","urban")
		state.capacity.kiln_built_round = state.round
		state.capacity.kiln_builder = h.id
		state.capacity.construction_spent = rules.kiln_cost.duplicate(true)
		events.append({"type":"kiln_constructed","house":h.id,"cost":rules.kiln_cost,"plot":"urban"})
		return
	super._experimental_action(action,h,events)
	if action.type == "cancel_contract" and action.resource == "clay":
		var released = int(state.capacity.wood)
		state.capacity.wood = 0
		_add_lot("wood",released,"","released_export_capacity",0)
		state.ledger.wood.created -= released
		events.append({"type":"export_capacity_released","wood":released})
func apply(action: Dictionary) -> Dictionary:
	var result = super.apply(action)
	if result.ok:
		if action.type == "secure_clay_contract":
			# The setup's wood token changes location instead of being consumed.
			state.ledger.wood.consumed -= 1
			state.capacity.wood += 1
			for e in result.event.consequences:
				if e.get("type","") == "consume" and e.get("resource","") == "wood":
					e.type = "commit_resource"
					e.destination = "clay_export_capacity"
			result.event.consequences.append({"type":"wood_committed_to_export","wood":1})
		if action.type == "activate" and action.building == "kiln": state.capacity.kiln_activations += 1
	return result
func violations() -> Array:
	var errors = super.violations().filter(func(e): return e not in ["source/sink accounting: wood","bricks must originate exclusively from caravan barter"])
	if total_physical("wood")+int(state.capacity.wood) != int(state.ledger.wood.created)-int(state.ledger.wood.consumed): errors.append("committed wood conservation")
	if int(state.capacity.wood) != (1 if not state.clay_contract.is_empty() else 0): errors.append("one wood backs clay export link")
	if int(state.ledger.brick.created) != int(state.access_metrics.bricks_bartered)+int(state.capacity.kiln_bricks): errors.append("imported and manufactured brick accounting")
	return errors

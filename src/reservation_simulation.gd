class_name ReservationSimulation
extends TownSimulation
## Cashless shared stock with one-personal-action production reservations.
const INPUT_ORDER = ["grain","clay","wood","brick","pop","luxury"]
func _init() -> void:
	rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/reservation_rules.json"))
	definitions.clear()
	for d in rules.buildings:
		definitions[d.id] = d

func start(seed_value: int, locale: String = "river_valley", house_count: int = 3) -> void:
	rng.seed = seed_value
	state = {"schema_version":3,"experiment":rules.experiment,"seed":seed_value,"locale":locale,"round":0,"actor":0,"sequence":0,
		"houses":[],"buildings":{},"deck":[],"discard":[],"revealed":[],"used":[],"passed":[],"actions_taken":{},
		"market":{},"terrain_free":rules.locales[locale].terrain.duplicate(true),"lots":[],"next_lot":1,"next_hut":4,
		"contracts":[],"ledger":{},"history":[],"round_events":[],"reservation_metrics":{"produced_units":0,"producer_consumed":0,"released_units":0,"later_public_consumed":0,"expired_pops":0},
		"pop_granted":0,"pop_worked":0}
	for r in rules.resources:
		state.ledger[r] = {"created":0,"consumed":0}
		if r != "influence":
			state.market[r] = 0
	for i in range(house_count):
		var h: Dictionary = rules.houses[i].duplicate(true)
		h.inventory = {"influence":int(rules.initial_influence)}
		h.turns_taken = 0
		h.first_claim_round = 0
		h.first_upgrade_round = 0
		state.houses.append(h)
		state.ledger.influence.created += h.inventory.influence
	for r in rules.locales[locale].stock:
		_add_lot(r, int(rules.locales[locale].stock[r]), "", "initial", 0)
	for d in rules.buildings:
		if d.kind != "housing":
			state.buildings[d.id] = {"definition":d.id,"built":false,"owner":"","level":1,"plot":""}
	for id in ["lumber_camp","grain_farm","clay_pit","brick_kiln","pottery_workshop"]:
		_build_on(id, str(definitions[id].terrain))
	for i in range(3):
		var id = "hut_%d" % (i + 1)
		state.buildings[id] = {"definition":"hut","built":false,"owner":"","level":1,"plot":""}
		_build_on(id, "urban")
	_shuffle(state.deck)
	_new_round()

func definition(id: String) -> Dictionary:
	return definitions[state.buildings[id].definition]

func is_housing(id: String) -> bool:
	return state.buildings[id].definition == "hut"

func _build_on(id: String, terrain: String) -> void:
	state.buildings[id].built = true
	state.buildings[id].plot = terrain
	state.terrain_free[terrain] -= 1
	state.deck.append(id)

func owned_huts(id: String, upgraded_only: bool = false) -> Array:
	var result: Array = []
	for key in _sorted_keys(state.buildings):
		var b: Dictionary = state.buildings[key]
		if b.built and is_housing(key) and b.owner == id and (not upgraded_only or b.level == 2):
			result.append(key)
	return result

func inputs(id: String) -> Dictionary:
	var d = definition(id)
	return d.upgraded_inputs if is_housing(id) and state.buildings[id].level == 2 else d.inputs

func outputs(id: String) -> Dictionary:
	var d = definition(id)
	if is_housing(id):
		return d.upgraded_outputs if state.buildings[id].level == 2 else d.outputs
	var result: Dictionary = d.outputs.duplicate(true)
	for r in result:
		result[r] *= int(state.buildings[id].level)
	return result

func available(house_id: String) -> Dictionary:
	var result: Dictionary = {}
	for r in rules.goods:
		result[r] = 0
	for lot in state.lots:
		if lot.reserved_for == "" or lot.reserved_for == house_id:
			result[lot.resource] += lot.amount
	return result

func _add_lot(resource: String, amount: int, producer: String, source: String, turn_no: int) -> void:
	if amount == 0:
		return
	state.lots.append({"id":state.next_lot,"resource":resource,"amount":amount,"producer":producer,"reserved_for":producer,
		"expires_after_action":turn_no + 1 if producer != "" else 0,"source":source,"released":false})
	state.next_lot += 1
	state.ledger[resource].created += amount
	state.market[resource] += amount
	if producer != "":
		state.reservation_metrics.produced_units += amount
	if resource == "pop":
		state.pop_granted += amount

func _consume_stock(house_id: String, cost: Dictionary, reason: String, events: Array) -> void:
	# Consume own exclusive stock before public lots. Other reservations are skipped.
	for resource in INPUT_ORDER:
		if not cost.has(resource):
			continue
		var remaining = int(cost[resource])
		for exclusive in [true, false]:
			for lot in state.lots:
				if lot.resource != resource or lot.amount == 0:
					continue
				if exclusive and lot.reserved_for != house_id:
					continue
				if not exclusive and lot.reserved_for != "":
					continue
				var take = mini(remaining, int(lot.amount))
				if take == 0:
					continue
				lot.amount -= take
				remaining -= take
				state.market[resource] -= take
				state.ledger[resource].consumed += take
				if lot.reserved_for == house_id:
					state.reservation_metrics.producer_consumed += take
				elif lot.released:
					state.reservation_metrics.later_public_consumed += take
				if resource == "pop":
					state.pop_worked += take
				events.append({"type":"consume","resource":resource,"amount":take,"lot":lot.id,"reservation":lot.reserved_for,"reason":reason})
		assert(remaining == 0, "Validated stock disappeared during command")
	state.lots = state.lots.filter(func(lot): return lot.amount > 0)

func _release(house_id: String, turn_no: int, events: Array) -> void:
	for lot in state.lots:
		if lot.reserved_for == house_id and lot.expires_after_action <= turn_no:
			state.reservation_metrics.released_units += lot.amount
			events.append({"type":"release","lot":lot.id,"resource":lot.resource,"amount":lot.amount,"producer":house_id})
			lot.reserved_for = ""
			lot.expires_after_action = 0
			lot.released = true

func legal_actions() -> Array:
	var h = current_house()
	var stock = available(h.id)
	var result: Array = [{"type":"pass"}]
	if state.actions_taken[h.id] >= rules.max_actions_per_house:
		return result
	for id in state.revealed:
		var b: Dictionary = state.buildings[id]
		if id not in state.used and _can_pay(stock, inputs(id)):
			var fits = true
			for r in outputs(id):
				if state.market[r] - inputs(id).get(r, 0) + outputs(id)[r] > rules.pool_capacity:
					fits = false
			if fits:
				result.append({"type":"activate","building":id})
		if b.owner == "" and _owns(h.id) < rules.ownership_slots and h.inventory.influence >= rules.claim_cost:
			result.append({"type":"claim","building":id})
		if b.owner == h.id and b.level == 1 and _can_pay(stock, rules.housing_upgrade_cost):
			result.append({"type":"upgrade","building":id})
	if _can_pay(stock, rules.construct_cost):
		if state.terrain_free.urban > 0:
			result.append({"type":"construct_hut"})
		for id in _sorted_keys(state.buildings):
			if not state.buildings[id].built and state.terrain_free[definition(id).terrain] > 0:
				result.append({"type":"construct","building":id})
	return result

func apply(action: Dictionary) -> Dictionary:
	if action not in legal_actions():
		return {"ok":false,"error":"illegal_action","action":action.duplicate(true)}
	var h = current_house()
	var round_before = int(state.round)
	var turn_no = int(h.turns_taken) + 1
	var id = str(action.get("building", ""))
	var consequences: Array = []
	match action.type:
		"pass":
			state.passed.append(h.id)
			h.inventory.influence += 1
			state.ledger.influence.created += 1
			consequences.append({"type":"influence_from_pass","amount":1})
		"activate":
			_consume_stock(h.id, inputs(id), "activate:" + id, consequences)
			for r in outputs(id):
				var amount = int(outputs(id)[r])
				_add_lot(r, amount, h.id, id, turn_no)
				consequences.append({"type":"produce_reserved","resource":r,"amount":amount,"house":h.id,"exclusive_through_personal_action":turn_no + 1})
			state.used.append(id)
		"claim":
			h.inventory.influence -= rules.claim_cost
			state.ledger.influence.consumed += rules.claim_cost
			state.buildings[id].owner = h.id
			if is_housing(id) and h.first_claim_round == 0:
				h.first_claim_round = state.round
		"upgrade":
			_consume_stock(h.id, rules.housing_upgrade_cost, "upgrade:" + id, consequences)
			state.buildings[id].level = 2
			if is_housing(id) and h.first_upgrade_round == 0:
				h.first_upgrade_round = state.round
		"construct_hut":
			_consume_stock(h.id, rules.construct_cost, "construct_hut", consequences)
			id = "hut_%d" % int(state.next_hut)
			state.next_hut += 1
			state.buildings[id] = {"definition":"hut","built":false,"owner":"","level":1,"plot":""}
			_build_on(id, "urban")
			consequences.append({"type":"public_construction","building":id,"plot":"urban"})
		"construct":
			_consume_stock(h.id, rules.construct_cost, "construct:" + id, consequences)
			_build_on(id, str(definition(id).terrain))
			consequences.append({"type":"public_construction","building":id,"plot":definition(id).terrain})
	h.turns_taken = turn_no
	_release(h.id, turn_no, consequences)
	state.actions_taken[h.id] += 1
	state.sequence += 1
	var event = {"sequence":state.sequence,"round":round_before,"house":h.id,"action":action.duplicate(true),"personal_action":turn_no,"consequences":consequences}
	state.history.append(event)
	if state.history.size() > 64:
		state.history.pop_front()
	var round_done = state.passed.size() == state.houses.size()
	if round_done:
		_close_round()
	else:
		for i in range(state.houses.size()):
			state.actor = (int(state.actor) + 1) % state.houses.size()
			if current_house().id not in state.passed:
				break
	return {"ok":true,"event":event,"round_closed":round_done}

func _close_round() -> void:
	state.round_events = []
	var surviving: Array = []
	for lot in state.lots:
		if lot.resource == "pop":
			state.ledger.pop.consumed += lot.amount
			state.market.pop -= lot.amount
			state.reservation_metrics.expired_pops += lot.amount
			state.round_events.append({"type":"unused_pop_expires","amount":lot.amount,"producer":lot.producer})
		else:
			surviving.append(lot)
	state.lots = surviving
	state.discard.append_array(state.revealed)
	_new_round()

func restore(saved: Dictionary) -> void:
	assert(int(saved.state.schema_version) == 3, "Unsupported reservation save schema")
	rules = saved.rules.duplicate(true)
	definitions.clear()
	for d in rules.buildings:
		definitions[d.id] = d
	state = saved.state.duplicate(true)
	rng.seed = int(state.seed)
	rng.state = int(saved.rng_state)

func violations() -> Array:
	var errors: Array = []
	var totals: Dictionary = {}
	for r in rules.resources:
		totals[r] = 0
	for h in state.houses:
		if h.inventory.influence < 0 or _owns(h.id) > rules.ownership_slots:
			errors.append("invalid influence/property count: " + h.id)
		totals.influence += h.inventory.influence
	var lot_ids: Array = []
	for lot in state.lots:
		if lot.amount <= 0 or lot.resource not in rules.goods or lot.id in lot_ids:
			errors.append("invalid stock lot")
		lot_ids.append(lot.id)
		if lot.reserved_for != "" and (house(lot.reserved_for).is_empty() or lot.expires_after_action <= house(lot.reserved_for).turns_taken):
			errors.append("invalid/stale reservation")
		totals[lot.resource] += lot.amount
	for r in rules.goods:
		if state.market[r] != totals[r] or totals[r] < 0 or totals[r] > rules.pool_capacity:
			errors.append("pool accounting/capacity: " + r)
	for r in rules.resources:
		if totals[r] != state.ledger[r].created - state.ledger[r].consumed:
			errors.append("source/sink accounting: " + r)
	if state.pop_granted != state.pop_worked + state.reservation_metrics.expired_pops + totals.pop:
		errors.append("pop work/regeneration accounting")
	var cards: Array = state.deck + state.discard + state.revealed
	for id in state.buildings:
		var b: Dictionary = state.buildings[id]
		if cards.count(id) != (1 if b.built else 0):
			errors.append("card identity: " + id)
		if b.built and (b.plot != definition(id).terrain or (is_housing(id) and b.plot != "urban")):
			errors.append("urban/rural placement: " + id)
	for terrain in state.terrain_free:
		var occupied = 0
		for b in state.buildings.values():
			if b.built and b.plot == terrain:
				occupied += 1
		if state.terrain_free[terrain] < 0 or occupied + state.terrain_free[terrain] != rules.locales[state.locale].terrain[terrain]:
			errors.append("plot accounting: " + terrain)
	return errors

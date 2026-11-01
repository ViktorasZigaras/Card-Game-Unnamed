class_name HousingSimulation
extends TownSimulation
## Isolated experimental ruleset. The cash baseline remains available.
func _init() -> void:
	rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/housing_rules.json"))
	definitions.clear()
	for d in rules.buildings:
		definitions[d.id] = d

func start(seed_value: int, locale: String = "river_valley", house_count: int = 3) -> void:
	rng.seed = seed_value
	state = {"schema_version":2,"experiment":rules.experiment,"seed":seed_value,"locale":locale,"round":0,"actor":0,"sequence":0,
		"houses":[],"buildings":{},"deck":[],"discard":[],"revealed":[],"used":[],"passed":[],"actions_taken":{},
		"market":rules.locales[locale].market.duplicate(true),"terrain_free":rules.locales[locale].terrain.duplicate(true),
		"contracts":[],"ledger":{},"history":[],"population_events":[],"next_hut":house_count + 1}
	for resource in rules.resources:
		state.ledger[resource] = {"created":0,"consumed":0}
		state.market[resource] = int(state.market.get(resource, 0))
		state.ledger[resource].created = state.market[resource]
	for i in range(house_count):
		var h: Dictionary = rules.houses[i].duplicate(true)
		h.inventory = rules.starting_inventory.duplicate(true)
		h.labour = 0
		h.labour_granted = 0
		h.labour_spent = 0
		h.first_claim_round = 0
		h.first_upgrade_round = 0
		for r in rules.resources:
			state.ledger[r].created += h.inventory[r]
		state.houses.append(h)
	for d in rules.buildings:
		if d.kind != "housing":
			state.buildings[d.id] = {"definition":d.id,"built":false,"owner":"","level":1,"plot":"","residents":{}}
	for id in ["lumber_camp","grain_farm","clay_pit","brick_kiln","carpenter"]:
		_build_on(id, str(definitions[id].terrain))
	# Initial housing is public; resident allegiance and property ownership differ.
	for i in range(house_count):
		var id = "hut_%d" % (i + 1)
		state.buildings[id] = {"definition":"hut","built":false,"owner":"","level":1,"plot":"","residents":{state.houses[i].id:2}}
		_build_on(id, available_plots()[0])
	_shuffle(state.deck)
	_new_round()

func definition(id: String) -> Dictionary:
	return definitions[state.buildings[id].definition]

func is_housing(id: String) -> bool:
	return state.buildings[id].definition == "hut"

func available_plots() -> Array:
	var result: Array = []
	for terrain in ["town","field","forest","claybank"]:
		if state.terrain_free[terrain] > 0:
			result.append(terrain)
	return result

func _build_on(id: String, terrain: String) -> void:
	state.buildings[id].built = true
	state.buildings[id].plot = terrain
	state.terrain_free[terrain] -= 1
	state.deck.append(id)

func population(house_id: String) -> int:
	var total = 0
	for b in state.buildings.values():
		total += int(b.residents.get(house_id, 0))
	return total

func occupancy(id: String) -> int:
	var total = 0
	for count in state.buildings[id].residents.values():
		total += int(count)
	return total

func capacity(id: String) -> int:
	return int(rules.housing_capacity[str(int(state.buildings[id].level))])

func owned_huts(house_id: String, upgraded_only: bool = false) -> Array:
	var result: Array = []
	for id in _sorted_keys(state.buildings):
		var b: Dictionary = state.buildings[id]
		if b.built and is_housing(id) and b.owner == house_id and (not upgraded_only or b.level == 2):
			result.append(id)
	return result

func _goods(inv: Dictionary) -> int:
	var total = 0
	for r in rules.goods:
		total += int(inv[r])
	return total

func _new_round() -> void:
	super._new_round()
	for h in state.houses:
		h.labour = population(h.id)
		h.labour_granted = h.labour
		h.labour_spent = 0

func labour_cost(action: Dictionary) -> int:
	match action.type:
		"pass": return 0
		"upgrade", "construct", "construct_hut": return 2
		_: return 1

func legal_actions() -> Array:
	var h = current_house()
	var inv: Dictionary = h.inventory
	var result: Array = [{"type":"pass"}]
	if state.actions_taken[h.id] >= rules.max_actions_per_house or h.labour < 1:
		return result
	result.append({"type":"rally_support"})
	for id in state.revealed:
		var b: Dictionary = state.buildings[id]
		var d = definition(id)
		if not is_housing(id) and id not in state.used and _can_pay(inv, d.inputs):
			var net_goods = 0
			for r in rules.goods:
				net_goods += int(d.outputs.get(r, 0)) * int(b.level) - int(d.inputs.get(r, 0))
			if _goods(inv) + net_goods <= rules.inventory_capacity:
				result.append({"type":"activate","building":id})
		var claim_cost: Dictionary = rules.housing_claim_cost if is_housing(id) else rules.productive_claim_cost
		if b.owner == "" and _owns(h.id) < rules.ownership_slots and _can_pay(inv, claim_cost):
			result.append({"type":"claim","building":id})
		var upgrade_cost: Dictionary = rules.housing_upgrade_cost if is_housing(id) else rules.productive_upgrade_cost
		if b.owner == h.id and b.level == 1 and h.labour >= 2 and _can_pay(inv, upgrade_cost):
			result.append({"type":"upgrade","building":id})
	if _owns(h.id) < rules.ownership_slots and h.labour >= 2:
		if _can_pay(inv, rules.housing_build_cost):
			for terrain in available_plots():
				result.append({"type":"construct_hut","plot":terrain})
		if _can_pay(inv, rules.productive_build_cost):
			for id in _sorted_keys(state.buildings):
				var b: Dictionary = state.buildings[id]
				if not b.built and state.terrain_free[definition(id).terrain] > 0:
					result.append({"type":"construct","building":id})
	for give in rules.goods:
		if inv[give] == 0 or state.market[give] >= rules.market_capacity:
			continue
		for take in rules.goods:
			if take != give and state.market[take] > 0:
				result.append({"type":"barter","give":give,"take":take})
	return result

func _create(inv: Dictionary, resource: String, amount: int) -> void:
	inv[resource] += amount
	state.ledger[resource].created += amount

func apply(action: Dictionary) -> Dictionary:
	if action not in legal_actions():
		return {"ok":false,"error":"illegal_action","action":action.duplicate(true)}
	var h = current_house()
	var inv: Dictionary = h.inventory
	var round_before = int(state.round)
	var id = str(action.get("building", ""))
	var labour = labour_cost(action)
	h.labour -= labour
	h.labour_spent += labour
	var consequences: Array = []
	match action.type:
		"pass": state.passed.append(h.id)
		"rally_support": _create(inv, "influence", 1)
		"activate":
			var d = definition(id)
			var b: Dictionary = state.buildings[id]
			_consume(inv, d.inputs)
			for r in d.outputs:
				_create(inv, r, int(d.outputs[r]) * int(b.level))
			if b.owner != "" and b.owner != h.id:
				_create(house(b.owner).inventory, "influence", 1)
				consequences.append({"type":"owner_recognition","house":b.owner,"influence":1})
			state.used.append(id)
		"claim":
			_consume(inv, rules.housing_claim_cost if is_housing(id) else rules.productive_claim_cost)
			state.buildings[id].owner = h.id
			if is_housing(id) and h.first_claim_round == 0:
				h.first_claim_round = state.round
		"upgrade":
			_consume(inv, rules.housing_upgrade_cost if is_housing(id) else rules.productive_upgrade_cost)
			state.buildings[id].level = 2
			if is_housing(id) and h.first_upgrade_round == 0:
				h.first_upgrade_round = state.round
		"construct_hut":
			_consume(inv, rules.housing_build_cost)
			id = "hut_%d" % int(state.next_hut)
			state.next_hut += 1
			state.buildings[id] = {"definition":"hut","built":false,"owner":h.id,"level":1,"plot":"","residents":{}}
			_build_on(id, action.plot)
			consequences.append({"type":"built","building":id,"plot":action.plot})
			if h.first_claim_round == 0:
				h.first_claim_round = state.round
		"construct":
			_consume(inv, rules.productive_build_cost)
			_build_on(id, str(definition(id).terrain))
			state.buildings[id].owner = h.id
		"barter":
			inv[action.give] -= 1
			state.market[action.give] += 1
			state.market[action.take] -= 1
			inv[action.take] += 1
	state.actions_taken[h.id] += 1
	state.sequence += 1
	var event = {"sequence":state.sequence,"round":round_before,"house":h.id,"action":action.duplicate(true),"labour_spent":labour,"consequences":consequences}
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
	state.population_events = []
	for id in _sorted_keys(state.buildings):
		var b: Dictionary = state.buildings[id]
		if not b.built or not is_housing(id) or b.owner == "":
			continue
		var inv: Dictionary = house(b.owner).inventory
		if b.level == 2 and occupancy(id) > 0:
			_create(inv, "influence", 1)
			state.population_events.append({"type":"housing_influence","building":id,"house":b.owner,"amount":1})
		if occupancy(id) < capacity(id) and inv.grain > 0:
			_consume(inv, {"grain":1})
			b.residents[b.owner] = b.residents.get(b.owner, 0) + 1
			state.population_events.append({"type":"arrival","building":id,"house":b.owner,"grain_spent":1})
	state.discard.append_array(state.revealed)
	_new_round()

func restore(saved: Dictionary) -> void:
	assert(int(saved.state.schema_version) == 2, "Unsupported housing save schema")
	rules = saved.rules.duplicate(true)
	definitions.clear()
	for d in rules.buildings:
		definitions[d.id] = d
	state = saved.state.duplicate(true)
	rng.seed = int(state.seed)
	rng.state = int(saved.rng_state)

func violations() -> Array:
	var errors: Array = []
	var totals: Dictionary = state.market.duplicate()
	var cards: Array = state.deck + state.discard + state.revealed
	for h in state.houses:
		if _owns(h.id) > rules.ownership_slots or _goods(h.inventory) > rules.inventory_capacity:
			errors.append("ownership or storage overflow: " + h.id)
		if h.labour < 0 or h.labour_spent < 0 or h.labour + h.labour_spent != h.labour_granted or h.labour_granted != population(h.id):
			errors.append("labour accounting: " + h.id)
		if population(h.id) < 2:
			errors.append("lost initial population: " + h.id)
		for r in rules.resources:
			if h.inventory[r] < 0:
				errors.append("negative inventory: " + h.id + "/" + r)
			totals[r] += h.inventory[r]
	for r in rules.resources:
		if state.market[r] < 0 or state.market[r] > rules.market_capacity:
			errors.append("invalid market stock: " + r)
		if totals[r] != state.ledger[r].created - state.ledger[r].consumed:
			errors.append("resource/influence accounting: " + r)
	for id in state.buildings:
		var b: Dictionary = state.buildings[id]
		if cards.count(id) != (1 if b.built else 0):
			errors.append("card identity mismatch: " + id)
		if is_housing(id):
			if occupancy(id) > capacity(id):
				errors.append("housing capacity overflow: " + id)
			for resident_house in b.residents:
				if house(resident_house).is_empty() or b.residents[resident_house] < 0:
					errors.append("invalid resident affiliation: " + id)
	for terrain in state.terrain_free:
		var occupied = 0
		for b in state.buildings.values():
			if b.built and b.plot == terrain:
				occupied += 1
		if state.terrain_free[terrain] < 0 or occupied + state.terrain_free[terrain] != rules.locales[state.locale].terrain[terrain]:
			errors.append("plot accounting: " + terrain)
	return errors

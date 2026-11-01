class_name TownSimulation
extends RefCounted
## All rules live here. Call legal_actions/apply; UI and AI receive copies.
const RULES_PATH = "res://data/rules.json"
var rules: Dictionary
var state: Dictionary
var rng = RandomNumberGenerator.new()
var definitions: Dictionary = {}

func _init() -> void:
	rules = JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH))
	for b in rules.buildings:
		definitions[b.id] = b

func start(seed_value: int, locale: String = "river_valley", house_count: int = 3) -> void:
	rng.seed = seed_value
	state = {"schema_version":1,"seed":seed_value,"locale":locale,"round":0,"actor":0,"sequence":0,
		"bank":int(rules.initial_bank),"houses":[],"buildings":{},"deck":[],"discard":[],"revealed":[],
		"used":[],"passed":[],"actions_taken":{},"market":rules.locales[locale].market.duplicate(true),
		"terrain_free":rules.locales[locale].terrain.duplicate(true),"contracts":[],"ledger":{},"history":[]}
	for resource in rules.resources:
		state.ledger[resource] = {"created":0,"consumed":0}
		state.market[resource] = int(state.market.get(resource, 0))
		state.ledger[resource].created += state.market[resource]
	state.ledger.coin.created += state.bank
	for i in range(house_count):
		var h: Dictionary = rules.houses[i].duplicate(true)
		h.inventory = {"wood":1,"grain":2,"clay":1,"brick":0,"coin":10}
		state.bank -= 10
		for r in ["wood","grain","clay"]:
			state.ledger[r].created += h.inventory[r]
		state.houses.append(h)
	for b in rules.buildings:
		# Construction candidates exist independently of whether they are built.
		state.buildings[b.id] = {"built":false,"owner":"","level":1}
	# Small public core: five cards; others require construction and terrain.
	for id in ["lumber_camp","grain_farm","clay_pit","brick_kiln","carpenter"]:
		_build(id)
	_shuffle(state.deck)
	_new_round()

func _shuffle(cards: Array) -> void:
	for i in range(cards.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = cards[i]
		cards[i] = cards[j]
		cards[j] = temp

func _build(id: String) -> void:
	state.buildings[id].built = true
	state.terrain_free[definitions[id].terrain] -= 1
	state.deck.append(id)

func _new_round() -> void:
	state.round += 1
	state.used = []
	state.passed = []
	state.actions_taken = {}
	for h in state.houses:
		state.actions_taken[h.id] = 0
	state.revealed = []
	var count = mini(int(rules.reveal_count), state.deck.size() + state.discard.size())
	for i in range(count):
		if state.deck.is_empty():
			state.deck = state.discard.duplicate()
			state.discard.clear()
			_shuffle(state.deck)
		state.revealed.append(state.deck.pop_back())
	state.actor = (int(state.round) - 1) % state.houses.size()

func house(id: String) -> Dictionary:
	for h in state.houses:
		if h.id == id:
			return h
	return {}

func current_house() -> Dictionary:
	return state.houses[int(state.actor)]

func _can_pay(inv: Dictionary, cost: Dictionary) -> bool:
	for r in cost:
		if inv.get(r, 0) < cost[r]:
			return false
	return true

func _goods(inv: Dictionary) -> int:
	var total = 0
	for r in inv:
		if r != "coin":
			total += int(inv[r])
	return total

func _owns(id: String) -> int:
	var count = 0
	for b in state.buildings.values():
		if b.owner == id:
			count += 1
	return count

func legal_actions() -> Array:
	var h = current_house()
	var inv: Dictionary = h.inventory
	var result: Array = [{"type":"pass"}]
	if state.actions_taken[h.id] >= rules.max_actions_per_house:
		return result
	if state.bank > 0:
		result.append({"type":"work"})
	for id in state.revealed:
		var b: Dictionary = state.buildings[id]
		var d: Dictionary = definitions[id]
		var fee = 1 if b.owner != "" and b.owner != h.id else 0
		var cost: Dictionary = d.inputs.duplicate()
		cost.coin = cost.get("coin", 0) + fee
		var gain = 0
		var spend = 0
		for r in d.outputs:
			if r != "coin":
				gain += int(d.outputs[r]) * int(b.level)
		for r in d.inputs:
			if r != "coin":
				spend += int(d.inputs[r])
		var coin_output = int(d.outputs.get("coin", 0)) * int(b.level)
		if id not in state.used and _can_pay(inv, cost) and _goods(inv) + gain - spend <= rules.inventory_capacity and state.bank >= coin_output:
			result.append({"type":"activate","building":id})
		if b.owner == "" and _owns(h.id) < rules.ownership_slots and inv.coin >= d.price:
			result.append({"type":"buy_building","building":id})
		if b.owner == h.id:
			result.append({"type":"sell_building","building":id})
			if b.level == 1 and _can_pay(inv, {"coin":3,"brick":1}):
				result.append({"type":"upgrade","building":id})
	if _owns(h.id) < rules.ownership_slots:
		for id in _sorted_keys(state.buildings):
			var b: Dictionary = state.buildings[id]
			if not b.built and state.terrain_free[definitions[id].terrain] > 0 and _can_pay(inv, {"wood":2,"brick":1,"coin":2}):
				result.append({"type":"construct","building":id})
	for r in _sorted_keys(rules.prices):
		var price = int(rules.prices[r])
		if state.market[r] > 0 and inv.coin >= price and _goods(inv) < rules.inventory_capacity:
			result.append({"type":"market_buy","resource":r})
		if inv[r] > 0 and state.market[r] < rules.market_capacity and state.bank >= price:
			result.append({"type":"market_sell","resource":r})
	# One rotating export offer; grain is escrowed immediately, payment on round close.
	var contracted = false
	for c in state.contracts:
		if c.house == h.id:
			contracted = true
	if int(state.round) % 3 == 1 and not contracted and inv.grain >= 2 and state.bank >= 4:
		result.append({"type":"contract"})
	return result

func _consume(inv: Dictionary, cost: Dictionary) -> void:
	for r in cost:
		inv[r] -= cost[r]
		state.ledger[r].consumed += cost[r]

func _pay_bank(inv: Dictionary, amount: int) -> void:
	inv.coin -= amount
	state.bank += amount

func _receive_bank(inv: Dictionary, amount: int) -> void:
	inv.coin += amount
	state.bank -= amount

func apply(action: Dictionary) -> Dictionary:
	# Reject illegal commands before mutating anything.
	if action not in legal_actions():
		return {"ok":false,"error":"illegal_action","action":action.duplicate(true)}
	var h = current_house()
	var inv: Dictionary = h.inventory
	var round_before = state.round
	var id = str(action.get("building", ""))
	match action.type:
		"pass": state.passed.append(h.id)
		"work": _receive_bank(inv, 1)
		"activate":
			var d: Dictionary = definitions[id]
			var b: Dictionary = state.buildings[id]
			if b.owner != "" and b.owner != h.id:
				inv.coin -= 1
				house(b.owner).inventory.coin += 1
			_consume(inv, d.inputs)
			for r in d.outputs:
				var amount = int(d.outputs[r]) * int(b.level)
				if r == "coin":
					_receive_bank(inv, amount)
				else:
					inv[r] += amount
					state.ledger[r].created += amount
			state.used.append(id)
		"buy_building":
			_pay_bank(inv, int(definitions[id].price))
			state.buildings[id].owner = h.id
		"sell_building":
			# Sale returns ownership to the town; town can pay only its current funds.
			_receive_bank(inv, mini(state.bank, int(definitions[id].price) / 2))
			state.buildings[id].owner = ""
		"upgrade":
			_pay_bank(inv, 3)
			_consume(inv, {"brick":1})
			state.buildings[id].level = 2
		"construct":
			_pay_bank(inv, 2)
			_consume(inv, {"wood":2,"brick":1})
			_build(id)
			state.buildings[id].owner = h.id
		"market_buy":
			var r: String = action.resource
			_pay_bank(inv, int(rules.prices[r]))
			state.market[r] -= 1
			inv[r] += 1
		"market_sell":
			var r: String = action.resource
			_receive_bank(inv, int(rules.prices[r]))
			state.market[r] += 1
			inv[r] -= 1
		"contract":
			inv.grain -= 2
			state.bank -= 4
			state.contracts.append({"house":h.id,"remaining":3,"grain_escrow":2,"coin_escrow":4})
	state.actions_taken[h.id] += 1
	state.sequence += 1
	var event = {"sequence":state.sequence,"round":round_before,"house":h.id,"action":action.duplicate(true)}
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
	var continuing: Array = []
	for c in state.contracts:
		var inv: Dictionary = house(c.house).inventory
		state.ledger.grain.consumed += c.grain_escrow
		inv.coin += c.coin_escrow
		c.remaining -= 1
		# Renewal is automatic only when both sides can fund the next delivery.
		if c.remaining > 0 and inv.grain >= 2 and state.bank >= 4:
			inv.grain -= 2
			state.bank -= 4
			continuing.append(c)
	state.contracts = continuing
	state.discard.append_array(state.revealed)
	_new_round()

func snapshot() -> Dictionary:
	return {"state":state.duplicate(true),"rng_state":str(rng.state),"rules":rules.duplicate(true)}

func restore(saved: Dictionary) -> void:
	assert(int(saved.state.schema_version) == 1, "Unsupported save schema")
	rules = saved.rules.duplicate(true)
	definitions.clear()
	for b in rules.buildings:
		definitions[b.id] = b
	state = saved.state.duplicate(true)
	rng.seed = int(state.seed)
	rng.state = int(saved.rng_state)

func violations() -> Array:
	var errors: Array = []
	var totals: Dictionary = state.market.duplicate()
	totals.coin += state.bank
	if state.bank < 0:
		errors.append("negative bank")
	for h in state.houses:
		if _owns(h.id) > rules.ownership_slots:
			errors.append("ownership overflow: " + h.id)
		if _goods(h.inventory) > rules.inventory_capacity:
			errors.append("storage overflow: " + h.id)
		for r in rules.resources:
			if h.inventory[r] < 0:
				errors.append("negative inventory: " + h.id + "/" + r)
			totals[r] += h.inventory[r]
	for c in state.contracts:
		totals.grain += c.grain_escrow
		totals.coin += c.coin_escrow
	for r in rules.resources:
		if state.market[r] < 0 or (r != "coin" and state.market[r] > rules.market_capacity):
			errors.append("invalid market stock: " + r)
		if totals[r] != state.ledger[r].created - state.ledger[r].consumed:
			errors.append("accounting mismatch: " + r)
	var cards: Array = state.deck + state.discard + state.revealed
	for id in _sorted_keys(state.buildings):
		var b: Dictionary = state.buildings[id]
		if cards.count(id) != (1 if b.built else 0):
			errors.append("deck persistence mismatch: " + id)
	for terrain in state.terrain_free:
		var occupied = 0
		for id in _sorted_keys(state.buildings):
			if state.buildings[id].built and definitions[id].terrain == terrain:
				occupied += 1
		if state.terrain_free[terrain] < 0 or occupied + state.terrain_free[terrain] != rules.locales[state.locale].terrain[terrain]:
			errors.append("terrain mismatch: " + terrain)
	return errors

func _sorted_keys(value: Dictionary) -> Array:
	var keys = value.keys()
	keys.sort()
	return keys

static func canonical(value: Dictionary) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(value)), "", true)

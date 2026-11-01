class_name CommonsSimulation
extends ReservationSimulation
## Persistent commons, protected three-token stores, direct influence-paid access.
func _init() -> void:
	rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/commons_rules.json"))
	definitions.clear()
	for d in rules.buildings:
		definitions[d.id] = d

func start(seed_value: int, locale: String = "river_valley", house_count: int = 3) -> void:
	# Parent initialization creates the eight public starting assets and stocks.
	super.start(seed_value,locale,house_count)
	state.schema_version = 4
	state.experiment = rules.experiment
	state.access_metrics = {"building_uses":0,"reserved_units_used":0,"influence_transferred":0,"cap_overflow":0,"chapel_activations":0,"idle_pass_rewards":0,"working_passes":0,"stockpile_takes":0,"paid_free_actions":0,"hut_fallbacks":0,"rural_fallbacks":0,"rural_free_activations":0}
	for h in state.houses:
		h.stockpile = {}
		for r in rules.goods:
			h.stockpile[r] = 0
		h.did_something = false
	# The extra built chapel occupies the final initially free urban plot.
	_build_on("chapel","urban")
	state.deck = state.deck + state.discard + state.revealed
	state.discard = []
	state.revealed = []
	_shuffle(state.deck)
	_draw_hand()

func _new_round() -> void:
	# Called during the parent's start before commons-only metrics exist.
	state.round += 1
	state.used = []
	state.passed = []
	state.actions_taken = {}
	for h in state.houses:
		state.actions_taken[h.id] = 0
		h.did_something = false
	_draw_hand()
	state.actor = (int(state.round) - 1) % state.houses.size()

func _draw_hand() -> void:
	state.revealed = []
	var count = mini(int(rules.reveal_count), state.deck.size() + state.discard.size())
	for i in range(count):
		if state.deck.is_empty():
			state.deck = state.discard.duplicate()
			state.discard.clear()
			_shuffle(state.deck)
		state.revealed.append(state.deck.pop_back())

func _close_round() -> void:
	# Every physical token persists, including unused pops.
	state.round_events = []
	state.discard.append_array(state.revealed)
	_new_round()

func pile_size(house_id: String) -> int:
	var total = 0
	for amount in house(house_id).stockpile.values():
		total += int(amount)
	return total

func available(house_id: String) -> Dictionary:
	var result = super.available(house_id)
	if house(house_id).has("stockpile"):
		for r in rules.goods:
			result[r] += house(house_id).stockpile[r]
	return result

func modes(id: String) -> Array:
	var d = definition(id)
	var level = int(state.buildings[id].level)
	var result: Array = [{"name":"basic","inputs":d.inputs,"outputs":d.outputs}]
	if level == 2:
		if d.has("upgraded_inputs"):
			result.append({"name":"enhanced","inputs":d.upgraded_inputs,"outputs":d.upgraded_outputs})
		else:
			var enhanced: Dictionary = d.outputs.duplicate(true)
			for r in enhanced:
				enhanced[r] *= 2
			result.append({"name":"enhanced","inputs":d.inputs,"outputs":enhanced})
	return result

func recipe(action: Dictionary) -> Dictionary:
	for mode in modes(action.building):
		if mode.name == action.mode:
			return mode
	return {}

func payment_plan(house_id: String, cost: Dictionary, building_id: String = "") -> Dictionary:
	var h = house(house_id)
	var plan = {"ok":true,"allocations":[],"payments":{},"building_fee":0,"reserved_units":0}
	if building_id != "":
		var owner = str(state.buildings[building_id].owner)
		if owner != "" and owner != house_id:
			plan.payments[owner] = int(rules.access_fee)
			plan.building_fee = int(rules.access_fee)
	for r in INPUT_ORDER:
		if not cost.has(r): continue
		var needed = int(cost[r])
		for category in ["own_reserved","public","stockpile","rival_reserved"]:
			if category == "stockpile":
				var amount = mini(needed,int(h.stockpile[r]))
				if amount > 0:
					plan.allocations.append({"source":"stockpile","resource":r,"amount":amount,"owner":house_id})
					needed -= amount
				continue
			for lot in state.lots:
				if lot.resource != r or needed == 0: continue
				var reserve = str(lot.reserved_for)
				if category == "own_reserved" and reserve != house_id: continue
				if category == "public" and reserve != "": continue
				if category == "rival_reserved" and reserve in ["",house_id]: continue
				var amount = mini(needed,int(lot.amount))
				plan.allocations.append({"source":"lot","lot":lot.id,"resource":r,"amount":amount,"owner":reserve})
				needed -= amount
				if category == "rival_reserved":
					plan.payments[reserve] = plan.payments.get(reserve,0) + amount * int(rules.access_fee)
					plan.reserved_units += amount
		if needed > 0:
			plan.ok = false
	var total = 0
	for amount in plan.payments.values(): total += int(amount)
	plan.total_influence = total
	if h.inventory.influence < total:
		plan.ok = false
	return plan

func _consume_plan(house_id: String, plan: Dictionary, events: Array) -> void:
	for allocation in plan.allocations:
		var r: String = allocation.resource
		var amount = int(allocation.amount)
		if allocation.source == "stockpile":
			house(house_id).stockpile[r] -= amount
		else:
			for lot in state.lots:
				if lot.id == allocation.lot:
					lot.amount -= amount
					state.market[r] -= amount
					if lot.reserved_for == house_id:
						state.reservation_metrics.producer_consumed += amount
					elif lot.released:
						state.reservation_metrics.later_public_consumed += amount
					break
		state.ledger[r].consumed += amount
		if r == "pop": state.pop_worked += amount
		events.append({"type":"consume","resource":r,"amount":amount,"source":allocation.duplicate(true)})
	state.lots = state.lots.filter(func(lot): return lot.amount > 0)

func _gain_influence(house_id: String, amount: int, source: String, events: Array) -> void:
	var h = house(house_id)
	var credited = mini(amount,int(rules.influence_cap) - int(h.inventory.influence))
	h.inventory.influence += credited
	state.ledger.influence.created += amount
	state.ledger.influence.consumed += amount - credited
	state.access_metrics.cap_overflow += amount - credited
	events.append({"type":"influence_gain","house":house_id,"source":source,"amount":credited,"cap_overflow":amount-credited})

func _pay(house_id: String, plan: Dictionary, events: Array) -> void:
	var h = house(house_id)
	for owner in _sorted_keys(plan.payments):
		var amount = int(plan.payments[owner])
		h.inventory.influence -= amount
		var credited = mini(amount,int(rules.influence_cap)-int(house(owner).inventory.influence))
		house(owner).inventory.influence += credited
		var overflow = amount - credited
		state.ledger.influence.consumed += overflow
		state.access_metrics.cap_overflow += overflow
		state.access_metrics.influence_transferred += amount
		events.append({"type":"direct_use_payment","from":house_id,"to":owner,"amount":amount,"credited":credited,"cap_overflow":overflow})
	state.access_metrics.reserved_units_used += plan.reserved_units
	if plan.building_fee > 0: state.access_metrics.building_uses += 1

func legal_actions() -> Array:
	var h = current_house()
	var result: Array = [{"type":"pass"}]
	for id in state.revealed:
		var b: Dictionary = state.buildings[id]
		if id not in state.used:
			for mode in modes(id):
				var plan = payment_plan(h.id,mode.inputs,id)
				if plan.ok:
					result.append({"type":"activate","building":id,"mode":mode.name})
		if b.owner == "" and _owns(h.id) < rules.ownership_slots and h.inventory.influence >= rules.claim_cost:
			result.append({"type":"claim","building":id})
		if b.owner == h.id and b.level == 1 and id != "chapel" and payment_plan(h.id,rules.housing_upgrade_cost).ok:
			result.append({"type":"upgrade","building":id})
	if payment_plan(h.id,rules.construct_cost).ok:
		if state.terrain_free.urban > 0: result.append({"type":"construct_hut"})
		for id in _sorted_keys(state.buildings):
			if not state.buildings[id].built and state.terrain_free[definition(id).terrain] > 0:
				result.append({"type":"construct","building":id})
	if pile_size(h.id) < rules.stockpile_capacity:
		for r in rules.goods:
			var loose = 0
			for lot in state.lots:
				if lot.resource == r and lot.reserved_for in ["",h.id]: loose += int(lot.amount)
			if loose > 0: result.append({"type":"take","resource":r})
	for r in rules.goods:
		if h.stockpile[r] > 0: result.append({"type":"return","resource":r})
	return result

func apply(action: Dictionary) -> Dictionary:
	if action not in legal_actions(): return {"ok":false,"error":"illegal_action","action":action.duplicate(true)}
	var h = current_house()
	var before_round = int(state.round)
	var events: Array = []
	var free = false
	var turn_no = int(h.turns_taken) + 1
	match action.type:
		"pass":
			if not h.did_something:
				_gain_influence(h.id,1,"idle_pass",events)
				state.access_metrics.idle_pass_rewards += 1
			else: state.access_metrics.working_passes += 1
			state.passed.append(h.id)
		"activate":
			var mode = recipe(action)
			var plan = payment_plan(h.id,mode.inputs,action.building)
			free = plan.building_fee > 0
			if free:
				turn_no = int(h.turns_taken)
				state.access_metrics.paid_free_actions += 1
			_pay(h.id,plan,events)
			_consume_plan(h.id,plan,events)
			for r in _sorted_keys(mode.outputs):
				var amount = int(mode.outputs[r])
				if r == "influence": _gain_influence(h.id,amount,"chapel",events)
				else:
					_add_lot(r,amount,h.id,action.building,turn_no)
					events.append({"type":"reserved_production","resource":r,"amount":amount,"free_action":free})
			state.used.append(action.building)
			if action.building == "chapel": state.access_metrics.chapel_activations += 1
			if is_housing(action.building) and state.buildings[action.building].level == 2 and action.mode == "basic": state.access_metrics.hut_fallbacks += 1
			if definition(action.building).kind == "rural":
				if action.mode == "basic": state.access_metrics.rural_free_activations += 1
				if state.buildings[action.building].level == 2 and action.mode == "basic": state.access_metrics.rural_fallbacks += 1
		"claim":
			h.inventory.influence -= rules.claim_cost
			state.ledger.influence.consumed += rules.claim_cost
			state.buildings[action.building].owner = h.id
			if is_housing(action.building) and h.first_claim_round == 0: h.first_claim_round = state.round
		"upgrade":
			var plan = payment_plan(h.id,rules.housing_upgrade_cost)
			_pay(h.id,plan,events)
			_consume_plan(h.id,plan,events)
			state.buildings[action.building].level = 2
			if is_housing(action.building) and h.first_upgrade_round == 0: h.first_upgrade_round = state.round
		"construct_hut":
			var plan = payment_plan(h.id,rules.construct_cost)
			_pay(h.id,plan,events)
			_consume_plan(h.id,plan,events)
			var id = "hut_%d" % int(state.next_hut)
			state.next_hut += 1
			state.buildings[id] = {"definition":"hut","built":false,"owner":"","level":1,"plot":""}
			_build_on(id,"urban")
		"construct":
			var plan = payment_plan(h.id,rules.construct_cost)
			_pay(h.id,plan,events)
			_consume_plan(h.id,plan,events)
			_build_on(action.building,str(definition(action.building).terrain))
		"take":
			# Protect one unreserved/own-reserved token; never buy a rival reservation to hoard it.
			var selected: Dictionary = {}
			for own in [true,false]:
				for lot in state.lots:
					if lot.resource == action.resource and ((own and lot.reserved_for == h.id) or (not own and lot.reserved_for == "")):
						selected = lot
						break
				if not selected.is_empty(): break
			selected.amount -= 1
			state.market[action.resource] -= 1
			h.stockpile[action.resource] += 1
			state.lots = state.lots.filter(func(lot): return lot.amount > 0)
			state.access_metrics.stockpile_takes += 1
			events.append({"type":"safekeeping","resource":action.resource,"amount":1})
		"return":
			h.stockpile[action.resource] -= 1
			# Move, rather than create, this token back into a public lot.
			_add_lot(action.resource,1,"","returned",0)
			state.ledger[action.resource].created -= 1
			if action.resource == "pop": state.pop_granted -= 1
	if action.type != "pass": h.did_something = true
	if not free:
		h.turns_taken = turn_no
		state.actions_taken[h.id] += 1
		_release(h.id,turn_no,events)
	state.sequence += 1
	var event = {"sequence":state.sequence,"round":before_round,"house":h.id,"action":action.duplicate(true),"free_action":free,"consequences":events}
	state.history.append(event)
	if state.history.size() > 64: state.history.pop_front()
	var round_done = state.passed.size() == state.houses.size()
	if round_done: _close_round()
	elif not free:
		for i in range(state.houses.size()):
			state.actor = (int(state.actor)+1) % state.houses.size()
			if current_house().id not in state.passed: break
	return {"ok":true,"event":event,"round_closed":round_done,"free_action":free}

func restore(saved: Dictionary) -> void:
	assert(int(saved.state.schema_version) == 4,"Unsupported commons save schema")
	rules = saved.rules.duplicate(true)
	definitions.clear()
	for d in rules.buildings: definitions[d.id] = d
	state = saved.state.duplicate(true)
	rng.seed = int(state.seed)
	rng.state = int(saved.rng_state)

func violations() -> Array:
	var errors: Array = []
	var totals: Dictionary = {}
	for r in rules.resources: totals[r] = 0
	for h in state.houses:
		if h.inventory.influence < 0 or h.inventory.influence > rules.influence_cap or _owns(h.id) > rules.ownership_slots or pile_size(h.id) > rules.stockpile_capacity:
			errors.append("house cap/ownership violation: " + h.id)
		totals.influence += h.inventory.influence
		for r in rules.goods:
			if h.stockpile[r] < 0: errors.append("negative protected stock")
			totals[r] += h.stockpile[r]
	var lot_ids: Array = []
	var loose: Dictionary = {}
	for r in rules.goods: loose[r] = 0
	for lot in state.lots:
		if lot.amount <= 0 or lot.id in lot_ids: errors.append("invalid lot")
		lot_ids.append(lot.id)
		if lot.reserved_for != "" and (house(lot.reserved_for).is_empty() or lot.expires_after_action <= house(lot.reserved_for).turns_taken): errors.append("stale reservation")
		loose[lot.resource] += lot.amount
		totals[lot.resource] += lot.amount
	for r in rules.goods:
		if loose[r] != state.market[r]: errors.append("general pile accounting: " + r)
	for r in rules.resources:
		if totals[r] != state.ledger[r].created-state.ledger[r].consumed: errors.append("source/sink accounting: " + r)
	if state.pop_granted != state.pop_worked + totals.pop: errors.append("persistent pop accounting")
	var cards: Array = state.deck + state.discard + state.revealed
	for id in state.buildings:
		var b: Dictionary = state.buildings[id]
		if cards.count(id) != (1 if b.built else 0): errors.append("card identity: " + id)
		if b.built and b.plot != definition(id).terrain: errors.append("urban/rural plot placement")
	for terrain in state.terrain_free:
		var occupied = 0
		for b in state.buildings.values():
			if b.built and b.plot == terrain: occupied += 1
		if state.terrain_free[terrain] < 0 or occupied+state.terrain_free[terrain] != rules.locales[state.locale].terrain[terrain]: errors.append("plot accounting: " + terrain)
	return errors

class_name MarketplaceSimulation
extends CommonsSimulation
## Latest core plus a finite scenario: market -> import link -> decent brick house.
var scenario_lumber_link = false
func _init() -> void:
	rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/marketplace_rules.json"))
	definitions.clear()
	for d in rules.buildings: definitions[d.id] = d

func start(seed_value: int, locale: String = "clayless_valley", house_count: int = 3) -> void:
	var lumber_link = scenario_lumber_link
	rng.seed = seed_value
	state = {"schema_version":5,"experiment":rules.experiment,"seed":seed_value,"locale":locale,"round":0,"actor":0,"sequence":0,
		"houses":[],"buildings":{},"deck":[],"discard":[],"revealed":[],"used":[],"passed":[],"actions_taken":{},
		"market":{},"terrain_free":rules.locales[locale].terrain.duplicate(true),"lots":[],"next_lot":1,"next_hut":4,
		"contracts":[],"ledger":{},"history":[],"round_events":[],"consecutive_passes":0,"linked_assets":[],"passive_assets":[],
		"pop_granted":0,"pop_worked":0,"pop_limit":int(rules.pop_limit),"committed_pops":1 if lumber_link else 0,
		"lumber_link":lumber_link,"clay_contract":{},"ended":false,"end_reason":"","milestones":[],"rewards":{},
		"caravan":{"present":false,"visits":0,"first_round":0,"bricks_left":0},"market_round":0,"clay_deliveries":0,
		"reservation_metrics":{"produced_units":0,"producer_consumed":0,"released_units":0,"later_public_consumed":0,"expired_pops":0},
		"access_metrics":{"building_uses":0,"reserved_units_used":0,"influence_transferred":0,"cap_overflow":0,"chapel_activations":0,"idle_pass_rewards":0,"working_passes":0,"stockpile_takes":0,"paid_free_actions":0,"hut_fallbacks":0,"rural_fallbacks":0,"rural_free_activations":0,"emergency_units":0,"reentries":0,"lumber_delivered":0,"furniture_exported":0,"bricks_bartered":0,"missed_clay_shipments":0,"prestige_conversions":0}}
	for r in rules.resources:
		state.ledger[r] = {"created":0,"consumed":0}
		if r in rules.goods: state.market[r] = 0
	for i in range(house_count):
		var h: Dictionary = rules.houses[i].duplicate(true)
		h.inventory = {"influence":0,"prestige":0}
		h.stockpile = {}
		for r in rules.goods: h.stockpile[r] = 0
		h.turns_taken = 0
		h.first_claim_round = 0
		h.first_upgrade_round = 0
		h.did_something = false
		h.idle_rewarded = false
		h.passed_last = false
		state.houses.append(h)
	for r in rules.locales[locale].stock:
		_add_lot(r,int(rules.locales[locale].stock[r]),"","initial",0)
	for id in ["lumber_camp","grain_farm","carpenter","marketplace","chapel"]:
		state.buildings[id] = {"definition":id,"built":false,"owner":"","level":1,"plot":""}
	for id in ["lumber_camp","grain_farm","carpenter"]:
		_build_on(id,str(definition(id).terrain))
	for i in range(3):
		var id = "hut_%d" % (i+1)
		state.buildings[id] = {"definition":"hut","built":false,"owner":"","level":1,"plot":""}
		_build_on(id,"urban")
	state.buildings.chapel.built = true
	state.buildings.chapel.plot = "special"
	state.deck.append("chapel")
	if lumber_link:
		state.deck.erase("lumber_camp")
		state.linked_assets.append("lumber_camp")
		state.contracts.append({"id":"preset_lumber","committed_pop":1,"output":{"wood":1},"cadence":"hand_refresh"})
	_shuffle(state.deck)
	_new_round()

func total_physical(resource: String) -> int:
	var total = int(state.market[resource])
	for h in state.houses: total += int(h.stockpile[resource])
	return total

func free_pop_tokens() -> int:
	return int(state.pop_limit) - int(state.committed_pops) - total_physical("pop")

func _add_lot(resource: String, amount: int, producer: String, source: String, turn_no: int) -> void:
	if resource == "pop": amount = mini(amount,free_pop_tokens())
	if amount > 0: super._add_lot(resource,amount,producer,source,turn_no)

func _new_round() -> void:
	state.round += 1
	state.used = []
	state.passed = []
	state.consecutive_passes = 0
	state.actions_taken = {}
	for h in state.houses:
		state.actions_taken[h.id] = 0
		h.did_something = false
		h.idle_rewarded = false
		h.passed_last = false
	state.round_events = []
	if state.lumber_link:
		_add_lot("wood",1,"","lumber_link",0)
		state.access_metrics.lumber_delivered += 1
		state.round_events.append({"type":"automatic_lumber","amount":1})
	state.caravan.present = false
	state.caravan.bricks_left = 0
	if state.market_round > 0 and state.round >= state.caravan.first_round and (int(state.round)-int(state.caravan.first_round)) % int(rules.caravan_interval) == 0:
		state.caravan.present = true
		state.caravan.visits += 1
		state.caravan.bricks_left = 2
		state.round_events.append({"type":"caravan_arrival","visit":state.caravan.visits})
		if not state.clay_contract.is_empty():
			var plan = public_plan({"wood":1})
			if plan.ok:
				_consume_plan(state.clay_contract.sponsor,plan,state.round_events)
				_add_lot("clay",1,"","clay_import",0)
				state.clay_deliveries += 1
				state.round_events.append({"type":"automatic_clay_import","wood_exported":1,"clay":1})
			else: state.access_metrics.missed_clay_shipments += 1
	_draw_hand()
	state.actor = (int(state.round)-1) % state.houses.size()
	_check_end()

func _close_round() -> void:
	state.discard.append_array(state.revealed)
	_new_round()

func public_plan(cost: Dictionary) -> Dictionary:
	var plan = {"ok":true,"allocations":[],"payments":{},"building_fee":0,"reserved_units":0,"emergency_units":0,"total_influence":0}
	for r in _sorted_keys(cost):
		var remaining = int(cost[r])
		for lot in state.lots:
			if lot.resource == r and lot.reserved_for == "" and remaining > 0:
				var amount = mini(remaining,int(lot.amount))
				plan.allocations.append({"source":"lot","lot":lot.id,"resource":r,"amount":amount,"owner":""})
				remaining -= amount
		if remaining > 0: plan.ok = false
	return plan

func payment_plan(house_id: String,cost: Dictionary,building_id: String = "") -> Dictionary:
	var h = house(house_id)
	var plan = {"ok":true,"allocations":[],"payments":{},"building_fee":0,"reserved_units":0,"emergency_units":0}
	if building_id != "":
		var owner = str(state.buildings[building_id].owner)
		if owner != "" and owner != house_id:
			plan.payments[owner] = 1
			plan.building_fee = 1
	for r in _sorted_keys(cost):
		var remaining = int(cost[r])
		for category in ["own_reserved","public","own_stockpile","rival_reserved","rival_stockpile"]:
			if category in ["own_stockpile","rival_stockpile"]:
				for owner in state.houses:
					if (category == "own_stockpile" and owner.id != house_id) or (category == "rival_stockpile" and owner.id == house_id): continue
					var amount = mini(remaining,int(owner.stockpile[r]))
					if amount > 0:
						plan.allocations.append({"source":"stockpile","resource":r,"amount":amount,"owner":owner.id})
						remaining -= amount
						if category == "rival_stockpile":
							plan.payments[owner.id] = plan.payments.get(owner.id,0)+2*amount
							plan.emergency_units += amount
				continue
			for lot in state.lots:
				if lot.resource != r or remaining == 0: continue
				var reserved = str(lot.reserved_for)
				if category == "own_reserved" and reserved != house_id: continue
				if category == "public" and reserved != "": continue
				if category == "rival_reserved" and reserved in ["",house_id]: continue
				var amount = mini(remaining,int(lot.amount))
				plan.allocations.append({"source":"lot","lot":lot.id,"resource":r,"amount":amount,"owner":reserved})
				remaining -= amount
				if category == "rival_reserved":
					plan.payments[reserved] = plan.payments.get(reserved,0)+amount
					plan.reserved_units += amount
		if remaining > 0: plan.ok = false
	var total = 0
	for amount in plan.payments.values(): total += int(amount)
	plan.total_influence = total
	if h.inventory.influence < total: plan.ok = false
	return plan

func _consume_plan(_house_id: String,plan: Dictionary,events: Array) -> void:
	for allocation in plan.allocations:
		var r: String = allocation.resource
		var amount = int(allocation.amount)
		if allocation.source == "stockpile": house(allocation.owner).stockpile[r] -= amount
		else:
			for lot in state.lots:
				if lot.id == allocation.lot:
					lot.amount -= amount
					state.market[r] -= amount
					if lot.reserved_for == _house_id: state.reservation_metrics.producer_consumed += amount
					elif lot.released: state.reservation_metrics.later_public_consumed += amount
					break
		state.ledger[r].consumed += amount
		if r == "pop": state.pop_worked += amount
		events.append({"type":"consume","resource":r,"amount":amount,"source":allocation.duplicate(true)})
	state.lots = state.lots.filter(func(lot): return lot.amount > 0)

func _pay(house_id: String,plan: Dictionary,events: Array) -> void:
	super._pay(house_id,plan,events)
	state.access_metrics.emergency_units += plan.get("emergency_units",0)

func chapel_eligible(house_id: String) -> bool:
	var least = 999
	for h in state.houses: least = mini(least,owned_huts(h.id,true).size())
	return owned_huts(house_id,true).size() == least

func legal_actions() -> Array:
	if state.ended: return []
	var h = current_house()
	var result: Array = [{"type":"pass"}]
	for id in state.revealed:
		var b: Dictionary = state.buildings[id]
		if id not in state.used:
			for mode in modes(id):
				if id == "chapel" and not chapel_eligible(h.id): continue
				if mode.outputs.has("pop") and free_pop_tokens() < int(mode.outputs.pop): continue
				if payment_plan(h.id,mode.inputs,id).ok: result.append({"type":"activate","building":id,"mode":mode.name})
		if id != "chapel" and b.owner == "" and _owns(h.id) < rules.ownership_slots and h.inventory.influence >= rules.claim_cost:
			result.append({"type":"claim","building":id})
		if is_housing(id) and b.owner == h.id and b.level == 1 and payment_plan(h.id,rules.housing_upgrade_cost).ok:
			result.append({"type":"upgrade","building":id})
	if not state.buildings.marketplace.built and state.terrain_free.urban > 0 and payment_plan(h.id,rules.market_cost).ok: result.append({"type":"build_market"})
	if state.caravan.present:
		if state.clay_contract.is_empty() and payment_plan(h.id,rules.clay_setup_cost).ok: result.append({"type":"secure_clay_contract"})
		if state.caravan.bricks_left > 0 and payment_plan(h.id,rules.brick_price).ok: result.append({"type":"buy_brick"})
	if h.inventory.influence >= rules.prestige_conversion_cost: result.append({"type":"convert_prestige"})
	if pile_size(h.id) < rules.stockpile_capacity:
		for r in rules.goods:
			var loose = 0
			for lot in state.lots:
				if lot.resource == r and lot.reserved_for in ["",h.id]: loose += int(lot.amount)
			if loose > 0: result.append({"type":"take","resource":r})
	for r in rules.goods:
		if h.stockpile[r] > 0: result.append({"type":"return","resource":r})
	return result

func _prestige(house_id: String,amount: int,source: String,events: Array) -> void:
	house(house_id).inventory.prestige += amount
	state.ledger.prestige.created += amount
	events.append({"type":"prestige_award","house":house_id,"amount":amount,"source":source})

func _milestone(key: String,house_id: String,events: Array) -> void:
	var amount = int(rules.milestone_rewards[key])
	_prestige(house_id,amount,key,events)
	state.milestones.append({"kind":key,"house":house_id,"round":state.round,"sequence":int(state.sequence)+1,"prestige":amount})

func apply(action: Dictionary) -> Dictionary:
	if action not in legal_actions(): return {"ok":false,"error":"illegal_action","action":action.duplicate(true)}
	var h = current_house()
	var events: Array = []
	var before_round = int(state.round)
	var free = false
	var turn_no = int(h.turns_taken)+1
	if action.type != "pass":
		if h.passed_last: state.access_metrics.reentries += 1
		h.passed_last = false
		state.consecutive_passes = 0
		state.passed = []
	match action.type:
		"pass":
			if not h.did_something and not h.idle_rewarded:
				_gain_influence(h.id,1,"idle_pass",events)
				h.idle_rewarded = true
				state.access_metrics.idle_pass_rewards += 1
			elif h.did_something: state.access_metrics.working_passes += 1
			h.passed_last = true
			state.consecutive_passes += 1
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
				if r == "influence": _gain_influence(h.id,int(mode.outputs[r]),"chapel",events)
				else: _add_lot(r,int(mode.outputs[r]),h.id,action.building,turn_no)
			state.used.append(action.building)
			state.revealed.erase(action.building)
			state.discard.append(action.building)
			if action.building == "chapel": state.access_metrics.chapel_activations += 1
			if is_housing(action.building) and state.buildings[action.building].level == 2 and action.mode == "basic": state.access_metrics.hut_fallbacks += 1
			if definition(action.building).kind == "rural" and action.mode == "basic": state.access_metrics.rural_free_activations += 1
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
			if h.first_upgrade_round == 0: h.first_upgrade_round = state.round
			_milestone("brick_house",h.id,events)
		"build_market":
			var plan = payment_plan(h.id,rules.market_cost)
			_pay(h.id,plan,events)
			_consume_plan(h.id,plan,events)
			state.buildings.marketplace.built = true
			state.buildings.marketplace.plot = "urban"
			state.terrain_free.urban -= 1
			state.passive_assets.append("marketplace")
			state.market_round = state.round
			state.caravan.first_round = int(state.round)+1
			_milestone("market",h.id,events)
		"secure_clay_contract":
			var plan = payment_plan(h.id,rules.clay_setup_cost)
			_pay(h.id,plan,events)
			_consume_plan(h.id,plan,events)
			state.committed_pops += 1
			state.clay_contract = {"sponsor":h.id,"committed_pop":1,"export":"wooden_chest_supply","last_visit":state.caravan.visits}
			state.contracts.append({"id":"clay_import","sponsor":h.id,"committed_pop":1,"cadence":"caravan_visit"})
			_add_lot("clay",1,"","clay_import",0)
			state.clay_deliveries += 1
			state.access_metrics.furniture_exported += 1
			_milestone("clay_contract",h.id,events)
		"buy_brick":
			var plan = payment_plan(h.id,rules.brick_price)
			_pay(h.id,plan,events)
			_consume_plan(h.id,plan,events)
			_add_lot("brick",1,h.id,"caravan_brick",turn_no)
			state.caravan.bricks_left -= 1
			state.access_metrics.furniture_exported += 1
			state.access_metrics.bricks_bartered += 1
		"convert_prestige":
			h.inventory.influence -= rules.prestige_conversion_cost
			state.ledger.influence.consumed += rules.prestige_conversion_cost
			_prestige(h.id,1,"influence_conversion",events)
			state.access_metrics.prestige_conversions += 1
		"take":
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
		"return":
			h.stockpile[action.resource] -= 1
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
	_check_end()
	var round_done = false
	if not state.ended and state.consecutive_passes == state.houses.size():
		_close_round()
		round_done = true
	elif not state.ended and not free: state.actor = (int(state.actor)+1) % state.houses.size()
	return {"ok":true,"event":event,"round_closed":round_done,"free_action":free,"scenario_ended":state.ended}

func _check_end() -> void:
	if not state.clay_contract.is_empty() and state.clay_deliveries > 0:
		for h in state.houses:
			if not owned_huts(h.id,true).is_empty():
				state.ended = true
				state.end_reason = "clay_import_and_brick_house"
				return

func restore(saved: Dictionary) -> void:
	assert(int(saved.state.schema_version) == 5,"Unsupported marketplace save schema")
	rules = saved.rules.duplicate(true)
	definitions.clear()
	for d in rules.buildings: definitions[d.id] = d
	state = saved.state.duplicate(true)
	rng.seed = int(state.seed)
	rng.state = int(saved.rng_state)

func violations() -> Array:
	# Core accounts for physical goods, prestige is an additional house-held resource.
	var original: Array = rules.resources
	rules.resources = original.filter(func(r): return r != "prestige")
	var errors = super.violations()
	rules.resources = original
	var prestige = 0
	for h in state.houses:
		prestige += int(h.inventory.prestige)
		if h.inventory.prestige < 0: errors.append("negative prestige")
	if prestige != state.ledger.prestige.created-state.ledger.prestige.consumed: errors.append("prestige accounting")
	var expected_commitment = (1 if state.lumber_link else 0)+(1 if not state.clay_contract.is_empty() else 0)
	if state.committed_pops != expected_commitment: errors.append("contract commitment identity")
	var reserve = free_pop_tokens()
	if reserve < 0 or reserve+total_physical("pop")+state.committed_pops != state.pop_limit: errors.append("finite pop pool / commitment accounting")
	# Parent card/plot checks differ for special and automated/passive assets.
	errors = errors.filter(func(e): return e not in ["urban/rural plot placement","plot accounting: special"] and not e.begins_with("card identity:"))
	var cards: Array = state.deck+state.discard+state.revealed
	for id in state.buildings:
		var b: Dictionary = state.buildings[id]
		var linked = id in state.linked_assets or id in state.passive_assets
		if cards.count(id) != (1 if b.built and not linked else 0): errors.append("scenario card identity: "+id)
		if b.built and b.plot != definition(id).terrain: errors.append("scenario plot placement: "+id)
	if state.buildings.chapel.owner != "" or state.buildings.chapel.plot != "special": errors.append("chapel must be unownable and off-budget")
	if state.ledger.clay.created != state.clay_deliveries: errors.append("clay must originate exclusively from imports")
	if state.ledger.brick.created != state.access_metrics.bricks_bartered: errors.append("bricks must originate exclusively from caravan barter")
	if state.consecutive_passes != state.passed.size(): errors.append("consecutive pass chain accounting")
	var has_good_house = false
	for h in state.houses:
		if not owned_huts(h.id,true).is_empty(): has_good_house = true
	if state.ended and (state.clay_contract.is_empty() or state.clay_deliveries == 0 or not has_good_house): errors.append("premature scenario success")
	return errors

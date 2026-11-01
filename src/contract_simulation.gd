class_name ContractSimulation
extends MarketplaceSimulation
## Experimental contract economy. All goods enter public supply; no instant output on setup.
var batch = 1
func _init() -> void:
	super._init()
	rules.schema_version = 6
	rules.experiment = "contract_economy"
	rules.contract_batch = 1
	rules.contract_specs = {
		"wood":{"setup":{"wood":1,"pop":1},"upkeep":{},"source":"lumber_camp","commit":1,"cadence":"round","cancel":1},
		"grain":{"setup":{"wood":1,"pop":1},"upkeep":{},"source":"grain_farm","commit":1,"cadence":"round","cancel":1},
		"furniture":{"setup":{"wood":2,"pop":1},"upkeep":{"wood":2},"source":"carpenter","commit":1,"cadence":"round","cancel":3},
		"pop":{"setup":{"grain":1,"wood":1},"upkeep":{"grain":1},"source":"owned_hut","commit":0,"cadence":"round","cancel":3},
		"brick":{"setup":{"furniture":1,"pop":1},"upkeep":{"furniture":1},"source":"marketplace","commit":1,"cadence":"caravan","cancel":2},
		"luxury":{"setup":{"wood":2,"pop":1},"upkeep":{"wood":2},"source":"marketplace","commit":1,"cadence":"caravan","cancel":2}}
func start(seed_value: int, locale: String = "clayless_valley", house_count: int = 3) -> void:
	rules.contract_batch = batch
	if batch >= 3: rules.contract_specs.furniture.upkeep = {"wood":1}
	super.start(seed_value,locale,house_count)
func _process_links() -> void:
	state.schema_version = 6
	if not state.has("economy"):
		state.economy = {"deliveries":{},"misses":{},"setups":{},"cancellations":0,"demolitions":0,"exchanges":0,"exchanged":{},"goal_round":0,"goals":[],"cumulative_consumed_inputs":{}}
	for c in state.contracts:
		if not c.has("resource"): continue
		var spec: Dictionary = rules.contract_specs[c.resource]
		if spec.cadence == "caravan" and not state.caravan.present: continue
		var plan = public_plan(spec.upkeep)
		if not plan.ok or (c.resource == "pop" and free_pop_tokens() < 1) or (c.resource == "brick" and state.caravan.bricks_left < 1):
			state.economy.misses[c.resource] = state.economy.misses.get(c.resource,0)+1
			c.streak += 1
			continue
		_consume_plan(c.sponsor,plan,state.round_events)
		for r in spec.upkeep: state.economy.cumulative_consumed_inputs[r] = state.economy.cumulative_consumed_inputs.get(r,0)+spec.upkeep[r]
		_add_lot(c.resource,1,"","contract_"+c.resource,0)
		if c.resource == "brick":
			state.caravan.bricks_left -= 1
			state.access_metrics.bricks_bartered += 1
			state.access_metrics.furniture_exported += 1
		state.economy.deliveries[c.resource] = state.economy.deliveries.get(c.resource,0)+1
		c.delivered += 1
		c.streak = 0
		state.round_events.append({"type":"contract_delivery","resource":c.resource,"input":spec.upkeep})
func contract_for(resource: String) -> Dictionary:
	if resource == "wood" and state.lumber_link: return {"id":"preset_lumber","resource":"wood","source":"lumber_camp","streak":0,"delivered":state.access_metrics.lumber_delivered}
	if resource == "clay" and not state.clay_contract.is_empty(): return {"id":"clay_import","resource":"clay","source":"marketplace","streak":0,"delivered":state.clay_deliveries}
	for c in state.contracts:
		if c.get("resource","") == resource: return c
	return {}
func source_for(resource: String, house_id: String) -> String:
	var source = str(rules.contract_specs[resource].source)
	if source == "owned_hut":
		for id in owned_huts(house_id):
			if id not in state.linked_assets: return id
		return ""
	return source
func cancel_price(resource: String) -> int:
	if resource == "wood" and state.lumber_link: return 1
	if resource == "clay": return 2
	return int(rules.contract_specs[resource].cancel)
func legal_actions() -> Array:
	var actions = super.legal_actions()
	if state.ended: return actions
	var h = current_house()
	for resource in rules.contract_specs:
		var spec: Dictionary = rules.contract_specs[resource]
		var source = source_for(resource,h.id)
		if not contract_for(resource).is_empty() or source == "" or not state.buildings[source].built: continue
		if spec.cadence == "caravan" and not state.caravan.present: continue
		if source in state.used or (source in state.linked_assets and source != "marketplace"): continue
		var owner = str(state.buildings[source].owner)
		if owner != "" and owner != h.id: continue
		if payment_plan(h.id,spec.setup).ok: actions.append({"type":"secure_contract","resource":resource,"source":source})
	for resource in rules.goods:
		if not contract_for(resource).is_empty() and h.inventory.prestige >= cancel_price(resource): actions.append({"type":"cancel_contract","resource":resource})
	for id in state.buildings:
		var b: Dictionary = state.buildings[id]
		if not b.built or b.owner != "" or b.plot == "special" or id in state.linked_assets: continue
		var dependent = false
		for c in state.contracts:
			if c.get("source","") == id or (id == "marketplace" and c.id == "clay_import"): dependent = true
		if dependent: continue
		var price = 1 if b.plot in ["field","forest"] else 3
		if h.inventory.prestige >= price: actions.append({"type":"demolish","building":id})
	if pile_size(h.id) >= 3: actions.append({"type":"bulk_exchange"})
	return actions
func _experimental_action(action: Dictionary,h: Dictionary,events: Array) -> void:
	match action.type:
		"secure_contract":
			var spec: Dictionary = rules.contract_specs[action.resource]
			var plan = payment_plan(h.id,spec.setup)
			_pay(h.id,plan,events)
			_consume_plan(h.id,plan,events)
			state.committed_pops += spec.commit
			var c = {"id":"auto_"+action.resource,"resource":action.resource,"sponsor":h.id,"source":action.source,"committed_pop":spec.commit,"delivered":0,"streak":0,"cadence":spec.cadence}
			state.contracts.append(c)
			if spec.cadence == "round":
				state.linked_assets.append(action.source)
				for pile in [state.deck,state.discard,state.revealed]: pile.erase(action.source)
			state.economy.setups[action.resource] = state.economy.setups.get(action.resource,0)+1
			events.append({"type":"contract_secured","contract":c.duplicate(true)})
		"cancel_contract":
			var resource = str(action.resource)
			var c = contract_for(resource).duplicate(true)
			var price = cancel_price(resource)
			h.inventory.prestige -= price
			state.ledger.prestige.consumed += price
			var commitment = 1 if resource == "clay" or c.id == "preset_lumber" else int(c.committed_pop)
			state.committed_pops -= commitment
			state.contracts = state.contracts.filter(func(x): return x.id != c.id)
			if c.id == "preset_lumber": state.lumber_link = false
			if resource == "clay": state.clay_contract = {}
			if str(c.source) in state.linked_assets:
				state.linked_assets.erase(c.source)
				state.discard.append(c.source)
			state.economy.cancellations += 1
			events.append({"type":"contract_cancelled","resource":resource,"prestige":price,"released_pop":commitment})
		"demolish":
			var b: Dictionary = state.buildings[action.building]
			var price = 1 if b.plot in ["field","forest"] else 3
			h.inventory.prestige -= price
			state.ledger.prestige.consumed += price
			state.terrain_free[b.plot] += 1
			b.built = false
			b.plot = ""
			for pile in [state.deck,state.discard,state.revealed,state.passive_assets,state.used]: pile.erase(action.building)
			if action.building == "marketplace":
				state.market_round = 0
				state.caravan.present = false
			state.economy.demolitions += 1
			events.append({"type":"demolished","building":action.building,"prestige":price})
		"bulk_exchange":
			var count = 3
			for r in rules.goods:
				var amount = mini(count,int(h.stockpile[r]))
				h.stockpile[r] -= amount
				state.ledger[r].consumed += amount
				if r == "pop": state.pop_worked += amount
				state.economy.exchanged[r] = state.economy.exchanged.get(r,0)+amount
				count -= amount
			_gain_influence(h.id,3,"bulk_exchange",events)
			state.economy.exchanges += 1
			events.append({"type":"bulk_exchange","influence":3})
func _check_end() -> void:
	if not state.has("economy"): return
	var fulfilled = not state.clay_contract.is_empty() and state.clay_deliveries > 0
	for h in state.houses:
		if owned_huts(h.id,true).is_empty(): fulfilled = false
	if fulfilled and state.economy.goal_round == 0:
		state.economy.goal_round = state.round
		state.economy.goals.append({"round":state.round,"sequence":state.sequence})
	# Keep observing the economy through round 40, including after housing success.
	state.ended = false
func violations() -> Array:
	var errors = super.violations().filter(func(e): return e != "contract commitment identity")
	var expected = (1 if state.lumber_link else 0)+(1 if not state.clay_contract.is_empty() else 0)
	var resources: Array = []
	for c in state.contracts:
		if not c.has("resource"): continue
		expected += int(c.committed_pop)
		if c.resource in resources: errors.append("duplicate automatic resource contract")
		resources.append(c.resource)
		if not state.buildings[c.source].built: errors.append("contract source removed")
		if c.cadence == "round" and c.source not in state.linked_assets: errors.append("local contract card still rotates")
	if expected != state.committed_pops: errors.append("generic contract commitment identity")
	return errors

class_name TradeSimulation
extends CapacitySimulation
func _init() -> void:
	super._init()
	rules.schema_version = 10
	rules.experiment = "town_brick_demand_and_gold_trade"
	rules.trade_policy_version = 2
	rules.town_brick_influence = 2
	rules.prestige_gold_price = 2
func ensure_trade() -> void:
	if not state.has("trade"):
		state.trade = {"town_bricks":0,"exported_bricks":0,"gold_minted":0,"gold_spent":0,"prestige_bought":0,"orders":{},"industry_rounds":{},"all_goals_round":0}
		for h in state.houses:
			h.inventory.gold = 0
			state.trade.industry_rounds[h.id] = 0
func _new_round() -> void:
	ensure_trade()
	super._new_round()
	state.schema_version = 10
	state.caravan.brick_order_open = state.caravan.present
func industries(house_id: String) -> Array:
	var result: Array = []
	for id in state.buildings:
		var b: Dictionary = state.buildings[id]
		if b.built and b.owner == house_id and definition(id).kind in ["rural","workshop"]: result.append(id)
	return result
func legal_actions() -> Array:
	var actions = super.legal_actions().filter(func(a): return a.type != "buy_brick" and not (a.type == "secure_contract" and a.resource == "brick"))
	var h = current_house()
	if payment_plan(h.id,{"brick":1}).ok:
		actions.append({"type":"supply_town"})
		if state.caravan.present and state.caravan.get("brick_order_open",false): actions.append({"type":"export_brick"})
	if state.caravan.present and h.inventory.gold >= rules.prestige_gold_price: actions.append({"type":"buy_prestige"})
	# Automation removes work cards, not the existence or purchasability of public property.
	if h.inventory.influence >= rules.claim_cost and _owns(h.id) < rules.ownership_slots:
		for id in state.linked_assets:
			if state.buildings[id].owner == "" and definition(id).kind in ["rural","workshop"]:
				var a = {"type":"claim","building":id}
				if a not in actions: actions.append(a)
	return actions
func _experimental_action(action: Dictionary,h: Dictionary,events: Array) -> void:
	match action.type:
		"supply_town", "export_brick":
			var plan = payment_plan(h.id,{"brick":1})
			_pay(h.id,plan,events)
			_consume_plan(h.id,plan,events)
			if action.type == "supply_town":
				_gain_influence(h.id,int(rules.town_brick_influence),"town_brick_order",events)
				state.trade.town_bricks += 1
				events.append({"type":"town_order_delivery","house":h.id,"brick":1,"influence":rules.town_brick_influence})
			else:
				h.inventory.gold += 1
				state.trade.gold_minted += 1
				state.trade.exported_bricks += 1
				state.caravan.brick_order_open = false
				var key = str(int(state.caravan.visits))
				state.trade.orders[key] = state.trade.orders.get(key,0)+1
				events.append({"type":"caravan_brick_export","house":h.id,"brick":1,"gold":1,"visit":state.caravan.visits})
		"buy_prestige":
			h.inventory.gold -= int(rules.prestige_gold_price)
			state.trade.gold_spent += int(rules.prestige_gold_price)
			_prestige(h.id,1,"caravan_prestige_purchase",events)
			state.trade.prestige_bought += 1
			events.append({"type":"caravan_prestige_purchase","house":h.id,"gold":rules.prestige_gold_price,"prestige":1})
		_: super._experimental_action(action,h,events)
func _check_end() -> void:
	super._check_end()
	if not state.has("trade"): return
	var goals_met = not state.clay_contract.is_empty() and state.clay_deliveries > 0
	for h in state.houses:
		if not industries(h.id).is_empty() and state.trade.industry_rounds[h.id] == 0: state.trade.industry_rounds[h.id] = state.round
		if owned_huts(h.id,true).is_empty() or industries(h.id).is_empty(): goals_met = false
	if goals_met and state.trade.all_goals_round == 0: state.trade.all_goals_round = state.round
func violations() -> Array:
	var errors = super.violations()
	var gold = 0
	for h in state.houses:
		gold += int(h.inventory.gold)
		if h.inventory.gold < 0: errors.append("negative gold")
	if gold != state.trade.gold_minted-state.trade.gold_spent: errors.append("gold conservation")
	if state.trade.gold_spent != state.trade.prestige_bought*int(rules.prestige_gold_price): errors.append("prestige gold price accounting")
	for count in state.trade.orders.values():
		if count > 1: errors.append("more than one shared brick order per caravan visit")
	return errors

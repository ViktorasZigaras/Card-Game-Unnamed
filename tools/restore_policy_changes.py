from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=root/'src/planner_ai.gd';t=p.read_text()
t=t.replace('func assess_offer(sim: ExpeditionSimulation,offer: Dictionary) -> Dictionary:', 'func assess_offer(sim: ExpeditionSimulation,offer: Dictionary,access: String = "priority") -> Dictionary:')
t=t.replace('var social = int(sim.rules.expedition_contract_prestige)\n\tvar exit_price = social+2+3','''var flexible = sim is FlexibleContractSimulation
	var social = int(sim.rules.public_route_prestige) if flexible else int(sim.rules.expedition_contract_prestige)
	var exit_price = (int(sim.rules.public_route_cancel) if access == "public" else int(sim.rules.own_route_cancel)) if flexible else social+2+3
	var influence = int(sim.rules.route_priority_influence) if flexible and access == "priority" else 0''')
t=t.replace('\tvar opportunities = caravan_opportunities(sim,horizon)','\tvar guaranteed_reward = 0 if flexible else reward\n\tvar opportunities = caravan_opportunities(sim,horizon)').replace('social+exit_price-reward','social+exit_price-guaranteed_reward')
t=t.replace('var bridge = need >= MIN_BRIDGE_UNITS','var bridge = h.inventory.influence >= influence and need >= MIN_BRIDGE_UNITS')
t=t.replace('return {"resource":offer.resource,"needed_units":need,','return {"resource":offer.resource,"access":access,"priority_influence":influence,"needed_units":need,')
t=t.replace('var exit_price = int(route.price)+3','var exit_price = sim.route_cancel_price(route,h.id) if sim is FlexibleContractSimulation else int(route.price)+3')
t=t.replace('var remaining = maxi(0,target-supplied)','var remaining = maxi(0,target-supplied)\n\tif sim is FlexibleContractSimulation: remaining = mini(remaining,needed_units(sim,route.resource))')
t=t.replace('var f: Dictionary = assessments[str(int(a.offer))]','var f: Dictionary = assess_offer(sim,trip.buy[int(a.offer)],a.get("access","priority")) if sim is FlexibleContractSimulation else assessments[str(int(a.offer))]')
t=t.replace('c.score = 260 if f.prefunded_bridge else -1','c.score = 260 if f.prefunded_bridge else -1\n\t\t\tif sim is FlexibleContractSimulation and a.get("access","") == "priority": c.score = 265 if f.prefunded_bridge and priority_value(sim,f.resource).justified else -1')
t=t.replace('c.financing = f\n','c.financing = f\n\t\t\tc.priority_value = priority_value(sim,f.resource)\n')
t=t.replace('c.reasons = [f.reason,"Import flow is not accepted as an indefinitely affordable entitlement"]','c.reasons = [f.reason,"Public supply keeps shared access; sponsor still funds transport and deliveries" if a.get("access","") == "public" else priority_value(sim,f.resource).reason]')
t=t.replace('if a.type == "cancel_route":\n\t\t\tvar route = sim.route_by_id(int(a.route))\n\t\t\tc.score = -1','''if a.type == "own_route":
			var route = sim.route_by_id(int(a.route))
			c.priority_value = priority_value(sim,route.resource)
			c.score = 215 if c.priority_value.justified and needed_units(sim,route.resource) > 0 and h.inventory.prestige >= int(sim.rules.own_route_cancel) else -1
			c.reasons = [c.priority_value.reason]
		if a.type == "cancel_route":
			var route = sim.route_by_id(int(a.route))
			c.score = -1''')
helper='''func priority_value(sim: ExpeditionSimulation,resource: String) -> Dictionary:
	var h = sim.current_house()
	var units = 0
	var goal = "no bounded private milestone need"
	if sim.owned_huts(h.id,true).is_empty():
		var brick_need = 1
		var wood_need = 2
		for id in sim.owned_huts(h.id):
			brick_need = int(sim.remaining(id).get("brick",0))
			wood_need = int(sim.remaining(id).get("wood",0))
		if resource in ["clay","brick"]: units = maxi(0,brick_need-sim.total_physical("brick"))
		if resource == "wood": units = wood_need
		goal = "finish own home"
	elif not sim.state.buildings[sim.hall_id(h.id)].built:
		units = int(sim.site_remaining(sim.hall_id(h.id)).get(resource,0))
		goal = "finish own Hall"
	var own_units = int(h.stockpile.get(resource,0))
	for lot in sim.state.lots:
		if lot.resource == resource and lot.reserved_for in ["",h.id]: own_units += int(lot.amount)
	for trip in sim.state.exploration.trips:
		if trip.owner != h.id: continue
		own_units += int(trip.cargo.get(resource,0))
		if resource == "clay": own_units += int(trip.cargo.get("brick",0))
	units = maxi(0,units-own_units)
	var access_upper = units*2
	var ownership = int(sim.rules.get("route_priority_influence",2))
	var exit_prestige = int(sim.rules.get("own_route_cancel",1))
	var exit_weight = int(sim.rules.prestige_conversion_cost)*exit_prestige
	var cost = ownership+exit_weight
	var liquidity = units > 1 and h.inventory.influence >= ownership and h.inventory.influence < access_upper
	var better = units > 0 and (access_upper > cost or liquidity) and h.inventory.prestige >= exit_prestige
	return {"goal":goal,"private_units":units,"access_cost_upper_influence":access_upper,"ownership_influence":ownership,"exit_prestige":exit_prestige,"exit_comparison_weight":exit_weight,"ownership_comparison_cost":cost,"delay_benefit_assumed":0,"access_liquidity_risk":liquidity,"justified":better,"reason":"Repeated private inputs exceed available access budget" if better and liquidity else "Bounded access costs exceed ownership and exit comparison" if better else "Paying legal access is no worse for this short private goal; priority has no proven timing benefit"}
'''
t=t.replace('func decide(simulation: TownSimulation)',helper+'\nfunc decide(simulation: TownSimulation)');p.write_text(t)
p=root/'src/marketplace_simulation.gd';t=p.read_text().replace('14,15,16]','14,15,16,17,18]').replace('"buy_route", "cancel_route":','"buy_route", "cancel_route", "own_route":');p.write_text(t)
p=root/'src/game_probe.gd';t=p.read_text().replace('16: replay = FinancingSimulation.new()','16: replay = FinancingSimulation.new()\n\t\t17: replay = FlexibleContractSimulation.new()');p.write_text(t)

class_name HouseAI
extends RefCounted
## Stateless policy: its only memory is the public action history in the save.
func decide(sim: TownSimulation) -> Dictionary:
	var h = sim.current_house()
	var candidates: Array = []
	for action in sim.legal_actions():
		var score = 0.0
		var reasons: Array = []
		match action.type:
			"pass":
				score = -1.0
				reasons.append("End participation this round")
			"work":
				score = 0.4 if h.inventory.coin >= 8 else 2.0
				reasons.append("Earn one coin from town bank")
			"activate":
				var d: Dictionary = sim.definitions[action.building]
				var b: Dictionary = sim.state.buildings[action.building]
				var value = 0.0
				for r in d.outputs:
					var marginal = 1.0 if r == "coin" else (1.8 if h.inventory[r] < 4 else 0.3)
					value += float(d.outputs[r]) * float(b.level) * marginal
				for r in d.inputs:
					value -= float(d.inputs[r]) * 0.8
				if b.owner != "" and b.owner != h.id:
					value -= 1.0
				score = value * float(h.bias.production)
				reasons.append("Marginal production value after inputs and owner fee")
			"buy_building":
				score = (2.2 if h.inventory.coin >= 8 else 0.1) * float(h.bias.ownership)
				reasons.append("Acquire persistent income and activation privilege")
			"sell_building":
				score = -0.5 if h.inventory.coin > 2 else 1.5
				reasons.append("Divest for liquidity; retain assets when solvent")
			"upgrade":
				score = 3.5 * float(h.bias.production)
				reasons.append("Increase output without taking another ownership slot")
			"construct":
				score = 3.0 * float(h.bias.ownership)
				reasons.append("Expand shared deck and own new asset")
			"market_sell":
				var stock = int(h.inventory[action.resource])
				score = (2.8 if stock > 3 else 0.1) * float(h.bias.trade)
				if sim._goods(h.inventory) >= int(sim.rules.inventory_capacity) - 2:
					score += 3.0
				reasons.append("Sell surplus or free storage")
			"market_buy":
				score = -0.2
				# Only buy toward a currently revealed recipe or a concrete upgrade.
				for id in sim.state.revealed:
					if id in sim.state.used:
						continue
					var inputs: Dictionary = sim.definitions[id].inputs
					if inputs.get(action.resource, 0) > h.inventory[action.resource]:
						score = maxf(score, 1.2 * float(h.bias.production))
				if action.resource == "brick" and h.inventory.brick == 0 and sim._owns(h.id) > 0 and h.inventory.coin >= 7:
					score = maxf(score, 1.8)
				reasons.append("Buy only toward visible processing or upgrade needs")
			"contract":
				score = 2.5 * float(h.bias.trade)
				reasons.append("Reserve grain for three possible export deliveries")
		# Avoid immediate buy/sell reversal, with deterministic tie breaking.
		for i in range(sim.state.history.size() - 1, maxi(-1, sim.state.history.size() - 13), -1):
			var previous: Dictionary = sim.state.history[i]
			if previous.house == h.id and previous.round == sim.state.round:
				var old: Dictionary = previous.action
				if action.get("resource", "") != "" and old.get("resource", "") == action.get("resource", "") and old.type != action.type:
					score -= 4.0
					reasons.append("Discourage reversing own trade this round")
				if old.get("building", "") == action.get("building", "") and action.type == "sell_building" and old.type == "buy_building":
					score -= 4.0
		candidates.append({"action":action.duplicate(true),"score":snappedf(score, 0.001),"reasons":reasons})
	var best: Dictionary = candidates[0]
	for candidate in candidates:
		if candidate.score > best.score:
			best = candidate
	return {"house":h.id,"round":sim.state.round,"policy_version":1,"candidates":candidates,"chosen":best.action.duplicate(true),"score":best.score}

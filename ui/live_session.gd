extends RefCounted
## Presentation adapter. Commands and previews use the existing authoritative simulation.
var sim: MarketplaceSimulation
var probe: GameProbe
var frames: Array = []
var run_path := ""

func start(seed_value: int = 7, linked: bool = false) -> void:
	sim = MarketplaceSimulation.new()
	sim.scenario_lumber_link = linked
	sim.start(seed_value)
	_attach("new")

func _attach(reason: String) -> void:
	probe = GameProbe.new()
	probe.policy = MarketplaceAI.new()
	run_path = "user://runs/ui_%s_%s_%d" % [reason,Time.get_datetime_string_from_system().replace(":","-"),Time.get_ticks_usec()]
	probe.attach(sim,run_path+"/decisions.jsonl")
	frames = [project()]

func step(action: Dictionary = {}) -> Dictionary:
	if sim.state.ended: return {"ok":false,"error":"Scenario complete"}
	if not action.is_empty() and action not in sim.legal_actions(): return {"ok":false,"error":"Action is no longer legal"}
	var result := probe.step(action)
	if result.ok: frames.append(project())
	return result

func save_game() -> Error:
	DirAccess.make_dir_recursive_absolute("user://saves")
	return probe.save_game("user://saves/manual.json")

func load_game() -> Error:
	var error := probe.load_game("user://saves/manual.json")
	if error == OK: _attach("loaded")
	return error

func preview(action: Dictionary) -> Dictionary:
	var p := {"action":action.duplicate(true),"inputs":{},"outputs":{},"free":false,"plan":{},"prestige":0}
	match action.type:
		"activate":
			var recipe = sim.recipe(action)
			p.inputs = recipe.inputs
			p.outputs = recipe.outputs
			p.plan = sim.payment_plan(sim.current_house().id,p.inputs,action.building)
			p.free = p.plan.building_fee > 0
		"upgrade", "build_market", "secure_clay_contract", "buy_brick":
			var costs := {"upgrade":"housing_upgrade_cost","build_market":"market_cost","secure_clay_contract":"clay_setup_cost","buy_brick":"brick_price"}
			p.inputs = sim.rules[costs[action.type]]
			p.plan = sim.payment_plan(sim.current_house().id,p.inputs)
			if action.type == "buy_brick": p.outputs = {"brick":1}
			else:
				var milestone := {"upgrade":"brick_house","build_market":"market","secure_clay_contract":"clay_contract"}
				p.prestige = sim.rules.milestone_rewards[milestone[action.type]]
		"claim": p.inputs = {"influence":sim.rules.claim_cost}
		"convert_prestige":
			p.inputs = {"influence":5}
			p.outputs = {"prestige":1}
		"take": p.outputs = {action.resource:1}
		"return": p.inputs = {action.resource:1}
		"pass":
			var h = sim.current_house()
			if not h.did_something and not h.idle_rewarded: p.outputs = {"influence":1}
	return p

func project() -> Dictionary:
	var legal: Array = []
	for action in sim.legal_actions(): legal.append(preview(action))
	var modes: Dictionary = {}
	for id in sim.state.buildings:
		if sim.state.buildings[id].built: modes[id] = sim.modes(id)
	return {"state":sim.state.duplicate(true),"modes":modes,"legal":legal,"decision":probe.last_decision.duplicate(true),"event":probe.last_result.get("event",{}).duplicate(true)}

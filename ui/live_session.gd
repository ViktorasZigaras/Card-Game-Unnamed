extends RefCounted
## Presentation adapter. Commands and previews use the existing authoritative simulation.
var sim: ProjectSimulation
var probe: GameProbe
var frames: Array = []
var run_path := ""

func start(seed_value: int = 7, linked: bool = false) -> void:
	sim = ProjectSimulation.new()
	sim.batch = 3
	sim.scenario_lumber_link = linked
	sim.start(seed_value)
	_attach("new")

func _attach(reason: String) -> void:
	probe = GameProbe.new()
	probe.policy = ProjectAI.new()
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
			p.inputs = sim.remaining(action.building) if action.type == "upgrade" and (action.building == "chapel" or sim.is_housing(action.building)) else sim.rules[costs[action.type]]
			p.plan = sim.payment_plan(sim.current_house().id,p.inputs)
			if action.type == "buy_brick": p.outputs = {"brick":1}
			else:
				var milestone := {"upgrade":"brick_house","build_market":"market","secure_clay_contract":"clay_contract"}
				p.prestige = sim.rules.milestone_rewards[milestone[action.type]]
				if action.type == "upgrade" and not sim.is_housing(action.building): p.prestige = 0
		"contribute_upgrade":
			p.inputs = action.bundle.duplicate(true)
			p.plan = sim.payment_plan(sim.current_house().id,p.inputs)
		"buy_stone":
			p.inputs = {"gold":sim.rules.stone_gold_price}
			p.outputs = {"stone":1}
		"supply_town", "export_brick":
			p.inputs = {"brick":1}
			p.plan = sim.payment_plan(sim.current_house().id,p.inputs)
			p.outputs = {"influence":sim.rules.town_brick_influence} if action.type == "supply_town" else {"gold":1}
		"buy_prestige":
			p.inputs = {"gold":sim.rules.prestige_gold_price}
			p.outputs = {"prestige":1}
		"build_kiln":
			p.inputs = sim.rules.kiln_cost
			p.plan = sim.payment_plan(sim.current_house().id,p.inputs)
		"secure_contract":
			var spec: Dictionary = sim.rules.contract_specs[action.resource]
			p.inputs = spec.setup
			p.plan = sim.payment_plan(sim.current_house().id,p.inputs)
			p.recurring = spec.duplicate(true)
		"buy_contract": p.inputs = {"prestige":int(sim.title(action.resource).price)}
		"cancel_contract": p.inputs = {"prestige":sim.cancel_price(action.resource)}
		"demolish": p.inputs = {"prestige":1 if sim.state.buildings[action.building].plot in ["field","forest"] else 3}
		"bulk_exchange":
			p.inputs = sim.current_house().stockpile.duplicate(true)
			p.outputs = {"influence":3}
		"claim": p.inputs = {"influence":sim.rules.claim_cost}
		"convert_prestige":
			p.inputs = {"influence":5}
			p.outputs = {"prestige":1}
		"take": p.outputs = {action.resource:1}
		"return": p.inputs = {action.resource:1}
		"pass":
			var h = sim.current_house()
			if not h.did_something and not h.idle_rewarded: p.outputs = {"influence":1}
	if action.type == "secure_clay_contract": p.commitments = {"wood":1,"pop":1}
	return p

func project() -> Dictionary:
	var legal: Array = []
	for action in sim.legal_actions(): legal.append(preview(action))
	var modes: Dictionary = {}
	for id in sim.state.buildings:
		if sim.state.buildings[id].built: modes[id] = sim.modes(id)
	return {"state":sim.state.duplicate(true),"modes":modes,"legal":legal,"decision":probe.last_decision.duplicate(true),"event":probe.last_result.get("event",{}).duplicate(true)}

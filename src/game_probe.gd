class_name GameProbe
extends RefCounted
## The game's testing/logging tool; independent of visible presentation.
## Every JSONL line includes the full decision and post-action snapshot.
var sim: TownSimulation
var policy = HouseAI.new()
var journal: FileAccess
var failure: String = ""
var last_decision: Dictionary = {}
var last_result: Dictionary = {}
var metrics: Dictionary = {}

func attach(simulation: TownSimulation, path: String = "") -> void:
	sim = simulation
	metrics = {"actions":{},"decisions":0,"invariant_checks":0,"rounds_closed":0,"failures":[],"owner_fee_activations":0,"owner_recognition_activations":0,"max_built":0}
	if path != "":
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		journal = FileAccess.open(path, FileAccess.WRITE)
		if journal == null:
			failure = "Cannot open journal: " + path
		else:
			_write({"kind":"initial","snapshot":sim.snapshot()})

func _write(record: Dictionary) -> void:
	if journal != null:
		journal.store_line(JSON.stringify(record))
		journal.flush()

func step(override_action: Dictionary = {}) -> Dictionary:
	var before = sim.snapshot()
	var decision = policy.decide(sim) if override_action.is_empty() else {"house":sim.current_house().id,"round":sim.state.round,"chosen":override_action,"source":"test_or_manual"}
	last_decision = decision.duplicate(true)
	var action: Dictionary = decision.chosen
	if action.type == "activate":
		var owner = str(sim.state.buildings[action.building].owner)
		if owner != "" and owner != sim.current_house().id:
			if sim.state.get("schema_version", 1) == 2:
				metrics.owner_recognition_activations += 1
			elif sim.state.get("schema_version", 1) == 1:
				metrics.owner_fee_activations += 1
	var result = sim.apply(action)
	last_result = result.duplicate(true)
	var errors = sim.violations()
	metrics.invariant_checks += 1
	if not result.ok:
		errors.append("Action rejected: " + JSON.stringify(result))
	if not errors.is_empty():
		failure = JSON.stringify(errors)
		metrics.failures.append({"sequence":sim.state.sequence,"errors":errors})
		_write({"kind":"failure","before":before,"decision":decision,"result":result,"errors":errors,"after":sim.snapshot()})
		return {"ok":false,"errors":errors}
	metrics.decisions += 1
	metrics.actions[action.type] = metrics.actions.get(action.type, 0) + 1
	if result.round_closed:
		metrics.rounds_closed += 1
	var built = 0
	for b in sim.state.buildings.values():
		if b.built:
			built += 1
	metrics.max_built = maxi(metrics.max_built, built)
	_write({"kind":"decision","sequence":sim.state.sequence,"decision":decision,"event":result.event,"round_closed":result.round_closed,"snapshot":sim.snapshot(),"invariant_errors":errors})
	return result

func run_rounds(count: int) -> Dictionary:
	var target = int(sim.state.round) + count
	while sim.state.round < target and failure == "" and not sim.state.get("ended",false):
		step()
	return summary()

func summary() -> Dictionary:
	var result = {"seed":sim.state.seed,"locale":sim.state.locale,"round":sim.state.round,"sequence":sim.state.sequence,"metrics":metrics.duplicate(true),"failure":failure,"houses":sim.state.houses.duplicate(true),"buildings":sim.state.buildings.duplicate(true),"market":sim.state.market.duplicate(true)}
	if sim.state.has("bank"):
		result.bank = sim.state.bank
	return result

func save_game(path: String) -> Error:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(sim.snapshot(), "\t"))
	var error = file.get_error()
	file.close()
	return error

func load_game(path: String) -> Error:
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var saved = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not saved is Dictionary or not saved.has("state") or not saved.has("rules") or not saved.has("rng_state"):
		return ERR_PARSE_ERROR
	if int(saved.state.get("schema_version", -1)) != int(sim.rules.schema_version):
		return ERR_FILE_UNRECOGNIZED
	sim.restore(saved)
	return OK

static func replay_journal(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok":false,"error":"journal_missing"}
	var initial = JSON.parse_string(file.get_line())
	var replay: TownSimulation
	match int(initial.snapshot.state.schema_version):
		5: replay = MarketplaceSimulation.new()
		4: replay = CommonsSimulation.new()
		3: replay = ReservationSimulation.new()
		2: replay = HousingSimulation.new()
		_: replay = TownSimulation.new()
	replay.restore(initial.snapshot)
	var checked = 0
	while not file.eof_reached():
		var line = file.get_line()
		if line.is_empty():
			continue
		var record = JSON.parse_string(line)
		if record.kind != "decision":
			return {"ok":false,"error":"failure_record","checked":checked}
		var result = replay.apply(record.decision.chosen)
		# Compare canonical JSON after round-trip to normalize int/float parsing.
		if not result.ok or TownSimulation.canonical(replay.snapshot()) != TownSimulation.canonical(record.snapshot):
			return {"ok":false,"error":"replay_diverged","sequence":record.sequence}
		checked += 1
	return {"ok":true,"checked":checked}

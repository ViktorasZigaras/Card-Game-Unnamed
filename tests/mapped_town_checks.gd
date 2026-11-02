extends SceneTree
var fx = preload("res://tests/flexible_fixture.gd").new()
var failures: Array = []
var checks = 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func coords(s: MappedTownSimulation) -> Array:
	return s.state.town_map.cells.map(func(c): return [c.id,c.column,c.row])
func act(s: MappedTownSimulation,a: Dictionary) -> void:
	s.state.actor = 0
	check(s.apply(a).ok,"legal plot transition: "+str(a))
	check(s.violations().is_empty(),"mapped invariants: "+str(s.violations()))
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var s = MappedTownSimulation.new()
	s.batch = 3
	s.rules.town_wood_sweep = false
	s.start(7)
	DirAccess.make_dir_recursive_absolute("res://experiments/mapped_checks")
	FileAccess.open("res://experiments/mapped_checks/initial_state.json",FileAccess.WRITE).store_string(JSON.stringify(s.snapshot()))
	var positions = coords(s)
	check(positions.size() == 15,"ten economic plots, chapel and four outer plots")
	check(s.state.town_map.cells.filter(func(c): return not c.active).size() == 4,"initial wilderness count")
	check(s.violations().is_empty(),"initial map capacity")
	var hut_cell = s.cell_for("hut_1").id
	fx.home(s,0)
	check(s.cell_for("hut_1").id == hut_cell,"upgraded house stays in place")
	fx.build(s,"marketplace")
	var market_cell = s.cell_for("marketplace").id
	fx.wallet(s,10,30)
	fx.fund(s,"pop",8)
	fx.fund(s,"wood",8)
	fx.fund(s,"stone",4)
	for i in 6: act(s,{"type":"supply_wood"})
	var forest_cell = s.cell_for("lumber_camp").id
	act(s,{"type":"redevelop_occupied","building":"lumber_camp"})
	var converted: Dictionary = s.state.town_map.cells.filter(func(c): return c.id == forest_cell)[0]
	check(converted.terrain == "urban" and converted.building == "" and not converted.vegetation,"occupied rural conversion clears in place")
	act(s,{"type":"redevelop_rural","terrain":"field"})
	var wild = s.state.town_map.cells.filter(func(c): return not c.active)[0]
	var wild_id = str(wild.id)
	act(s,{"type":"claim_rural"})
	check(wild.id == wild_id and wild.active and not wild.vegetation,"claimed nature clears without moving neighbours")
	check(s.state.development.land_rolls[-1].terrain == wild.terrain,"visual terrain matches real biome roll")
	s._gain_influence("blue",3,"fixture",[])
	act(s,{"type":"claim_site","building":"hall_blue","replace":"marketplace"})
	check(s.cell_for("hall_blue").id == market_cell,"force replacement inherits address")
	check(not s.state.buildings.hall_blue.built,"site claim does not create functionality")
	fx.fund(s,"planks",3)
	fx.fund(s,"stone",1)
	fx.fund(s,"pop",1)
	fx.expose(s,"hall_blue")
	act(s,{"type":"supply_site","building":"hall_blue","bundle":{"planks":1}})
	check(s.cell_for("hall_blue").id == market_cell and not s.state.buildings.hall_blue.built,"partial build holds its address")
	fx.expose(s,"hall_blue")
	act(s,{"type":"supply_site","building":"hall_blue","bundle":s.site_remaining("hall_blue")})
	check(s.cell_for("hall_blue").id == market_cell and s.state.buildings.hall_blue.built,"completion stays in place")
	check(coords(s) == positions,"all addresses and coordinates remain fixed")
	var clone = MappedTownSimulation.new()
	clone.restore(JSON.parse_string(JSON.stringify(s.snapshot())))
	check(TownSimulation.canonical(s.snapshot()) == TownSimulation.canonical(clone.snapshot()),"exact schema18 save restore")
	var view = load("res://ui/town_view.gd").new()
	root.add_child(view)
	view.size = Vector2(1000,650)
	view.set_state(s.state,"")
	var before = TownSimulation.canonical(s.snapshot())
	check(view.ambience.items.size() == s.state.buildings.values().filter(func(b): return b.built).size(),"exactly one effect per completed building")
	var unique = {}
	for item in view.ambience.items: unique[item.key] = true
	check(unique.size() == view.ambience.items.size(),"no duplicate ambient effect")
	view.ambience._process(30)
	view.motion(false)
	var clock = float(view.ambience.elapsed)
	view.ambience._process(30)
	check(view.ambience.elapsed == clock,"motion off stops visual clock")
	check(before == TownSimulation.canonical(s.snapshot()),"animation never changes state or RNG")
	var out = {"checks":checks,"failures":failures}
	FileAccess.open("res://experiments/mapped_checks/results.json",FileAccess.WRITE).store_string(JSON.stringify(out,"\t"))
	print(JSON.stringify(out))
	quit(0 if failures.is_empty() else 1)

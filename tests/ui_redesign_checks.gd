extends SceneTree
var checks := 0
var failures: Array = []
func check(value: bool,label: String) -> void:
	checks += 1
	if not value: failures.append(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1920,1080)
	var ui = load("res://ui/interface.tscn").instantiate();root.add_child(ui)
	await process_frame
	check(ui.hand.is_visible_in_tree() and ui.goods_view.is_visible_in_tree(),"hand and goods always visible")
	check(not ui.lab.visible and not ui.info_window.visible,"menus start closed")
	var before = TownSimulation.canonical(ui.session.sim.snapshot())
	for category in ["Build","Upgrade","Contracts","Trade"]:
		ui._category(category)
		await process_frame
		var minimum = ui.root_box.get_minimum_size()+Vector2(20,20)
		check(minimum.x <= 1920 and minimum.y <= 1080,"1080p layout "+category+": "+str(minimum))
	ui._show_deck();ui.deck_window.hide()
	var sum := 0
	for count in ui.deck_counts().values(): sum += int(count)
	check(sum == ui._s().deck.size(),"exact deck composition")
	sum = 0
	for count in ui.deck_counts(true).values(): sum += int(count)
	check(sum == ui._s().discard.size(),"exact discard composition")
	ui._show_houses();ui.info_window.hide()
	ui._select("building","hut_1");ui._select("resource","wood");ui._select("plot","stockade")
	check(before == TownSimulation.canonical(ui.session.sim.snapshot()),"all inspection leaves state and RNG unchanged")
	check(not ui.detail.text.contains("{"),"no raw JSON in normal inspector")
	ui.safe_actions = true
	var seq = ui.session.sim.state.sequence
	ui._review_type("pass")
	check(ui.confirm_dialog.visible and ui.session.sim.state.sequence == seq,"safe mode waits for confirmation")
	ui.confirm_dialog.canceled.emit();ui.confirm_dialog.hide()
	check(ui.confirmation_entry.is_empty() and ui.session.sim.state.sequence == seq,"cancel is free")
	ui._review_type("pass")
	ui.confirm_dialog.confirmed.emit();ui.confirm_dialog.hide()
	check(ui.session.sim.state.sequence == seq+1,"confirmation executes exactly once")
	ui.confirm_dialog.confirmed.emit()
	check(ui.session.sim.state.sequence == seq+1,"duplicate confirmation does not execute")
	ui.safe_actions = false;ui._review_type("pass")
	check(ui.session.sim.state.sequence == seq+2,"skip immediately executes once with safety off")
	# Actor gold has obtained idle influence; Blue obtains influence after first pass too.
	ui._review_type("pass")
	ui._category("Build");ui.catalogue_building = "marketplace";ui._draw_detail()
	var entries = ui._m().legal.filter(func(e): return e.action.type == "claim_site" and e.action.building == "marketplace" and e.action.replace == "")
	check(not entries.is_empty(),"market site is legally available after idle influence")
	if not entries.is_empty():
		var e = entries[0]
		var valid: Array = ui.session.sim.placement_cells(e.action)
		check(valid.size() == 2,"two vacant urban choices")
		before = TownSimulation.canonical(ui.session.sim.snapshot())
		ui._choose(e)
		check(before == TownSimulation.canonical(ui.session.sim.snapshot()),"starting site choice does not spend")
		ui._map_choice("plot","N1")
		check(before == TownSimulation.canonical(ui.session.sim.snapshot()),"ineligible site rejected without spending")
		var bad = e.action.duplicate(true);bad.plot = "N1"
		check(not ui.session.sim.apply(bad).ok,"authoritative placement validates eligibility")
		check(before == TownSimulation.canonical(ui.session.sim.snapshot()),"invalid authoritative placement pure")
		var chosen: String = valid[-1].id
		seq = ui.session.sim.state.sequence
		ui._map_choice("plot",chosen)
		check(ui.session.sim.state.sequence == seq+1,"chosen site claim executes one action")
		check(ui.session.sim.cell_for("marketplace").id == chosen,"chosen site persists rather than automatic first plot")
		check(not ui._s().buildings.marketplace.built and ui._s().houseworks.sites.marketplace.paid.is_empty(),"claim does not build or spend materials")
		check(ui.session.sim.violations().is_empty(),"placement preserves all invariants")
		check(ui.session.save_game() == OK,"save game")
		var saved = TownSimulation.canonical(ui.session.sim.snapshot())
		ui._ai_step();check(ui.session.load_game() == OK,"reload game")
		check(saved == TownSimulation.canonical(ui.session.sim.snapshot()),"exact save/reload includes chosen plot")
		ui.cursor = ui.session.frames.size()-1;ui._draw()
		# Journal replay uses chosen action including optional plot; no change to AI legal-action set.
		var sim = MappedTownSimulation.new();sim.start(7)
		for i in 3: sim.apply({"type":"pass"})
		var action = e.action.duplicate(true);action.plot = chosen
		check(sim.apply(action).ok and sim.cell_for("marketplace").id == chosen,"manual placement action replays")
	var represented := 0
	for group in preload("res://ui/goods_view.gd").groups(ui._s()): represented += int(group.count)
	check(represented == ui.goods_view.represented_units,"goods exact unit totals")
	before = TownSimulation.canonical(ui.session.sim.snapshot())
	ui.town_view.motion(false);ui.town_view.motion(true)
	ui.town_view.size = Vector2(1000,650);ui.town_view.redraw()
	await process_frame
	check(before == TownSimulation.canonical(ui.session.sim.snapshot()),"motion and resize preserve state/RNG")
	ui.safe_actions = true;ui._prefs()
	var pref = ConfigFile.new();pref.load("user://presentation.cfg")
	check(pref.get_value("ui","safe_actions",false),"safe action preference persists separately")
	ui.safe_actions = false;ui._prefs()
	var out = {"checks":checks,"failures":failures}
	DirAccess.make_dir_recursive_absolute("res://experiments/ui_0910")
	FileAccess.open("res://experiments/ui_0910/results.json",FileAccess.WRITE).store_string(JSON.stringify(out,"\t"))
	print(JSON.stringify(out));quit(0 if failures.is_empty() else 1)

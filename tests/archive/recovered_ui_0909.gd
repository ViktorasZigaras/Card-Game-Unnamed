extends SceneTree
const Goods = preload("res://ui/goods_view.gd")
var checks = 0
var failures: Array = []
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1920,1080)
	var ui = load("res://ui/interface.tscn").instantiate()
	root.add_child(ui)
	await process_frame
	check(ui.workspace_tabs.get_tab_count() == 3 and ui.side_tabs.get_tab_count() == 2,"central and sidebar workspaces restored")
	check(ui.workspace_tabs.current_tab == 0 and not ui.hand.is_visible_in_tree() and not ui.goods_view.is_visible_in_tree(),"quiet town default")
	var before = TownSimulation.canonical(ui.session.sim.snapshot())
	var largest = Vector2.ZERO
	for i in 3:
		ui.workspace_tabs.current_tab = i
		for j in 2:
			ui.side_tabs.current_tab = j
			await process_frame
			largest = largest.max(ui.root_box.get_minimum_size()+Vector2(32,32))
			check(largest.x <= 1920 and largest.y <= 1080,"workspace fits 1080p")
	check(before == TownSimulation.canonical(ui.session.sim.snapshot()),"tabs do not change state or RNG")
	ui.workspace_tabs.current_tab = 1
	ui._refresh_goods()
	var expected = 0
	for group in Goods.groups(ui._s()): expected += int(group.count)
	check(ui.goods_view.represented_units == expected,"physical quantities exactly represented")
	var clicks: Array = []
	ui.goods_view.resource_selected.connect(func(r): clicks.append(r))
	for row in ui.goods_view.get_children():
		if row is HBoxContainer and row.get_child_count() == 2:
			var tokens = row.get_child(1)
			if tokens.get_child_count() > 0 and tokens.get_child(0) is Button:
				tokens.get_child(0).pressed.emit()
				check(ui.selected_kind == "resource" and ui.selected == clicks[-1],"token opens matching inspector")
	check(before == TownSimulation.canonical(ui.session.sim.snapshot()),"token inspection does not move or spend goods")
	ui.archive = true
	for i in [0,9,40,82]:
		ui.cursor = i
		ui._draw()
		expected = 0
		for n in ui._s().market.values(): expected += int(n)
		for h in ui._s().houses:
			for n in h.stockpile.values(): expected += int(n)
		check(expected == ui.goods_view.represented_units,"historical tokens match piles and stores")
	var visual = ui._s().duplicate(true)
	visual.lots = [{"resource":"wood","amount":30,"reserved_for":""},{"resource":"wood","amount":2,"reserved_for":"blue"}]
	for h in visual.houses:
		for r in h.stockpile: h.stockpile[r] = 0
	visual.houses[0].stockpile.clay = 3
	ui.goods_view.set_state(visual)
	check(ui.goods_view.represented_units == 35 and ui.goods_view.displayed_units == 17,"explicit overflow preserves quantities with bounded icons")
	var groups = Goods.groups(visual)
	check(groups.size() == 3 and groups[0].scope == "Public supply","public reserved and private access remain distinct")
	ui.archive = false
	ui.cursor = ui.session.frames.size()-1
	ui.workspace_tabs.current_tab = 2
	ui._draw()
	await process_frame
	check(ui.hand.is_visible_in_tree(),"shared hand accessible in Cards")
	ui._select("building","carpenter")
	check(ui.tab == "Selected" and ui.workspace_tabs.current_tab == 2,"inspection preserves chosen workspace")
	ui._select("plot","N1")
	check(ui.detail.get_parsed_text().contains("Unclaimed wilderness"),"wild plot inspector")
	ui._select("plot","U5")
	check(ui.detail.get_parsed_text().contains("Vacant town land"),"vacant plot inspector")
	var map = ui.town_view
	for dims in [Vector2(700,400),Vector2(1000,650)]:
		map.size = dims
		map.redraw()
		var rects: Array = []
		var fits = true
		var overlaps = false
		for cell in map.layout.cells:
			var r = map.cell_rect(cell)
			fits = fits and Rect2(Vector2.ZERO,dims).encloses(r)
			for prior in rects: overlaps = overlaps or r.intersects(prior)
			rects.append(r)
		check(fits and not overlaps,"all plot footprints fit without overlapping at resized dimensions")
	check(map.layer.get_child_count() == 30,"fifteen click targets and labels")
	for i in 10: map.set_state(ui._s(),"")
	check(map.layer.get_child_count() == 30,"refresh does not accumulate nodes")
	map.motion(false)
	check(not map.ambience.visible,"reduced motion switch")
	map.motion(true)
	check(map.ambience.visible,"motion can be restored")
	check(before == TownSimulation.canonical(ui.session.sim.snapshot()),"map selection resize and motion do not change simulation")
	check(not ui.lab.visible,"technical logs hidden by default")
	var out = {"checks":checks,"failures":failures,"minimum":str(largest)}
	DirAccess.make_dir_recursive_absolute("res://experiments/recovered_ui")
	FileAccess.open("res://experiments/recovered_ui/results.json",FileAccess.WRITE).store_string(JSON.stringify(out,"\t"))
	print(JSON.stringify(out))
	quit(0 if failures.is_empty() else 1)

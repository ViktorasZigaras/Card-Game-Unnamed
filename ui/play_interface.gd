extends "res://ui/live_interface.gd"
## Human-facing workspaces; all commands retain authoritative previews.
var workspace_tabs: TabContainer
var goods_view: VBoxContainer
var side_tabs: TabContainer
func move_to(node: Node,parent: Node) -> void:
	node.get_parent().remove_child(node)
	parent.add_child(node)
func _build() -> void:
	super._build()
	var centre = goal.get_parent()
	var town = town_view.get_parent()
	var old_children = centre.get_children()
	workspace_tabs = TabContainer.new()
	workspace_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.add_child(workspace_tabs)
	var town_page = VBoxContainer.new()
	town_page.name = "Town"
	workspace_tabs.add_child(town_page)
	move_to(town,town_page)
	town.custom_minimum_size.y = 340
	town_view.plot_selected.connect(func(id): _select("plot",id))
	var motion_toggle = CheckButton.new()
	motion_toggle.text = "Gentle motion"
	motion_toggle.button_pressed = true
	motion_toggle.toggled.connect(func(value): town_view.motion(value))
	town_page.add_child(motion_toggle)
	var town_hint = Label.new()
	town_hint.text = "Select a building or plot to inspect it. Available work also follows the shared cards."
	town_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	town_page.add_child(town_hint)
	var goods_page = ScrollContainer.new()
	goods_page.name = "Goods"
	goods_page.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	workspace_tabs.add_child(goods_page)
	goods_view = load("res://ui/goods_view.gd").new()
	goods_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goods_view.add_theme_constant_override("separation",12)
	goods_page.add_child(goods_view)
	goods_view.resource_selected.connect(func(resource): _select("resource",resource))
	var cards_page = VBoxContainer.new()
	cards_page.name = "Cards"
	workspace_tabs.add_child(cards_page)
	var cards_hint = Label.new()
	cards_hint.text = "Shared cards · select one to inspect actions. Used cards return in later rounds."
	cards_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cards_page.add_child(cards_hint)
	move_to(hand,cards_page)
	move_to(pile,self)
	pile.hide()
	for node in old_children:
		if node == goal or node == town or node == hand or node == pile: continue
		centre.remove_child(node)
		node.queue_free()
	goal.custom_minimum_size.y = 54
	workspace_tabs.tab_changed.connect(func(_index): _refresh_goods())
	var side = houses.get_parent()
	var asset_scroll = assets.get_parent()
	var side_children = side.get_children()
	side_tabs = TabContainer.new()
	side_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(side_tabs)
	var houses_page = VBoxContainer.new()
	houses_page.name = "Houses"
	side_tabs.add_child(houses_page)
	move_to(houses,houses_page)
	var assets_page = VBoxContainer.new()
	assets_page.name = "Buildings"
	side_tabs.add_child(assets_page)
	move_to(asset_scroll,assets_page)
	for node in side_children:
		if node == houses or node == asset_scroll: continue
		side.remove_child(node)
		node.queue_free()
	var inspector_tabs = inspector.get_child(0)
	var labels = ["Inspect","Trade","Plans","Log"]
	for i in inspector_tabs.get_child_count(): inspector_tabs.get_child(i).text = labels[i]
	for button in action_footer.get_children():
		if button is Button and button.text not in ["Pass","Trade 3 goods","5 influence → prestige"]: move_to(button,seed_controls)
	var lab_parent = seed_controls.get_parent()
	var tools = HFlowContainer.new()
	lab_parent.add_child(tools)
	lab_parent.move_child(tools,1)
	for child in seed_controls.get_children():
		if child is Button and child != linked_box: move_to(child,tools)
func _refresh_goods() -> void:
	if workspace_tabs != null and workspace_tabs.current_tab == 1: goods_view.set_state(_s())
func _draw() -> void:
	super._draw()
	_refresh_goods()
	if workspace_tabs != null: workspace_tabs.set_tab_title(2,"Cards · %d" % _s().revealed.size())
func _draw_detail() -> void:
	super._draw_detail()
	if selected_kind != "plot": return
	var map: Dictionary = _s().town_map if _s().has("town_map") else TownLayout.legacy(_s())
	for cell in map.cells:
		if cell.id != selected: continue
		hero.hide()
		_clear(action_list)
		detail.text = "[b]Plot %s[/b]\n\n%s\n\n%s\n\nPositions stay fixed. Use Plans to claim or redevelop land. Paths are decorative." % [cell.id,cell.terrain.capitalize(),"Unclaimed wilderness; foreground growth clears when claimed." if not cell.active else "Vacant town land." if cell.building == "" else "Occupied by "+_name(cell.building)]

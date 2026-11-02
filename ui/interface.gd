extends Control
## Native Godot structural preview. Reads recorded authoritative state/action projections.
const NAMES = {"lumber_camp":"Lumber camp", "grain_farm":"Grain farm", "carpenter":"Carpenter", "chapel":"Chapel", "marketplace":"Marketplace", "hut_1":"Hut 1", "hut_2":"Hut 2", "hut_3":"Hut 3", "furniture":"Chests"}
var replay: Dictionary
var cursor := 9
var selected := "carpenter"
var selected_kind := "building"
var status: Label
var houses: VBoxContainer
var assets: VBoxContainer
var pile: HBoxContainer
var hand: HBoxContainer
var inspector: VBoxContainer
var action_list: VBoxContainer
var detail: RichTextLabel
var goal: Label
var land: Label
var recent: Label
var lab: Window
var history: RichTextLabel
var slider: HSlider
var root_box: VBoxContainer
var tab := "Selected"

func _ready() -> void:
	# Preserve the previous command-line simulation entry point.
	if not OS.get_cmdline_user_args().is_empty() and not "--ui-check" in OS.get_cmdline_user_args():
		add_child(load("res://src/laboratory.gd").new())
		return
	replay = JSON.parse_string(FileAccess.get_file_as_string("res://ui/recorded_preview.json"))
	get_window().min_size = Vector2i(1920,1080)
	_build()
	_draw()
	if "--ui-check" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		var largest := Vector2.ZERO
		for i in replay.states.size():
			cursor = i
			for view in ["Selected","Caravan","Links","Journal"]:
				tab = view
				_draw()
			for kind in ["building","resource","house"]:
				selected_kind = kind
				var keys: Array = _s().buildings.keys() if kind == "building" else (_s().market.keys() if kind == "resource" else ["blue","red","gold"])
				for key in keys:
					selected = key
					tab = "Selected"
					_draw_detail()
			for action in _m().legal:
				_preview(action)
			await get_tree().process_frame
			largest = largest.max(root_box.get_minimum_size())
		await get_tree().process_frame
		assert(largest.y + 32 <= 1080, "Layout exceeds 1080p")
		assert(largest.x + 32 <= 1920, "Layout exceeds 1920px")
		print("UI check passed: 83 states, selections, tabs, all action previews; largest minimum including margins ", largest + Vector2(32,32))
		get_tree().quit()

func _m() -> Dictionary: return replay.states[cursor]
func _s() -> Dictionary: return _m().state
func _name(id: String) -> String: return NAMES.get(id,id.replace("_"," ").capitalize())
func _bundle(d: Dictionary) -> String:
	var parts: Array[String] = []
	for key in d:
		if int(d[key]) > 0: parts.append("%d %s" % [int(d[key]), _name(key)])
	return " + ".join(parts) if not parts.is_empty() else "None"
func _label(parent: Node, text: String, font_size: int = 20) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size",font_size)
	parent.add_child(node)
	return node
func _button(parent: Node, text: String, callback: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.y = 42
	node.pressed.connect(callback)
	parent.add_child(node)
	return node
func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
func _select(kind: String, id: String) -> void:
	selected_kind = kind
	selected = id
	tab = "Selected"
	_draw_detail()
func _panel(parent: Node, width: int = 0) -> VBoxContainer:
	var frame := PanelContainer.new()
	frame.custom_minimum_size.x = width
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(frame)
	var margins := MarginContainer.new()
	for edge in ["left","right","top","bottom"]: margins.add_theme_constant_override("margin_"+edge,12)
	frame.add_child(margins)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",10)
	margins.add_child(box)
	return box
func _build() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font_size = 18
	theme = ui_theme
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,16)
	add_child(margin)
	root_box = VBoxContainer.new()
	root_box.add_theme_constant_override("separation",12)
	margin.add_child(root_box)
	var header := HBoxContainer.new()
	root_box.add_child(header)
	_label(header,"CARD GAME  ·  v0.55",24)
	status = _label(header,"")
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(header,"Laboratory / replay",func(): lab.popup_centered())
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation",16)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(columns)
	var left := _panel(columns,280)
	_label(left,"Houses",24)
	houses = VBoxContainer.new()
	houses.add_theme_constant_override("separation",14)
	left.add_child(houses)
	_label(left,"Town assets",22)
	assets = VBoxContainer.new()
	var asset_scroll := ScrollContainer.new()
	asset_scroll.custom_minimum_size.y = 140
	asset_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	asset_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(asset_scroll)
	assets.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	asset_scroll.add_child(assets)
	var centre := VBoxContainer.new()
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.add_theme_constant_override("separation",10)
	columns.add_child(centre)
	goal = _label(centre,"",19)
	goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal.custom_minimum_size.y = 76
	var town := PanelContainer.new()
	town.custom_minimum_size.y = 340
	town.size_flags_vertical = Control.SIZE_EXPAND_FILL
	centre.add_child(town)
	_button(centre,"Inspect marketplace / construction",_select.bind("building","marketplace"))
	var reserved := VBoxContainer.new()
	reserved.alignment = BoxContainer.ALIGNMENT_CENTER
	town.add_child(reserved)
	for line in ["Town", "Reserved 2D sprite area"]:
		var label := _label(reserved,line,24)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	land = _label(reserved,"")
	land.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(centre,"General pile · free / reserved",20)
	pile = HBoxContainer.new()
	pile.add_theme_constant_override("separation",8)
	centre.add_child(pile)
	_label(centre,"Shared hand · cards discard immediately when activated",20)
	hand = HBoxContainer.new()
	hand.custom_minimum_size.y = 252
	hand.add_theme_constant_override("separation",12)
	centre.add_child(hand)
	inspector = _panel(columns,390)
	var tabs := HBoxContainer.new()
	inspector.add_child(tabs)
	for title in ["Selected","Caravan","Links","Journal"]:
		_button(tabs,title,func(): tab = title; _draw_detail())
	detail = RichTextLabel.new()
	detail.bbcode_enabled = true
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.custom_minimum_size = Vector2(360,300)
	inspector.add_child(detail)
	var action_scroll := ScrollContainer.new()
	action_scroll.custom_minimum_size.y = 160
	action_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inspector.add_child(action_scroll)
	action_list = VBoxContainer.new()
	action_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_scroll.add_child(action_list)
	var footer := HBoxContainer.new()
	root_box.add_child(footer)
	recent = _label(footer,"")
	recent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for title in ["Pass", "5 influence → 1 prestige"]:
		var b := _button(footer,title,func(): pass)
		b.disabled = true
	_label(footer,"Recorded replay",18)
	lab = Window.new()
	lab.title = "Laboratory · seed 7 / manual timber · recorded decisions"
	lab.size = Vector2i(1300,800)
	lab.close_requested.connect(lab.hide)
	add_child(lab)
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lab.add_child(content)
	var controls := HBoxContainer.new()
	content.add_child(controls)
	_button(controls,"Previous",func(): _seek(cursor-1))
	slider = HSlider.new()
	slider.max_value = replay.states.size()-1
	slider.step = 1
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(v): _seek(int(v)))
	controls.add_child(slider)
	_button(controls,"Next",func(): _seek(cursor+1))
	history = RichTextLabel.new()
	history.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(history)
func _seek(index: int) -> void:
	cursor = clampi(index,0,replay.states.size()-1)
	_draw()
func _draw() -> void:
	var s := _s()
	status.text = "   Round %d  ·  %s to act  ·  Pass chain %d/3  ·  Action %d" % [s.round,_name(s.houses[int(s.actor)].id),s.consecutive_passes,s.sequence]
	goal.text = "TOWN GOAL: clay import delivered + one owned brick house\nMarket +2 prestige  ·  Clay link +3  ·  Brick house +5  |  " + ("COMPLETE" if s.ended else "In progress")
	var capacities = _land_capacities(s)
	land.text = "Urban %d/%d · Forest %d/%d · Field %d/%d · Special projects outside plot budget" % [capacities.urban-int(s.terrain_free.urban),capacities.urban,capacities.forest-int(s.terrain_free.forest),capacities.forest,capacities.field-int(s.terrain_free.field),capacities.field]
	_clear(houses)
	var stored_pop := 0
	for h in s.houses:
		var owned := 0
		for b in s.buildings.values():
			if b.built and b.owner == h.id: owned += 1
		stored_pop += int(h.stockpile.pop)
		_button(houses,"%s   ·   Property %d/3\nInfluence %d/10  ·  Prestige %d" % [_name(h.id),owned,h.inventory.influence,h.inventory.prestige],_select.bind("house",h.id))
		var slots: Array[String] = []
		for resource in h.stockpile:
			for unit in int(h.stockpile[resource]): slots.append("["+_name(resource)+"]")
		while slots.size() < 3: slots.append("[Empty]")
		var store := _label(houses," ".join(slots),17)
		store.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(houses,"Pop reserve %d / %d\nPublic %d · Stored %d\nCommitted %d" % [int(s.pop_limit)-int(s.committed_pops)-int(s.market.pop)-stored_pop,s.pop_limit,s.market.pop,stored_pop,s.committed_pops],18)
	_clear(assets)
	for id in s.buildings:
		if s.buildings[id].built or s.get("houseworks",{}).get("sites",{}).has(id): _button(assets,_name(id),_select.bind("building",id))
	_clear(pile)
	for r in s.market:
		var reserved := 0
		for lot in s.lots:
			if lot.resource == r and lot.reserved_for != "" and not lot.released: reserved += int(lot.amount)
		var button := _button(pile,"%s\n%d / %d" % [_name(r),int(s.market[r])-reserved,reserved],_select.bind("resource",r))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clear(hand)
	for i in 4:
		var id: String = s.revealed[i] if i < s.revealed.size() else ""
		var button := _button(hand,"Used / discarded" if id == "" else _card(id),_select.bind("building",id))
		button.custom_minimum_size = Vector2(180,252)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = id == ""
	recent.text = "Replay %d/%d · Deck %d · Discard %d" % [cursor,replay.states.size()-1,s.deck.size(),s.discard.size()]
	slider.set_value_no_signal(cursor)
	history.text = "Decision %d / %d\n\nAI DECISION\n%s\n\nEVENT\n%s\n\nSTATE\n%s" % [cursor,replay.states.size()-1,JSON.stringify(_m().decision,"  "),JSON.stringify(_m().event,"  "),JSON.stringify(s,"  ")]
	_draw_detail()
func _card(id: String) -> String:
	var b: Dictionary = _s().buildings[id]
	if not b.built and _s().get("houseworks",{}).get("sites",{}).has(id):
		return _name(id)+"\nConstruction site · not functional\nPaid: "+_bundle(_s().houseworks.sites[id].paid)
	var text := "%s\n\nLevel %d\n%s\n\n" % [_name(id),b.level,"Public" if b.owner == "" else _name(b.owner)]
	for mode in _m().modes.get(id,[]): text += "%s\n%s\n→ %s\n" % [_name(mode.name),_bundle(mode.inputs),_bundle(mode.outputs)]
	return text
func _draw_detail() -> void:
	# Retain a single detail/action region, independently of town art.
	_clear(action_list)
	var s := _s()
	var text := "[b]%s[/b]\n\n" % tab
	if tab == "Caravan":
		text += "Present: %s\nVisits: %d\nBricks remaining: %d\n\nOne chest → one brick\n\nClay setup: one chest + one pop + one wood\nCommits one pop; first clay delivered.\nLater visits: public wood → clay.\n\n%s" % [s.caravan.present,s.caravan.visits,s.caravan.bricks_left,JSON.stringify(s.caravan,"  ")]
	elif tab == "Links":
		text += "Clay link\n%s\nDeliveries: %d\n\nLinked assets\n%s\nCommitted pop: %d" % [JSON.stringify(s.clay_contract,"  "),s.clay_deliveries,JSON.stringify(s.linked_assets),s.committed_pops]
	elif tab == "Journal": text += JSON.stringify(_m().event,"  ")
	elif selected_kind == "building" and s.buildings.has(selected):
		text += _card(selected)+"\nAvailable in hand: %s\n\nOnce activated, the card goes to discard.\n" % (selected in s.revealed)
	elif selected_kind == "resource":
		text += "%s\nGeneral pile: %d\n\n" % [_name(selected),s.market[selected]]
		for lot in s.lots:
			if lot.resource == selected: text += "Quantity %d · Holder %s\n" % [lot.amount,"Public" if lot.reserved_for == "" or lot.released else _name(lot.reserved_for)]
		for h in s.houses: text += "%s private: %d\n" % [_name(h.id),h.stockpile[selected]]
		text += "\nReserved rival input: 1 influence/unit\nInaccessible stockpile: 2 influence/unit\nPaid directly to the holder for immediate use."
	elif selected_kind == "house":
		for h in s.houses:
			if h.id == selected: text += JSON.stringify(h,"  ")
	detail.text = text
	var count := 0
	for entry in _m().legal:
		var a: Dictionary = entry.action
		var show: bool = (tab == "Links" and a.type in ["secure_contract","cancel_contract","bulk_exchange","buy_contract","build_kiln","supply_town","supply_wood","redevelop_rural","claim_rural","start_site","supply_site","hall_work","claim_site","redevelop_occupied"]) or (tab == "Caravan" and a.type in ["secure_clay_contract","buy_brick","export_brick","buy_prestige","buy_stone","launch_expedition","expedition_buy","expedition_sell","expedition_contract","return_expedition","buy_route","cancel_route","own_route"]) or (tab == "Selected" and ((selected_kind == "building" and (a.get("building","") == selected or (selected == "marketplace" and a.type in ["build_market","build_kiln"]))) or (selected_kind == "resource" and a.get("resource","") == selected)))
		if show:
			var label = "Preview " + _name(a.type)+"\n"+_name(str(a.get("building",a.get("resource",""))))+" "+str(a.get("recipe",a.get("terrain",a.get("mode",""))))
			if a.has("bundle"): label += " · "+_bundle(a.bundle)
			if a.get("replace","") != "": label += " · replace "+_name(a.replace)
			if a.has("offer"):
				label += " · offer "+str(int(a.offer)+1)
				for trip in s.get("exploration",{}).get("trips",[]):
					if trip.owner == s.houses[int(s.actor)].id and trip.status == "trading":
						var offer: Dictionary = trip.sell[int(a.offer)] if a.type == "expedition_sell" else trip.buy[int(a.offer)]
						label += " · "+_name(offer.resource)+" · "+str(int(offer.price))+" gold"
			if a.has("access"): label += " · "+_name(a.access)
			if a.has("route"): label += " · route "+str(int(a.route))
			var button = _button(action_list,label,_preview.bind(entry))
			button.clip_text = true
			button.tooltip_text = label
			count += 1
	if tab == "Selected" and count == 0:
		detail.append_text("\n\nNo matching legal actions for the current actor.")
		if selected_kind == "building" and selected not in s.revealed and selected != "marketplace" and not selected.begins_with("hall_"): detail.append_text("\nActivation/upgrade unavailable: card is outside the current hand.")
		if selected == "marketplace" and s.buildings.marketplace.built: detail.append_text("\nAlready built; passive public infrastructure.")
func _preview(entry: Dictionary) -> void:
	detail.text = "[b]Action preview · recorded state[/b]\n\n%s\n\n%s\n\nInputs: %s\nOutputs: %s\nPrestige: %d\n\nSource allocation and influence payments\n%s\n\nReplay only: this action will not execute." % [JSON.stringify(entry.action,"  "),"Free action; normal turn retained" if entry.free else "One normal action",_bundle(entry.inputs),_bundle(entry.outputs),entry.prestige,JSON.stringify(entry.plan,"  ")]

func _land_capacities(s: Dictionary) -> Dictionary:
	var caps = {"urban":6,"forest":2,"field":2}
	if s.has("town"):
		for terrain in ["forest","field"]:
			caps.urban += int(s.town.converted[terrain])
			caps[terrain] += int(s.town.claimed[terrain])-int(s.town.converted[terrain])
	return caps

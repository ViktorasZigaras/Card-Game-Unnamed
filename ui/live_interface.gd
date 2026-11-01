extends "res://ui/interface.gd"
## v0.60: themed native play, recorded inspection, and the same authoritative logging tool.
const Art = preload("res://ui/artwork.gd")
const Session = preload("res://ui/live_session.gd")
var session = Session.new()
var archive := false
var town_view: Control
var hero: TextureRect
var notice := ""
var pending: Dictionary = {}
var seed_box: SpinBox
var linked_box: CheckButton
var auto_timer: Timer
var auto_button: Button
var action_footer: HBoxContainer
var seed_controls: HBoxContainer
var batch_button: Button
var batch_busy := false
var batch_result := ""

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty() and not "--ui-check" in args:
		add_child(load("res://src/laboratory.gd").new())
		return
	replay = JSON.parse_string(FileAccess.get_file_as_string("res://ui/recorded_preview.json"))
	session.start(7)
	cursor = 0
	get_window().min_size = Vector2i(1920,1080)
	RenderingServer.set_default_clear_color(Color("201c17"))
	_build()
	_draw()
	if "--ui-check" in args: await _check_ui()

func _m() -> Dictionary:
	return replay.states[cursor] if archive else session.frames[cursor]
func _live() -> bool:
	return not archive and cursor == session.frames.size()-1 and not session.sim.state.ended and not batch_busy
func _build() -> void:
	super._build()
	theme = Art.game_theme()
	lab.theme = theme
	lab.hide()
	lab.title = "Town laboratory · live state, decisions and replay"
	# Replace the reserved panel with a selectable sprite town.
	var panel = land.get_parent().get_parent()
	var placeholder = land.get_parent()
	panel.remove_child(placeholder)
	placeholder.queue_free()
	land = Label.new() # Kept as a detached compatibility label; no duplicate map text.
	add_child(land)
	land.hide()
	town_view = load("res://ui/town_view.gd").new()
	panel.add_child(town_view)
	town_view.object_selected.connect(func(id): _select("building",id))
	hero = TextureRect.new()
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.custom_minimum_size.y = 125
	hero.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	inspector.add_child(hero)
	inspector.move_child(hero,1)
	var header = status.get_parent()
	header.get_child(0).text = "CARD GAME  ·  v0.60"
	_button(header,"New",_new_game)
	_button(header,"Save",_save)
	_button(header,"Load",_load_save)
	_button(header,"Replay / live",_toggle_archive)
	_button(header,"Fullscreen",_fullscreen)
	action_footer = recent.get_parent()
	for child in action_footer.get_children():
		if child != recent:
			action_footer.remove_child(child)
			child.queue_free()
	_button(action_footer,"AI step",_ai_step)
	auto_button = _button(action_footer,"AI play",_toggle_auto)
	_button(action_footer,"Pass",func(): _review_type("pass"))
	var conversion := _button(action_footer,"5 influence → prestige",func(): _review_type("convert_prestige"))
	conversion.icon = Art.sprite("influence")
	conversion.expand_icon = true
	conversion.add_theme_constant_override("icon_max_width",26)
	auto_timer = Timer.new()
	auto_timer.wait_time = .55
	auto_timer.timeout.connect(_ai_step)
	add_child(auto_timer)
	seed_controls = HBoxContainer.new()
	var lab_content = history.get_parent()
	lab_content.add_child(seed_controls)
	lab_content.move_child(seed_controls,0)
	_label(seed_controls,"New game seed",18)
	seed_box = SpinBox.new()
	seed_box.min_value = 1
	seed_box.max_value = 999999
	seed_box.value = 7
	seed_controls.add_child(seed_box)
	linked_box = CheckButton.new()
	linked_box.text = "Preset lumber link"
	seed_controls.add_child(linked_box)
	_button(seed_controls,"Start new",_new_game)
	batch_button = _button(seed_controls,"Regression batch · 6",_batch)
	_button(seed_controls,"Open logs",func(): OS.shell_open(ProjectSettings.globalize_path("user://runs")))

func _draw() -> void:
	super._draw()
	var s := _s()
	var mode := "REPLAY" if archive else ("LIVE" if cursor == session.frames.size()-1 else "HISTORY")
	status.text = "  %s  ·  Round %d  ·  %s  ·  Pass %d/3" % [mode,s.round,_name(s.houses[int(s.actor)].id),s.consecutive_passes]
	if s.ended: status.text += "  ·  COMPLETE"
	goal.text = "TOWN GOAL: clay delivered + one brick house  |  " + ("COMPLETE" if s.ended else "In progress")
	goal.text += "\nMarket +2  ·  Clay link +3  ·  Brick house +5 prestige"
	goal.text += "   |   Urban %d/6 · Rural %d/4" % [6-int(s.terrain_free.urban),4-int(s.terrain_free.forest)-int(s.terrain_free.field)]
	for m in s.milestones: goal.text += "\n%s: %s +%d (round %d)" % [_name(m.kind),_name(m.house),m.prestige,m.round]
	# Milestone history belongs in the inspector to keep the town's geometry stable.
	goal.max_lines_visible = 2
	town_view.set_state(s,selected if selected_kind == "building" else "")
	for house_button in houses.get_children():
		if house_button is Button:
			house_button.icon = Art.sprite("prestige")
			house_button.expand_icon = true
			house_button.add_theme_constant_override("icon_max_width",26)
	_clear(pile)
	for r in ["wood","grain","clay","brick","furniture","luxury","pop"]:
		var reserved := 0
		for lot in s.lots:
			if lot.resource == r and lot.reserved_for != "" and not lot.released: reserved += int(lot.amount)
		var button := _button(pile,"%s  %d / %d" % [_name(r),int(s.market[r])-reserved,reserved],_select.bind("resource",r))
		button.icon = Art.sprite(r)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width",36)
		button.custom_minimum_size.y = 62
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clear(hand)
	for i in 4:
		var id: String = s.revealed[i] if i < s.revealed.size() else ""
		var button := _button(hand,"",_select.bind("building",id))
		button.custom_minimum_size = Vector2(180,252)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = id == ""
		var content := VBoxContainer.new()
		button.add_child(content)
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 9
		content.offset_right = -9
		content.offset_top = 7
		content.offset_bottom = -7
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var title = _label(content,"Discarded" if id == "" else _name(id),20)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if id == "":
			_label(content,"Used this round",17)
			continue
		Art.picture(content,Art.building_id(id,s),Vector2(120,110))
		var b: Dictionary = s.buildings[id]
		var owner := _label(content,"%s · Level %d" % ["Public" if b.owner == "" else _name(b.owner),b.level],17)
		owner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var recipes: Array[String] = []
		for recipe in _m().modes.get(id,[]): recipes.append(_bundle(recipe.inputs)+" → "+_bundle(recipe.outputs))
		var recipe_label = _label(content,"\n".join(recipes),16)
		recipe_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		recipe_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		for c in content.get_children():
			if c is Control: c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slider.max_value = (replay.states.size() if archive else session.frames.size())-1
	slider.set_value_no_signal(cursor)
	recent.text = "%s · Action %d · Deck %d / Discard %d" % [mode,s.sequence,s.deck.size(),s.discard.size()]
	if notice != "": recent.text += " · "+notice
	history.text = "Mode: %s · frame %d/%d\n%s\n\n%s\n\nDECISION\n%s\n\nEVENT\n%s\n\nSTATE\n%s" % [mode,cursor,int(slider.max_value),session.run_path,batch_result,JSON.stringify(_m().decision,"  "),JSON.stringify(_m().event,"  "),JSON.stringify(s,"  ")]
	for child in action_footer.get_children():
		if child is Button: child.disabled = not _live()
	if s.ended:
		auto_timer.stop()
		auto_button.text = "AI play"
	_draw_detail()

func _select(kind: String, id: String) -> void:
	super._select(kind,id)
	town_view.set_state(_s(),selected if kind == "building" else "")
func _draw_detail() -> void:
	detail.text = ""
	super._draw_detail()
	pending = {}
	if hero == null: return
	hero.hide()
	if tab == "Selected":
		if selected_kind == "building" and _s().buildings.has(selected):
			hero.texture = Art.sprite(Art.building_id(selected,_s()))
			hero.show()
		elif selected_kind == "resource":
			hero.texture = Art.sprite(selected)
			hero.show()
	if tab == "Caravan":
		hero.texture = Art.sprite("caravan")
		hero.show()
	if tab == "Links":
		detail.append_text("\n\n[State-based milestones]\n"+JSON.stringify(_s().milestones,"  "))
	if _s().ended: detail.append_text("\n\nTown objective complete. Inspect the journal or start another game.")

func _preview(entry: Dictionary) -> void:
	detail.text = ""
	pending = entry.action.duplicate(true)
	var text := "[b]%s[/b]\n\n%s\n\nInputs: %s\nOutputs: %s\nPrestige: %d\n\n" % [_name(pending.type),"Free action; normal turn retained" if entry.free else "One normal action",_bundle(entry.inputs),_bundle(entry.outputs),entry.prestige]
	var plan: Dictionary = entry.plan
	for allocation in plan.get("allocations",[]):
		text += "%d %s · %s\n" % [allocation.amount,_name(allocation.resource),("private store of " if allocation.source == "stockpile" else "reserved by ")+_name(allocation.owner) if allocation.get("owner","") != "" else "public pile"]
	for owner in plan.get("payments",{}): text += "Pay %d influence to %s\n" % [plan.payments[owner],_name(owner)]
	text += "\n"+("Execute below to apply this action." if _live() else "Historical inspection only; return to latest live frame to act.")
	detail.text = text
	for child in inspector.get_children():
		if child is Button:
			inspector.remove_child(child)
			child.queue_free()
	var execute := _button(inspector,"Execute · "+_name(pending.type),_execute_pending)
	execute.disabled = not _live()
func _execute_pending() -> void:
	if not _live() or pending.is_empty(): return
	var result: Dictionary = session.step(pending)
	notice = "Applied" if result.ok else str(result.get("error",result.get("errors","Rejected")))
	cursor = session.frames.size()-1
	_draw()
func _review_type(type: String) -> void:
	for entry in _m().legal:
		if entry.action.type == type:
			_preview(entry)
			return
	notice = "Unavailable: "+_name(type)
	_draw()
func _seek(index: int) -> void:
	auto_timer.stop()
	auto_button.text = "AI play"
	cursor = clampi(index,0,(replay.states.size() if archive else session.frames.size())-1)
	_draw()
func _new_game() -> void:
	auto_timer.stop()
	auto_button.text = "AI play"
	archive = false
	session.start(int(seed_box.value),linked_box.button_pressed)
	cursor = 0
	notice = "Seed %d" % int(seed_box.value)
	_draw()
func _save() -> void:
	if archive:
		notice = "Return to live to save"
	else:
		notice = "Saved latest live state" if session.save_game() == OK else "Save failed"
	_draw()
func _load_save() -> void:
	auto_timer.stop()
	auto_button.text = "AI play"
	var error: Error = session.load_game()
	if error == OK:
		archive = false
		cursor = session.frames.size()-1
		notice = "Loaded · new journal"
	else: notice = "No valid save found (%d)" % error
	_draw()
func _toggle_archive() -> void:
	auto_timer.stop()
	auto_button.text = "AI play"
	archive = not archive
	cursor = 9 if archive else session.frames.size()-1
	notice = ""
	_draw()
func _ai_step() -> void:
	if not _live():
		auto_timer.stop()
		return
	var result: Dictionary = session.step()
	notice = "AI decision" if result.ok else "AI stopped: "+JSON.stringify(result)
	if not result.ok: auto_timer.stop()
	cursor = session.frames.size()-1
	_draw()
func _toggle_auto() -> void:
	if auto_timer.is_stopped() and _live():
		auto_timer.start()
		auto_button.text = "Pause AI"
	else:
		auto_timer.stop()
		auto_button.text = "AI play"
func _batch() -> void:
	if batch_busy: return
	batch_busy = true
	auto_timer.stop()
	auto_button.text = "AI play"
	batch_button.disabled = true
	var reports: Array = []
	var directory := "user://runs/batch_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(directory)
	for link in [false,true]:
		for seed_value in [1,7,42]:
			var test = Session.new()
			test.start(seed_value,link)
			while not test.sim.state.ended and test.sim.state.round <= 40 and test.probe.failure == "":
				test.step()
				if int(test.sim.state.sequence) % 10 == 0: await get_tree().process_frame
			var report: Dictionary = test.probe.summary()
			report.scenario_ended = test.sim.state.ended
			report.lumber_link = link
			report.journal = test.run_path
			reports.append(report)
			test.probe.save_game(test.run_path+"/save.json")
			batch_result = "Regression batch: %d/6 complete" % reports.size()
			history.text = batch_result
			await get_tree().process_frame
	var file := FileAccess.open(directory+"/summary.json",FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(reports,"  "))
	batch_result = "Six runs saved: "+directory
	batch_busy = false
	batch_button.disabled = false
	_draw()

func _check_ui() -> void:
	await get_tree().process_frame
	archive = true
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
		for entry in _m().legal: _preview(entry)
		await get_tree().process_frame
		largest = largest.max(root_box.get_minimum_size())
	archive = false
	cursor = session.frames.size()-1
	selected_kind = "building"
	selected = "carpenter"
	tab = "Selected"
	_draw_detail()
	_draw_detail()
	assert(detail.get_parsed_text().contains("Carpenter"),"Inspector content disappeared on refresh")
	var before = TownSimulation.canonical(session.sim.snapshot())
	for entry in session.project().legal: _preview(entry)
	assert(before == TownSimulation.canonical(session.sim.snapshot()),"Preview mutated simulation")
	pending = {"type":"pass"}
	_execute_pending()
	assert(session.sim.state.sequence == 1,"Manual UI command did not execute")
	_ai_step()
	assert(session.sim.state.sequence == 2,"AI UI step did not execute")
	assert(session.save_game() == OK,"Save failed")
	var saved = TownSimulation.canonical(session.sim.snapshot())
	_ai_step()
	assert(session.load_game() == OK,"Load failed")
	assert(saved == TownSimulation.canonical(session.sim.snapshot()),"Save/load state mismatch")
	cursor = session.frames.size()-1
	_draw()
	await get_tree().process_frame
	largest = largest.max(root_box.get_minimum_size())
	assert(largest.x+32 <= 1920 and largest.y+32 <= 1080,"Layout exceeds 1080p: "+str(largest))
	print("v0.60 UI checks passed: 83 states, all selections, tabs, previews, manual action, AI step, exact save/load; minimum ",largest+Vector2(32,32))
	get_tree().quit()

func _fullscreen() -> void:
	var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		_fullscreen()

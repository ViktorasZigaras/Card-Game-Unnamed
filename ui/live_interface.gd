extends "res://ui/interface.gd"
## v0.905: themed native play, recorded inspection, and the same authoritative logging tool.
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
	header.get_child(0).text = "CARD GAME  ·  v0.905"
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
	_button(action_footer,"Trade 3 goods",func(): _review_type("bulk_exchange"))
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
	goal.text = "EVERY HOUSE: " + ("reached round %d; economy continues" % s.economy.goal_round if s.has("economy") and s.economy.goal_round > 0 else "clay import + three good homes")
	if s.has("trade"):
		goal.text = "HOME + INDUSTRY: " + ("all reached round %d; prestige phase" % s.trade.all_goals_round if s.trade.all_goals_round > 0 else "houses pursuing their goals")
	if s.has("exploration"):
		goal.text = "HOME → INDUSTRY → HALL: %d/3 seats · then further opportunities" % s.houseworks.hall_rounds.size()
	goal.text += "\nMarket +2  ·  Clay link +3  ·  Brick house +5 prestige"
	var caps = _land_capacities(s)
	goal.text += "   |   Urban %d/%d · Rural %d/%d" % [caps.urban-int(s.terrain_free.urban),caps.urban,caps.forest+caps.field-int(s.terrain_free.forest)-int(s.terrain_free.field),caps.forest+caps.field]
	for m in s.milestones: goal.text += "\n%s: %s +%d (round %d)" % [_name(m.kind),_name(m.house),m.prestige,m.round]
	# Milestone history belongs in the inspector to keep the town's geometry stable.
	goal.max_lines_visible = 2
	town_view.set_state(s,selected if selected_kind == "building" else "")
	var house_i = 0
	for house_button in houses.get_children():
		if house_button is Button:
			house_button.icon = Art.sprite("prestige")
			house_button.expand_icon = true
			house_button.add_theme_constant_override("icon_max_width",26)
			if s.has("trade"): house_button.text += "\nGold: %d" % s.houses[house_i].inventory.get("gold",0)
			house_i += 1
	_clear(pile)
	for r in ["wood","grain","clay","brick","furniture","luxury","pop"] + (["stone"] if s.market.has("stone") else []) + (["planks"] if s.market.has("planks") else []):
		var reserved := 0
		for lot in s.lots:
			if lot.resource == r and lot.reserved_for != "" and not lot.released: reserved += int(lot.amount)
		var button := _button(pile,"%s\n%d / %d" % [_name(r),int(s.market[r])-reserved,reserved],_select.bind("resource",r))
		button.icon = Art.sprite(r)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width",24)
		button.add_theme_font_size_override("font_size",16)
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
	if tab == "Caravan" and _s().has("capacity"):
		detail.text = "[b]Caravan[/b]\n\nOne chest buys one brick.\nClay link: one chest consumed, one pop and one wood committed.\nOne clay per visit; no further wood payment.\nCommitted wood returns on cancellation.\n\n"+JSON.stringify(_s().caravan,"  ")
	if tab == "Caravan" and _s().has("trade"):
		detail.text = "[b]Caravan[/b]\n\nOne shared brick order per visit: 1 brick → 1 gold.\nOrder available: %s\nPrestige for sale: 2 gold → 1 prestige.\nNo bricks for sale.\n\nClay import: one wood and one pop committed; one clay per visit.\n\n" % _s().caravan.get("brick_order_open",false)
	if tab == "Caravan" and _s().has("exploration"):
		var x = _s().exploration
		var id = _s().houses[int(_s().actor)].id
		detail.append_text("\n\nLand transport: one per completed Hall. Trips hold crew until return; contracts retain transport.\nNormal-action travel clock: %d\n" % x.clock)
		for trip in x.trips:
			if trip.owner != id or trip.status == "home": continue
			detail.append_text("\n[b]Your expedition %d · %s[/b]\n" % [trip.id,_name(trip.status)])
			if trip.status != "trading": detail.append_text("Arrival in %d normal town actions.\n" % maxi(0,int(trip.due)-int(x.clock)))
			detail.append_text("Cargo: "+_bundle(trip.cargo)+"\n")
			if trip.status == "trading":
				detail.append_text("Buy or contract:\n")
				for offer in trip.buy: detail.append_text("• %s: %d gold · %d finite units left%s\n" % [_name(offer.resource),offer.price,offer.left," · route secured" if offer.contracted else ""])
				detail.append_text("Sell:\n")
				for offer in trip.sell: detail.append_text("• %s: %d gold · %d orders left\n" % [_name(offer.resource),offer.price,offer.left])
		for route in x.routes:
			if route.active: detail.append_text("\nRoute %d: %s → %s · %d gold/round\nDelivered %d · Missed %d · One land capacity committed.\n" % [route.id,_name(route.resource),_name(route.owner),route.unit_price,route.delivered,route.misses])
	if tab == "Caravan" and _s().has("projects"):
		detail.append_text("\nStone: 1 gold each; %d left this visit.\nChapel upgrade: 2 stone + 1 wood + 1 pop.\nCompleted chapel produces 3 influence." % _s().caravan.stone_left)
	if tab == "Selected" and selected_kind == "building" and _s().get("projects",{}).has(selected):
		detail.append_text("\n\nUpgrade progress (goods already consumed):\n"+JSON.stringify(_s().projects[selected],"  "))
	if _s().has("houseworks") and tab == "Links":
		detail.append_text("\n\nHouse Halls: claim for 3 influence, then separately build for 3 planks + 1 stone + 1 pop.\nOne chosen known workshop recipe each round; owner only.\nSmall sawmill: 2 wood + 1 pop to build; 1 wood + 1 pop → 2 planks.\nPaid sites hold their plots but produce nothing until finished.")
	if tab == "Selected" and _s().get("houseworks",{}).get("sites",{}).has(selected):
		detail.append_text("\n\nConstruction progress: \n"+JSON.stringify(_s().houseworks.sites[selected],"  "))
	if tab == "Selected" and selected.begins_with("hall_") and _s().has("houseworks"):
		var house_id = _s().buildings[selected].owner
		detail.append_text("\nKnown recipes: "+str(_s().houseworks.unlocked[house_id])+"\nLast workshop round: "+str(_s().houseworks.last_work.get(house_id,0)))
	if tab == "Links" and _s().has("town"):
		var town = _s().town
		detail.append_text("\n\nStockade: %d/6 wood · deliveries award 1 influence each.\nTown uses unreserved public wood at round end.\nUrban conversions: %d/2 (1 stone + 1 pop each; occupied clearance costs extra).\nOuter rural claims: %d/4 (1 pop each; award 1 prestige).\n" % [town.wall_wood,town.converted.forest+town.converted.field,town.claimed.forest+town.claimed.field])
	if tab == "Links" and _s().has("trade"):
		detail.append_text("\n\nTown demand: 1 brick → 2 influence.\nHouse goals: one brick home, one industry, then prestige.\n"+JSON.stringify(_s().trade,"  "))
	if tab == "Links" and _s().has("capacity"):
		detail.append_text("\n\nCommitted export wood: %d (excluded from public/private stock)" % _s().capacity.wood)
	if tab == "Links":
		detail.append_text("\n\nContract ownership\n"+JSON.stringify(_s().get("titles",{}),"  "))
		detail.append_text("\n\nContracts\n"+JSON.stringify(_s().get("contracts",[]),"  "))
		detail.append_text("\n\n[State-based milestones]\n"+JSON.stringify(_s().milestones,"  "))
	if _s().ended: detail.append_text("\n\nTown objective complete. Inspect the journal or start another game.")

func _preview(entry: Dictionary) -> void:
	detail.text = ""
	pending = entry.action.duplicate(true)
	var text := "[b]%s[/b]\n\n%s\n\nInputs: %s\nOutputs: %s\nPrestige: %d\n\n" % [_name(pending.type),"Free action; normal turn retained" if entry.free else "One normal action",_bundle(entry.inputs),_bundle(entry.outputs),entry.prestige]
	if entry.has("recurring"): text += "Contract upkeep and cadence:\n"+JSON.stringify(entry.recurring,"  ")+"\n"
	if entry.has("commitments"): text += "Committed capacity, unavailable until cancellation: "+_bundle(entry.commitments)+"\n\n"
	if entry.has("timing"): text += entry.timing+"\n\n"
	if entry.has("financing_note"): text += entry.financing_note+"\n\n"
	var plan: Dictionary = entry.plan
	for allocation in plan.get("allocations",[]):
		text += "%d %s · %s\n" % [allocation.amount,_name(allocation.resource),("private store of " if allocation.source == "stockpile" else "reserved by ")+_name(allocation.owner) if allocation.get("owner","") != "" else "public pile"]
	for owner in plan.get("payments",{}): text += "Pay %d influence to %s\n" % [plan.payments[owner],_name(owner)]
	text += "\n"+("Execute below to apply this action." if _live() else "Historical inspection only; return to latest live frame to act.")
	detail.text = text
	_clear(action_list)
	var execute := _button(action_list,"Execute · "+_name(pending.type),_execute_pending)
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
	print("v0.905 UI checks passed: 83 states, all selections, tabs, previews, manual action, AI step, exact save/load; minimum ",largest+Vector2(32,32))
	get_tree().quit()

func _fullscreen() -> void:
	var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		_fullscreen()

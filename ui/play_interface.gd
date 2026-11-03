extends "res://ui/live_interface.gd"
## v0.910 human play surface. Economic commands remain authoritative.
const Tokens = preload("res://ui/token_strip.gd")
var goods_view: VBoxContainer
var trade_cards: HBoxContainer
var category := "Inspect"
var catalogue_building := ""
var placement_entry: Dictionary = {}
var deck_window: Window
var deck_content: VBoxContainer
var info_window: Window
var info_content: VBoxContainer
var game_menu: MenuButton
var info_menu: MenuButton
var safe_actions := false
var gentle_motion := true
var confirm_dialog: ConfirmationDialog
var confirmation_entry: Dictionary = {}
var context_tokens: VBoxContainer
var deck_button: Button
var discard_button: Button
var selection_hint: Label
var event_log: Array[String] = []
var preview_card: Dictionary = {}
var last_event_sequence := -1
var hud: HBoxContainer

func _build() -> void:
	theme = Art.game_theme()
	var prefs = ConfigFile.new()
	if prefs.load("user://presentation.cfg") == OK:
		safe_actions = prefs.get_value("ui","safe_actions",false)
		gentle_motion = prefs.get_value("ui","motion",true)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,10)
	add_child(margin)
	root_box = VBoxContainer.new()
	root_box.add_theme_constant_override("separation",8)
	margin.add_child(root_box)
	var header = HBoxContainer.new()
	header.custom_minimum_size.y = 154
	root_box.add_child(header)
	var brand = _panel(header,268)
	_label(brand,"MEDIEVAL TOWN",24)
	status = _label(brand,"",16)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hand = HBoxContainer.new()
	hand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(hand)
	var decks = VBoxContainer.new()
	header.add_child(decks)
	deck_button = _button(decks,"Deck",func(): _show_deck(false))
	discard_button = _button(decks,"Discard",func(): _show_deck(true))
	_label(decks,"Shared opportunities",14)
	var utilities = VBoxContainer.new()
	utilities.custom_minimum_size.x = 150
	header.add_child(utilities)
	game_menu = MenuButton.new(); game_menu.text = "Game"
	utilities.add_child(game_menu)
	var menu = game_menu.get_popup()
	for label in ["New game","Save game","Load game","Safe actions","Gentle motion","Fullscreen","Developer diagnostics","AI step","AI play / pause","Replay / live"]: menu.add_item(label)
	menu.set_item_as_checkable(3,true); menu.set_item_as_checkable(4,true)
	menu.set_item_checked(3,safe_actions);menu.set_item_checked(4,gentle_motion)
	menu.id_pressed.connect(_game_menu)
	info_menu = MenuButton.new();info_menu.text = "Info"
	utilities.add_child(info_menu)
	for label in ["Buildings","Recent events","How to play","AI reasoning"]: info_menu.get_popup().add_item(label)
	info_menu.get_popup().id_pressed.connect(_info_menu)
	_button(utilities,"House Info",_show_houses)
	var columns = HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",8)
	root_box.add_child(columns)
	var shelves = _panel(columns,268)
	shelves.custom_minimum_size.x = 268
	_label(shelves,"GOODS",24)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shelves.add_child(scroll)
	goods_view = load("res://ui/goods_view.gd").new()
	goods_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(goods_view)
	goods_view.resource_selected.connect(func(r): _select("resource",r))
	var centre = VBoxContainer.new()
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(centre)
	hud = HBoxContainer.new();centre.add_child(hud)
	goal = _label(centre,"",16)
	goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var town_frame = PanelContainer.new()
	town_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	centre.add_child(town_frame)
	town_view = load("res://ui/town_view.gd").new()
	town_view.custom_minimum_size = Vector2(480,340)
	town_frame.add_child(town_view)
	town_view.object_selected.connect(func(id): _map_choice("building",id))
	town_view.plot_selected.connect(func(id): _map_choice("plot",id))
	selection_hint = _label(centre,"Select a building to inspect it, or choose Build to begin.",16)
	selection_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var inspector_frame = _panel(columns,390)
	var inspector_scroll = ScrollContainer.new()
	inspector_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspector_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inspector_frame.add_child(inspector_scroll)
	inspector = VBoxContainer.new()
	inspector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector_scroll.add_child(inspector)
	var categories = HBoxContainer.new()
	inspector.add_child(categories)
	for title in ["Build","Upgrade","Contracts","Trade"]:
		var button = _button(categories,title,func(): _category(title))
		button.add_theme_font_size_override("font_size",15)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero = TextureRect.new()
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.custom_minimum_size.y = 104
	inspector.add_child(hero)
	detail = RichTextLabel.new()
	detail.bbcode_enabled = true
	detail.custom_minimum_size = Vector2(330,120)
	detail.fit_content = true
	detail.scroll_active = false
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspector.add_child(detail)
	context_tokens = VBoxContainer.new();inspector.add_child(context_tokens)
	var actions_scroll = ScrollContainer.new()
	actions_scroll.custom_minimum_size.y = 180
	actions_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inspector.add_child(actions_scroll)
	action_list = VBoxContainer.new()
	action_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_scroll.add_child(action_list)
	var trade_frame = PanelContainer.new()
	trade_frame.custom_minimum_size.y = 132
	root_box.add_child(trade_frame)
	var trade_row = HBoxContainer.new();trade_frame.add_child(trade_row)
	var trade_heading = VBoxContainer.new();trade_heading.custom_minimum_size.x = 170;trade_row.add_child(trade_heading)
	_label(trade_heading,"TRADE",24)
	_button(trade_heading,"Expeditions",func(): _category("Trade"))
	var trade_scroll = ScrollContainer.new()
	trade_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trade_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	trade_row.add_child(trade_scroll)
	trade_cards = HBoxContainer.new();trade_scroll.add_child(trade_cards)
	action_footer = HBoxContainer.new();root_box.add_child(action_footer)
	recent = _label(action_footer,"",15)
	recent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recent.clip_text = true
	_button(action_footer,"Exchange surplus",func(): _review_type("bulk_exchange"))
	_button(action_footer,"Prestige",func(): _review_type("convert_prestige"))
	_button(action_footer,"Skip",func(): _review_type("pass"))
	# Compatibility nodes live inside their own information windows.
	info_window = _window("Town information",Vector2i(940,740))
	info_content = _scroll_box(info_window)
	houses = VBoxContainer.new();info_content.add_child(houses)
	assets = VBoxContainer.new();info_content.add_child(assets)
	deck_window = _window("Deck contents",Vector2i(720,720))
	deck_content = _scroll_box(deck_window)
	lab = _window("Developer diagnostics",Vector2i(1300,800))
	var lab_box = VBoxContainer.new();lab_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);lab.add_child(lab_box)
	seed_controls = HBoxContainer.new();lab_box.add_child(seed_controls)
	_label(seed_controls,"New seed",18)
	seed_box = SpinBox.new();seed_box.min_value = 1;seed_box.max_value = 999999;seed_box.value = 7;seed_controls.add_child(seed_box)
	linked_box = CheckButton.new();linked_box.text = "Preset timber link";seed_controls.add_child(linked_box)
	_button(seed_controls,"Start new",_new_game)
	batch_button = _button(seed_controls,"Six test cases",_batch)
	auto_button = _button(seed_controls,"AI play",_toggle_auto)
	_button(seed_controls,"AI step",_ai_step)
	var timeline = HBoxContainer.new();lab_box.add_child(timeline)
	_button(timeline,"Previous",func(): _seek(cursor-1))
	slider = HSlider.new();slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL;slider.step = 1
	slider.value_changed.connect(func(v): _seek(int(v)));timeline.add_child(slider)
	_button(timeline,"Next",func(): _seek(cursor+1))
	history = RichTextLabel.new();history.size_flags_vertical = Control.SIZE_EXPAND_FILL;lab_box.add_child(history)
	auto_timer = Timer.new();auto_timer.wait_time = .8;auto_timer.timeout.connect(_ai_step);add_child(auto_timer)
	confirm_dialog = ConfirmationDialog.new();confirm_dialog.title = "Confirm action"
	confirm_dialog.confirmed.connect(func():
		var chosen = confirmation_entry.duplicate(true)
		confirmation_entry = {}
		if not chosen.is_empty(): _perform(chosen))
	confirm_dialog.canceled.connect(func(): confirmation_entry = {})
	add_child(confirm_dialog)
	pile = HBoxContainer.new();add_child(pile);pile.hide()
	land = Label.new();add_child(land);land.hide()
	town_view.motion(gentle_motion)

func _window(title: String,dims: Vector2i) -> Window:
	var window = Window.new();window.title = title;window.size = dims;window.theme = theme
	window.close_requested.connect(window.hide);add_child(window);window.hide();return window
func _scroll_box(parent: Node) -> VBoxContainer:
	var sc = ScrollContainer.new();sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED;parent.add_child(sc)
	var box = VBoxContainer.new();box.size_flags_horizontal = Control.SIZE_EXPAND_FILL;sc.add_child(box);return box
func _prefs() -> void:
	var file = ConfigFile.new();file.set_value("ui","safe_actions",safe_actions);file.set_value("ui","motion",gentle_motion);file.save("user://presentation.cfg")
func _game_menu(id: int) -> void:
	match id:
		0: _new_game()
		1: _save()
		2: _load_save()
		3:
			safe_actions = not safe_actions;game_menu.get_popup().set_item_checked(3,safe_actions);_prefs()
		4:
			gentle_motion = not gentle_motion;game_menu.get_popup().set_item_checked(4,gentle_motion);town_view.motion(gentle_motion);_prefs()
		5: _fullscreen()
		6: lab.popup_centered()
		7: _ai_step()
		8: _toggle_auto()
		9: _toggle_archive()
func _info_menu(id: int) -> void:
	_clear(info_content)
	match id:
		0:
			for key in _s().buildings:
				if TownLayout.occupied(_s(),key): _button(info_content,_name(key),func(): info_window.hide();_select("building",key))
		1:
			for line in event_log: _label(info_content,line,18)
		2:
			var help = _label(info_content,"Develop a good home, an industry, then a House Hall.\n\nCards above are shared opportunities. Goods remain physical and scarce.\nBuild → choose a building → choose a site → claim it. Supply materials on later actions.\nUpgrades retain their old function while partially paid.\nCrests identify temporary priority; padlock marks private stores.\nInspect tokens for access rights and fees.\nThree consecutive skips end a round; you may re-enter after skipping.\nSafe actions in Game adds confirmation.\nThe deck window lists counts without revealing shuffled order.",20)
			help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		3: _show_reasoning(info_content)
	info_window.popup_centered()
func _show_houses() -> void:
	_clear(info_content)
	for h in _s().houses:
		_label(info_content,"%s HOUSE" % h.id.to_upper(),26)
		_label(info_content,"Influence %d/10 · Prestige %d · Gold %d" % [h.inventory.influence,h.inventory.prestige,h.inventory.get("gold",0)],20)
		for id in _s().buildings:
			if _s().buildings[id].owner == h.id: _button(info_content,_name(id),func(): info_window.hide();_select("building",id))
		_label(info_content,"Private store",18)
		_tokens(info_content,h.stockpile,h.stockpile,"Private stock")
	info_window.popup_centered()
func _show_reasoning(parent: Node) -> void:
	var d: Dictionary = _m().decision
	if d.is_empty() or not d.has("chosen"):
		_label(parent,"No AI decision recorded yet.",20);return
	_label(parent,"Last recorded choice: "+_action_name(d.chosen),22)
	if d.get("source","") == "test_or_manual":
		_label(parent,"This was a manual action.",18);return
	var text = RichTextLabel.new();text.bbcode_enabled = true;text.fit_content = true
	text.text = "[b]Evaluated choice[/b]\n"
	for candidate in d.get("candidates",[]):
		if candidate.get("action",{}) == d.chosen:
			text.text += "Score: %s\n" % candidate.get("score","unavailable")
			text.text += "; ".join(PackedStringArray(candidate.get("reasons",[candidate.get("reason","No reason recorded")]))).replace("_"," ")+"\n"
	if d.has("plan"): text.text += "\nCurrent goal: "+str(d.plan.get("goal","Unspecified")).replace("_"," ")
	text.text += "\n\nThese are recorded heuristic assessments. Full candidate scores are in Game → Developer diagnostics."
	parent.add_child(text)
func deck_counts(discard := false) -> Dictionary:
	var counts: Dictionary = {}
	for id in (_s().discard if discard else _s().deck): counts[id] = int(counts.get(id,0))+1
	return counts
func _show_deck(discard := false) -> void:
	_clear(deck_content)
	_label(deck_content,"Discarded cards" if discard else "Remaining deck · composition only",25)
	var counts = deck_counts(discard)
	var keys = counts.keys();keys.sort()
	for id in keys:
		var row = HBoxContainer.new();deck_content.add_child(row)
		Art.picture(row,Art.building_id(id,_s()),Vector2(100,70))
		_label(row,"%s × %d" % [_name(id),counts[id]],21)
	if keys.is_empty(): _label(deck_content,"No cards here.",20)
	deck_window.popup_centered()
func _tokens(parent: Node,bundle: Dictionary,supplied: Dictionary,context: String) -> Node:
	var strip = Tokens.new();strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL;parent.add_child(strip);strip.show_bundle(bundle,supplied,context);return strip
func _available(bundle: Dictionary,building := "") -> Dictionary:
	var found = {}
	var sim = session.sim
	for r in bundle:
		if r in ["influence","prestige","gold"]:
			found[r] = mini(int(bundle[r]),int(_s().houses[int(_s().actor)].inventory.get(r,0)))
		elif _live():
			for amount in range(1,int(bundle[r])+1):
				if sim.payment_plan(sim.current_house().id,{r:amount},building).ok: found[r] = amount
	return found
func _action_name(a: Dictionary) -> String:
	var names = {"pass":"Skip","claim_site":"Claim protected site","supply_site":"Contribute materials","contribute_upgrade":"Contribute to upgrade","claim":"Acquire property","activate":"Work","secure_contract":"Establish supply","secure_clay_contract":"Establish clay import","buy_contract":"Buy supply priority","cancel_contract":"Cancel supply","supply_wood":"Supply stockade","supply_town":"Supply town bricks","take":"Store one token","return":"Return one token","hall_work":"Hall workshop","convert_prestige":"Convert influence","bulk_exchange":"Exchange stored surplus"}
	var label: String = names.get(a.type,_name(a.type))
	if a.has("building"): label += " · "+_name(a.building)
	if a.has("resource"): label += " · "+_name(a.resource)
	if a.has("bundle"): label += " · "+_bundle(a.bundle)
	if a.get("replace","") != "": label += " · replace "+_name(a.replace)
	if a.has("access"): label += " · "+str(a.access)
	if a.has("offer"):
		for trip in _s().get("exploration",{}).get("trips",[]):
			if trip.owner == _s().houses[int(_s().actor)].id and trip.status == "trading":
				var offer: Dictionary = trip.sell[int(a.offer)] if a.type == "expedition_sell" else trip.buy[int(a.offer)]
				label += " · "+_name(offer.resource)
	return label
func _action_button(parent: Node,entry: Dictionary) -> Button:
	var label = _action_name(entry.action)
	if entry.action.type == "claim_site": label = "Choose location · "+label
	var button = _button(parent,label,func(): _choose(entry))
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size",16)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.disabled = not _live()
	button.tooltip_text = label+"\nCost: "+_bundle(entry.inputs)+"\nOutput: "+_bundle(entry.outputs)+"\n"+entry.get("timing","One action")
	if not entry.inputs.is_empty():
		_label(parent,"Pays now",14);_tokens(parent,entry.inputs,entry.inputs,"Pays now")
	var payments: Dictionary = entry.get("plan",{}).get("payments",{})
	for owner in payments:
		_label(parent,"Access fee → "+owner.capitalize(),14)
		_tokens(parent,{"influence":int(payments[owner])},{"influence":int(payments[owner])},"Access fee")
	if entry.has("commitments"):
		_label(parent,"Held until released",14)
		_tokens(parent,entry.commitments,entry.commitments,"Commitment")
	if entry.has("recurring"):
		var recurring: Dictionary = entry.recurring
		var note = "Ongoing: "+_bundle(recurring.get("upkeep",{}))
		if recurring.has("gold_each_round"): note = "Ongoing: %d gold per round" % recurring.gold_each_round
		var obligation = _label(parent,note,14);obligation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not entry.outputs.is_empty():
		_label(parent,"Produces",14);_tokens(parent,entry.outputs,entry.outputs,"Output")
	return button
func _category(value: String) -> void:
	category = value;catalogue_building = "";placement_entry = {};preview_card = {}
	town_view.eligible_plots = [];town_view.redraw();_draw_detail()
func _select(kind: String,id: String) -> void:
	placement_entry = {};town_view.eligible_plots = []
	selected_kind = kind;selected = id;category = "Inspect";catalogue_building = "";preview_card = {}
	tab = "Selected";_draw_detail();town_view.set_state(_s(),id);town_view.redraw()
func _map_choice(kind: String,id: String) -> void:
	if placement_entry.is_empty(): _select(kind,id);return
	var plot_id = id
	if kind == "building":
		for cell in town_view.layout.cells:
			if cell.building == id: plot_id = cell.id
	if plot_id not in town_view.eligible_plots:
		notice = "Choose one of the highlighted eligible sites.";recent.text = notice;return
	var entry = placement_entry.duplicate(true);entry.action.plot = plot_id
	_choose(entry)
func _choose(entry: Dictionary) -> void:
	if not _live(): return
	auto_timer.stop();auto_button.text = "AI play"
	if entry.action.type == "claim_site" and not entry.action.has("plot"):
		placement_entry = entry.duplicate(true)
		town_view.eligible_plots = session.sim.placement_cells(entry.action).map(func(c): return c.id)
		town_view.redraw()
		selection_hint.text = "Choose a highlighted site for "+_name(entry.action.building)+". Claiming and construction are separate actions."
		_label(action_list,"Select the site on the map.",17)
		_button(action_list,"Cancel site choice",func(): _category("Build"))
		return
	if safe_actions:
		confirmation_entry = entry.duplicate(true)
		confirm_dialog.dialog_text = _confirmation_text(entry)
		confirm_dialog.popup_centered(Vector2i(620,290))
	else: _perform(entry)
func _perform(entry: Dictionary) -> void:
	pending = entry.action.duplicate(true)
	var label = _action_name(pending)
	var result = session.step(pending)
	pending = {};placement_entry = {};confirmation_entry = {};town_view.eligible_plots = []
	notice = label+" · paid "+_bundle(entry.inputs)+" · output "+_bundle(entry.outputs) if result.ok else "Action unavailable: requirements or target changed. Inspect the current options."
	
	cursor = session.frames.size()-1;_draw()
func _review_type(type: String) -> void:
	for entry in _m().legal:
		if entry.action.type == type: _choose(entry);return
	notice = "Unavailable: "+_name(type)+". Inspect requirements or try another opportunity.";_draw()
func _preview(entry: Dictionary) -> void:
	# Explicit inspect-only route used by tools and previews, never executes.
	preview_card = entry.duplicate(true);_draw_detail();pending = entry.action.duplicate(true)
func _execute_pending() -> void:
	if pending.is_empty() or not _live(): return
	var action = pending.duplicate(true)
	_perform(session.preview(action))
func _draw() -> void:
	if status == null: return
	var s = _s()
	status.text = "Round %d · %s to act\nv0.910 · %s" % [s.round,_name(s.houses[int(s.actor)].id),"Replay" if archive else "Live" if _live() else "History"]
	_clear(hud)
	for h in s.houses:
		var crest = preload("res://ui/crest.gd").new();crest.house = h.id;crest.custom_minimum_size = Vector2(22,27);hud.add_child(crest)
		_label(hud,"%s  %d influence · %d prestige · %d gold" % [h.id.capitalize(),h.inventory.influence,h.inventory.prestige,h.inventory.get("gold",0)],14)
	goal.text = "A good home → an industry → a House Hall · %d/3 Halls established" % s.houseworks.hall_rounds.size()
	_clear(hand)
	for id in s.revealed:
		var button = _button(hand,"",_select.bind("building",id))
		button.custom_minimum_size = Vector2(150,138);button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = _card(id)
		var card = VBoxContainer.new();card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);card.offset_left = 8;card.offset_right = -8;card.offset_top = 5;button.add_child(card)
		var title = _label(card,_name(id),19);title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Art.picture(card,Art.building_id(id,s),Vector2(100,78))
		var subtitle = _label(card,"Public" if s.buildings[id].owner == "" else s.buildings[id].owner.capitalize()+" house",14)
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		for child in card.get_children(): child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if s.revealed.is_empty(): _label(hand,"No shared cards remain this round.\nOther legal actions and Skip remain available.",20)
	deck_button.text = "Deck · %d" % s.deck.size();discard_button.text = "Discard · %d" % s.discard.size()
	goods_view.set_state(s)
	town_view.project_costs = {}
	for id in s.houseworks.sites: town_view.project_costs[id] = session.sim.site_cost(id)
	for id in s.get("projects",{}): town_view.project_costs[id] = session.sim.cost_for(id)
	town_view.set_state(s,selected if selected_kind in ["building","plot"] else "")
	_draw_trade()
	if placement_entry.is_empty(): selection_hint.text = "Select a building to inspect it, or choose Build to begin. Stockade progress is below the town."
	recent.text = notice if notice != "" else "Inspect, plan, then act. Three consecutive skips close the round."
	slider.max_value = (replay.states.size() if archive else session.frames.size())-1;slider.set_value_no_signal(cursor)
	history.text = "DECISION\n%s\n\nEVENT\n%s\n\nSTATE\n%s" % [JSON.stringify(_m().decision,"  "),JSON.stringify(_m().event,"  "),JSON.stringify(s,"  ")]
	if last_event_sequence != int(s.sequence) and int(s.sequence) > 0:
		last_event_sequence = int(s.sequence)
		var event: Dictionary = _m().event
		if event.has("action"):
			event_log.append("Round %d · %s" % [s.round,_action_name(event.action)])
			if event_log.size() > 64: event_log.pop_front()
	_draw_detail()
func _draw_trade() -> void:
	_clear(trade_cards)
	var s = _s()
	var box = _panel(trade_cards,240)
	_label(box,"Caravan visiting" if s.caravan.present else "Caravan away",20)
	if not s.caravan.present:
		_label(box,"Build the marketplace" if not s.buildings.marketplace.built else "Returns on its scheduled round",16)
	else:
		_label(box,"Shared visit stock; act before it leaves.",14)
		for entry in _m().legal:
			if entry.action.type in ["export_brick","buy_stone","buy_prestige"]: _trade_offer(entry)

	var links = _panel(trade_cards,250)
	_label(links,"Supply & expeditions",20)
	var active_routes = s.exploration.routes.filter(func(r): return r.active).size()
	_label(links,"%d active routes · %d trips" % [active_routes,s.exploration.trips.filter(func(t): return t.status != "home").size()],16)
	_button(links,"Inspect trade opportunities",func(): _category("Trade"))
	for trip in s.exploration.trips:
		if trip.status == "home": continue
		var trip_card = _panel(trade_cards,210)
		_label(trip_card,trip.owner.capitalize()+" expedition",19)
		_label(trip_card,_name(trip.status),17)
		if trip.status != "trading": _label(trip_card,"%d actions until arrival" % maxi(0,int(trip.due)-int(s.exploration.clock)),15)
		else:
			_button(trip_card,"View offers",func(): _category("Trade"))
	for entry in _m().legal:
		if entry.action.type in ["expedition_buy","expedition_sell","expedition_contract"]: _trade_offer(entry)
func _draw_detail() -> void:
	if detail == null: return
	_clear(action_list);_clear(context_tokens);hero.hide();pending = {}
	detail.text = ""
	if not preview_card.is_empty():
		detail.text = "[b]"+_action_name(preview_card.action)+"[/b]\n"+preview_card.get("timing","One action")
		_label(context_tokens,"Pays now",16);_tokens(context_tokens,preview_card.inputs,preview_card.inputs,"Required inputs")
		_action_button(action_list,preview_card);return
	if archive and category != "Inspect":
		detail.text = "Historical recording: select existing cards, goods and buildings to inspect this version. Return to Live to build or trade.";return
	if category == "Build": _draw_catalogue();return
	if category in ["Contracts","Trade","Upgrade"]:
		detail.text = "[b]"+category+"[/b]\n"+{"Upgrade":"Select a building below or on the map to inspect its benefit and full requirement.","Contracts":"Establish supply, purchase priority or end an obligation. Material setup and rights are distinct.","Trade":"Real caravan and expedition opportunities. Cargo is unavailable until return."}[category]
		var count = 0
		for entry in _m().legal:
			var a: Dictionary = entry.action
			var show = a.type in ["upgrade","contribute_upgrade"] if category == "Upgrade" else a.type in ["secure_contract","secure_clay_contract","buy_contract","cancel_contract","own_route","buy_route","cancel_route"] if category == "Contracts" else a.type in ["export_brick","buy_stone","buy_prestige","launch_expedition","expedition_buy","expedition_sell","expedition_contract","return_expedition"]
			if show: _action_button(action_list,entry);count += 1
		if category == "Upgrade":
			for id in _s().buildings:
				if _s().buildings[id].built and (id.begins_with("hut_") or id == "chapel"): _button(action_list,"Inspect "+_name(id),_select.bind("building",id))
		if category == "Trade": _trade_description()
		if count == 0: detail.append_text("\n\nNo matching legal action now. Check your goods, influence, cards and transport prerequisites.")
		return
	var s = _s()
	if selected_kind == "building" and s.buildings.has(selected):
		var b: Dictionary = s.buildings[selected]
		hero.texture = Art.sprite(Art.building_id(selected,s));hero.show()
		detail.text = "[b]%s[/b]\n%s · %s\n" % [_name(selected),"Public" if b.owner == "" else b.owner.capitalize()+" house","Built" if b.built else "Protected construction site"]
		for mode in _m().modes.get(selected,[]):
			_label(context_tokens,_name(mode.name)+" · inputs → output",14)
			_label(context_tokens,"Inputs",14)
			_tokens(context_tokens,mode.inputs,mode.inputs,"Recipe inputs")
			_label(context_tokens,"Produces",14)
			_tokens(context_tokens,mode.outputs,mode.outputs,"Recipe output")
		if selected.begins_with("hut_") or selected == "chapel":
			var cost: Dictionary = session.sim.rules.chapel_upgrade_cost if selected == "chapel" else session.sim.rules.housing_upgrade_cost
			if int(b.level) < 2:
				detail.append_text("\nUpgrade: chapel gives 3 influence." if selected == "chapel" else "\nUpgrade: enables 1 grain + 1 luxury → 2 labour; basic recipe remains.")
				_label(context_tokens,"Upgrade requirement · ✓ already supplied",15)
				_tokens(context_tokens,cost,s.get("projects",{}).get(selected,{}).get("paid",{}),"Committed upgrade progress")
		var site: Dictionary = s.houseworks.sites.get(selected,{})
		if not site.is_empty() and not site.completed:
			_label(context_tokens,"Construction · ✓ committed materials",15)
			_tokens(context_tokens,session.sim.site_cost(selected),site.paid,"Construction progress")
			detail.append_text("\nClaimed site is protected. No function until all materials are supplied.")
		var count = 0
		for entry in _m().legal:
			if entry.action.get("building","") == selected: _action_button(action_list,entry);count += 1
		if count == 0: detail.append_text("\n\n"+_building_blocked(selected))
	elif selected_kind == "resource":
		hero.texture = Art.sprite(selected);hero.show()
		detail.text = "[b]%s[/b]\nPublic and reserved supply: %d\n\nCrest = temporary output priority; lock = private store. Rival reserved input use costs 1 influence; private input use costs 2. Fees transfer to the holder. Paid use cannot hoard a rival's token." % [_name(selected),s.market.get(selected,0)]
		for entry in _m().legal:
			if entry.action.get("resource","") == selected: _action_button(action_list,entry)
	elif selected_kind == "plot":
		if selected == "stockade":
			detail.text = "[b]Town stockade[/b]\n"+("Complete: enables rural-to-urban conversion." if s.town.wall_complete else "Complete the perimeter to unlock land conversion. Active deliveries award influence; automatic round-end use does not.")
			_tokens(context_tokens,{"wood":6},{"wood":int(s.town.wall_wood)},"Stockade construction progress")
			for entry in _m().legal:
				if entry.action.type in ["supply_wood","redevelop_rural","claim_rural","redevelop_occupied"]: _action_button(action_list,entry)
		else:
			for cell in town_view.layout.cells:
				if cell.id == selected: detail.text = "[b]%s[/b]\n%s\n%s\nChoose Build first to select a structure for this location." % [cell.terrain.capitalize(),"Unclaimed wilderness" if not cell.active else "Vacant town land" if cell.building == "" else _name(cell.building),"Paths are decorative; land rights are unchanged."]
	else: detail.text = "Select a map object, token or shared card to inspect it."
func _draw_catalogue() -> void:
	var s = _s()
	if catalogue_building == "":
		detail.text = "[b]Build[/b]\nChoose a structure, then its site. Social claiming and material construction take separate actions. Unavailable buildings remain visible."
		for id in ["marketplace","kiln","small_sawmill","hall_"+s.houses[int(s.actor)].id]:
			var button = _button(action_list,_name(id),func(): catalogue_building = id;_draw_detail())
			button.icon = Art.sprite(Art.building_id(id,s));button.expand_icon = true;button.add_theme_constant_override("icon_max_width",60)
		return
	var id = catalogue_building
	hero.texture = Art.sprite(Art.building_id(id,s));hero.show()
	var benefits = {"marketplace":"Welcomes scheduled caravans and enables clay imports.","kiln":"Turns clay and labour into bricks. Unlocks brickmaking for every Hall.","small_sawmill":"Turns wood and labour into two planks for Hall construction."}
	detail.text = "[b]%s[/b]\n%s\n\nFirst claim a site; then contribute materials on later actions." % [_name(id),benefits.get(id,"Unique headquarters. Owner-only known workshop recipe once per round, plus one land transport capacity.")]
	_label(context_tokens,"Full material requirement",16)
	var cost: Dictionary = session.sim.site_cost(id)
	_tokens(context_tokens,cost,_available(cost),"Available / missing materials")
	_label(context_tokens,"Site claim · pays now",16)
	_tokens(context_tokens,{"influence":session.sim.site_social(id)},_available({"influence":session.sim.site_social(id)}),"Social claim cost")
	var count = 0
	for entry in _m().legal:
		if entry.action.get("building","") == id and entry.action.type in ["claim_site","supply_site"]:
			_action_button(action_list,entry);count += 1
	if count == 0:
		detail.append_text("\n\n"+_build_blocked(id))
	_button(action_list,"Back to catalogue",func(): catalogue_building = "";_draw_detail())
func _trade_description() -> void:
	for route in _s().exploration.routes:
		if route.active: detail.append_text("\n%s supply: %s pays %d gold/round · %s access · %d deliveries, %d missed." % [_name(route.resource),route.owner.capitalize(),route.unit_price,route.get("access","priority"),route.delivered,route.misses])
	for trip in _s().exploration.trips:
		if trip.status != "home": detail.append_text("\n%s expedition: %s. Cargo: %s. Crew returns with the expedition." % [trip.owner.capitalize(),trip.status,_bundle(trip.cargo)])

func _confirmation_text(entry: Dictionary) -> String:
	var text = _action_name(entry.action)+"\n\nConsumed now: "+_bundle(entry.inputs)
	text += "\nOutput: "+_bundle(entry.outputs)
	var payments: Dictionary = entry.get("plan",{}).get("payments",{})
	for owner in payments: text += "\nAccess fee: %d influence to %s house" % [int(payments[owner]),owner.capitalize()]
	if not entry.get("commitments",{}).is_empty(): text += "\nHeld, unavailable for spending: "+_bundle(entry.commitments)
	var recurring: Dictionary = entry.get("recurring",{})
	if not recurring.is_empty():
		text += "\nOngoing: %d gold per round" % int(recurring.gold_each_round) if recurring.has("gold_each_round") else "\nOngoing upkeep: "+_bundle(recurring.get("upkeep",{}))
		if recurring.has("cadence"): text += " · "+str(recurring.cadence).replace("_"," ")
	if entry.get("prestige",0) > 0: text += "\nCompletion reward: %d prestige" % int(entry.prestige)
	return text+"\n\n"+entry.get("timing","One action; ordinary turn rules apply.")

func _build_blocked(id: String) -> String:
	var sim = session.sim
	var b: Dictionary = _s().buildings[id]
	if b.built: return "Already built. Select the building to inspect its work."
	if _s().houseworks.sites.has(id): return "Site already claimed. Select it to inspect the outstanding materials; contributions need its shared card."
	if sim.has_unfinished_site(sim.current_house().id): return "Finish your existing sponsored construction site before claiming another."
	if sim.current_house().inventory.influence < sim.site_social(id): return "Site claim needs %d influence; your house has %d. A first idle Skip can earn influence." % [sim.site_social(id),sim.current_house().inventory.influence]
	return "No eligible affordable site. Existing private properties and ongoing projects are protected; clearance also needs prestige."

func _building_blocked(id: String) -> String:
	var s = _s()
	var b: Dictionary = s.buildings[id]
	if not _live(): return "Viewing history. Return to the latest live state to act."
	if not b.built: return "Construction is unfinished. Its shared card must appear before supplying available materials."
	if id in s.used: return "Already worked this round. Wait for the next round."
	if id not in s.revealed and not id.begins_with("hall_"): return "Its shared card is not available this round. Inspect the remaining deck."
	return "No affordable legal action. Inspect the required inputs and access fees; committed goods cannot be spent."

func _reset_choices() -> void:
	pending = {};placement_entry = {};confirmation_entry = {};preview_card = {}
	confirm_dialog.hide();town_view.eligible_plots = [];event_log.clear();last_event_sequence = -1
func _new_game() -> void:
	_reset_choices();super._new_game()
func _load_save() -> void:
	_reset_choices();super._load_save()
func _toggle_archive() -> void:
	_reset_choices();super._toggle_archive()
func _ai_step() -> void:
	if not _live(): auto_timer.stop();return
	var result: Dictionary = session.step()
	notice = "AI: "+_action_name(session.probe.last_decision.chosen) if result.ok else "AI stopped. Open developer diagnostics for the recorded failure."
	if not result.ok: auto_timer.stop()
	cursor = session.frames.size()-1;_draw()

func _trade_offer(entry: Dictionary) -> void:
	var card = _panel(trade_cards,205)
	var action = _button(card,_action_name(entry.action),func(): _choose(entry))
	action.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action.add_theme_font_size_override("font_size",15)
	action.tooltip_text = _confirmation_text(entry)
	_label(card,"Pays → receives",13)
	var exchange = HBoxContainer.new();card.add_child(exchange)
	var cost = Tokens.new();cost.size_flags_horizontal = Control.SIZE_EXPAND_FILL;exchange.add_child(cost);cost.show_bundle(entry.inputs,entry.inputs,"Pays now",28)
	_label(exchange,"→",16)
	var output = Tokens.new();output.size_flags_horizontal = Control.SIZE_EXPAND_FILL;exchange.add_child(output);output.show_bundle(entry.outputs,entry.outputs,"Receives",28)
	if entry.has("recurring"): _label(card,"Recurring · inspect terms",13)

func _s() -> Dictionary:
	var state: Dictionary = _m().state
	if not archive: return state
	# Historical recordings predate Halls, stockades and expeditions. Supply display
	# defaults on a copy, never rewrite the historical save or infer new mechanics.
	var view = state.duplicate(true)
	if not view.has('houseworks'): view.houseworks = {'sites':{},'hall_rounds':{}}
	if not view.has('town'): view.town = {'wall_wood':0,'wall_complete':false}
	if not view.has('exploration'): view.exploration = {'routes':[],'trips':[],'clock':0}
	if not view.has('projects'): view.projects = {}
	return view

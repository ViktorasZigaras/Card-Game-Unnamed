extends VBoxContainer
const Art = preload("res://ui/artwork.gd")
signal resource_selected(resource: String)
const TOKEN_LIMIT = 12
var displayed_units = 0
var represented_units = 0
static func groups(state: Dictionary) -> Array:
	var buckets: Dictionary = {}
	for lot in state.lots:
		var holder: String = lot.reserved_for
		var scope = "Public supply" if holder == "" else "Reserved · "+holder.capitalize()
		var key = scope+":"+lot.resource
		if not buckets.has(key): buckets[key] = {"scope":scope,"holder":holder,"resource":lot.resource,"count":0,"private":false}
		buckets[key].count += int(lot.amount)
	for h in state.houses:
		for resource in h.stockpile:
			var amount = int(h.stockpile[resource])
			if amount <= 0: continue
			var scope: String = h.id.capitalize()+" · private store"
			buckets[scope+":"+resource] = {"scope":scope,"holder":h.id,"resource":resource,"count":amount,"private":true}
	var result: Array = buckets.values()
	result.sort_custom(func(a,b):
		var ar = 2 if a.private else 0 if a.holder == "" else 1
		var br = 2 if b.private else 0 if b.holder == "" else 1
		return ar < br if ar != br else a.scope+":"+a.resource < b.scope+":"+b.resource)
	return result
func set_state(state: Dictionary) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	displayed_units = 0
	represented_units = 0
	var caption = Label.new()
	caption.text = "Each token is one unit. Click to inspect legal uses.\nReservations give priority; immediate use can still be bought with influence.\nCommitted elsewhere: %d labour, %d export wood. Incoming cargo stays in Trade until arrival." % [int(state.get("committed_pops",0)),int(state.get("capacity",{}).get("wood",0))]
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(caption)
	var last_scope = ""
	for group in groups(state):
		if last_scope != group.scope:
			last_scope = group.scope
			var heading = Label.new()
			heading.text = last_scope
			heading.add_theme_font_size_override("font_size",23)
			add_child(heading)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation",6)
		add_child(row)
		var label = Label.new()
		label.text = "%s · %d" % [{"pop":"Labour","furniture":"Chests"}.get(group.resource,str(group.resource).capitalize()),group.count]
		label.custom_minimum_size.x = 135
		label.add_theme_font_size_override("font_size",17)
		row.add_child(label)
		var tokens = HFlowContainer.new()
		tokens.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(tokens)
		represented_units += int(group.count)
		for i in mini(TOKEN_LIMIT,int(group.count)):
			var token = Button.new()
			token.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var icon = Art.sprite(group.resource)
			if icon != null:
				token.icon = icon
				token.expand_icon = true
				token.add_theme_constant_override("icon_max_width",38)
			else: token.text = str(group.resource).left(2).to_upper()
			token.custom_minimum_size = Vector2(48,48)
			token.tooltip_text = "1 %s · %s\n%s" % [group.resource,group.scope,"Private goods: immediate rival use can cost 2 influence; cannot be taken into another store." if group.private else "Reserved goods: immediate rival use can cost 1 influence; cannot be hoarded by rivals." if group.holder != "" else "Public goods: no holder's access fee."]
			token.pressed.connect(func(): resource_selected.emit(group.resource))
			tokens.add_child(token)
			displayed_units += 1
		if group.count > TOKEN_LIMIT:
			var extra = Label.new()
			extra.text = "+%d more" % (int(group.count)-TOKEN_LIMIT)
			tokens.add_child(extra)
	if represented_units == 0:
		var empty = Label.new()
		empty.text = "No physical goods currently in supply or stores."
		add_child(empty)

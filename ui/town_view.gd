extends Control
const Art = preload("res://ui/artwork.gd")
signal object_selected(id: String)
signal plot_selected(id: String)
var current: Dictionary = {}
var layout: Dictionary = {}
var selected_id = ""
var layer: Control
var ambience: Control
var signature = ""
const OWNER_COLORS = {"blue":Color("72a6d5"),"red":Color("c86f55"),"gold":Color("d9bc57"),"":Color("a79970")}
func _ready() -> void:
	clip_contents = true
	layer = Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	ambience = load("res://ui/town_ambience.gd").new()
	ambience.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ambience.z_index = 3
	add_child(ambience)
	resized.connect(redraw)
func set_state(state: Dictionary,selection: String) -> void:
	var next_layout: Dictionary = state.town_map if state.has("town_map") else TownLayout.legacy(state)
	var next_signature = JSON.stringify([next_layout,state.buildings,state.get("used",[]),selection,state.get("caravan",{}).get("present",false),state.get("town",{}).get("wall_complete",false)])
	current = state
	layout = next_layout
	selected_id = selection
	if next_signature != signature:
		signature = next_signature
		redraw()
func cell_rect(cell: Dictionary) -> Rect2:
	var step = Vector2((size.x-24)/5.0,(size.y-30)/3.0)
	return Rect2(Vector2(12,10)+Vector2(cell.column,cell.row)*step+Vector2(5,4),step-Vector2(10,18))
func motion(value: bool) -> void:
	if ambience != null: ambience.set_motion(value)
func redraw() -> void:
	queue_redraw()
	if layer == null or current.is_empty(): return
	for child in layer.get_children():
		layer.remove_child(child)
		child.queue_free()
	ambience.items = []
	for cell in layout.cells:
		var rect = cell_rect(cell)
		var id: String = cell.building
		var button = TextureButton.new()
		button.position = rect.position
		button.size = rect.size-Vector2(0,18)
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if id != "":
			var b: Dictionary = current.buildings[id]
			var sprite = Art.sprite(Art.building_id(id,current))
			if id.begins_with("hall_"): sprite = Art.sprite("brick_house")
			if id == "small_sawmill": sprite = Art.sprite("carpenter")
			button.texture_normal = sprite
			button.tooltip_text = id.replace("_"," ").capitalize()+" · "+cell.id+" · "+cell.terrain+"\n"+("Public" if b.owner == "" else str(b.owner).capitalize())+(" · used this round" if id in current.used else "")+"\nMotion is decorative; production requires an action."
			button.pressed.connect(func(): object_selected.emit(id))
			if not b.built: button.modulate = Color(.8,.8,.65,.55)
			else:
				var kind = "saw" if id in ["carpenter","small_sawmill"] else "smoke" if id == "kiln" else "banner" if id.begins_with("hall_") or id in ["grain_farm","lumber_camp","marketplace"] else "window"
				ambience.items.append({"key":id,"kind":kind,"rect":Rect2(button.position,button.size),"color":OWNER_COLORS.get(b.owner,OWNER_COLORS[""])})
		else:
			button.tooltip_text = cell.id+" · "+("Unclaimed wilderness" if not cell.active else "Vacant "+cell.terrain+" plot")
			button.pressed.connect(func(): plot_selected.emit(cell.id))
		layer.add_child(button)
		var label = Label.new()
		var owner = "" if id == "" else current.buildings[id].owner
		label.text = ((cell.id+" · "+cell.terrain.capitalize()) if id == "" else id.replace("_"," ").capitalize()+(" · site" if not current.buildings[id].built else ""))+(" ✓" if id in current.get("used",[]) else "")
		label.add_theme_font_size_override("font_size",13)
		label.add_theme_color_override("font_color",OWNER_COLORS.get(owner,OWNER_COLORS[""]))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.clip_text = true
		label.position = rect.position+Vector2(0,rect.size.y-17)
		label.size = Vector2(rect.size.x,18)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(label)
	ambience.queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("34452e"))
	if layout.is_empty(): return
	var step = Vector2((size.x-24)/5.0,(size.y-30)/3.0)
	for y in [10+step.y-.5,10+2*step.y-.5]:
		draw_line(Vector2(20,y),Vector2(size.x-20,y),Color("605538"),10)
		draw_line(Vector2(20,y),Vector2(size.x-20,y),Color("98845a"),5)
	draw_line(Vector2(12+step.x,15),Vector2(12+step.x,size.y-15),Color("98845a"),5)
	for cell in layout.cells:
		var r = cell_rect(cell)
		var fill = {"urban":Color("786b4b"),"forest":Color("344e35"),"field":Color("687146"),"wild":Color("2e462e"),"special":Color("6d6650")}[cell.terrain]
		draw_rect(r,fill)
		draw_rect(r,Color("c9b582") if selected_id != "" and (cell.building == selected_id or cell.id == selected_id) else Color("4c5538"),false,1)
		if cell.vegetation:
			for i in 4:
				var p = r.position+r.size*Vector2(.16+float(posmod(hash(cell.id+str(i)),69))*.01,.22+float(i%2)*.35)
				if cell.terrain in ["forest","wild"]:
					draw_rect(Rect2(p+Vector2(-2,0),Vector2(4,15)),Color("786042"))
					for j in 3:
						var top = p-Vector2(0,25-j*8)
						draw_colored_polygon(PackedVector2Array([top,top+Vector2(-13,18),top+Vector2(13,18)]),Color("3e673c") if j%2 else Color("294d32"))
				else:
					for j in 3: draw_line(p+Vector2(j*4,0),p+Vector2(j*4-2,-9-j),Color("9b9b52"),2)
		if cell.building == "kiln":
			draw_rect(Rect2(r.position+r.size*Vector2(.25,.37),r.size*Vector2(.5,.36)),Color("9e8d74"))
			draw_rect(Rect2(r.position+r.size*Vector2(.42,.55),r.size*Vector2(.16,.18)),Color("483a2c"))
			draw_rect(Rect2(r.position+r.size*Vector2(.48,.2),r.size*Vector2(.08,.2)),Color("8c7b65"))
	if current.get("town",{}).get("wall_complete",false):
		draw_rect(Rect2(Vector2(12+step.x,9),Vector2(step.x*3,step.y*2)),Color("b19765"),false,3)

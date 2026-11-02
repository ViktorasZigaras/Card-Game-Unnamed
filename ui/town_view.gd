extends Control
const Art = preload("res://ui/artwork.gd")
signal object_selected(id: String)
var current: Dictionary = {}
var selected_id := ""
var layer: Control
const PLACES = {"lumber_camp":Vector2(.035,.025),"hut_1":Vector2(.275,.015),"hut_2":Vector2(.515,.015),"chapel":Vector2(.765,.025),"grain_farm":Vector2(.03,.49),"carpenter":Vector2(.28,.49),"hut_3":Vector2(.53,.49),"marketplace":Vector2(.77,.49)}
func _ready() -> void:
	clip_contents = true
	var ground := TextureRect.new()
	ground.texture = load("res://art/town_ground.png")
	ground.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ground.stretch_mode = TextureRect.STRETCH_SCALE
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground)
	layer = Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	resized.connect(redraw)
func set_state(state: Dictionary, selection: String) -> void:
	current = state
	selected_id = selection
	if layer != null: redraw()
func redraw() -> void:
	if current.is_empty() or layer == null: return
	for child in layer.get_children():
		layer.remove_child(child)
		child.queue_free()
	var footprint := Vector2(size.x*.20,size.y*.45)
	for id in PLACES:
		var building: Dictionary = current.buildings[id]
		if not building.built: continue
		var button := TextureButton.new()
		button.texture_normal = Art.sprite(Art.building_id(id,current))
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.position = PLACES[id]*size
		button.size = footprint
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.tooltip_text = id.replace("_"," ").capitalize()+" · click to inspect"
		button.pressed.connect(func(): object_selected.emit(id))
		layer.add_child(button)
		var label := Label.new()
		var owner: String = building.owner.capitalize() if building.owner != "" else "Public"
		label.text = id.replace("_"," ").capitalize()+" · "+owner+ ("  ✓" if id in current.used else "")
		label.add_theme_font_size_override("font_size",14)
		label.add_theme_stylebox_override("normal",Art.box(Color("29271ee8"),Color("e2bc70") if id == selected_id else Color("5b5239")))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.position = button.position+Vector2(-5,footprint.y-20)
		label.size.x = footprint.x+10
		layer.add_child(label)
	var extra_ids = ["kiln","small_sawmill","hall_blue","hall_red","hall_gold"]
	for i in extra_ids.size():
		var id = extra_ids[i]
		if not current.buildings.has(id): continue
		var b: Dictionary = current.buildings[id]
		if not b.built and not current.get("houseworks",{}).get("sites",{}).has(id): continue
		var marker := Button.new()
		marker.text = id.replace("_"," ").capitalize()+(" · site" if not b.built else "")
		marker.add_theme_font_size_override("font_size",14)
		marker.clip_text = true
		marker.position = Vector2(i*size.x/5,size.y*.41)
		marker.size = Vector2(size.x/5-5,44)
		marker.tooltip_text = marker.text+" — temporary marker"
		marker.pressed.connect(func(): object_selected.emit(id))
		layer.add_child(marker)
	if current.caravan.present:
		var wagon := Art.picture(layer,"caravan",Vector2(120,90))
		wagon.position = Vector2(size.x*.66,size.y*.30)
		wagon.size = Vector2(120,90)

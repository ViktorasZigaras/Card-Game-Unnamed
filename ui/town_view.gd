extends Control
const Art = preload("res://ui/artwork.gd")
signal object_selected(id: String)
signal plot_selected(id: String)
var current: Dictionary = {}
var layout: Dictionary = {}
var selected_id = ""
var eligible_plots: Array = []
var layer: Control
var ambience: Control
var signature = ""
var background: Texture2D = preload("res://art/valley_0910.png")
const OWNER_COLORS = {"blue":Color("72a6d5"),"red":Color("c86f55"),"gold":Color("d9bc57"),"":Color("a79970")}
# Stable plot addresses under a less regular picturesque composition.
const POSITIONS = {"F1":Vector2(.13,.32),"U1":Vector2(.33,.35),"U2":Vector2(.51,.29),"U3":Vector2(.70,.36),"S1":Vector2(.87,.28),"F2":Vector2(.12,.56),"U4":Vector2(.34,.57),"U5":Vector2(.55,.55),"U6":Vector2(.75,.59),"D1":Vector2(.30,.79),"D2":Vector2(.51,.80),"N1":Vector2(.10,.83),"N2":Vector2(.72,.83),"N3":Vector2(.91,.54),"N4":Vector2(.91,.80)}
func _ready() -> void:
	clip_contents = true
	layer = Control.new();layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(layer)
	ambience = load("res://ui/town_ambience.gd").new()
	ambience.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ambience.z_index = 3;add_child(ambience)
	resized.connect(redraw)
func set_state(state: Dictionary,selection: String) -> void:
	var next_layout: Dictionary = state.town_map if state.has("town_map") else TownLayout.legacy(state)
	var next_signature = JSON.stringify([next_layout,state.buildings,state.get("projects",{}),state.get("houseworks",{}).get("sites",{}),state.get("used",[]),selection,state.get("town",{}).get("wall_wood",0)])
	current = state;layout = next_layout;selected_id = selection
	if next_signature != signature: signature = next_signature;redraw()
func cell_rect(cell: Dictionary) -> Rect2:
	var anchor: Vector2 = POSITIONS.get(cell.id,Vector2(.5,.5))*size
	var dims = Vector2(size.x*.174,size.y*.255)
	return Rect2(anchor-dims*.5,dims)
func motion(value: bool) -> void:
	if ambience != null: ambience.set_motion(value)
func sprite_rect(rect: Rect2,texture: Texture2D) -> Rect2:
	var ratio = texture.get_size().x/texture.get_size().y
	var dims = Vector2(minf(rect.size.x,rect.size.y*ratio),minf(rect.size.y,rect.size.x/ratio))
	return Rect2(rect.position+(rect.size-dims)*.5,dims)
func _image(id: String,rect: Rect2,parent: Node = null) -> TextureRect:
	var pic = TextureRect.new();pic.texture = Art.sprite(id)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.position = rect.position;pic.size = rect.size;pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	(parent if parent != null else layer).add_child(pic);return pic
func redraw() -> void:
	queue_redraw()
	if layer == null or current.is_empty(): return
	for child in layer.get_children(): layer.remove_child(child);child.queue_free()
	ambience.items = []
	var cells = layout.cells.duplicate();cells.sort_custom(func(a,b): return POSITIONS[a.id].y < POSITIONS[b.id].y)
	for cell in cells:
		var rect = cell_rect(cell)
		if cell.vegetation:
			if cell.terrain in ["forest","wild"]:
				for i in 2:
					_image("oak",Rect2(rect.position+Vector2(i*rect.size.x*.26,-rect.size.y*.18),rect.size*Vector2(.8,1.2)))
			else: _image("bush",Rect2(rect.position+rect.size*.4,rect.size*.6))
		var id: String = cell.building
		var button = TextureButton.new()
		button.position = rect.position;button.size = rect.size
		button.ignore_texture_size = true;button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if id != "":
			var b: Dictionary = current.buildings[id]
			var sprite = Art.sprite(Art.building_id(id,current))
			button.texture_normal = sprite if b.built else Art.sprite("construction")
			button.tooltip_text = id.replace("_"," ").capitalize()+" · "+cell.id+"\n"+("Public" if b.owner == "" else b.owner.capitalize()+" house")+(" · used this round" if id in current.used else "")
			button.pressed.connect(func(): object_selected.emit(id))
			if b.built:
				var fitted = sprite_rect(rect,sprite)
				var kind = "saw" if id in ["carpenter","small_sawmill"] else "smoke" if id == "kiln" else "banner" if id.begins_with("hall_") or id in ["grain_farm","lumber_camp","marketplace"] else "window"
				ambience.items.append({"key":id,"kind":kind,"rect":fitted,"color":OWNER_COLORS.get(b.owner,OWNER_COLORS[""])})
			layer.add_child(button)
			if b.owner != "":
				var crest = preload("res://ui/crest.gd").new();crest.house = b.owner;crest.position = rect.position+rect.size*Vector2(.73,.31);crest.size = Vector2(20,27);layer.add_child(crest)
			var project: Dictionary = current.get("houseworks",{}).get("sites",{}).get(id,{})
			var upgrade: Dictionary = current.get("projects",{}).get(id,{})
			var cost: Dictionary = {}
			var paid: Dictionary = {}
			if not project.is_empty() and not project.completed:
				cost = {"wood":3,"pop":1} if id == "marketplace" else {"wood":2,"pop":1} if id in ["kiln","small_sawmill"] else {"planks":3,"stone":1,"pop":1}
				paid = project.paid
			elif not upgrade.is_empty() and not upgrade.get("completed",false):
				cost = {"stone":2,"wood":1,"pop":1} if id == "chapel" else {"wood":2,"brick":1,"pop":1}
				paid = upgrade.get("paid",{})
			if not cost.is_empty():
				var panel = PanelContainer.new();panel.z_index = 4;panel.position = rect.position+Vector2(-5,rect.size.y-8);panel.size = Vector2(rect.size.x+10,29)
				panel.mouse_filter = Control.MOUSE_FILTER_PASS;layer.add_child(panel)
				var strip = preload("res://ui/token_strip.gd").new();panel.add_child(strip);strip.show_bundle(cost,paid,"Committed project materials",21)
			if id == "carpenter": _image("barrels",Rect2(rect.end-Vector2(30,28),Vector2(34,34)))
		else:
			button.tooltip_text = cell.id+" · "+("Unclaimed wilderness" if not cell.active else "Vacant "+cell.terrain+" plot")
			button.pressed.connect(func(): plot_selected.emit(cell.id));layer.add_child(button)
	# Stockade is a real selectable project, outside the finite economic plot budget.
	if int(current.town.wall_wood) >= 6: _image("gate",Rect2(size*Vector2(.46,.79),size*Vector2(.08,.15)))
	var wall_button = Button.new();wall_button.text = "Stockade  %d/6" % current.town.wall_wood
	wall_button.position = size*Vector2(.40,.91);wall_button.size = Vector2(size.x*.24,30)
	wall_button.add_theme_font_size_override("font_size",14)
	wall_button.pressed.connect(func(): plot_selected.emit("stockade"));layer.add_child(wall_button)
func _draw() -> void:
	draw_texture_rect(background,Rect2(Vector2.ZERO,size),false)
	if layout.is_empty(): return
	# Soft irregular tracks below the independent buildings.
	var track = PackedVector2Array([Vector2(.06,.66)*size,Vector2(.29,.66)*size,Vector2(.43,.70)*size,Vector2(.61,.65)*size,Vector2(.83,.68)*size,Vector2(.98,.61)*size])
	draw_polyline(track,Color("8a8452"),18,false);draw_polyline(track,Color("c0ad78"),10,false)
	draw_polyline(PackedVector2Array([Vector2(.50,.95)*size,Vector2(.49,.70)*size,Vector2(.58,.44)*size,Vector2(.81,.33)*size]),Color("b6a477"),10,false)
	for cell in layout.cells:
		var rect = cell_rect(cell)
		if cell.id in eligible_plots:
			draw_rect(rect,Color(.95,.85,.43,.17));draw_rect(rect,Color("f6db80"),false,3)
		elif selected_id != "" and (cell.id == selected_id or cell.building == selected_id):
			draw_arc(rect.get_center()+Vector2(0,rect.size.y*.36),rect.size.x*.42,0,TAU,32,Color("e2ce88"),2)
	# Six paid wall sections, plus subdued construction stakes for unfinished sections.
	var wall = int(current.get("town",{}).get("wall_wood",0))
	var left = size*Vector2(.045,.895);var right = size*Vector2(.965,.895)
	for segment in 6:
		var a = left.lerp(right,float(segment)/6.0);var b = left.lerp(right,float(segment+1)/6.0)
		var paid = segment < wall
		var n = maxi(3,int((b.x-a.x)/7))
		for i in n:
			if not paid and i % 4 != 0: continue
			var p = a.lerp(b,float(i)/n)
			var height = 25 if paid else 10
			draw_rect(Rect2(p-Vector2(0,height),Vector2(5,height)),Color("6f5030") if paid else Color("8c7950"))
			draw_line(p-Vector2(0,height),p-Vector2(-3,height+4),Color("c7a56c"),2)
		if paid: draw_line(a-Vector2(0,9),b-Vector2(0,9),Color("ac8450"),3)
	if wall >= 6:
		# Receding side rails complete a coherent perimeter.
		for side in [.045,.965]:
			draw_line(Vector2(side*size.x,size.y*.895),Vector2((side+.025 if side < .5 else side-.025)*size.x,size.y*.24),Color("987443"),5)

		draw_line(Vector2(size.x*.07,size.y*.24),Vector2(size.x*.94,size.y*.24),Color("987443"),5)

extends RefCounted
const BUILDINGS = {"hut":0,"brick_house":1,"grain_farm":2,"lumber_camp":3,"carpenter":4,"marketplace":5,"chapel":6,"caravan":7}
const GOODS = {"wood":0,"grain":1,"clay":2,"brick":3,"furniture":4,"luxury":5,"pop":6,"influence":7,"prestige":8}
static var cache: Dictionary = {}
static func sprite(id: String) -> Texture2D:
	if id == "stone": return null # Text-only placeholder until artwork is selected.
	var building := BUILDINGS.has(id)
	var key := ("b:" if building else "g:")+id
	if cache.has(key): return cache[key]
	var sheet: Texture2D = load("res://art/buildings.png" if building else "res://art/goods.png")
	var cols := 4 if building else 3
	var rows := 2 if building else 3
	var index: int = BUILDINGS.get(id,0) if building else GOODS.get(id,0)
	var left := roundi(float(index % cols)*sheet.get_width()/cols)
	var top := roundi(float(floori(float(index)/cols))*sheet.get_height()/rows)
	var right := roundi(float(index % cols+1)*sheet.get_width()/cols)
	var bottom := roundi(float(floori(float(index)/cols)+1)*sheet.get_height()/rows)
	var texture := AtlasTexture.new()
	texture.atlas = sheet
	texture.region = Rect2(left,top,right-left,bottom-top)
	texture.filter_clip = true
	cache[key] = texture
	return texture
static func building_id(id: String, state: Dictionary) -> String:
	if id == "kiln": return "brick" # Temporary resource icon; no kiln sprite has been commissioned.
	if id.begins_with("hut_"): return "brick_house" if int(state.buildings[id].level)>1 else "hut"
	return id
static func picture(parent: Node, id: String, size: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = sprite(id)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = size
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
	return image
static func box(fill: Color, border: Color = Color("69533b")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_content_margin_all(9)
	return style
static func game_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 18
	for type in ["Label","Button","CheckButton","RichTextLabel","SpinBox","LineEdit"]:
		t.set_color("font_color",type,Color("eadbb9"))
		t.set_color("default_color",type,Color("eadbb9"))
	t.set_color("font_disabled_color","Button",Color("a29177"))
	t.set_color("font_hover_color","Button",Color("fff0c9"))
	t.set_stylebox("panel","PanelContainer",box(Color("302a23")))
	t.set_stylebox("normal","Button",box(Color("493a29")))
	t.set_stylebox("hover","Button",box(Color("635139"),Color("c8a964")))
	t.set_stylebox("pressed","Button",box(Color("74613f"),Color("e5c980")))
	t.set_stylebox("disabled","Button",box(Color("342e26"),Color("4a4031")))
	t.set_stylebox("focus","Button",box(Color(0,0,0,0),Color("e7c573")))
	t.set_color("font_color","LineEdit",Color("30251b"))
	t.set_stylebox("normal","LineEdit",box(Color("e0cfaa")))
	for state in ["normal","hover","pressed","disabled","focus"]:
		var button_style = t.get_stylebox(state,"Button")
		button_style.content_margin_top = 4
		button_style.content_margin_bottom = 4
	return t

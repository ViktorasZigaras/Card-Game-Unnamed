extends Control
var house := ""
var private_goods := false
const COLORS = {"blue":Color("356fa5"),"red":Color("a74335"),"gold":Color("ba8e2f"),"":Color("8b9271")}
func _ready() -> void: mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var w = size.x
	var h = size.y
	var p = PackedVector2Array([Vector2(1,1),Vector2(w-1,1),Vector2(w-2,h*.67),Vector2(w*.5,h-1),Vector2(2,h*.67)])
	draw_colored_polygon(p,COLORS.get(house,COLORS[""]))
	p.append(p[0]);draw_polyline(p,Color("e4c378"),2)
	var symbol = "✦" if house == "blue" else "✚" if house == "red" else "◆" if house == "gold" else "○"
	draw_string(ThemeDB.fallback_font,Vector2(w*.2,h*.65),symbol,HORIZONTAL_ALIGNMENT_LEFT,-1,int(h*.6),Color("ffe3a3"))
	if private_goods: draw_rect(Rect2(w-9,h-12,8,7),Color("eee2bd"),true)

extends Control
## Cosmetic time and hash variation are independent of gameplay RNG.
var items: Array = []
var elapsed = 0.0
var accumulator = 0.0
var enabled = true
func _ready() -> void: mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
	if not enabled or not is_visible_in_tree(): return
	elapsed += delta
	accumulator += delta
	if accumulator >= 1.0/12.0:
		accumulator = 0
		queue_redraw()
func set_motion(value: bool) -> void:
	enabled = value
	visible = value
func _draw() -> void:
	if not enabled: return
	for item in items:
		var r: Rect2 = item.rect
		var t = elapsed+float(posmod(hash(item.key),71))*.37
		var anchor = r.position
		var unit = maxf(1.0,r.size.x/100.0)
		match item.kind:
			"window":
				var cycle = int(t/23.0)
				var start = float(2+posmod(hash(item.key+str(cycle)),10))
				var duration = float(2+posmod(hash(str(cycle)+item.key),7))
				var p = fmod(t,23.0)-start
				if p >= 0 and p < duration:
					var glow = .65 if int(p*2) % 5 != 0 else .4
					draw_rect(Rect2(anchor+r.size*Vector2(.58,.56),Vector2(5,7)*unit),Color(1.0,.71,.25,glow))
			"saw":
				var a = anchor+r.size*Vector2(.43,.64)+Vector2(float([0,2,4,2,0,-2][int(t*4)%6])*unit,0)
				draw_rect(Rect2(a,Vector2(20,2)*unit),Color("b8b9a5"))
				for i in 7: draw_line(a+Vector2(i*3,2)*unit,a+Vector2(i*3+1,4)*unit,Color("858e8c"),unit)
			"banner":
				var a = anchor+r.size*Vector2(.79,.22)
				draw_line(a,a+Vector2(0,25)*unit,Color("ad9261"),unit)
				var sway = float([0,1,2,1,0,-1][int(t*2)%6])*unit
				draw_colored_polygon(PackedVector2Array([a,a+Vector2(12*unit,sway),a+Vector2(11*unit,8*unit+sway),a+Vector2(0,8*unit)]),item.color)
			"smoke":
				for i in 2:
					var p = fmod(t*.06+i*.5,1.0)
					var a = anchor+r.size*Vector2(.53,.23)+Vector2(sin(t*.5+p*2)*4*unit,-p*22*unit)
					draw_rect(Rect2(a,Vector2(5+p*3,3+p*3)*unit),Color(.72,.74,.67,(1-p)*.27))

extends HFlowContainer
## Repeated token silhouettes; never inventory unless the surrounding label says so.
const Art = preload("res://ui/artwork.gd")
var exact_total := 0
var expanded := false
var expanded_bundle: Dictionary = {}
var expanded_supplied: Dictionary = {}
var expanded_context := ""
var expanded_size := 32
func show_bundle(bundle: Dictionary, supplied: Dictionary = {}, context := "Required", token_size := 32) -> void:
	for child in get_children(): remove_child(child); child.queue_free()
	expanded_bundle = bundle.duplicate(true);expanded_supplied = supplied.duplicate(true);expanded_context = context;expanded_size = token_size
	exact_total = 0
	add_theme_constant_override("h_separation",2)
	for resource in bundle:
		var count = int(bundle[resource])
		exact_total += count
		for i in (count if expanded else mini(count,12)):
			var token = TextureRect.new()
			token.texture = Art.sprite(resource)
			token.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			token.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			token.custom_minimum_size = Vector2(token_size,token_size)
			token.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var paid = i < int(supplied.get(resource,0))
			token.modulate = Color.WHITE if paid else Color(.39,.34,.26,.55)
			token.tooltip_text = "%s · %s · %d of %d" % [resource.capitalize(),"supplied / available" if paid else "missing / outstanding",i+1,count]
			var mark = Label.new()
			mark.text = "✓" if paid else "·"
			mark.add_theme_font_size_override("font_size",13)
			mark.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			mark.position = Vector2(token_size-13,token_size-17)
			mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			token.add_child(mark)
			add_child(token)
		if count > 12 and not expanded:
			var extra = Button.new()
			extra.text = "+%d · show all" % (count-12)
			extra.pressed.connect(func(): expanded = true;show_bundle(expanded_bundle,expanded_supplied,expanded_context,expanded_size))
			extra.tooltip_text = "%s: %d exact total; %d supplied" % [resource,count,int(supplied.get(resource,0))]
			add_child(extra)
	tooltip_text = context+" · "+str(exact_total)+" units"

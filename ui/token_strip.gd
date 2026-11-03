extends HFlowContainer
## Repeated token silhouettes; never inventory unless the surrounding label says so.
const Art = preload("res://ui/artwork.gd")
var exact_total := 0
func show_bundle(bundle: Dictionary, supplied: Dictionary = {}, context := "Required", token_size := 32) -> void:
	for child in get_children(): remove_child(child); child.queue_free()
	exact_total = 0
	add_theme_constant_override("h_separation",2)
	for resource in bundle:
		var count = int(bundle[resource])
		exact_total += count
		for i in mini(count,12):
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
			mark.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
			mark.position = Vector2(token_size-13,token_size-17)
			mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			token.add_child(mark)
			add_child(token)
		if count > 12:
			var extra = Label.new()
			extra.text = "+%d" % (count-12)
			extra.tooltip_text = "%s: %d exact total; %d supplied" % [resource,count,int(supplied.get(resource,0))]
			add_child(extra)
	tooltip_text = context+" · "+str(exact_total)+" units"

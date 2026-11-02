class_name MappedTownSimulation
extends FlexibleContractSimulation
## Saved visual bookkeeping; no road, adjacency or distance economy.
func _init() -> void:
	super._init()
	rules.schema_version = 18
	rules.experiment = "recovered_mapped_town"
func ensure_map() -> void:
	if not state.has("town_map"): state.town_map = TownLayout.make(rules.locales[state.locale].terrain)
	TownLayout.sync(state.town_map,state)
func _new_round() -> void:
	super._new_round()
	ensure_map()
	state.schema_version = 18
func cell_for(id: String) -> Dictionary:
	for cell in state.town_map.cells:
		if cell.building == id: return cell
	return {}
func _experimental_action(action: Dictionary,h: Dictionary,events: Array) -> void:
	var target: Dictionary = {}
	if action.get("building","") != "": target = cell_for(action.building)
	if action.get("replace","") != "": target = cell_for(action.replace)
	super._experimental_action(action,h,events)
	if action.type == "redevelop_occupied":
		target.building = ""
		target.terrain = "urban"
		target.vegetation = false
	elif action.type == "redevelop_rural":
		for cell in state.town_map.cells:
			if cell.active and cell.terrain == action.terrain and cell.building == "":
				cell.terrain = "urban"
				cell.vegetation = false
				break
	elif action.type == "claim_rural":
		for cell in state.town_map.cells:
			if not cell.active:
				cell.active = true
				cell.terrain = state.town.land_events[-1].terrain
				cell.vegetation = false
				break
	elif action.type == "claim_site" and not target.is_empty():
		target.building = action.building
		target.vegetation = false
	ensure_map()
func _after_action(event: Dictionary) -> void:
	super._after_action(event)
	ensure_map()
func violations() -> Array:
	var errors = super.violations()
	var ids: Array = []
	var occupied_ids: Array = []
	for cell in state.town_map.cells:
		if cell.id in ids: errors.append("duplicate visual plot")
		ids.append(cell.id)
		if cell.building != "":
			if cell.building in occupied_ids: errors.append("duplicate visual occupant")
			occupied_ids.append(cell.building)
			if cell.terrain != state.buildings[cell.building].plot: errors.append("visual plot type disagrees with building")
	for id in state.buildings:
		if TownLayout.occupied(state,id) and id not in occupied_ids: errors.append("building missing from town map: "+id)
	for terrain in ["urban","forest","field"]:
		var cells = state.town_map.cells.filter(func(c): return c.active and c.terrain == terrain)
		if cells.size() != effective_capacity(terrain): errors.append("visual terrain capacity: "+terrain)
		if cells.filter(func(c): return c.building == "").size() != int(state.terrain_free[terrain]): errors.append("visual free plot count: "+terrain)
	return errors

class_name TownLayout
extends RefCounted
## Presentation addresses remain stable while terrain and occupancy change.
static func make(base: Dictionary) -> Dictionary:
	var cells: Array = []
	var places = {"urban":[[1,0],[2,0],[3,0],[1,1],[2,1],[3,1]],"forest":[[0,0],[0,1]],"field":[[1,2],[2,2]],"special":[[4,0]]}
	for terrain in ["urban","forest","field","special"]:
		var count = 1 if terrain == "special" else int(base[terrain])
		for i in count:
			var pos: Array = places[terrain][i]
			cells.append({"id":({"urban":"U","forest":"F","field":"D","special":"S"}[terrain])+str(i+1),"column":pos[0],"row":pos[1],"terrain":terrain,"active":true,"vegetation":terrain in ["forest","field"],"building":""})
	var outer = [[0,2],[3,2],[4,1],[4,2]]
	for i in outer.size():
		cells.append({"id":"N"+str(i+1),"column":outer[i][0],"row":outer[i][1],"terrain":"wild","active":false,"vegetation":true,"building":""})
	return {"version":1,"columns":5,"rows":3,"cells":cells}
static func occupied(state: Dictionary,id: String) -> bool:
	return state.buildings[id].built or state.get("houseworks",{}).get("sites",{}).has(id)
static func sync(layout: Dictionary,state: Dictionary) -> void:
	for cell in layout.cells:
		if cell.building != "" and (not state.buildings.has(cell.building) or not occupied(state,cell.building)): cell.building = ""
	var preferred = {"hut_1":"U1","hut_2":"U2","hut_3":"U3","carpenter":"U4"}
	var keys = state.buildings.keys()
	keys.sort_custom(func(a,b): return (0 if preferred.has(a) else 1) < (0 if preferred.has(b) else 1))
	for id in keys:
		if not occupied(state,id) or layout.cells.any(func(c): return c.building == id): continue
		var terrain: String = state.buildings[id].plot
		var candidates = layout.cells.filter(func(c): return c.active and c.terrain == terrain and c.building == "")
		if candidates.is_empty(): continue
		var target: Dictionary = candidates[0]
		for cell in candidates:
			if cell.id == preferred.get(id,""): target = cell
		target.building = id
		target.vegetation = false
static func legacy(state: Dictionary) -> Dictionary:
	var layout = make({"urban":6,"forest":2,"field":2})
	for event in state.get("town",{}).get("land_events",[]):
		if event.type in ["rural_redeveloped","occupied_rural_redeveloped"]:
			for cell in layout.cells:
				if cell.active and cell.terrain == event.from:
					cell.terrain = "urban"
					cell.vegetation = false
					break
		elif event.type in ["biome_land_claimed","rural_claimed_for_town"]:
			for cell in layout.cells:
				if not cell.active:
					cell.active = true
					cell.terrain = event.terrain
					cell.vegetation = false
					break
	sync(layout,state)
	return layout

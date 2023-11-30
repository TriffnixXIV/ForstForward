extends Node
class_name CrystalManager

var map: Map

var CrystalScene = preload("res://Scenes/Crystal.tscn")
var crystals: Array[Crystal] = []
var cell_crystal_map = {}
var spawn_chances = {
	Crystal.Type.life: -0.1,
	Crystal.Type.growth: -0.1,
	Crystal.Type.weather: -0.1
}
var fully_grown_crystals: Array[Crystal] = []
var pending_crystal_spawns: Array[Crystal.Type] = []

func _init(map_: Map):
	self.map = map_

func reset():
	for crystal in crystals:
		map.remove_child(crystal)
		crystal.queue_free()
	crystals = []
	cell_crystal_map = {}
	spawn_chances = {
		Crystal.Type.life: -0.1,
		Crystal.Type.growth: -0.1,
		Crystal.Type.weather: -0.1
	}
	fully_grown_crystals = []
	pending_crystal_spawns = []

func add_progress(crystal_type: Crystal.Type, amount: int):
	var crystals_with_type = []
	for crystal in crystals:
		if crystal.type == crystal_type:
			crystals_with_type.append(crystal)
	
	if crystals_with_type != []:
		crystals_with_type.sort_custom(func(a, b): return a.progress > b.progress)
		
		for crystal in crystals_with_type:
			var growth = clampi(7 - crystal.progress, 0, amount)
			crystal.grow(growth)
			amount -= growth
		
		if amount > 0:
			crystals_with_type[0].grow(amount)
	
	spawn_chances[crystal_type] += 0.02

func advance():
	for crystal in crystals:
		crystal.grow()
		if crystal.is_grown():
			fully_grown_crystals.append(crystal)
	plant_crystals()

func plant_crystals():
	for type in spawn_chances:
		while spawn_chances[type] >= 1:
			pending_crystal_spawns.append(type)
			spawn_chances[type] -= 1.0
		if randf() < spawn_chances[type]:
			pending_crystal_spawns.append(type)
			spawn_chances[type] -= 0.2
	
	for _i in len(pending_crystal_spawns):
		var crystal_type = pending_crystal_spawns.pop_front()
		find_spot_and_spawn_crystal(crystal_type)

func find_spot_and_spawn_crystal(crystal_type: Crystal.Type):
	var spawn_spot = find_crystal_spawn_spot(crystal_type)
	if spawn_spot != null:
		spawn_crystal(spawn_spot, crystal_type)
		return true
	else:
		pending_crystal_spawns.append(crystal_type)
		return false

func find_crystal_spawn_spot(crystal_type: Crystal.Type):
	var values: Array[Array] = map.get_cell_value_array()
	
	var weighted_forest_cells = []
	var total_weight = 0
	for x in map.width:
		for y in map.height:
			var cell = Vector2i(x, y)
			if map.is_forest(cell) and not cell in cell_crystal_map:
				var weight = 0
				var closeness_weight = -6 # the closer to a similar crystal, the higher
				var farness_weight = 6 # the farther from a dissimilar crystal, the higher
				for crystal in crystals:
					var path = crystal.cell_position - cell
					var distance = abs(path.x) + abs(path.y)
					if crystal.type == crystal_type:
						closeness_weight = max(closeness_weight, floori(pow(6 - distance, 3) / 2.0))
					else:
						farness_weight = min(farness_weight, distance - 12)
				
				weight += closeness_weight + farness_weight
				
				for diff in [
					Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1),
					Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, -1),
					Vector2i(2, 0), Vector2i(0, 2), Vector2i(-2, 0), Vector2i(0, -2)]:
					if map.is_forest(cell + diff):
						weight += 1
					elif map.is_valid_tile(cell + diff):
						weight -= 3
				if weight > 0:
					weighted_forest_cells.append([cell, weight])
					total_weight += weight
					values[x][y] = weight
	
	var x = randi_range(1, total_weight)
	for i in len(weighted_forest_cells):
		var cell = weighted_forest_cells[i][0]
		var weight = weighted_forest_cells[i][1]
		if x <= weight:
			return cell
		x -= weight
	
	return null

func spawn_crystal(cell_position: Vector2i, type: Crystal.Type):
	var crystal: Crystal = CrystalScene.instantiate()
	crystal.position.x = cell_position.x * map.tile_set.tile_size.x
	crystal.position.y = cell_position.y * map.tile_set.tile_size.y
	crystal.connect("cracked", crystal_has_cracked)
	map.add_child(crystal)
	
	crystal.map = map
	crystal.cell_position = cell_position
	crystal.set_type(type)
	crystals.append(crystal)
	cell_crystal_map[cell_position] = crystal

func crystal_has_cracked(crystal: Crystal):
	map.sounds.crystal_crack()
	crystals.erase(crystal)
	cell_crystal_map.erase(crystal.cell_position)
	if crystal.is_grown():
		fully_grown_crystals.erase(crystal)
	map.remove_child(crystal)
	crystal.queue_free()

func claim_crystal():
	return fully_grown_crystals.pop_front()

func forest_died_at(cell_position: Vector2i):
	if cell_position in cell_crystal_map:
		crystal_has_cracked(cell_crystal_map[cell_position])

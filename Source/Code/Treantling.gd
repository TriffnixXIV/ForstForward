extends Node2D
class_name Treantling

var map: Map
var cell_position: Vector2i

var actions = 0
var strength = 0
var lifespan = 0
var lifespan_left = 0
var death_spread = 0

var target_location

signal moved
signal attacked
signal grown_trees
signal has_died

func prepare_turn(action_amount: int):
	actions = action_amount

func act():
	if actions <= 0:
		return false
	
	if target_location == null or target_location == cell_position or map.get_building_progress(target_location) == 0:
		update_target_location()
	
	if target_location != null:
		if get_distance_to(target_location) > 0:
			move(0)
	
	stomp()
	actions -= 1
	
	lifespan_left -= 1
	if lifespan_left <= 0:
		convert_to_forest()
	
	return actions > 0

func set_lifespan(new_lifespan: int):
	lifespan_left += max(0, new_lifespan - lifespan)
	lifespan = new_lifespan
	lifespan_left = min(lifespan_left, lifespan)

func stomp():
	var previous_villager_amount = len(map.villagers.villagers)
	var damage = min(strength, map.get_building_progress(cell_position))
	var growth = min(strength - damage, floori((10 - map.get_yield(cell_position)) / 4.0))
	map.trees_from_treantlings += map.increase_yield(cell_position, damage + growth)
	map.deaths_to_treantlings += previous_villager_amount - len(map.villagers.villagers)
	
	if damage > 0: emit_signal("attacked")

func convert_to_forest():
	var previous_villager_amount = len(map.villagers.villagers)
	map.spread_forest(cell_position, death_spread, true, "treantling")
	map.deaths_to_treantlings += previous_villager_amount - len(map.villagers.villagers)
	actions = 0
	
	emit_signal("grown_trees")
	emit_signal("has_died", self)

func update_target_location():
	var closest_valid_targets = map.find_closest_matching_cells(cell_position, is_valid_target, null, 20)
	var current_value = evaluate_for_buildings(cell_position)
	
	if closest_valid_targets == [] and current_value <= 0:
		target_location = map.find_closest_matching_cell(cell_position, is_good_death_spot, null, 20)
		if cell_position == target_location or target_location == null:
			convert_to_forest()
	elif current_value <= 0:
		target_location = null
	
	for valid_target in closest_valid_targets:
		var target_value = evaluate_for_buildings(valid_target) - pow(map.get_distance(valid_target, cell_position), 2) + 1
		if target_location == null or target_value > current_value:
			target_location = valid_target
			current_value = target_value

func is_valid_target(cell: Vector2i, _extra):
	return evaluate_for_buildings(cell) > evaluate_for_buildings(cell_position)

func evaluate_for_buildings(cell: Vector2i):
	var value = map.get_building_progress(cell)
	return 0 if value == 0 else 11 - value

func is_good_death_spot(cell: Vector2i, _extra):
	return not map.is_forest(cell)

func move(target_distance: int):
	var path = target_location - cell_position
	if abs(path.x) + abs(path.y) > target_distance:
		if abs(path.x) > 0 and abs(path.x) > abs(path.y):
			cell_position.x += path.x / abs(path.x)
		elif abs(path.y) > 0 and abs(path.y) > abs(path.x):
			cell_position.y += path.y / abs(path.y)
		else:
			match randi_range(0, 1):
				0: cell_position.x += path.x / abs(path.x)
				1: cell_position.y += path.y / abs(path.y)
	
	emit_signal("moved")
	update_position()

func get_distance_to(cell: Vector2i):
	var path = cell - cell_position
	return abs(path.x) + abs(path.y)

func update_position():
	position.x = cell_position.x * map.tile_set.tile_size.x
	position.y = cell_position.y * map.tile_set.tile_size.y

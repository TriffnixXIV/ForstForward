extends Node2D
class_name Treant

var map: Map
var cell_position: Vector2i

var actions = 0

var target_location

var has_signaled_inaction = false

signal done_acting
signal has_died

func prepare_turn(action_amount: int):
	update_target_location()
	has_signaled_inaction = false
	actions = action_amount
	
	stomp()

func act():
	if actions <= 0:
		if not has_signaled_inaction:
			has_signaled_inaction = true
			emit_signal("done_acting")
		return null
	
	if target_location == null or target_location == cell_position or map.get_building_progress(target_location) == 0:
		update_target_location()
	
	if target_location != null:
		if get_distance_to(target_location) > 0:
			move(0)
	
	stomp()
	actions -= 1

func stomp():
	var previous_villager_amount = len(map.villagers)
	for diff in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
		var cell = cell_position + diff
		var damage = map.get_building_progress(cell)
		var growth = map.get_yield(cell)
		var value = damage + floori((10 - growth) / 4.0)
		map.total_trees_from_treants += map.increase_yield(cell, value)
		if damage >= 10:
			actions -= 1
		elif damage > 0:
			actions -= 0.5
	map.total_deaths_to_treants += previous_villager_amount - len(map.villagers)

func convert_to_forest():
	var diffs = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]
	for diff in diffs:
		var cell = cell_position + diff
		map.total_trees_from_treants += map.increase_yield(cell, 20)
	diffs.shuffle()
	for diff in diffs:
		map.spread_forest(cell_position, 40, true)
	emit_signal("has_died", self)

func update_target_location():
	var closest_valid_targets = map.find_closest_matching_cells(cell_position, is_valid_target, null, 20)
	if closest_valid_targets == []:
		target_location = map.find_closest_matching_cell(cell_position, is_good_death_spot, null, 20)
		if cell_position == target_location or target_location == null:
			convert_to_forest()
	
	var current_best_value = 0
	for valid_target in closest_valid_targets:
		var target_value = evaluate_for_buildings(valid_target)
		if target_location == null or target_value > current_best_value:
			target_location = valid_target
			current_best_value = target_value

func is_valid_target(cell: Vector2i, _extra):
	return cell != cell_position and evaluate_for_buildings(cell) > 0

func evaluate_for_buildings(cell: Vector2i):
	var value = 0
	for diff in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
		value += map.get_building_progress(cell + diff)
	return value

func is_good_death_spot(cell: Vector2i, _extra):
	var value = 0
	for diff in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
		if map.is_valid_tile(cell + diff) and not map.is_forest(cell + diff):
			value += 1
	return value >= 3

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
	update_position()

func get_distance_to(cell: Vector2i):
	var path = cell - cell_position
	return abs(path.x) + abs(path.y)

func update_position():
	position.x = cell_position.x * map.tile_set.tile_size.x
	position.y = cell_position.y * map.tile_set.tile_size.y

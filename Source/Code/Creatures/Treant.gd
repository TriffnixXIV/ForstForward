extends Creature
class_name Treant

var actions = 0
var lifespan = 0
var lifespan_left = 0
var death_spread = 0

signal attacked
signal grown_trees
signal has_died

func prepare_turn(action_amount: int):
	actions = action_amount

func act():
	if actions <= 0:
		return false
	
	if target_location == null or target_location == cell_position or not is_valid_target(target_location):
		update_target_location()
	
	if target_location != null:
		if target_location != cell_position:
			move(0)
	
	stomp()
	actions -= 1
	
	if map.treants.has_lifespan:
		lifespan_left -= 1
		if lifespan_left <= 0:
			convert_to_forest()
			return false
	
	return actions > 0

func stomp():
	var previous_villager_amount = len(map.villagers.villagers)
	for diff in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
		var cell = cell_position + diff
		var damage = map.get_building_progress(cell)
		var growth = map.get_yield(cell)
		var value = min(6, damage + floori((10 - growth) / 4.0))
		map.treants.trees += map.increase_yield(cell, value)
	
		if damage > 0: emit_signal("attacked")
	map.treants.kills += previous_villager_amount - len(map.villagers.villagers)

func set_lifespan(new_lifespan: int):
	lifespan_left += max(0, new_lifespan - lifespan)
	lifespan = new_lifespan
	lifespan_left = min(lifespan_left, lifespan)

func convert_to_forest():
	var previous_villager_amount = len(map.villagers.villagers)
	var diffs = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]
	diffs.shuffle()
	for diff in diffs:
		map.spread_forest(cell_position, death_spread, true, "treant")
	map.treants.kills += previous_villager_amount - len(map.villagers.villagers)
	actions = 0
	
	emit_signal("grown_trees")
	emit_signal("has_died", self)

func update_target_location():
	var target_updated = false
	var closest_valid_targets = map.find_closest_matching_cells(cell_position, is_valid_target, null, 20, false, 2)
	var current_value = evaluate_for_buildings(cell_position)
	
	if closest_valid_targets == [] and current_value <= 0:
		target_location = map.find_closest_matching_cell(cell_position, is_good_death_spot, null, 20, false, 2)
		if cell_position == target_location or target_location == null:
			convert_to_forest()
		elif target_location != null:
			target_updated = true
	elif current_value <= 0:
		target_location = null
	
	for valid_target in closest_valid_targets:
		var distance = map.last_distance_map[valid_target.x][valid_target.y]
		var target_value = evaluate_for_buildings(valid_target) - distance + 1
		if target_location == null or target_value > current_value:
			target_location = valid_target
			current_value = target_value
			target_updated = true
	
	if target_updated:
		inverse_path = map.pathing.get_move_sequence(map.last_distance_map, target_location, cell_position, 0, 2)

func is_valid_target(cell: Vector2i, _extra = null):
	return evaluate_for_buildings(cell) > evaluate_for_buildings(cell_position)

func evaluate_for_buildings(cell: Vector2i):
	var value = 0
	for diff in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
		if not map.is_walkable(cell + diff):
			return 0
		if map.get_building_progress(cell + diff) > 0:
			value += 1
	return min(3, value)

func is_good_death_spot(cell: Vector2i, _extra):
	var value = 0
	for diff in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
		if not map.is_walkable(cell + diff):
			return 0
		if not map.is_forest(cell + diff):
			value += 1
	return value >= 3

extends Node2D
class_name Villager

@export var villager_texture: Texture2D
@export var horst_texture: Texture2D
var is_devil = false # only true for villagers that got real
var blast_cooldown = 6
var current_blast_cooldown = 0

var map: Map
var cell_position
var home_cell
var looking_for_home = false

var carried_wood = 0

var actions = 0

enum State {idle, getting_wood, building}
var state = State.idle
var target_location

var target_wood_source
var target_build_site
var target_building_spot

signal moved
signal chopped_tree
signal built_house

func reset():
	state = State.idle
	
	current_blast_cooldown = 0
	carried_wood = 0
	
	actions = 0
	
	cell_position = home_cell
	update_position()
	
	target_location = null
	target_wood_source = null
	target_build_site = null
	target_building_spot = null
	
	if is_devil:
		unget_real()

func prepare_turn(action_amount: int):
	actions = action_amount

func end_turn():
	if is_devil:
		current_blast_cooldown = max(0, current_blast_cooldown - 1)
		update_sparks()

func act():
	if actions <= 0:
		return false
	
	update_state()
	
	match state:
		State.getting_wood:
			if get_distance_to(target_location) > 1:
				move(target_location, 1)
			else:
				chop_tree(target_location)
		
		State.building:
			if get_distance_to(target_location) > 1:
				move(target_location, 1)
			elif map.get_building_progress(target_location) < 10:
				if map.get_yield(target_location) > 0:
					if can_blast() and wants_to_blast(target_location):
						blast(target_location)
					else:
						chop_tree(target_location)
				else:
					build_house(target_location)
		
		State.idle:
			if home_cell != null:
				move(home_cell, 0)
	
	actions -= 1
	return actions > 0

func update_state():
	set_state(state)

func set_state(new_state: State):
	match new_state:
		State.idle:
			if carried_wood < 10:
				set_state(State.getting_wood)
			else:
				set_state(State.building)
		State.getting_wood:
			if wants_to_finish_house():
				set_state(State.building)
			elif carried_wood < 10:
				update_target_wood_source()
				target_location = target_wood_source
				state = State.getting_wood if target_location != null else State.idle
			else: # carried_wood >= 10:
				set_state(State.building)
		State.building:
			if carried_wood > 0:
				state = State.building
				if wants_to_finish_house():
					target_location = target_build_site
					if target_location == null:
						state = State.idle
				else:
					update_target_building_spot()
					target_location = target_building_spot
					if target_location == null:
						state = State.idle
			else:
				set_state(State.getting_wood)

func chop_tree(cell: Vector2i):
	carried_wood += 1
	map.villagers.chops -= map.decrease_yield(cell, 1)
	emit_signal("chopped_tree")

func build_house(cell: Vector2i):
	carried_wood -= 1
	map.increase_building_progress(cell, 1)
	emit_signal("built_house")

func blast(cell: Vector2i):
	map.blast_with_fire(cell)
	current_blast_cooldown = blast_cooldown
	update_sparks()

func update_target_wood_source():
	# take wood in the immediate vicinity of home
	if home_cell != null:
		var wood_at_home = search_wood_source_at(home_cell, 2)
		if wood_at_home != null:
			target_wood_source = wood_at_home
			return
	
	# take the next best wood source around you
	var wood_here = search_wood_source_at(cell_position, 5, 0)
	if wood_here != null:
		target_wood_source = wood_here
		return
	
	# if the wood source became invalid, search one next to previous one
	if target_wood_source != null and map.get_yield(target_wood_source) == 0:
		target_wood_source = search_wood_source_at(target_wood_source, 2)
	
	# if you don't have a wood source, look at a larger distance around you
	if target_wood_source == null:
		target_wood_source = search_wood_source_at(cell_position, 30, 6)

func search_wood_source_at(cell: Vector2i, max_distance: int, min_distance: int = 1):
	var wood_sources = []
	var distance = max(min_distance, map.cell_tree_distance_map[cell.x][cell.y])
	var distance_threshhold = null
	var has_found_wood_source = false
	while distance <= max_distance:
		if distance == 0:
			if is_wood_source(cell):
				distance_threshhold = get_distance_to(cell)
				wood_sources = [cell]
		for d1 in distance:
			var d2 = distance - d1
			for diff in [Vector2i(d1, d2), Vector2i(-d2, d1), Vector2i(-d1, -d2), Vector2i(d2, -d1)]:
				var target_cell = cell + diff
				if is_wood_source(target_cell):
					if not has_found_wood_source:
						has_found_wood_source = true
						map.set_cell_tree_distance(cell, distance)
					var distance_to_cell = get_distance_to(target_cell)
					if distance_threshhold == null or distance_to_cell < distance_threshhold:
						distance_threshhold = distance_to_cell
						wood_sources = [target_cell]
					elif distance_to_cell == distance_threshhold:
						wood_sources.append(target_cell)
		distance += 1
	
	if len(wood_sources) > 0:
		return wood_sources[randi_range(0, len(wood_sources) - 1)]
	else:
		return null

func is_wood_source(cell: Vector2i):
	return map.get_yield(cell) > 0

func update_target_build_site():
	if target_build_site != null and (map.get_building_progress(target_build_site) in [0, 10]):
		target_build_site = null
	
	if target_build_site != null:
		var alternative_max_distance = min(get_distance_to(target_build_site), 2)
		var alternative = map.find_closest_cell_of_type(cell_position, [map.TileType.build_site], alternative_max_distance)
		if alternative != null:
			target_build_site = alternative
	else:
		target_build_site = map.find_closest_cell_of_type(cell_position, [map.TileType.build_site], 7)

func update_target_building_spot():
	if target_building_spot != null and not map.is_plains(target_building_spot):
		target_building_spot = null
	
	if target_building_spot == null:
		target_building_spot = find_building_spot()

func wants_to_finish_house():
	update_target_build_site()
	if target_build_site != null:
		var move_actions_needed = get_move_actions_needed_to_reach(target_build_site)
		var wood_needed = 10 - map.get_building_progress(target_build_site)
		var required_wood = min(
			2 * move_actions_needed + 1,
			max(wood_needed,
				2 * move_actions_needed - 3))
		
		# move_dist 0  1  2  3  4  5  6
		#           |  |  |  |  |  |  |
		# needs 9:  1  3  5  7  9  9  9
		# needs 8:  1  3  5  7  8  8  9
		# needs 7:  1  3  5  7  7  7  9
		# needs 6:  1  3  5  6  6  7  9
		# needs 5:  1  3  5  5  5  7  9
		# needs 4:  1  3  4  4  5  7  9
		# needs 3:  1  3  3  3  5  7  9
		# needs 2:  1  2  2  3  5  7  9
		# needs 1:  1  1  1  3  5  7  9
		return carried_wood >= required_wood
	else:
		return false

func find_building_spot():
	var good_spots = find_good_building_spots()
	if len(good_spots) > 0:
		return good_spots[randi_range(0, len(good_spots) - 1)]
	else:
		return map.find_closest_cell_of_type(cell_position, [map.TileType.growth, map.TileType.forest], 5)

func find_good_building_spots():
	var good_spots = []
	var distance = 0
	
	var max_value = 28 # the highest possible result of the evaluation function
	var max_distance = 20
	var distance_to_home = get_distance_from_home(cell_position)
	var value_threshhold = max_value - (max_distance + distance_to_home)
	
	while max_value - (distance + distance_to_home) > value_threshhold:
		if distance == 0:
			var cell_value = evaluate_building_spot(cell_position)
			if cell_value > 0:
				var score = cell_value - (distance + floori(get_distance_from_home(cell_position) / 2.0))
				if score > value_threshhold:
					good_spots = [cell_position]
					value_threshhold = score
				elif score == value_threshhold:
					good_spots.append(cell_position)
		for d1 in distance:
			var d2 = distance - d1
			for diff in [Vector2i(d1, d2), Vector2i(-d2, d1), Vector2i(-d1, -d2), Vector2i(d2, -d1)]:
				var target_cell = cell_position + diff
				var cell_value = evaluate_building_spot(target_cell)
				if cell_value > 0:
					var score = cell_value - (distance + floori(get_distance_from_home(target_cell) / 2.0))
					if score > value_threshhold:
						good_spots = [target_cell]
						value_threshhold = score
					elif score == value_threshhold:
						good_spots.append(target_cell)
		distance += 1
	return good_spots

func evaluate_building_spot(cell: Vector2i):
	if map.is_house(cell) or not map.is_valid_tile(cell):
		return 0
	else:
		var value = 0
		
		if map.is_plains(cell):
			value += 5
		elif map.get_yield(cell) > 0:
			if can_blast():
				value += 1
			else:
				value -= map.get_yield(cell)
		
		var has_house_neighbor = false
		for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			if map.is_forest(cell + diff) and not can_blast():
				value -= 2
			elif map.is_house(cell + diff):
				if has_house_neighbor:
					value += 1
				else:
					value += 20
					has_house_neighbor = true
		return value

func move(target_cell: Vector2i, target_distance: int):
	var path = target_cell - cell_position
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

func update_position():
	position.x = cell_position.x * map.tile_set.tile_size.x
	position.y = cell_position.y * map.tile_set.tile_size.y

func get_move_actions_needed_to_reach(cell: Vector2i):
	return max(0, get_distance_to(cell) - 1)

func get_distance_to(cell: Vector2i):
	var path = cell - cell_position
	return abs(path.x) + abs(path.y)

func get_distance_from_home(cell: Vector2i):
	if home_cell == null:
		return 0
	else:
		var path = cell - home_cell
		return abs(path.x) + abs(path.y)

# devilish stuff

func get_real():
	$Sprite.texture = horst_texture
	is_devil = true
	update_sparks()

func unget_real():
	$Sprite.texture = villager_texture
	is_devil = false
	update_sparks()

func update_sparks():
	if can_blast():
		$Sparks.visible = true
	else:
		$Sparks.visible = false

func can_blast():
	return is_devil and current_blast_cooldown <= 0

func wants_to_blast(target_cell: Vector2i):
	var tree_factor = 4 * map.get_yield(target_cell)
	var building_factor = 4 * map.get_building_progress(target_cell)
	for i in 3:
		var distance = i + 1
		var weight = 3 - i
		for d1 in distance:
			var d2 = distance - d1
			for diff in [Vector2i(d1, d2), Vector2i(-d2, d1), Vector2i(-d1, -d2), Vector2i(d2, -d1)]:
				var cell = target_cell + diff
				if map.is_valid_tile(cell):
					if distance == 3:
						tree_factor += weight * min(5, map.get_yield(cell))
						building_factor += weight * min(3, map.get_building_progress(cell))
					else:
						tree_factor += weight * map.get_yield(cell)
						building_factor += weight * min(6, map.get_building_progress(cell))
	
	return tree_factor > building_factor * 4 and tree_factor > 100

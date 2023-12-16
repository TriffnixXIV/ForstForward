extends Creature
class_name Villager

var villager_texture: Texture2D = preload("res://Images/VillagerStuff/Horst.png")
var horst_texture: Texture2D = preload("res://Images/VillagerStuff/DaRealHorst.png")
var is_devil = false # only true for villagers that got real
var blast_cooldown = 6
var current_blast_cooldown = 0

var home_cell
var looking_for_home = false

var carried_wood = 0

var actions = 0

enum State {idle, getting_wood, building}
var state = State.idle

var target_approach_distance

var target_wood_source
var target_build_location
var target_blast_location

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
	target_blast_location = null
	
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
	
	if can_blast() and wants_to_blast():
		blast(target_blast_location)
		actions -= 1
		return actions > 0
	
	match state:
		State.getting_wood:
			if get_distance_to(target_location) > target_approach_distance:
				move(target_approach_distance)
			else:
				chop_tree(target_location)
		
		State.building:
			if get_distance_to(target_location) > target_approach_distance:
				move(target_approach_distance)
			elif map.get_building_progress(target_location) < 10:
				if map.get_yield(target_location) > 0:
					chop_tree(target_location)
				else:
					build_house(target_location)
		
		State.idle:
			if home_cell != null:
				target_location = home_cell
				move(0)
	
	actions -= 1
	return actions > 0

func update_state():
	set_state(state)

func set_state(new_state: State):
	match new_state:
		State.idle:
			set_state(State.getting_wood)
		State.getting_wood:
			if wants_to_build():
				set_state(State.building)
			else:
				target_approach_distance = 1
				inverse_path = []
				update_target_wood_source()
				target_location = target_wood_source
				state = State.getting_wood if target_location != null else State.idle
		State.building:
			if wants_to_build():
				target_approach_distance = 1
				target_location = target_build_location
				state = State.building
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
	var wood_here = search_wood_source_at(cell_position, 5)
	if wood_here != null:
		target_wood_source = wood_here
		return
	
	# if the wood source became invalid, search one next to previous one
	if target_wood_source != null and map.get_yield(target_wood_source) == 0:
		target_wood_source = search_wood_source_at(target_wood_source, 2)
	
	# if you don't have a wood source, move along the cell-tree-distance-map
	if target_wood_source == null:
		var tree_distance = map.tree_distance_map[cell_position.x][cell_position.y]
		var closer_ones = []
		for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			var cell = cell_position + diff
			if map.is_walkable(cell) and map.tree_distance_map[cell.x][cell.y] < tree_distance:
				closer_ones.append(diff)
		
		if len(closer_ones) > 0:
			# not necessarily actually wood, but good enough
			next_move = closer_ones.pick_random()
			target_approach_distance = 0

func search_wood_source_at(cell: Vector2i, max_distance: int):
	var wood_sources = []
	var distance = 0
	distance_map = map.pathing.get_empty_distance_map()
	distance_map[cell.x][cell.y] = 0
	var distance_threshhold = null
	var has_found_wood_source = false
	var remaining_cells = [cell]
	var next_cells = []
	while distance <= max_distance and remaining_cells != []:
		for target_cell in remaining_cells:
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
		for target_cell in remaining_cells:
			for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
				var neighbor = target_cell + diff
				if map.is_walkable(neighbor) and distance_map[neighbor.x][neighbor.y] == -1:
					distance_map[neighbor.x][neighbor.y] = distance
					next_cells.append(neighbor)
		
		remaining_cells = next_cells.duplicate()
		next_cells = []
	
	if len(wood_sources) > 0:
		return wood_sources.pick_random()
	else:
		return null

func is_wood_source(cell: Vector2i):
	return map.get_yield(cell) > 0

func wants_to_build():
	update_build_location()
	return target_build_location != null

func update_build_location():
	if carried_wood == 0:
		inverse_path = []
		target_build_location = null
		return
	
	if target_build_location != null and map.get_building_progress(target_build_location) == 10:
		inverse_path = []
		target_build_location = null
	
	if target_build_location == null:
		target_build_location = find_build_location()
		if target_build_location != null:
			inverse_path = map.pathing.get_move_sequence(distance_map, target_build_location, cell_position)

func find_build_location():
	var good_spots = find_good_build_locations()
	if len(good_spots) > 0:
		return good_spots.pick_random()
	elif carried_wood >= 10:
		return home_cell
	else:
		return null

func find_good_build_locations():
	var good_spots = []
	var distance = 0
	
	var requirement_threshold = carried_wood
	
	var remaining_cells = [cell_position]
	var next_cells = []
	distance_map = map.pathing.get_empty_distance_map()
	distance_map[cell_position.x][cell_position.y] = 0
	while remaining_cells != [] and requirement_threshold >= 2 * max(0, distance - 1) - 3:
		for cell in remaining_cells:
			var required_wood = get_required_wood(cell)
			if required_wood > 0:
				if requirement_threshold > required_wood:
					good_spots = [cell]
					requirement_threshold = required_wood
				elif requirement_threshold == required_wood:
					good_spots.append(cell)
		
		distance += 1
		for cell in remaining_cells:
			for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
				var target_cell = cell + diff
				if map.is_walkable(target_cell):
					var target_distance = distance_map[target_cell.x][target_cell.y]
					if target_distance == -1 or target_distance > distance:
						distance_map[target_cell.x][target_cell.y] = distance
						next_cells.append(target_cell)
		
		remaining_cells = next_cells.duplicate()
		next_cells = []
	
	return good_spots

func get_required_wood(cell):
	if not map.is_buildable(cell):
		return 0
	
	var move_actions_needed = get_move_actions_needed_to_reach(cell)
	var wood_needed = 10 - map.get_building_progress(cell)
	
	match wood_needed:
		0:	return 0
		10:	move_actions_needed += 2
	
	# move_dist 0  1  2  3  4  5  6  7
	#           |  |  |  |  |  |  |  |
	# needs 10: 5  7  9 10 10 11 13 15
	# needs 9:  1  3  5  7  9  9  9 11
	# needs 8:  1  3  5  7  8  8  9 11
	# needs 7:  1  3  5  7  7  7  9 11
	# needs 6:  1  3  5  6  6  7  9 11
	# needs 5:  1  3  5  5  5  7  9 11
	# needs 4:  1  3  4  4  5  7  9 11
	# needs 3:  1  3  3  3  5  7  9 11
	# needs 2:  1  2  2  3  5  7  9 11
	# needs 1:  1  1  1  3  5  7  9 11
	var required_wood = clamp(wood_needed, 2 * move_actions_needed - 3, 2 * move_actions_needed + 1)
	
	if wood_needed >= 10:
		var has_house_neighbor = false
		for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			if map.is_forest(cell + diff) and not can_blast():
				required_wood += 2
			elif map.is_house(cell + diff):
				has_house_neighbor = true
		
		if not has_house_neighbor:
			required_wood += 20
	
	return required_wood

func get_move_actions_needed_to_reach(cell: Vector2i):
	return max(0, get_distance_to(cell) - 1)

func get_distance_from_home(cell: Vector2i):
	if home_cell == null:
		return 0
	else:
		var direct_path = cell - home_cell
		return abs(direct_path.x) + abs(direct_path.y)

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

func wants_to_blast():
	update_blast_location()
	return target_blast_location != null

func update_blast_location():
	var good_targets = []
	var threshold: int = 0
	for diff in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
		var value = evaluate_blast_location(cell_position + diff)
		if value > threshold:
			good_targets = [cell_position + diff]
			threshold = value
		elif value == threshold:
			good_targets.append(cell_position + diff)
	
	if len(good_targets) > 0:
		target_blast_location = good_targets.pick_random()
	else:
		target_blast_location = null

func evaluate_blast_location(target_cell: Vector2i):
	var value = -15
	
	value += carried_wood
	if map.is_forest(target_cell):
		value += 1
	if map.get_building_progress(target_cell) > 0:
		value -= 1
	for i in 2:
		var distance = i + 1
		for d1 in distance:
			var d2 = distance - d1
			for diff in [Vector2i(d1, d2), Vector2i(-d2, d1), Vector2i(-d1, -d2), Vector2i(d2, -d1)]:
				var cell = target_cell + diff
				if map.is_forest(cell):
					value += 1
				if map.get_building_progress(cell) > 0:
					value -= 1
	
#	map.set_cell_label(target_cell, str(value))
	return value

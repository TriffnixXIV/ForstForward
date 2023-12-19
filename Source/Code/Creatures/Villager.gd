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
			if next_move != null:
				move()
			else:
				chop_tree(target_wood_source)
		
		State.building:
			if next_move != null:
				move()
			elif map.get_building_progress(target_build_location) < 10:
				if map.get_yield(target_build_location) > 0:
					chop_tree(target_build_location)
				else:
					build_house(target_build_location)
		
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
			elif wants_to_chop():
				state = State.getting_wood
			else:
				state = State.idle
		State.building:
			if wants_to_build():
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

func wants_to_chop():
	next_move = null
	target_wood_source = null
	
	var good_moves = []
	var good_wood_sources = []
	for diff in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
		var cell = cell_position + diff
		if map.get_yield(cell) > 0:
			good_wood_sources.append(cell)
		if map.is_walkable(cell) and map.pathing.tree_distance_map[cell.x][cell.y] < map.pathing.tree_distance_map[cell_position.x][cell_position.y]:
			good_moves.append(diff)
	
	if len(good_wood_sources) > 0:
		target_wood_source = good_wood_sources.pick_random()
		return true
	elif len(good_moves) > 0:
		next_move = good_moves.pick_random()
		return true
	else:
		return false

func wants_to_build():
	if map.pathing.no_build_site(cell_position) and map.is_buildable(cell_position) and not map.is_house(cell_position):
		target_build_location = cell_position
		return carried_wood + map.get_yield(cell_position) >= 10
	
	next_move = null
	target_build_location = null
	
	var good_moves = []
	var good_build_spots = []
	var build_threshold = null
	for diff in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
		var cell = cell_position + diff
		if map.is_valid_tile(cell) and carried_wood >= map.pathing.build_site_distance_map[cell.x][cell.y]:
			if map.pathing.build_site_distance_map[cell.x][cell.y] == 1:
				var progress = map.get_building_progress(cell)
				if build_threshold == null or progress > build_threshold:
					good_build_spots = [cell]
					build_threshold = progress
				elif progress == build_threshold:
					good_build_spots.append(cell)
			elif map.is_walkable(cell) and map.pathing.build_site_distance_map[cell.x][cell.y] < map.pathing.build_site_distance_map[cell_position.x][cell_position.y]:
				good_moves.append(diff)
	
	if len(good_build_spots) > 0:
		target_build_location = good_build_spots.pick_random()
		return true
	if len(good_moves) > 0:
		next_move = good_moves.pick_random()
		return true
	else:
		return false

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

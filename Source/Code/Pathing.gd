extends Node
class_name Pathing

var map: Map

var unwalkable_map
var cell_target_distance_map

var update_semaphore: Semaphore
var update_thread: Thread
var do_updates: bool = true

var expand_steps: int = 0
var fix_steps: int = 0
var shown_cell: Vector2i = Vector2i(8, 4)

func _ready():
	update_semaphore = Semaphore.new()
	update_thread = Thread.new()
	update_thread.start(_update_thread_function)

func initialize() -> void:
	unwalkable_map = []
	cell_target_distance_map = []
	for x in map.width:
		unwalkable_map.append([])
		cell_target_distance_map.append([])
		for y in map.height:
			unwalkable_map[x].append(-1)
			cell_target_distance_map[x].append([])
			initialize_cell(Vector2i(x, y))
	reset()

func initialize_cell(cell: Vector2i):
	for x in map.width:
		cell_target_distance_map[cell.x][cell.y].append([])
		for y in map.height:
			var base_distance = abs(cell.x - x) + abs(cell.y - y)
			cell_target_distance_map[cell.x][cell.y][x].append(base_distance)

func reset() -> void:
	for x in map.width:
		for y in map.height:
			for x_2 in map.width:
				for y_2 in map.height:
					cell_target_distance_map[x][y][x_2][y_2] = abs(x - x_2) + abs(y - y_2)

func clear() -> void:
	[].duplicate()
	for x in map.width:
		for y in map.height:
			cell_target_distance_map[x][y] = unwalkable_map.duplicate(true)
	
	for x in map.width:
		for y in map.height:
			map.set_cell_label(Vector2i(x, y), str(cell_target_distance_map[10][10][x][y]))

func update() -> void:
	update_semaphore.post()

func _update_thread_function():
	while do_updates:
		update_semaphore.wait()
		if not do_updates:
			break
		update_map()

func update_map() -> void:
	print("start")
	var starting_time = Time.get_unix_time_from_system()
	if cell_target_distance_map == null:
		initialize()
	
	var is_water_level = map.is_water_level()
	if is_water_level:
		clear()
	else:
		reset()
	
	expand_steps = 0
	fix_steps = 0
	
	for x in map.width:
		for y in map.height:
			if is_water_level:
				cell_target_distance_map[x][y][x][y] = 0
				expand_cell(Vector2i(x, y), Vector2i(x, y))
			elif not map.is_walkable(Vector2i(x, y)):
				cell_target_distance_map[x][y] = unwalkable_map.duplicate(true)
				for x_2 in map.width:
					for y_2 in map.height:
						fix_cell(Vector2i(x_2, y_2), Vector2i(x, y))
	
	print("fix steps: ", fix_steps, " expand steps: ", expand_steps)
	print("stop: ", Time.get_unix_time_from_system() - starting_time)

func expand_cell(start: Vector2i, cell: Vector2i) -> void:
	var distance = cell_target_distance_map[start.x][start.y][cell.x][cell.y]
	if distance == -1:
		return
	
	var remaining_cells = [cell]
	var next_cells = []
	
	while remaining_cells != []:
		distance += 1
		for target_cell in remaining_cells:
			expand_steps += 1
			
			for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
				var neighbor = target_cell + diff
				if map.is_walkable(neighbor):
					var current_distance = cell_target_distance_map[start.x][start.y][neighbor.x][neighbor.y]
					if current_distance == -1 or distance < current_distance:
						cell_target_distance_map[start.x][start.y][neighbor.x][neighbor.y] = distance
						next_cells.append(neighbor)
		
		remaining_cells = next_cells.duplicate()
		next_cells = []

func fix_cell(start: Vector2i, cell: Vector2i) -> void:
	if not map.is_walkable(start):
		return
	
	var current_distance = cell_target_distance_map[start.x][start.y][cell.x][cell.y]
	var remaining_cells = [cell]
	var next_cells = []
	var cells_to_expand = []
	
	while remaining_cells != []:
		for current_cell in remaining_cells:
			fix_steps += 1
			
			current_distance = cell_target_distance_map[start.x][start.y][current_cell.x][current_cell.y]
			if not map.is_walkable(current_cell) and current_distance != -1:
				cell_target_distance_map[start.x][start.y][current_cell.x][current_cell.y] = -1
				for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
					var neighbor = current_cell + diff
					if map.is_walkable(neighbor):
						next_cells.append(neighbor)
			
			elif map.is_walkable(current_cell) and current_distance > 0:
				var closest_neighbor = null
				var further_neighbors = []
				for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
					var neighbor = current_cell + diff
					if map.is_walkable(neighbor):
						var other_distance = cell_target_distance_map[start.x][start.y][neighbor.x][neighbor.y]
						if other_distance != -1:
							if other_distance < current_distance:
								closest_neighbor = neighbor
								current_distance = other_distance + 1
							else:
								further_neighbors.append(neighbor)
				
				if closest_neighbor == null:
					cell_target_distance_map[start.x][start.y][current_cell.x][current_cell.y] = -1
					for neighbor in further_neighbors:
						next_cells.append(neighbor)
				else:
					cells_to_expand.append(current_cell)
		
		remaining_cells = next_cells.duplicate()
		next_cells = []
	
	for cell_to_expand in cells_to_expand:
		expand_cell(start, cell_to_expand)

func show_distance_map(cell: Vector2i):
	shown_cell = cell
	for x in map.width:
		for y in map.height:
			map.set_cell_label(Vector2i(x, y), str(cell_target_distance_map[cell.x][cell.y][x][y]))

func show_path(cell: Vector2i):
	if map.is_valid_tile(cell) and cell_target_distance_map:
		map.reset_cell_label_highlights()
		map.highlight_cell_label(cell)
		while cell_target_distance_map[shown_cell.x][shown_cell.y][cell.x][cell.y] > 0:
			var move = get_move(cell, shown_cell)
			cell += move
			map.highlight_cell_label(cell)

func get_move(start: Vector2i, target: Vector2i, approach_distance: int = 0) -> Vector2i:
	var direct_path = target - start
	var move = Vector2i(0, 0)
	if abs(direct_path.x) + abs(direct_path.y) > approach_distance:
		var distance_map = cell_target_distance_map[target.x][target.y]
		var good_moves = []
		var current_distance = distance_map[start.x][start.y]
		for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			var neighbor = start + diff
			if map.is_valid_tile(neighbor):
				var neighbor_distance = distance_map[neighbor.x][neighbor.y]
				if neighbor_distance != -1 and neighbor_distance < distance_map[start.x][start.y]:
					if neighbor_distance < current_distance:
						good_moves = [diff]
						current_distance = neighbor_distance
					elif neighbor_distance == current_distance:
						good_moves.append(diff)
		
		if len(good_moves) > 0:
			move = good_moves.pick_random()
	
	return move

func _exit_tree():
	do_updates = false
	update_semaphore.post()
	update_thread.wait_to_finish()

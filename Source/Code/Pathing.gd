extends Node
class_name Pathing

var map: Map

var base_cell_target_distance_map
var cell_target_distance_map

func initialize() -> void:
	base_cell_target_distance_map = []
	for x in map.width:
		base_cell_target_distance_map.append([])
		for y in map.height:
			base_cell_target_distance_map[x].append([])
			initialize_cell(Vector2i(x, y))
	reset()

func initialize_cell(cell: Vector2i):
	for x in map.width:
		base_cell_target_distance_map[cell.x][cell.y].append([])
		for y in map.height:
			var base_distance = abs(cell.x - x) + abs(cell.y - y)
			base_cell_target_distance_map[cell.x][cell.y][x].append(base_distance)

func reset() -> void:
	cell_target_distance_map = base_cell_target_distance_map

func update() -> void:
	var starting_time = Time.get_unix_time_from_system()
	if cell_target_distance_map == null:
		initialize()
	else:
		reset()
	
	for x in map.width:
		for y in map.height:
			update_cell(Vector2i(x, y))
	
	for x in map.width:
		for y in map.height:
			map.set_cell_label(Vector2i(x, y), str(cell_target_distance_map[0][0][x][y]))
	
	print(Time.get_unix_time_from_system() - starting_time)

func update_cell(cell: Vector2i) -> void:
	var x = cell.x
	var y = cell.y
	
	var remaining_cells = []
	if not map.is_walkable(cell):
		remaining_cells.append(cell)
		cell_target_distance_map[x][y][cell.x][cell.y] = -1
	
	var distance = 0
	while remaining_cells != []:
		var target_cell = remaining_cells.pop_back()
		for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			var new_cell = target_cell + diff
			if map.is_walkable(new_cell):
				var current_distance = cell_target_distance_map[x][y][new_cell.x][new_cell.y]
				if (current_distance == -1 or distance + 1 < current_distance):
					cell_target_distance_map[x][y][new_cell.x][new_cell.y] = distance + 1
					remaining_cells.append(new_cell)

func get_move(start: Vector2i, target: Vector2i, approach_distance: int = 0) -> Vector2i:
	var path = target - start
	var move = Vector2i(0, 0)
	if abs(path.x) + abs(path.y) > approach_distance:
		if abs(path.x) == 0:
			move.y = path.y / abs(path.y)
		elif abs(path.y) == 0:
			move.x = path.x / abs(path.x)
		else:
			if randi_range(0, abs(path.x) + abs(path.y) - 1) < abs(path.x):
				move.x = path.x / abs(path.x)
			else:
				move.y = path.y / abs(path.y)
	
	return move

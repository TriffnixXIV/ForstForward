extends Node
class_name Pathing

var map: Map

var unwalkable_map
var cell_target_distance_map

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
	print("start")
	var starting_time = Time.get_unix_time_from_system()
	if cell_target_distance_map == null:
		initialize()
	
	var walkable_tiles = 0
	for x in map.width:
		for y in map.height:
			if map.is_walkable(Vector2i(x, y)):
				walkable_tiles += 1
	
	var is_water_level = walkable_tiles < map.width * map.height / 2.0
	if is_water_level:
		clear()
	else:
		reset()
	
	var cells_to_expand = []
	for x in map.width:
		for y in map.height:
#			print(x, " - ", y)
			if is_water_level:
				expand_cell(Vector2i(x, y), Vector2i(x, y), 0)
			else:
				cells_to_expand += fix_cell(Vector2i(x, y), Vector2i(x, y))
	
	for entry in cells_to_expand:
		var start = entry[0]
		var cell = entry[1]
		expand_cell(start, cell, cell_target_distance_map[start.x][start.y][cell.x][cell.y])
	
	for x in map.width:
		for y in map.height:
			map.set_cell_label(Vector2i(x, y), str(cell_target_distance_map[0][0][x][y]))
	
	print("stop: ", Time.get_unix_time_from_system() - starting_time)

func expand_cell(start: Vector2i, cell: Vector2i, distance: int) -> void:
		var remaining_cells = [cell]
		var next_cells = []
		while remaining_cells != []:
			for i in len(remaining_cells):
				var target_cell = remaining_cells[i]
				if map.is_walkable(target_cell):
					var current_distance = cell_target_distance_map[start.x][start.y][target_cell.x][target_cell.y]
					if current_distance == -1 or distance < current_distance:
						cell_target_distance_map[start.x][start.y][target_cell.x][target_cell.y] = distance
						
						for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
							next_cells.append(target_cell + diff)
			
			remaining_cells = next_cells.duplicate()
			next_cells = []
			distance += 1

func fix_cell(start: Vector2i, cell: Vector2i) -> Array:
	var current_distance = cell_target_distance_map[start.x][start.y][cell.x][cell.y]
	var cells_to_expand: Array = []
	
	if not map.is_walkable(start) and current_distance != -1:
		print("unwalkable: ", cell)
		cell_target_distance_map[start.x][start.y] = unwalkable_map.duplicate(true)
		for x in map.width:
			for y in map.height:
				cell_target_distance_map[x][y][cell.x][cell.y] = -1
				for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
					var new_cell = cell + diff
					if map.is_walkable(new_cell):
						cells_to_expand += fix_cell(Vector2i(x, y), new_cell)
	
	elif map.is_walkable(cell):
		if current_distance == 0:
			return []
		
		var closer_neighbors = []
		var further_neighbors = []
		for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			var neighbor = cell + diff
			if map.is_walkable(neighbor):
				var other_distance = cell_target_distance_map[start.x][start.y][neighbor.x][neighbor.y]
				if other_distance != -1:
					if other_distance < current_distance:
						closer_neighbors.append(neighbor)
					else:
						further_neighbors.append(neighbor)
		
		if len(closer_neighbors) == 0:
			if start == Vector2i(0, 0): print("invalid: ", cell, " -> ", further_neighbors)
			cell_target_distance_map[start.x][start.y][cell.x][cell.y] = -1
			for neighbor in further_neighbors:
				cells_to_expand += fix_cell(start, neighbor)
		
		for neighbor in closer_neighbors:
			cells_to_expand.append([start, neighbor])
	
	return cells_to_expand

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

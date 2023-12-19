extends Node
class_name Pathing

var map: Map

var cell_target_distance_map

var tree_distance_map: Array[Array]
var build_site_distance_map: Array[Array]

var expand_steps: int = 0
var fix_steps: int = 0
var shown_cell: Vector2i = Vector2i(4, 4)

var currently_updating: bool = false
signal update_done

func initialize() -> void:
	cell_target_distance_map = []
	for x in map.width:
		cell_target_distance_map.append([])
		for y in map.height:
			cell_target_distance_map[x].append(null)

func reset() -> void:
	for x in map.width:
		for y in map.height:
			cell_target_distance_map[x][y] = null

func add_distance_map(start: Vector2i):
	cell_target_distance_map[start.x][start.y] = get_empty_distance_map()
	cell_target_distance_map[start.x][start.y][start.x][start.y] = 0
	expand_cell(start, start)

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

# currently out of use, would be relevant for placing water during a run
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
			if not map.is_walkable(current_cell):
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
					next_cells += further_neighbors
				else:
					cells_to_expand.append(current_cell)
		
		remaining_cells = next_cells.duplicate()
		next_cells = []
	
	for cell_to_expand in cells_to_expand:
		expand_cell(start, cell_to_expand)

func get_distance(cell: Vector2i, other: Vector2i):
	return cell_target_distance_map[cell.x][cell.y][other.x][other.y]

func get_empty_distance_map(initial_distance: int = -1) -> Array[Array]:
	var distance_map: Array[Array] = []
	var array = []
	array.resize(map.height)
	array.fill(initial_distance)
	for _x in map.width:
		distance_map.append(array.duplicate())
	
	return distance_map

func show_distance_map(cell: Vector2i):
	shown_cell = cell
	map.set_cell_labels(cell_target_distance_map[shown_cell.x][shown_cell.y])

func show_path(cell: Vector2i):
	if map.is_valid_tile(cell) and cell_target_distance_map:
		map.reset_cell_label_highlights()
		map.highlight_cell_label(cell)
		while cell_target_distance_map[shown_cell.x][shown_cell.y][cell.x][cell.y] > 0:
			var move = get_move(cell, shown_cell)
			cell += move
			map.highlight_cell_label(cell)

func get_move(start: Vector2i, target: Vector2i, approach_distance: int = 0, size: int = 1):
	var distance_map = cell_target_distance_map[target.x][target.y]
	return get_move_by_distance_map(distance_map, start, target, approach_distance, size)

func get_move_by_distance_map(distance_map, start: Vector2i, target: Vector2i, approach_distance: int = 0, size: int = 1) -> Vector2i:
	return get_moves(distance_map, start, target, approach_distance, size).pick_random()

func get_moves(distance_map, start: Vector2i, target: Vector2i, approach_distance: int = 0, size: int = 1) -> Array[Vector2i]:
	var direct_path = target - start
	var moves: Array[Vector2i] = [Vector2i(0, 0)]
	if abs(direct_path.x) + abs(direct_path.y) > approach_distance:
		var current_distance = distance_map[start.x][start.y]
		for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			var neighbor = start + diff
			if map.is_walkable(neighbor, size):
				var neighbor_distance = distance_map[neighbor.x][neighbor.y]
				if neighbor_distance != -1 and neighbor_distance < distance_map[start.x][start.y]:
					if neighbor_distance < current_distance:
						moves = [diff]
						current_distance = neighbor_distance
					elif neighbor_distance == current_distance:
						moves.append(diff)
	
	return moves

func get_move_sequence(distance_map, start: Vector2i, target: Vector2i, approach_distance: int = 0, size: int = 1):
	var sequence = []
	var current_cell = start
	while true:
		var move = get_move_by_distance_map(distance_map, current_cell, target, approach_distance, size)
		if move == Vector2i(0, 0):
			break
		current_cell += move
		sequence.append(move)
	
	return sequence

func no_build_site(cell: Vector2i):
	return build_site_distance_map[cell.x][cell.y] == map.width * map.height

func update_build_site_distance_map():
	if build_site_distance_map == []:
		build_site_distance_map = get_empty_distance_map()
	
	var remaining_cells: Array[Vector2i] = []
	for x in map.width:
		for y in map.height:
			var cell = Vector2i(x, y)
			if map.is_build_site(cell):
				build_site_distance_map[x][y] = 1
				remaining_cells.append(cell)
			elif not map.is_walkable(cell):
				build_site_distance_map[x][y] = -1
			else:
				build_site_distance_map[x][y] = map.width * map.height
	
	for x in map.width:
		for y in map.height:
			var cell = Vector2i(x, y)
			if map.is_house(cell):
				for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
					var neighbor = cell + diff
					if map.is_walkable(neighbor) and not map.is_house(neighbor) and not map.is_build_site(neighbor):
						build_site_distance_map[neighbor.x][neighbor.y] = 1
						remaining_cells.append(neighbor)
	
	expand_build_sites(remaining_cells)

func update_house(house_position: Vector2i):
	update_build_site(house_position)
	for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
		update_build_site(house_position + diff)

func update_build_site(build_site_position: Vector2i):
	if not map.is_walkable(build_site_position):
		return
	if map.is_house(build_site_position):
		remove_build_site(build_site_position)
		return
	
	for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
		if map.is_house(build_site_position + diff):
			add_build_site(build_site_position)
			return
	remove_build_site(build_site_position)

func add_build_site(build_site_position: Vector2i):
	build_site_distance_map[build_site_position.x][build_site_position.y] = 1
	expand_build_sites([build_site_position])

func remove_build_site(build_site_position: Vector2i):
	var remaining_cells = [build_site_position]
	var next_cells = []
	var cells_to_expand: Array[Vector2i] = []
	while remaining_cells != []:
		for cell in remaining_cells:
			var neighbors = []
			for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
				var neighbor = cell + diff
				if map.is_walkable(neighbor):
					if build_site_distance_map[neighbor.x][neighbor.y] == build_site_distance_map[cell.x][cell.y] - 2:
						cells_to_expand.append(cell)
						break
					elif build_site_distance_map[neighbor.x][neighbor.y] == 1:
						cells_to_expand.append(neighbor)
					elif build_site_distance_map[neighbor.x][neighbor.y] >= build_site_distance_map[cell.x][cell.y] and (
						build_site_distance_map[neighbor.x][neighbor.y] < map.width * map.height):
						neighbors.append(neighbor)
			
			if cell not in cells_to_expand:
				build_site_distance_map[cell.x][cell.y] = map.width * map.height
				next_cells += neighbors
		
		remaining_cells = next_cells.duplicate()
		next_cells = []
	
	expand_build_sites(cells_to_expand)

func expand_build_sites(cells: Array[Vector2i]):
	var remaining_cells = cells.duplicate()
	var next_cells = []
	while remaining_cells != []:
		for cell in remaining_cells:
			for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
				var target_cell = cell + diff
				if map.is_walkable(target_cell):
					if build_site_distance_map[target_cell.x][target_cell.y] > build_site_distance_map[cell.x][cell.y] + 2:
						build_site_distance_map[target_cell.x][target_cell.y] = build_site_distance_map[cell.x][cell.y] + 2
						next_cells.append(target_cell)
		
		remaining_cells = next_cells.duplicate()
		next_cells = []

func update_tree_distance_map():
	if tree_distance_map == []:
		tree_distance_map = get_empty_distance_map()
	
	var remaining_cells: Array[Vector2i] = []
	for x in map.width:
		for y in map.height:
			var cell = Vector2i(x, y)
			if map.get_yield(cell) > 0:
				tree_distance_map[x][y] = 0
				remaining_cells.append(cell)
			elif not map.is_walkable(cell):
				tree_distance_map[x][y] = -1
			else:
				tree_distance_map[x][y] = map.width * map.height
	
	expand_trees(remaining_cells)

func add_tree(tree_position: Vector2i):
	tree_distance_map[tree_position.x][tree_position.y] = 0
	expand_trees([tree_position])

func remove_tree(tree_position: Vector2i):
	var remaining_cells = [tree_position]
	var next_cells = []
	var cells_to_expand: Array[Vector2i] = []
	while remaining_cells != []:
		for cell in remaining_cells:
			var neighbors = []
			for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
				var neighbor = cell + diff
				if map.is_walkable(neighbor):
					if tree_distance_map[neighbor.x][neighbor.y] == tree_distance_map[cell.x][cell.y] - 1:
						cells_to_expand.append(cell)
						break
					elif tree_distance_map[neighbor.x][neighbor.y] == 0:
						cells_to_expand.append(neighbor)
					elif tree_distance_map[neighbor.x][neighbor.y] >= tree_distance_map[cell.x][cell.y] and (
						tree_distance_map[neighbor.x][neighbor.y] < map.width * map.height):
						neighbors.append(neighbor)
			
			if cell not in cells_to_expand:
				tree_distance_map[cell.x][cell.y] = map.width * map.height
				next_cells += neighbors
		
		remaining_cells = next_cells.duplicate()
		next_cells = []
	
	expand_trees(cells_to_expand)

func expand_trees(cells: Array[Vector2i]):
	var remaining_cells = cells.duplicate()
	var next_cells = []
	while remaining_cells != []:
		for cell in remaining_cells:
			for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
				var target_cell = cell + diff
				if map.is_walkable(target_cell):
					if tree_distance_map[target_cell.x][target_cell.y] > tree_distance_map[cell.x][cell.y] + 1:
						tree_distance_map[target_cell.x][target_cell.y] = tree_distance_map[cell.x][cell.y] + 1
						next_cells.append(target_cell)
		
		remaining_cells = next_cells.duplicate()
		next_cells = []

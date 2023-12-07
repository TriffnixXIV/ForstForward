extends Node2D
class_name ForestEdges

var map: Map

var ForestEdge: PackedScene = preload("res://Scenes/ForestEdge.tscn")
var horizontal_forest_edges = []
var vertical_forest_edges = []

func resize():
	var array = []
	array.resize(map.height)
	for x in map.width + 1:
		horizontal_forest_edges.append(array.duplicate())
	array.resize(map.width)
	for y in map.height + 1:
		vertical_forest_edges.append(array.duplicate())

func update():
	for x in map.width + 1:
		for y in map.height + 1:
			update_horizontal(Vector2i(x, y))
			update_vertical(Vector2i(x, y))

func update_cell(cell_position: Vector2i):
	update_horizontal(cell_position)
	update_horizontal(cell_position + Vector2i(0, 1))
	update_vertical(cell_position)
	update_vertical(cell_position + Vector2i(1, 0))

func update_vertical(edge_position: Vector2i):
	if edge_position.x < len(horizontal_forest_edges) and edge_position.y < len(horizontal_forest_edges[edge_position.x]):
		var showing = show_edge(edge_position, edge_position + Vector2i(-1, 0))
		if showing and horizontal_forest_edges[edge_position.x][edge_position.y] == null:
			var instance = ForestEdge.instantiate()
			instance.position = Vector2i(edge_position.x * map.tile_set.tile_size.x, int((edge_position.y + 0.5) * map.tile_set.tile_size.y))
			horizontal_forest_edges[edge_position.x][edge_position.y] = instance
			add_child(instance)
		if not showing and not horizontal_forest_edges[edge_position.x][edge_position.y] == null:
			var instance = horizontal_forest_edges[edge_position.x][edge_position.y]
			instance.queue_free()
			horizontal_forest_edges[edge_position.x][edge_position.y] = null

func update_horizontal(edge_position: Vector2i):
	if edge_position.y < len(vertical_forest_edges) and edge_position.x < len(vertical_forest_edges[edge_position.y]):
		var showing = show_edge(edge_position, edge_position + Vector2i(0, -1))
		if showing and vertical_forest_edges[edge_position.y][edge_position.x] == null:
			var instance = ForestEdge.instantiate()
			instance.position = Vector2i(int((edge_position.x + 0.5) * map.tile_set.tile_size.x), edge_position.y * map.tile_set.tile_size.y)
			instance.rotation = PI / 2
			vertical_forest_edges[edge_position.y][edge_position.x] = instance
			add_child(instance)
		if not showing and not vertical_forest_edges[edge_position.y][edge_position.x] == null:
			var instance = vertical_forest_edges[edge_position.y][edge_position.x]
			instance.queue_free()
			vertical_forest_edges[edge_position.y][edge_position.x] = null

func show_edge(cell_1: Vector2i, cell_2: Vector2i):
	var cell_1_matches = map.is_forest(cell_1) or not map.is_valid_tile(cell_1)
	var cell_2_matches = map.is_forest(cell_2) or not map.is_valid_tile(cell_2)
	return cell_1_matches != cell_2_matches

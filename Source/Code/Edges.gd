extends Node2D
class_name Edges

var map: Map

var forest_edge_texture: Texture2D = preload("res://Images/Tiles/ForestEdge.png")
var plains_edge_texture: Texture2D = preload("res://Images/Tiles/PlainsEdge.png")
var sand_edge_texture: Texture2D = preload("res://Images/Tiles/SandEdge.png")
var horizontal_edges = []
var vertical_edges = []

enum EdgeType{forest, plains, sand}

func resize():
	var array = []
	array.resize(map.height)
	for x in map.width + 1:
		vertical_edges.append(array.duplicate())
	array.resize(map.height + 1)
	for x in map.width:
		horizontal_edges.append(array.duplicate())

func update():
	for x in map.width + 1:
		for y in map.height + 1:
			update_vertical_edge(Vector2i(x, y))
			update_horizontal_edge(Vector2i(x, y))

func update_cell(cell_position: Vector2i):
	update_vertical_edge(cell_position)
	update_vertical_edge(cell_position + Vector2i(1, 0))
	update_horizontal_edge(cell_position)
	update_horizontal_edge(cell_position + Vector2i(0, 1))

func update_horizontal_edge(edge_position: Vector2i):
	if edge_position.x < len(horizontal_edges) and edge_position.y < len(horizontal_edges[edge_position.x]):
		if horizontal_edges[edge_position.x][edge_position.y] != null:
			remove_horizontal_edge(edge_position)
		var edge_type = get_edge_type(edge_position, edge_position + Vector2i(0, -1))
		if edge_type != null:
			var sprite = get_sprite(edge_type)
			sprite.position = Vector2i(int((edge_position.x + 0.5) * map.tile_set.tile_size.x), edge_position.y * map.tile_set.tile_size.y)
			sprite.rotation = PI / 2
			horizontal_edges[edge_position.x][edge_position.y] = sprite
			add_sprite(sprite, edge_type)

func remove_horizontal_edge(edge_position: Vector2i):
	var sprite = horizontal_edges[edge_position.x][edge_position.y]
	sprite.get_parent().remove_child(sprite)
	sprite.queue_free()
	horizontal_edges[edge_position.x][edge_position.y] = null

func update_vertical_edge(edge_position: Vector2i):
	if edge_position.x < len(vertical_edges) and edge_position.y < len(vertical_edges[edge_position.x]):
		if vertical_edges[edge_position.x][edge_position.y] != null:
			remove_vertical_edge(edge_position)
		var edge_type = get_edge_type(edge_position, edge_position + Vector2i(-1, 0))
		if edge_type != null:
			var sprite = get_sprite(edge_type)
			sprite.position = Vector2i(edge_position.x * map.tile_set.tile_size.x, int((edge_position.y + 0.5) * map.tile_set.tile_size.y))
			vertical_edges[edge_position.x][edge_position.y] = sprite
			add_sprite(sprite, edge_type)

func remove_vertical_edge(edge_position: Vector2i):
	var sprite = vertical_edges[edge_position.x][edge_position.y]
	sprite.get_parent().remove_child(sprite)
	sprite.queue_free()
	vertical_edges[edge_position.x][edge_position.y] = null

func get_sprite(type: EdgeType):
	var sprite = Sprite2D.new()
	match type:
		EdgeType.forest:	sprite.texture = forest_edge_texture
		EdgeType.plains:	sprite.texture = plains_edge_texture
		EdgeType.sand:		sprite.texture = sand_edge_texture
	return sprite

func add_sprite(sprite: Sprite2D, type: EdgeType):
	match type:
		EdgeType.forest:	$Forest.add_child(sprite)
		EdgeType.plains:	$Plains.add_child(sprite)
		EdgeType.sand:		$Sand.add_child(sprite)

func get_edge_type(cell_1: Vector2i, cell_2: Vector2i):
	if (map.is_forest(cell_1) or map.is_empty(cell_1, 0)) != (map.is_forest(cell_2) or map.is_empty(cell_2, 0)):
		return EdgeType.forest
	elif map.is_forest(cell_1) and map.is_forest(cell_2):
		return null
	elif (map.is_plains(cell_1) and not map.is_forest(cell_1)) != (map.is_plains(cell_2) and not map.is_forest(cell_2)):
		return EdgeType.plains
	elif (map.is_sand(cell_1) and map.is_water(cell_2)) or (map.is_sand(cell_2) and map.is_water(cell_1)):
		return EdgeType.sand
	else:
		return null

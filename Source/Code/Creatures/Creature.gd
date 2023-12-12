extends Node2D
class_name Creature

var map: Map

var cell_position: Vector2i
var target_location
var inverse_path

signal moved

func move(approach_distance: int = 0):
	var step = Vector2i(0, 0)
	if inverse_path != null:
		step = -inverse_path.pop_back()
	else:
		step = map.pathing.get_move(cell_position, target_location, approach_distance)
	
	cell_position += step
	emit_signal("moved")
	update_position()

func update_position():
	position.x = cell_position.x * map.tile_set.tile_size.x
	position.y = cell_position.y * map.tile_set.tile_size.y

func get_distance_to(cell: Vector2i, beeline: bool = false):
	if beeline:
		var direct_path = cell - cell_position
		return abs(direct_path.x) + abs(direct_path.y)
	else:
		return map.pathing.cell_target_distance_map[cell.x][cell.y][cell_position.x][cell_position.y]

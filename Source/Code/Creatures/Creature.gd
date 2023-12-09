extends Node2D
class_name Creature

var map: Map

var cell_position: Vector2i
var target_location

signal moved

func move(approach_distance: int = 0):
	var path = map.pathing.get_move(cell_position, target_location, approach_distance)
	cell_position += path
	
	emit_signal("moved")
	update_position()

func update_position():
	position.x = cell_position.x * map.tile_set.tile_size.x
	position.y = cell_position.y * map.tile_set.tile_size.y

func get_distance_to(cell: Vector2i):
	var path = cell - cell_position
	return abs(path.x) + abs(path.y)

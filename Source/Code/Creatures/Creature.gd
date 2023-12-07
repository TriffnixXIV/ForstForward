extends Node2D
class_name Creature

var map: Map

var cell_position: Vector2i
var target_location

signal moved

func move(approach_distance: int = 0):
	var path = target_location - cell_position
	if abs(path.x) + abs(path.y) > approach_distance:
		if abs(path.x) == 0:
			cell_position.y += path.y / abs(path.y)
		elif abs(path.y) == 0:
			cell_position.x += path.x / abs(path.x)
		else:
			if randi_range(0, abs(path.x) + abs(path.y) - 1) < abs(path.x):
				cell_position.x += path.x / abs(path.x)
			else:
				cell_position.y += path.y / abs(path.y)
		
		emit_signal("moved")
		update_position()

func update_position():
	position.x = cell_position.x * map.tile_set.tile_size.x
	position.y = cell_position.y * map.tile_set.tile_size.y

func get_distance_to(cell: Vector2i):
	var path = cell - cell_position
	return abs(path.x) + abs(path.y)

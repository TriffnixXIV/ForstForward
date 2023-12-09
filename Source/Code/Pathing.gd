extends Node
class_name Pathing

var map: Map

func update() -> void:
	pass

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

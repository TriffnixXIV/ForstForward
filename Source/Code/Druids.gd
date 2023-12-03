extends Node2D
class_name Druids

var map: Map

var DruidScene: PackedScene = preload("res://Scenes/Druid.tscn")
var druids: Array[Druid] = []

func reset():
	for druid in druids:
		remove_child(druid)
		druid.queue_free()
	druids = []

func can_spawn(cell_position: Vector2i):
	return map.is_forest(cell_position)

func spawn(cell_position: Vector2i):
	if can_spawn(cell_position):
		var druid: Druid = DruidScene.instantiate()
		druid.cell_position = cell_position
		druid.map = map
		druid.update_position()
		druids.append(druid)
		add_child(druid)
		return true
	else:
		return false

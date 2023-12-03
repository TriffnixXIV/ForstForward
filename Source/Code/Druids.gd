extends Node2D
class_name Druids

var map: Map

var DruidScene: PackedScene = preload("res://Scenes/Druid.tscn")
var druids: Array[Druid] = []

var base_actions = 8
var base_circle_trees = 16

var actions: int
var circle_trees: int

func reset():
	actions			= base_actions
	circle_trees	= base_circle_trees
	
	for druid in druids:
		remove_child(druid)
		druid.queue_free()
	druids = []

func prepare_turn():
	for druid in druids:
		druid.prepare_turn(actions)

func set_circle_trees(amount: int):
	circle_trees = amount
	for druid in druids:
		druid.set_circle_trees(circle_trees)

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

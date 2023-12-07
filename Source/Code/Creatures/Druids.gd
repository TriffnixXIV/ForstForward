extends Node2D
class_name Druids

var map: Map

var DruidScene: PackedScene = preload("res://Scenes/Druid.tscn")
var druids: Array[Druid] = []

var spawns: int = 0
var kills: int = 0
var trees: int = 0

var base_actions: int = 8
var base_circle_trees: int = 16

var actions: int
var circle_trees: int

func reset():
	spawns = 0
	kills = 0
	trees = 0
	
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
		
		druid.connect("moved", map.advancement._moved)
		druid.connect("grown_trees", map.advancement._grown)
		
		druid.update_position()
		druids.append(druid)
		add_child(druid)
		spawns += 1
		return true
	else:
		return false

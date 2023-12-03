extends Node2D
class_name Treantlings

var map: Map

var TreantlingScene: PackedScene = preload("res://Scenes/Treantling.tscn")
var treantlings: Array[Treantling] = []

func reset():
	for treantling in treantlings:
		remove_child(treantling)
		treantling.queue_free()
	treantlings = []

func can_spawn(cell_position: Vector2i):
	return map.is_forest(cell_position)

func spawn(cell_position: Vector2i):
	if can_spawn(cell_position):
		var treantling: Treantling = TreantlingScene.instantiate()
		treantling.cell_position = cell_position
		treantling.map = map
		treantling.set_lifespan(map.treantling_lifespan)
		treantling.update_position()
		treantling.connect("has_died", despawn)
		treantlings.append(treantling)
		add_child(treantling)
		map.treantlings_spawned += 1
		return true
	else:
		return false

func set_lifespan(actions: int):
	map.treantling_lifespan = actions
	for treantling in treantlings:
		treantling.set_lifespan(map.treantling_lifespan)

func despawn(treantling: Treantling):
	treantlings.erase(treantling)
	remove_child(treantling)
	treantling.queue_free()

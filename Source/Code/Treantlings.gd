extends Node2D
class_name Treantlings

var map: Map

var TreantlingScene: PackedScene = preload("res://Scenes/Treantling.tscn")
var treantlings: Array[Treantling] = []

var base_actions = 8
var base_strength = 1
var base_lifespan = 24
var base_death_spread = 8

var actions: int
var strength: int
var lifespan: int
var death_spread: int

func reset():
	actions			= base_actions
	strength		= base_strength
	lifespan		= base_lifespan
	death_spread	= base_death_spread
	
	for treantling in treantlings:
		remove_child(treantling)
		treantling.queue_free()
	treantlings = []

func prepare_turn():
	for treantling in treantlings:
		treantling.prepare_turn(actions)

func set_lifespan(duration: int):
	lifespan = duration
	for treantling in treantlings:
		treantling.set_lifespan(lifespan)

func set_strength(new_strength: int):
	strength = new_strength
	for treantling in treantlings:
		treantling.strength = strength

func set_death_spread(spread: int):
	death_spread = spread
	for treantling in treantlings:
		treantling.death_spread = death_spread

func can_spawn(cell_position: Vector2i):
	return map.is_forest(cell_position)

func spawn(cell_position: Vector2i):
	if can_spawn(cell_position):
		var treantling: Treantling = TreantlingScene.instantiate()
		treantling.cell_position = cell_position
		treantling.map = map
		treantling.set_lifespan(lifespan)
		treantling.strength = strength
		treantling.death_spread = death_spread
		
		treantling.connect("moved", map.advancement._moved)
		treantling.connect("attacked", map.advancement._chopped)
		treantling.connect("grown_trees", map.advancement._grown)
		treantling.connect("has_died", despawn)
		
		treantling.update_position()
		treantlings.append(treantling)
		add_child(treantling)
		map.treantlings_spawned += 1
		return true
	else:
		return false

func despawn(treantling: Treantling):
	treantlings.erase(treantling)
	remove_child(treantling)
	treantling.queue_free()

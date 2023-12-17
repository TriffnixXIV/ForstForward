extends Node2D
class_name Treants

var map: Map

var TreantScene: PackedScene = preload("res://Scenes/Treant.tscn")
var treants: Array[Treant] = []

var spawns: int = 0
var kills: int = 0
var trees: int = 0

var base_actions: int = 6
var base_has_lifespan: bool = false
var base_lifespan: int = 40
var base_death_spread: int = 40

var actions: int
var has_lifespan: bool
var lifespan: int
var death_spread: int

func reset():
	spawns = 0
	kills = 0
	trees = 0
	
	actions			= base_actions
	has_lifespan	= base_has_lifespan
	lifespan		= base_lifespan
	death_spread	= base_death_spread
	
	for treant in treants:
		remove_child(treant)
		treant.queue_free()
	treants = []

func prepare_turn():
	for treant in treants:
		treant.prepare_turn(actions)

func set_lifespan(duration: int):
	lifespan = duration
	for treant in treants:
		treant.set_lifespan(lifespan)

func set_death_spread(spread: int):
	death_spread = spread
	for treant in treants:
		treant.death_spread = death_spread

func can_spawn(cell_position: Vector2i):
	for diff in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
		var cell = cell_position + diff
		if not map.is_forest(cell):
			return false
	return true

func spawn(cell_position: Vector2i):
	if can_spawn(cell_position):
		var treant: Treant = TreantScene.instantiate()
		treant.cell_position = cell_position
		treant.map = map
		if has_lifespan:
			treant.set_lifespan(lifespan)
		treant.death_spread = death_spread
		
		treant.connect("moved", map.advancement._moved)
		treant.connect("attacked", map.advancement._chopped)
		treant.connect("grown_trees", map.advancement._planted)
		treant.connect("has_died", despawn)
		
		treant.update_position()
		treants.append(treant)
		add_child(treant)
		spawns += 1
		return true
	else:
		return false

func despawn(treant: Treant):
	treants.erase(treant)
	remove_child(treant)
	treant.queue_free()

extends Node2D
class_name Villagers

var map: Map

var VillagerScene: PackedScene = preload("res://Scenes/Villager.tscn")
var villagers: Array[Villager] = []
var homeless_villagers = []
var home_cell_villager_map = {}

var horst_amount: int = 1

var base_actions: int = 12
var actions: int

func reset():
	actions = base_actions
	
	for villager in homeless_villagers:
		despawn(villager, true)
	for villager in villagers:
		villager.reset()

func prepare_turn():
	var action_loss = map.get_coldness()
	for villager in villagers:
		map.actions_lost_to_frost += min(actions, action_loss)
		villager.prepare_turn(actions - action_loss)
	
	map.update_cell_tree_distance_map()

func act():
	var actions_left = false
	for villager in villagers:
		actions_left = villager.act() or actions_left
	return actions_left

func check_horst_amount():
	if len(villagers) > 0:
		var existing_horsts = 0
		for villager in villagers:
			if villager.is_devil:
				existing_horsts += 1
		
		villagers.shuffle()
		var i = 0
		while existing_horsts < horst_amount and i < len(villagers):
			if not villagers[i].is_devil:
				villagers[i].get_real()
				existing_horsts += 1
			i += 1

func occupy(cell_position: Vector2i):
	if not cell_position in home_cell_villager_map:
		if len(homeless_villagers) > 0:
			var villager = homeless_villagers.pop_back()
			villager.home_cell = cell_position
			home_cell_villager_map[cell_position] = villager
		else:
			spawn(cell_position)

func spawn(cell_position: Vector2i):
	var villager: Villager = VillagerScene.instantiate()
	villager.cell_position = cell_position
	villager.home_cell = cell_position
	villager.map = map
	villager.update_position()
	
	villager.connect("moved", map.advancement._villager_moved)
	villager.connect("chopped_tree", map.advancement._villager_chopped)
	villager.connect("built_house", map.advancement._villager_built)
	
	home_cell_villager_map[cell_position] = villager
	villagers.append(villager)
	villager.actions = villagers[0].actions
	
	add_child(villager)
	
	if not map.advancement.current_phase == map.advancement.Phase.transitioning:
		map.born_villagers += 1
	map.highest_villager_count = max(map.highest_villager_count, len(villagers))

func despawn_at(cell_position: Vector2i, also_horst: bool = false):
	if cell_position in home_cell_villager_map:
		var villager = home_cell_villager_map[cell_position]
		despawn(villager, also_horst)

func despawn(villager: Villager, also_horst: bool = true):
	home_cell_villager_map.erase(villager.home_cell)
	if also_horst or not villager.is_devil:
		villagers.erase(villager)
		homeless_villagers.erase(villager)
		remove_child(villager)
		villager.queue_free()
		if not map.advancement.current_phase == map.advancement.Phase.transitioning:
			map.dead_villagers += 1
	else:
		homeless_villagers.append(villager)
		villager.home_cell = null

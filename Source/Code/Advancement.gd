extends Node
class_name Advancement

var map

enum Phase {transitioning, idle, starting, druids, growth, villagers}
var current_phase = Phase.idle

var still_acting: bool = false

var step_done = false

var villager_moved = false
var villager_chopped = false
var villager_built = false

signal advancement_step_done
signal advancement_done

func start():
	$Timer.start()
	$Sounds/AdvancementStart.play()
	current_phase = Phase.starting
	map.crystal_manager.advance()
	step_done = true

func stop():
	$Timer.stop()

func start_druid_phase():
	$Sounds/DruidStart.play()
	still_acting = true
	current_phase = Phase.druids
	
	for druid in map.druids:
		druid.prepare_turn(map.druid_actions)
		druid.set_circle_trees(map.druid_circle_trees)
	
	for treant in map.treants:
		treant.prepare_turn(map.treant_actions)
		treant.set_death_spread(map.treant_death_spread)
	
	for treantling in map.treantlings:
		treantling.prepare_turn(map.treantling_actions)
		treantling.set_stomp_strength(map.treantling_strength)
		treantling.set_death_spread(map.treantling_death_spread)

func next_druid_step():
	$Sounds/DruidAdvance.play()
	still_acting = false
	for creature in map.druids + map.treants + map.treantlings:
		still_acting = creature.act() or still_acting

func start_growth_phase():
	$Sounds/GrowthStart.play()
	current_phase = Phase.growth
	map.remaining_growth_stages = map.get_growth_stages()

func next_growth_step():
	$Sounds/BaseAdvance.play()
	var growth_amounts: Dictionary = {}
	for x in map.width:
		for y in map.height:
			if map.is_forest(Vector2i(x, y)):
				for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
					var cell = Vector2i(x, y) + diff
					if cell in growth_amounts:
						growth_amounts[cell] += 1
					else:
						growth_amounts[cell] = 1
	
	for cell in growth_amounts:
		var previous_yield = map.get_yield(cell)
		map.increase_yield(cell, growth_amounts[cell])
		map.grown_trees += map.get_yield(cell) - previous_yield
	
	map.update_forest_edges()
	map.remaining_growth_stages -= 1
	map.total_growth_stages += 1

func start_villager_phase():
	$Sounds/HorstStart.play()
	still_acting = true
	current_phase = Phase.villagers
	
	var action_loss = map.get_coldness()
	for villager in map.villagers:
		map.actions_lost_to_frost += min(map.villager_actions, action_loss)
		villager.prepare_turn(map.villager_actions - action_loss)
	
	map.update_cell_tree_distance_map()

func next_villager_step():
	villager_moved = false
	villager_chopped = false
	villager_built = false
	
	still_acting = false
	for villager in map.villagers:
		still_acting = villager.act() or still_acting
	
	$Sounds/BaseAdvance.play()
	if villager_moved:		$Sounds.villager_move()
	if villager_chopped:	$Sounds.villager_chop()
	if villager_built:		$Sounds.villager_build()

func _villager_moved():		villager_moved = true
func _villager_chopped():	villager_chopped = true
func _villager_built():		villager_built = true

func _on_timer_timeout():
	next_step()

func next_step():
	if step_done:
		emit_signal("advancement_step_done")
		step_done = false
		match current_phase:
			Phase.starting:
				if len(map.druids) == 0 and len(map.treantlings) == 0 and len(map.treants) == 0:
					start_growth_phase()
				else:
					start_druid_phase()
			Phase.druids:
				if still_acting:
					next_druid_step()
				else:
					start_growth_phase()
			Phase.growth:
				if map.remaining_growth_stages > 0:
					next_growth_step()
				else:
					start_villager_phase()
			Phase.villagers:
				if still_acting:
					next_villager_step()
				else:
					finish()
		step_done = true

func finish():
	$Timer.stop()
	for villager in map.villagers:
		villager.end_turn()
	
	current_phase = Phase.idle
	map.advance_rain()
	map.advance_frost()
	map.growth_boost = max(0, floori(0.5 * map.growth_boost))
	emit_signal("advancement_done")

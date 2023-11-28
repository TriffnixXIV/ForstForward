extends Node
class_name Advancement

var map

enum Phase {transitioning, idle, starting, druids, growth, villagers}
var current_phase = Phase.idle

var still_acting: bool = false

var done_villager_count = 0
var all_villagers_are_done_with_this_step = false

signal advancement_step_done
signal advancement_done

func start():
	$AdvancementStart.play()
	current_phase = Phase.starting
	$Timer.start()
	map.crystal_manager.advance()

func stop():
	$Timer.stop()

func start_druid_phase():
	if len(map.druids) == 0 and len(map.treantlings) == 0 and len(map.treants) == 0:
		start_growth_phase()
	else:
		$DruidStart.play()
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

func advance_druid_phase():
	$DruidAdvance.play()
	still_acting = false
	for creature in map.druids + map.treants + map.treantlings:
		still_acting = creature.act() or still_acting

func start_growth_phase():
	$GrowthStart.play()
	current_phase = Phase.growth
	map.remaining_growth_stages = map.get_growth_stages()

func advance_growth_phase():
	$GrowthAdvance.play()
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
	$HorstStart.play()
	done_villager_count = 0
	current_phase = Phase.villagers
	var action_loss = map.get_coldness()
	for villager in map.villagers:
		map.actions_lost_to_frost += min(map.villager_actions, action_loss)
		villager.prepare_turn(map.villager_actions - action_loss)
	map.update_cell_tree_distance_map()
	all_villagers_are_done_with_this_step = true

func advance_villager_phase():
	$HorstAdvance.play()
	all_villagers_are_done_with_this_step = false
	for villager in map.villagers:
		villager.act()
	all_villagers_are_done_with_this_step = true

func _on_villager_done_acting():
	done_villager_count += 1

func _on_timer_timeout():
	advance_phase()

func advance_phase():
	emit_signal("advancement_step_done")
	match current_phase:
		Phase.starting:
			start_druid_phase()
		Phase.druids:
			if still_acting:
				advance_druid_phase()
			else:
				start_growth_phase()
		Phase.growth:
			if map.remaining_growth_stages > 0:
				advance_growth_phase()
			else:
				start_villager_phase()
		Phase.villagers:
			if all_villagers_are_done_with_this_step:
				if done_villager_count < len(map.villagers):
					advance_villager_phase()
				else:
					done_villager_count = 0
					finish_advancement()

func finish_advancement():
	$Timer.stop()
	current_phase = Phase.idle
	map.growth_boost = max(0, floori(0.5 * map.growth_boost))
	map.advance_rain()
	map.advance_frost()
	emit_signal("advancement_done")

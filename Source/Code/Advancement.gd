extends Node
class_name Advancement

var map: Map

enum Phase {transitioning, idle, starting, druids, growth, villagers}
var current_phase = Phase.idle

var actions_left: bool = false

var step_done = false

var moved = false
var grown = false
var planted = false
var chopped = false
var built = false

signal advancement_step_done
signal advancement_done

func _moved():		moved = true
func _grown():		grown = true
func _planted():	planted = true
func _chopped():	chopped = true
func _built():		built = true

func start():
	if map.pathing.currently_updating:
		await map.pathing.update_done
	$Timer.start()
	$Sounds/AdvancementStart.play()
	current_phase = Phase.starting
	map.crystals.advance()
	step_done = true

func stop():
	$Timer.stop()

func start_druid_phase():
	$Sounds/DruidStart.play()
	$Sounds/Base.pitch_scale = pow(2, 4.0/12.0)
	current_phase = Phase.druids
	actions_left = true
	
	map.treants.prepare_turn()
	map.treantlings.prepare_turn()
	map.druids.prepare_turn()

func next_druid_step():
	moved = false
	grown = false
	planted = false
	chopped = false
	
	actions_left = false
	for creature in map.druids.druids + map.treants.treants + map.treantlings.treantlings:
		actions_left = creature.act() or actions_left
	
	$Sounds/Base.play()
	if moved:	$Sounds.move()
	if grown:	$Sounds.grow()
	if planted:	$Sounds.plant()
	if chopped:	$Sounds.chop()

func start_growth_phase():
	$Sounds/GrowthStart.play()
	$Sounds/Base.pitch_scale = 1.0
	current_phase = Phase.growth
	map.remaining_growth_stages = map.get_growth_stages()

func next_growth_step():
	$Sounds/Base.play()
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
	
	map.edges.update()
	map.remaining_growth_stages -= 1
	map.total_growth_stages += 1

func start_villager_phase():
	$Sounds/HorstStart.play()
	$Sounds/Base.pitch_scale = pow(2, 2.0/12.0)
	current_phase = Phase.villagers
	actions_left = true
	map.villagers.prepare_turn()

func next_villager_step():
	moved = false
	chopped = false
	built = false
	
	actions_left = map.villagers.act()
	
	$Sounds/Base.play()
	if moved:	$Sounds.move()
	if chopped:	$Sounds.chop()
	if built:	$Sounds.build()

func _on_timer_timeout():
	next_step()

func next_step():
	if step_done:
		emit_signal("advancement_step_done")
		step_done = false
		match current_phase:
			Phase.starting:
				if len(map.druids.druids) == 0 and len(map.treantlings.treantlings) == 0 and len(map.treants.treants) == 0:
					start_growth_phase()
				else:
					start_druid_phase()
			Phase.druids:
				if actions_left:
					next_druid_step()
				else:
					start_growth_phase()
			Phase.growth:
				if map.remaining_growth_stages > 0:
					next_growth_step()
				else:
					start_villager_phase()
			Phase.villagers:
				if actions_left:
					next_villager_step()
				else:
					finish()
		step_done = true

func finish():
	$Timer.stop()
	for villager in map.villagers.villagers:
		villager.end_turn()
	
	current_phase = Phase.idle
	map.advance_rain()
	map.advance_frost()
	map.growth_boost = max(0, floori(0.5 * map.growth_boost))
	emit_signal("advancement_done")

extends Resource
class_name Action

enum Type {spawn_treant, spawn_druid, overgrowth, spread, plant, rain, lightning_strike, beer}

var type = null
var specifier = null
var progress = 0
var needed_progress = 0
var next_action: Action = null
var concurrent_actions: Array[Action] = [] # can only contain overgrowth, rain and beer actions

signal advance_success
signal advance_failure
signal text_changed
signal numbers_changed

func reset():
	type = null
	specifier = null
	progress = 0
	needed_progress = 0
	next_action = null

func set_action(other: Action):
	type = other.type
	specifier = other.specifier
	progress = other.progress
	needed_progress = other.needed_progress
	next_action = other.next_action
	if next_action != null:
		next_action.connect("text_changed", on_next_action_text_changed)
		next_action.connect("numbers_changed", on_next_action_numbers_changed)
		next_action.connect("advance_success", on_next_action_advance_success)
		next_action.connect("advance_failure", on_next_action_advance_failure)
	concurrent_actions = other.concurrent_actions
	
	emit_signal("text_changed")

func add_action(other: Action):
	if other.type in [Type.overgrowth, Type.rain, Type.beer]:
		concurrent_actions.append(other)
	else:
		if type in [Type.overgrowth, Type.rain, Type.beer]:
			other.concurrent_actions.append(copy())
			set_action(other)
		elif next_action != null:
			next_action.add_action(other)
		else:
			next_action = other
			next_action.connect("text_changed", on_next_action_text_changed)
			next_action.connect("numbers_changed", on_next_action_numbers_changed)
			next_action.connect("advance_success", on_next_action_advance_success)
			next_action.connect("advance_failure", on_next_action_advance_failure)

func copy():
	var action = Action.new()
	action.set_action(self)
	return action

func infer_needed_progress():
	match type:
		Type.overgrowth:	needed_progress = 0
		Type.rain:			needed_progress = 0
		Type.beer:			needed_progress = 0
		Type.spread:		needed_progress = 1
		_:					needed_progress = specifier

func get_full_text():
	var full_text = get_text()
	for action in concurrent_actions:
		full_text += "\nand " + action.get_text()
	if next_action != null:
		full_text += ",\nthen " + next_action.get_text()
	return full_text

func get_text():
	var progress_text = ""
	if progress > 0:
		progress_text = " (" + str(progress) + "/" + str(needed_progress) + ")"
	match type:
		Type.spawn_treant:
			if specifier > 1:
				return "spawn " + str(specifier) + " treants" + progress_text
			else:
				return "spawn a treant"
		Type.spawn_druid:
			if specifier > 1:
				return "spawn " + str(specifier) + " druids" + progress_text
			else:
				return "spawn a druid"
		Type.plant:
			if specifier > 1:
				return "plant " + str(specifier) + " forests" + progress_text
			else:
				return "plant a forest"
		Type.spread:
			return "spread " + str(specifier)
		Type.overgrowth:
			return "growth +" + str(specifier)
		Type.rain:
			return "rain +" + str(specifier)
		Type.beer:
			return "beer +" + str(specifier)
		Type.lightning_strike:
			if specifier > 1:
				return "summon " + str(specifier) + " lightning strikes" + progress_text
			else:
				return "summon a lightning strike"

func enact(map: Map):
	if type in [Type.overgrowth, Type.rain, Type.beer]:
		for action in concurrent_actions:
			action.enact(map)
	
	match type:
		Action.Type.overgrowth:
			map.growth_boost += specifier
		Action.Type.rain:
			map.rain_duration += specifier
			map.update_rain_overlay()
		Action.Type.beer:
			map.beer_level += specifier
			map.update_beer_overlay()

func advance(map: Map, cell_position: Vector2i):
	if progress >= needed_progress:
		next_action.advance(map, cell_position)
		return null
	
	var success = false
	match type:
		Action.Type.spawn_treant:
			success = map.spawn_treant(cell_position)
			emit_signal("numbers_changed")
		Action.Type.spawn_druid:
			success = map.spawn_druid(cell_position)
			emit_signal("numbers_changed")
		Action.Type.spread:
			success = map.spread_forest(cell_position, specifier)
		Action.Type.plant:
			success = map.plant_forest(cell_position)
		Action.Type.lightning_strike:
			success = map.strike_with_lightning(cell_position)
			emit_signal("numbers_changed")
	
	if success:
		if progress == 0:
			for action in concurrent_actions:
				action.enact(map)
		progress += 1
		emit_signal("text_changed")
		emit_signal("advance_success")
	else:
		emit_signal("advance_failure")

func is_done():
	var done = progress >= needed_progress
	if next_action != null:
		return done and next_action.is_done()
	else:
		return done

func get_active_type():
	if progress < needed_progress:
		return type
	elif next_action != null:
		return next_action.get_active_type()

func get_active_specifier():
	if progress < needed_progress:
		return specifier
	elif next_action != null:
		return next_action.get_active_specifier()

func on_next_action_text_changed():
	emit_signal("text_changed")

func on_next_action_numbers_changed():
	emit_signal("numbers_changed")

func on_next_action_advance_success():
	emit_signal("advance_success")

func on_next_action_advance_failure():
	emit_signal("advance_failure")

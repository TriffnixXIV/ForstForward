extends Resource
class_name Action

enum Type {spawn_treant, spawn_druid, overgrowth, spread, plant, rain, lightning_strike, beer}

var type = null
var strength = null
var clicks = null
var progress = 0

var next_action: Action = null
var concurrent_actions: Array[Action] = [] # can only contain overgrowth, rain and beer actions

signal advance_success
signal advance_failure
signal text_changed
signal numbers_changed

func reset():
	type = null
	strength = null
	progress = 0
	next_action = null

func set_action(other: Action):
	type = other.type
	strength = other.strength
	clicks = other.clicks
	progress = other.progress
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
		progress_text = " (" + str(progress) + "/" + str(clicks) + ")"
	match type:
		Type.spawn_treant:
			if clicks > 1:
				return "spawn " + str(clicks) + " treants" + progress_text
			else:
				return "spawn a treant"
		Type.spawn_druid:
			if clicks > 1:
				return "spawn " + str(clicks) + " druids" + progress_text
			else:
				return "spawn a druid"
		Type.plant:
			if clicks > 1:
				return "plant " + str(clicks) + " forests" + progress_text
			else:
				return "plant a forest"
		Type.spread:
			var click_text = str(clicks) + "x" if clicks > 1 else ""
			return "spread " + click_text + str(strength) + progress_text
		Type.overgrowth:
			return "growth +" + str(strength)
		Type.rain:
			return "rain +" + str(strength)
		Type.beer:
			return "beer +" + str(strength)
		Type.lightning_strike:
			if clicks > 1:
				return "summon " + str(clicks) + " lightning strikes" + progress_text
			else:
				return "summon a lightning strike"

func enact(map: Map):
	if type in [Type.overgrowth, Type.rain, Type.beer]:
		for action in concurrent_actions:
			action.enact(map)
	
	match type:
		Action.Type.overgrowth:
			map.growth_boost += strength
		Action.Type.rain:
			map.rain_duration += strength
			map.update_rain_overlay()
		Action.Type.beer:
			map.beer_level += strength
			map.update_beer_overlay()

func advance(map: Map, cell_position: Vector2i):
	if progress >= clicks:
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
			success = map.spread_forest(cell_position, strength)
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
	var done = progress >= clicks
	if next_action != null:
		return done and next_action.is_done()
	else:
		return done

func get_active_type():
	if progress < clicks:
		return type
	elif next_action != null:
		return next_action.get_active_type()

func get_active_strength():
	if progress < clicks:
		return strength
	elif next_action != null:
		return next_action.get_active_strength()

func on_next_action_text_changed():
	emit_signal("text_changed")

func on_next_action_numbers_changed():
	emit_signal("numbers_changed")

func on_next_action_advance_success():
	emit_signal("advance_success")

func on_next_action_advance_failure():
	emit_signal("advance_failure")

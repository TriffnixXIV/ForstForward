extends Resource
class_name Action

enum Type {spawn_treant, spawn_treantling, spawn_druid, overgrowth, spread, plant, rain, lightning_strike, frost}
var type

var strength
var cost
var clicks
var progress = 0

var next_action: Action
var concurrent_actions: Array[Action] = [] # can only contain overgrowth, rain and frost actions

signal advance_success
signal advance_failure
signal text_changed
signal numbers_changed

func reset():
	type = null
	strength = null
	cost = null
	clicks = null
	progress = 0
	next_action = null

func set_action(other: Action):
	type = other.type
	strength = other.strength
	cost = other.cost
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
	if other.type in [Type.overgrowth, Type.rain, Type.frost]:
		concurrent_actions.append(other)
	else:
		if type in [Type.overgrowth, Type.rain, Type.frost]:
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

func get_crystal_type():
	match type:
		Type.spawn_treant:		return Crystal.Type.life
		Type.spawn_treantling:	return Crystal.Type.life
		Type.spawn_druid:		return Crystal.Type.life
		Type.overgrowth:		return Crystal.Type.growth
		Type.spread:			return Crystal.Type.growth
		Type.plant:				return Crystal.Type.growth
		Type.rain:				return Crystal.Type.weather
		Type.lightning_strike:	return Crystal.Type.weather
		Type.frost:				return Crystal.Type.weather

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
		Type.spawn_treantling:
			if clicks > 1:
				return "spawn " + str(clicks) + " treantlings" + progress_text
			else:
				return "spawn a treantling"
		Type.spawn_druid:
			if clicks > 1:
				return "spawn " + str(clicks) + " druids" + progress_text
			else:
				return "spawn a druid"
		Type.plant:
			var spreadstr = "" if strength <= 0 else "\nspread each " + str(strength)
			if clicks > 1:
				return "plant " + str(clicks) + " forests" + progress_text + spreadstr
			else:
				return "plant a forest" + spreadstr
		Type.spread:
			var click_text = str(clicks) + "x " if clicks > 1 else ""
			return "spread " + click_text + str(strength) + progress_text
		Type.overgrowth:
			return "growth +" + str(strength)
		Type.rain:
			return "rain +" + str(strength) if strength > 0 else "rain " + str(strength) if strength < 0 else ""
		Type.frost:
			return "frost +" + str(strength)
		Type.lightning_strike:
			var rain_text = "rain " + str(-cost) if cost > 0 else "rain +" + str(-cost) if cost < 0 else ""
			if clicks > 1:
				if rain_text != "": rain_text += " for each"
				return "summon " + str(clicks) + " lightning strikes" + progress_text + "\n" + rain_text
			else:
				return "summon a lightning strike" + "\n" + rain_text

func enact(map: Map):
	if type in [Type.overgrowth, Type.rain, Type.frost]:
		for action in concurrent_actions:
			action.enact(map)
	
	match type:
		Type.overgrowth:
			map.growth_boost += strength
		Type.rain:
			map.set_rain(map.rain_duration + strength)
		Type.frost:
			map.frost_boost += strength
			map.update_frost_overlay()

func can_be_performed_on(map: Map, cell_position: Vector2i):
	match get_active_type():
		Type.spawn_treant:
			return map.treants.can_spawn(cell_position)
		Type.spawn_treantling:
			return map.treantlings.can_spawn(cell_position)
		Type.spawn_druid:
			return map.druids.can_spawn(cell_position)
		Type.plant:
			return map.can_plant_forest(cell_position)
		Type.spread:
			return map.can_spread_forest(cell_position)
		Type.lightning_strike:
			return map.can_lightning_strike(cell_position)

func advance(map: Map, cell_position: Vector2i):
	if progress >= clicks:
		next_action.advance(map, cell_position)
		return null
	
	var success = false
	match type:
		Type.spawn_treant:
			success = map.treants.spawn(cell_position)
		Type.spawn_treantling:
			success = map.treantlings.spawn(cell_position)
		Type.spawn_druid:
			success = map.druids.spawn(cell_position)
		Type.spread:
			success = map.spread_forest(cell_position, strength)
			emit_signal("numbers_changed")
		Type.plant:
			success = map.plant_forest(cell_position)
			if success and strength > 0:
				map.spread_forest(cell_position, strength, false, "plant")
			emit_signal("numbers_changed")
		Type.lightning_strike:
			success = map.strike_with_lightning(cell_position)
			if success:
				map.set_rain(map.rain_duration - cost)
			emit_signal("numbers_changed")
	
	if success:
		progress += 1
		
		match type:
			Type.plant:
				var plantable_spots = map.count_plantable_spots()
				if plantable_spots < clicks - progress:
					clicks = progress + plantable_spots
			Type.lightning_strike:
				var strikable_spots = map.count_strikeable_spots()
				if strikable_spots == 0 or not map.is_raining():
					clicks = progress
		
		if clicks == progress:
			for action in concurrent_actions:
				action.enact(map)
		
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

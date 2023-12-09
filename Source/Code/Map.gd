extends Level
class_name Map

var current_level: int = 0

var transition_duration: float = 0.25
var transition_progress: float = 0.0
var transition_info = []

var pathing: Pathing
var edges: Edges
var crystals: Crystals
var villagers: Villagers
var treants: Treants
var treantlings: Treantlings
var druids: Druids

var LightningStrike: PackedScene = preload("res://Scenes/Lightning.tscn")
var Blast: PackedScene = preload("res://Scenes/Blast.tscn")
var GrowthEffect: PackedScene = preload("res://Scenes/GrowthEffect.tscn")

var highest_possible_score: int

var base_min_growth = 1
var base_can_spread_on_plains = false
var base_can_spread_on_buildings = false
var base_can_plant_on_buildings = false
var base_rain_decay_rate = 1
var base_rain_growth_boost = 0
var base_rain_frost_boost = 0
var base_min_frost = 0

var min_growth: int
var can_spread_on_plains: bool
var can_spread_on_buildings: bool
var can_plant_on_buildings: bool
var rain_decay_rate: int
var rain_growth_boost: int
var rain_frost_boost: int
var min_frost: int

var growth_boost = 0
var remaining_growth_stages = 0
var rain_duration = 0
var frost_boost = 0

var deaths_to_lightning: int = 0
var total_coldness: int = 0
var actions_lost_to_frost: int = 0

var grown_trees: int = 0
var planted_trees: int = 0
var spread_trees: int = 0
var total_growth_stages: int = 0
var total_rain_duration: int = 0
var total_lightning_strikes: int = 0

var cell_labels: Array[Array]
var cell_label_settings = preload("res://Text/CellNumberLabelSettings.tres")

var cell_tree_distance_map: Array[Array]

var advancement: Advancement
var sounds

signal transition_done
signal score_changed

func _ready():
	super._ready()
	reset_upgrades()
	
	pathing = $Pathing
	sounds = $Sounds
	advancement = $Advancement
	edges = $Edges
	crystals = $Crystals
	villagers = $Villagers
	treants = $Treants
	treantlings = $Treantlings
	druids = $Druids
	
	pathing.map = self
	advancement.map = self
	edges.map = self
	crystals.map = self
	villagers.map = self
	treants.map = self
	treantlings.map = self
	druids.map = self
	
	highest_possible_score = width * height * 10
	
	edges.resize()
	
	var array = []
	cell_tree_distance_map = []
	array.resize(height)
	array.fill(width + height)
	for x in width:
		cell_tree_distance_map.append(array.duplicate())

func _process(delta):
	if transition_progress < transition_duration and len(transition_info) > 0:
		var start_index = floori((len(transition_info) - 1) * transition_progress / transition_duration)
		transition_progress = min(transition_duration, transition_progress + delta)
		var end_index = floori(len(transition_info) * transition_progress / transition_duration)
		
		for i in range(start_index, end_index):
			var data = transition_info[i]
			
			villagers.despawn_at(data[1], true)
			
			set_cell(data[0], data[1], data[2], data[3])
			
			if is_house(data[1]):
				villagers.spawn(data[1])
		edges.update()
	elif advancement.current_phase == advancement.Phase.transitioning:
		advancement.current_phase = advancement.Phase.idle
		
		villagers.check_horst_amount()
		update_highscore()
		
		for _i in random_starting_crystals:
			crystals.find_spot_and_spawn_crystal(randi_range(0, 2))
		for _i in base_life_crystals:
			crystals.find_spot_and_spawn_crystal(Crystal.Type.life)
		for _i in base_growth_crystals:
			crystals.find_spot_and_spawn_crystal(Crystal.Type.growth)
		for _i in base_weather_crystals:
			crystals.find_spot_and_spawn_crystal(Crystal.Type.weather)
		
		pathing.update()
		
		emit_signal("transition_done")
		emit_signal("score_changed")

func load_level(level_number: int):
	var level = $Levels.get_child(level_number)
	level.generate()
	level_name = level.level_name
	level_id = level.level_id
	
	level.load_save_data()
	save_data = level.save_data
	
	random_starting_crystals = level.random_starting_crystals
	base_life_crystals = level.base_life_crystals
	base_growth_crystals = level.base_growth_crystals
	base_weather_crystals = level.base_weather_crystals
	
	var bottom_layer = []
	var top_layer = []
	for x in width:
		for y in height:
			var cell = Vector2i(x, y)
			if not is_identical_tile(Vector2i(x, y), 0, 0, level.get_cell_atlas_coords(0, cell)):
				bottom_layer.append(
					[0, cell, 0, level.get_cell_atlas_coords(0, cell)]
				)
			if not is_identical_tile(Vector2i(x, y), 1, 0, level.get_cell_atlas_coords(1, cell)):
				top_layer.append(
					[1, cell, level.get_cell_source_id(1, cell), level.get_cell_atlas_coords(1, cell)]
				)
	
	bottom_layer.shuffle()
	top_layer.shuffle()
	transition_info = bottom_layer + top_layer
	advancement.current_phase = advancement.Phase.transitioning

func set_level(level_number: int):
	current_level = level_number
	reload_level()

func reload_level():
	reset()
	load_level(current_level)

func clear_level():
	reset()
	
	random_starting_crystals = 0
	base_life_crystals = 0
	base_growth_crystals = 0
	base_weather_crystals = 0
	
	for x in width:
		for y in height:
			if not is_plains(Vector2i(x, y)):
				transition_info.append([0, Vector2i(x, y), 0, Vector2i(0, 0)])
			if not is_forest(Vector2i(x, y)):
				transition_info.append([1, Vector2i(x, y), 0, Vector2i(10, 0)])
	
	transition_info.shuffle()
	advancement.current_phase = advancement.Phase.transitioning

func update_highscore():
	highest_possible_score = 0
	for x in width:
		for y in height:
			if is_plains(Vector2i(x, y)):
				highest_possible_score += 10
	print(highest_possible_score)

func stop():
	advancement.stop()
	growth_boost = 0
	set_rain(0)
	frost_boost = 0
	update_frost_overlay()
	advancement.current_phase = advancement.Phase.idle

func reset():
	advancement.stop()
	transition_progress = 0.0
	transition_info = []
	
	reset_upgrades()
	reset_stats()
	growth_boost = 0
	set_rain(0)
	frost_boost = 0
	update_frost_overlay()
	
	crystals.reset()
	villagers.reset()
	druids.reset()
	treants.reset()
	treantlings.reset()

func reset_upgrades():
	min_growth				= base_min_growth
	can_spread_on_plains	= base_can_spread_on_plains
	can_spread_on_buildings	= base_can_spread_on_buildings
	can_plant_on_buildings	= base_can_plant_on_buildings
	rain_decay_rate			= base_rain_decay_rate
	rain_growth_boost		= base_rain_growth_boost
	rain_frost_boost		= base_rain_frost_boost
	min_frost				= base_min_frost

func reset_stats():
	deaths_to_lightning = 0
	total_coldness = 0
	actions_lost_to_frost = 0
	
	grown_trees = 0
	planted_trees = 0
	spread_trees = 0
	total_growth_stages = 0
	total_lightning_strikes = 0
	total_rain_duration = 0

# miscellaneous advancement stuff

func reset_cell_tree_distance_map():
	for x in width:
		for y in height:
			cell_tree_distance_map[x][y] = width + height

func update_cell_tree_distance_map():
	reset_cell_tree_distance_map()
	
	for x in width:
		for y in height:
			for cell in [Vector2i(x, y), Vector2i(width - x - 1, height - y - 1)]:
				var x_1 = cell.x
				var y_1 = cell.y
				if get_yield(cell) > 0:
					cell_tree_distance_map[x_1][y_1] = 0
				else:
					for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
						var x_2 = cell.x + diff.x
						var y_2 = cell.y + diff.y
						if x_2 >= 0 and x_2 < width and y_2 >= 0 and y_2 < height:
							cell_tree_distance_map[x_1][y_1] = min(cell_tree_distance_map[x_1][y_1], cell_tree_distance_map[x_2][y_2] + 1)

func set_cell_tree_distance(cell: Vector2i, distance: int):
	if cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height:
		if distance > cell_tree_distance_map[cell.x][cell.y]:
			cell_tree_distance_map[cell.x][cell.y] = distance
			for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
				set_cell_tree_distance(cell + diff, distance - 1)

func get_growth_stages():
	var growth_stages = min_growth + growth_boost
	if is_raining():
		growth_stages += rain_growth_boost
	return growth_stages

func advance_rain():
	if is_raining():
		total_rain_duration += 1
	set_rain(rain_duration - rain_decay_rate)

func set_rain(duration: int):
	rain_duration = max(0, duration)
	update_rain_overlay()

func advance_frost():
	total_coldness += get_coldness()
	frost_boost = max(0, floori(0.5 * frost_boost))
	update_frost_overlay()

func get_coldness():
	var coldness = min_frost + frost_boost
	if is_raining():
		coldness += rain_frost_boost
	return coldness

# UI stuff

func update_rain_overlay():
	if rain_duration > 0:
		$Overlays/Rain.visible = true
	else:
		$Overlays/Rain.visible = false

func update_frost_overlay():
	var coldness = get_coldness()
	if coldness > 0:
		$Overlays/Frost.visible = true
		$Overlays/Frost.modulate.a = min(1, coldness / float(villagers.actions))
	else:
		$Overlays/Frost.visible = false

func initialize_cell_labels():
	var array = []
	array.resize(height)
	
	$CellNumbers.visible = true
	cell_labels = []
	for x in width:
		cell_labels.append(array.duplicate())
		for y in height:
			var label = Label.new()
			label.size = Vector2i(20, 20)
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.label_settings = cell_label_settings
			label.position.x = x * 20
			label.position.y = y * 20
			cell_labels[x][y] = label
			$CellNumbers.add_child(label)

func get_cell_value_array():
	var values: Array[Array] = []
	var array = []
	array.resize(height)
	array.fill(0)
	for x in width:
		values.append(array.duplicate())
	return values
	
func reset_cell_labels():
	if len(cell_labels) != width:
		initialize_cell_labels()
	for x in width:
		for y in height:
			cell_labels[x][y].text = ""

func set_cell_label(cell_position: Vector2i, text: String):
	if is_valid_tile(cell_position):
		if len(cell_labels) != width:
			initialize_cell_labels()
		cell_labels[cell_position.x][cell_position.y].text = text

func set_cell_labels(values: Array[Array]):
	if len(cell_labels) != width:
		initialize_cell_labels()
	for x in width:
		for y in height:
			cell_labels[x][y].text = str(values[x][y])

# cell changes

func increase_yield(cell_position: Vector2i, amount: int):
	if get_building_progress(cell_position) > 0:
		var remaining_amount = amount - get_building_progress(cell_position)
		decrease_building_progress(cell_position, amount)
		if remaining_amount > 0:
			return increase_yield(cell_position, remaining_amount)
		else:
			return 0
	else:
		var yield_0 = get_yield(cell_position)
		set_yield(cell_position, yield_0 + amount)
		return min(amount, 10 - yield_0)

func decrease_yield(cell_position: Vector2i, amount: int):
	var yield_0 = get_yield(cell_position)
	if yield_0 > 0:
		set_yield(cell_position, yield_0 - amount)
		return get_yield(cell_position) - yield_0
	else:
		return 0

func set_yield(cell_position: Vector2i, amount: int):
	if not is_growable(cell_position):
		return null
	
	var previous_yield = get_yield(cell_position)
	if previous_yield != amount:
		if amount > 0 and amount < 10:
			set_growth(cell_position, amount)
		elif amount >= 10:
			set_forest(cell_position)
			edges.update_cell(cell_position)
		else:
			set_empty(cell_position)
		if previous_yield >= 10 and amount < 10:
			edges.update_cell(cell_position)
			crystals.forest_died_at(cell_position)

func increase_building_progress(cell_position: Vector2i, amount: int):
	if get_yield(cell_position) > 0:
		var remaining_amount = amount - get_yield(cell_position)
		decrease_yield(cell_position, amount)
		if remaining_amount > 0:
			increase_building_progress(cell_position, remaining_amount)
	else:
		set_building_progress(cell_position, get_building_progress(cell_position) + amount)

func decrease_building_progress(cell_position: Vector2i, amount: int):
	if get_building_progress(cell_position) > 0:
		set_building_progress(cell_position, get_building_progress(cell_position) - amount)

func set_building_progress(cell_position: Vector2i, progress: int):
	if not is_buildable(cell_position):
		return null
	
	var previous_progress = get_building_progress(cell_position)
	if previous_progress != progress:
		if progress > 0 and progress < 10:
			set_build_site(cell_position, progress)
		elif progress >= 10:
			set_house(cell_position)
			villagers.occupy(cell_position)
		else:
			set_empty(cell_position)
			villagers.despawn_at(cell_position)

# miscellaneous functions

func get_distance(cell_1: Vector2i, cell_2: Vector2i):
	var path = cell_1 - cell_2
	return abs(path.x) + abs(path.y)

func find_closest_matching_cell(cell_position: Vector2i, match_function, extra_argument = null, max_distance = 50):
	var closest_matching_cells = find_closest_matching_cells(cell_position, match_function, extra_argument, max_distance)
	if closest_matching_cells != []:
		return closest_matching_cells[0]
	else:
		return null

func find_closest_matching_cells(cell_position: Vector2i, match_function, extra_argument = null, max_distance = 50):
	if is_valid_tile(cell_position) and match_function.call(cell_position, extra_argument):
		return [cell_position]
	
	var closest_matching_cells = []
	var distance = 1
	while closest_matching_cells == [] and distance < max_distance:
		for d1 in distance:
			var d2 = distance - d1
			for diff in [Vector2i(d1, d2), Vector2i(-d2, d1), Vector2i(-d1, -d2), Vector2i(d2, -d1)]:
				var target_cell = cell_position + diff
				if is_valid_tile(target_cell) and match_function.call(target_cell, extra_argument):
					closest_matching_cells.append(target_cell)
		distance += 1
	
	closest_matching_cells.shuffle()
	return closest_matching_cells

func is_raining():
	return rain_duration > 0

func get_score():
	var score = 0
	for x in width:
		for y in height:
			score += get_yield(Vector2i(x, y))
	return score

# player actions

func count_spots(cell_to_boolean_function: Callable):
	var count = 0
	for x in width:
		for y in height:
			if cell_to_boolean_function.call(Vector2i(x, y)):
				count += 1
	return count

func count_plantable_spots():
	return count_spots(can_plant_forest)

func can_plant_forest(cell_position):
	return is_plains(cell_position) and ((is_growth(cell_position) or is_empty(cell_position)
		) or (can_plant_on_buildings and (is_build_site(cell_position) or is_house(cell_position))))

func plant_forest(cell_position: Vector2i):
	if can_plant_forest(cell_position):
		var previous_yield = get_yield(cell_position)
		increase_yield(cell_position, 20)
		show_growth_effect(cell_position)
		planted_trees += get_yield(cell_position) - previous_yield
		emit_signal("score_changed")
		return true
	else:
		return false

func count_spreadable_spots():
	return count_spots(can_spread_forest)

func can_spread_forest(cell_position: Vector2i):
	return (is_forest(cell_position)
		) or ((can_spread_on_plains and is_plains(cell_position)
			) and ((is_growth(cell_position) or is_empty(cell_position)
				) or (can_spread_on_buildings and (is_build_site(cell_position) or is_house(cell_position)))))

func spread_forest(cell_position: Vector2i, tree_amount: int, bypass_condition: bool = false, source: String = "spread"):
	if bypass_condition or can_spread_forest(cell_position):
		var increase = increase_yield(cell_position, 20)
		match source:
			"treant":		treants.trees += increase
			"treantling":	treantlings.trees += increase
			"spread":		spread_trees += increase
			"plant":		planted_trees += increase
		
		show_growth_effect(cell_position)
		var distance = 1
		var cell_entries = []
		var more_growable = func(a, b): return a[1] > b[1]
		while tree_amount > 0:
			# get all growable cells at that distance
			cell_entries = []
			for d1 in distance:
				var d2 = distance - d1
				for diff in [Vector2i(d1, d2), Vector2i(d2, -d1), Vector2i(-d1, -d2), Vector2i(-d2, d1)]:
					var cell = cell_position + diff
					show_growth_effect(cell)
					var growable_amount = get_growable_amount(cell)
					if is_valid_tile(cell) and growable_amount > 0:
						cell_entries.append([cell, growable_amount, 0]) # last number will become the actual growth amount
			
			# distribute the trees in a min-max way
			cell_entries.sort_custom(more_growable)
			for i1 in len(cell_entries):
				# going backwards with i for later convenience
				var remaining_cells = len(cell_entries) - i1
				var i = remaining_cells - 1
				var growable_amount = cell_entries[i][1]
				# if a cell needs less than the fair share of trees to become a forest,
				# it get's exactly what it needs and not more.
				# the fair share is determined only using cells that need at least the same amount of trees,
				# as other cells were already checked before.
				# using multiplication instead of division for both technical reasons and my first intuition being
				# a different one that lead to that formula.
				if remaining_cells * growable_amount < tree_amount:
					cell_entries[i][2] = growable_amount
					tree_amount -= growable_amount
				else: # all remaining cells need more than the fair share
					# if the remaining amount of trees can be equally distributed, do that
					if tree_amount % remaining_cells == 0:
						var fair_share = int(tree_amount / float(remaining_cells))
						for i2 in remaining_cells:
							cell_entries[i2][2] = fair_share
					# otherwise divide the next-less amount of equally distributable trees equally,
					# then distribute the remaining trees randomly
					else:
						var growth_parts = []
						for i2 in remaining_cells:
							growth_parts.append(floori(tree_amount / float(remaining_cells)))
						for i2 in tree_amount % remaining_cells:
							growth_parts[i2] += 1
						growth_parts.shuffle()
						for i2 in remaining_cells:
							cell_entries[i2][2] = growth_parts[i2]
					tree_amount = 0
					break
			
			for cell_entry in cell_entries:
				increase_yield(cell_entry[0], cell_entry[2])
				
				match source:
					"treant":		treants.trees += cell_entry[2]
					"treantling":	treantlings.trees += cell_entry[2]
					"spread":		spread_trees += cell_entry[2]
					"plant":		planted_trees += cell_entry[2]
			
			# -1 tree for each ungrowable cell (forest or invalid tile)
			# 4 * distance is the total amount of cells at that distance
			# len(cell_entries) is the amount of growable cells
			tree_amount -= 4 * distance - len(cell_entries)
			
			distance += 1
		
		emit_signal("score_changed")
		return true
	else:
		return false

func show_growth_effect(cell_position: Vector2i):
	var growth_effect: GrowthEffect = GrowthEffect.instantiate()
	growth_effect.position.x = cell_position.x * tile_set.tile_size.x
	growth_effect.position.y = cell_position.y * tile_set.tile_size.y
	growth_effect.connect("complete", remove_growth_effect)
	add_child(growth_effect)

func remove_growth_effect(growth_effect: GrowthEffect):
	remove_child(growth_effect)
	growth_effect.queue_free()

func count_strikeable_spots():
	return count_spots(can_lightning_strike)

func can_lightning_strike(cell_position: Vector2i):
	if is_house(cell_position) or is_build_site(cell_position):
		return true
	else:
		for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			if is_house(cell_position + diff) or is_build_site(cell_position + diff):
				return true
		for diff in [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, -1)]:
			if is_house(cell_position + diff) or is_build_site(cell_position + diff):
				return true
		return false

func strike_with_lightning(cell_position: Vector2i):
	if can_lightning_strike(cell_position):
		var lightning: LightningStrike = LightningStrike.instantiate()
		lightning.position.x = cell_position.x * tile_set.tile_size.x
		lightning.position.y = cell_position.y * tile_set.tile_size.y
		lightning.connect("complete", remove_lightning)
		add_child(lightning)
		lightning.summon()
		
		var previous_villager_amount = len(villagers.villagers)
		set_building_progress(cell_position, 0)
		for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			set_building_progress(cell_position + diff, 0)
		for diff in [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, -1)]:
			decrease_building_progress(cell_position + diff, 5)
		
		total_lightning_strikes += 1
		deaths_to_lightning += previous_villager_amount - len(villagers.villagers)
		return true
	else:
		return false

func remove_lightning(lightning_strike: LightningStrike):
	remove_child(lightning_strike)
	lightning_strike.queue_free()

func count_treant_spawn_spots():
	return count_spots(treants.can_spawn)

func count_treantling_spawn_spots():
	return count_spots(treantlings.can_spawn)

func count_druid_spawn_spots():
	return count_spots(druids.can_spawn)

func blast_with_fire(cell_position: Vector2i):
	var blast: Blast = Blast.instantiate()
	blast.position.x = cell_position.x * tile_set.tile_size.x
	blast.position.y = cell_position.y * tile_set.tile_size.y
	blast.connect("complete", remove_blast)
	add_child(blast)
	blast.activate()
	
	decrease_yield(cell_position, 10)
	decrease_building_progress(cell_position, 10)
	for i in 3:
		var distance = i + 1
		for d1 in distance:
			var d2 = distance - d1
			for diff in [Vector2i(d1, d2), Vector2i(-d2, d1), Vector2i(-d1, -d2), Vector2i(d2, -d1)]:
				var target_cell = cell_position + diff
				if is_valid_tile(target_cell):
					if distance == 3:
						decrease_yield(target_cell, 5)
						decrease_building_progress(target_cell, 3)
					else:
						decrease_yield(target_cell, 10)
						decrease_building_progress(target_cell, 6)

func remove_blast(blast: Blast):
	remove_child(blast)
	blast.queue_free()

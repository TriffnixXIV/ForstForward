extends Level
class_name Map

@export var levels: Array[PackedScene]
var current_level: int = 0

var transition_duration: float = 0.25
var transition_progress: float = 0.0
var transition_info = []

@export var Villager: PackedScene
var villagers: Array = []
var homeless_villagers = []
var home_cell_villager_map = {}
var done_villager_count = 0
var all_villagers_are_done_with_this_step = false

@export var Druid: PackedScene
var druids = []
var done_druid_count = 0

@export var Treant: PackedScene
var treants = []
var done_treant_count = 0

@export var ForestEdge: PackedScene
var horizontal_forest_edges = []
var vertical_forest_edges = []

@export var LightningStrike: PackedScene
@export var Blast: PackedScene
@export var GrowthEffect: PackedScene

var highest_possible_score: int

var total_felled_trees: int = 0
var highest_villager_count: int = 0
var total_born_villagers: int = 0
var total_dead_villagers: int = 0
var total_deaths_to_treants: int = 0
var total_deaths_to_lightning: int = 0
var total_beer_level: int = 0
var actions_lost_to_beer: int = 0

var total_grown_trees: int = 0
var total_planted_trees: int = 0
var total_spread_trees: int = 0
var total_growth_stages: int = 0
var total_rain_duration: int = 0
var total_lightning_strikes: int = 0
var total_trees_from_druids: int = 0
var total_treants_spawned: int = 0
var total_trees_from_treants: int = 0

var base_growth_stages = 1
var growth_boost = 0
var remaining_growth_stages = 0

var rain_duration = 0
var beer_level = 0

var show_cell_labels = false
var cell_labels: Array[Array]
var cell_tree_distance_map: Array[Array]

enum Phase {transitioning, idle, starting, druids, growth, villagers}
var current_phase = Phase.idle

signal transition_done
signal score_changed
signal advancement_step_done
signal advancement_done

func _ready():
	super._ready()
	
	highest_possible_score = width * height * 10
	
	var array = []
	array.resize(height)
	for x in width + 1:
		horizontal_forest_edges.append(array.duplicate())
	array.resize(width)
	for y in height + 1:
		vertical_forest_edges.append(array.duplicate())
	
	cell_tree_distance_map = []
	array.resize(height)
	array.fill(width + height + 1)
	for x in width:
		cell_tree_distance_map.append(array.duplicate())
	
	if show_cell_labels:
		$CellNumbers.visible = true
		cell_labels = []
		for x in width:
			cell_labels.append(array.duplicate())
			for y in height:
				var label = Label.new()
				label.size = Vector2i(20, 20)
				label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.label_settings = $CellNumbers/Dummy.label_settings
				label.position.x = x * 20
				label.position.y = y * 20
				cell_labels[x][y] = label
				$CellNumbers.add_child(label)

func _process(delta):
	if transition_progress < transition_duration and len(transition_info) > 0:
		var start_index = floori((len(transition_info) - 1) * transition_progress / transition_duration)
		transition_progress = min(transition_duration, transition_progress + delta)
		var end_index = floori(len(transition_info) * transition_progress / transition_duration)
		
		for i in range(start_index, end_index):
			var data = transition_info[i]
			
			despawn_villager_at(data[1], true)
			
			set_cell(data[0], data[1], data[2], data[3])
			
			if is_house(data[1]):
				spawn_villager(data[1])
		update_forest_edges()
	elif current_phase == Phase.transitioning:
		if len(villagers) > 0:
			var horst_exists = false
			for villager in villagers:
				if villager.is_devil:
					horst_exists = true
					break
			if not horst_exists:
				villagers[0].get_real()
		current_phase = Phase.idle
		emit_signal("transition_done")

func load_level(level_number: int):
	var level = levels[level_number].instantiate()
	level_name = level.level_name
	level_id = level.level_id
	
	level.load_save_data()
	save_data = level.save_data
	
	for x in width:
		for y in height:
			var cell = Vector2i(x, y)
			if not is_identical_tile(Vector2i(x, y), level.get_cell_source_id(0, cell), level.get_cell_atlas_coords(0, cell)):
				transition_info.append(
					[0, cell, level.get_cell_source_id(0, cell), level.get_cell_atlas_coords(0, cell)]
				)
	
	transition_info.shuffle()
	current_phase = Phase.transitioning

func set_level(level_number: int):
	current_level = level_number
	reload_level()

func reload_level():
	reset()
	load_level(current_level)

func clear_level():
	reset()
	
	for x in width:
		for y in height:
			if not is_forest(Vector2i(x, y)):
				transition_info.append(
					[0, Vector2i(x, y), TileType.forest, Vector2i(0, 0)]
				)
	
	transition_info.shuffle()
	current_phase = Phase.transitioning

func stop():
	$Timer.stop()
	set_rain(0)
	set_beer(0)
	current_phase = Phase.idle

func reset():
	transition_progress = 0.0
	transition_info = []
	
	reset_stats()
	growth_boost = 0
	set_rain(0)
	set_beer(0)
	$Timer.stop()
	
	for villager in homeless_villagers:
		despawn_villager(villager, true)
	for villager in villagers:
		villager.reset()
	for druid in druids:
		remove_child(druid)
		druid.queue_free()
	druids = []
	for treant in treants:
		remove_child(treant)
		treant.queue_free()
	treants = []

func reset_stats():
	total_felled_trees = 0
	highest_villager_count = 0
	total_born_villagers = 0
	total_dead_villagers = 0
	total_deaths_to_treants = 0
	total_deaths_to_lightning = 0
	total_beer_level = 0
	actions_lost_to_beer = 0
	
	total_grown_trees = 0
	total_planted_trees = 0
	total_spread_trees = 0
	total_growth_stages = 0
	total_lightning_strikes = 0
	total_rain_duration = 0
	total_trees_from_druids = 0
	total_treants_spawned = 0
	total_trees_from_treants = 0

# cell type stuff

func set_plains(cell_position: Vector2i):
	set_cell(0, cell_position, TileType.plains, Vector2i(0, 0))

func set_growth(cell_position: Vector2i, amount: int):
	set_cell(0, cell_position, TileType.growth, Vector2i(amount - 1, 0))

func set_forest(cell_position: Vector2i):
	set_cell(0, cell_position, TileType.forest, Vector2i(0, 0))
	update_cell_forest_edges(cell_position)

func set_build_site(cell_position: Vector2i, progress: int):
	set_cell(0, cell_position, TileType.build_site, Vector2i(progress - 1, 0))

func set_house(cell_position: Vector2i):
	set_cell(0, cell_position, TileType.house, Vector2i(0, 0))

# forest edge stuff

func update_forest_edges():
	for x in width + 1:
		for y in height + 1:
			update_horizontal_edge(Vector2i(x, y))
			update_vertical_edge(Vector2i(x, y))

func update_cell_forest_edges(cell_position: Vector2i):
	update_horizontal_edge(cell_position)
	update_horizontal_edge(cell_position + Vector2i(0, 1))
	update_vertical_edge(cell_position)
	update_vertical_edge(cell_position + Vector2i(1, 0))

func update_vertical_edge(edge_position: Vector2i):
	if edge_position.x < len(horizontal_forest_edges) and edge_position.y < len(horizontal_forest_edges[edge_position.x]):
		var show_edge = (get_cell_source_id(0, edge_position) in [-1, 2]) != (get_cell_source_id(0, Vector2i(edge_position.x-1, edge_position.y)) in [-1, 2])
		if show_edge and horizontal_forest_edges[edge_position.x][edge_position.y] == null:
			var instance = ForestEdge.instantiate()
			instance.position = Vector2i(edge_position.x * tile_set.tile_size.x, int((edge_position.y + 0.5) * tile_set.tile_size.y))
			horizontal_forest_edges[edge_position.x][edge_position.y] = instance
			add_child(instance)
		if not show_edge and not horizontal_forest_edges[edge_position.x][edge_position.y] == null:
			var instance = horizontal_forest_edges[edge_position.x][edge_position.y]
			instance.queue_free()
			horizontal_forest_edges[edge_position.x][edge_position.y] = null

func update_horizontal_edge(edge_position: Vector2i):
	if edge_position.y < len(vertical_forest_edges) and edge_position.x < len(vertical_forest_edges[edge_position.y]):
		var show_edge = (get_cell_source_id(0, edge_position) in [-1, 2]) != (get_cell_source_id(0, Vector2i(edge_position.x, edge_position.y-1)) in [-1, 2])
		if show_edge and vertical_forest_edges[edge_position.y][edge_position.x] == null:
			var instance = ForestEdge.instantiate()
			instance.position = Vector2i(int((edge_position.x + 0.5) * tile_set.tile_size.x), edge_position.y * tile_set.tile_size.y)
			instance.rotation = PI / 2
			vertical_forest_edges[edge_position.y][edge_position.x] = instance
			add_child(instance)
		if not show_edge and not vertical_forest_edges[edge_position.y][edge_position.x] == null:
			var instance = vertical_forest_edges[edge_position.y][edge_position.x]
			instance.queue_free()
			vertical_forest_edges[edge_position.y][edge_position.x] = null

# map update stuff

func advance():
	$AdvancementStart.play()
	current_phase = Phase.starting
	$Timer.start()

func start_druid_phase():
	if len(druids) == 0 and len(treants) == 0:
		start_growth_phase()
	else:
		$DruidStart.play()
		current_phase = Phase.druids
		done_druid_count = 0
		for druid in druids:
			druid.reset_actions()
		done_treant_count = 0
		for treant in treants:
			treant.reset_actions()
		$Timer.start()

func advance_druid_phase():
	$DruidAdvance.play()
	for druid in druids:
		druid.act()
	for treant in treants:
		treant.act()
	$Timer.start()

func _on_druid_done_acting():
	done_druid_count += 1

func _on_treant_done_acting():
	done_treant_count += 1

func start_growth_phase():
	$GrowthStart.play()
	current_phase = Phase.growth
	remaining_growth_stages = get_growth_stages()
	$Timer.start()

func advance_growth_phase():
	$GrowthAdvance.play()
	var growth_amounts: Dictionary = {}
	for x in width:
		for y in height:
			if is_forest(Vector2i(x, y)):
				for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
					var cell = Vector2i(x, y) + diff
					if cell in growth_amounts:
						growth_amounts[cell] += 1
					else:
						growth_amounts[cell] = 1
	
	for cell in growth_amounts:
		var previous_yield = get_yield(cell)
		increase_yield(cell, growth_amounts[cell])
		total_grown_trees += get_yield(cell) - previous_yield
	
	update_forest_edges()
	remaining_growth_stages -= 1
	total_growth_stages += 1
	$Timer.start()

func start_villager_phase():
	$HorstStart.play()
	done_villager_count = 0
	current_phase = Phase.villagers
	for villager in villagers:
		villager.prepare_turn()
	update_cell_tree_distance_map()
	all_villagers_are_done_with_this_step = true
	$Timer.start()

func advance_villager_phase():
	$HorstAdvance.play()
	all_villagers_are_done_with_this_step = false
	$Timer.start()
	for villager in villagers:
		villager.act()
	all_villagers_are_done_with_this_step = true
	advance_phase()

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
			if done_druid_count < len(druids) or done_treant_count < len(treants):
				advance_druid_phase()
			else:
				done_druid_count = 0
				done_treant_count = 0
				start_growth_phase()
		Phase.growth:
			if remaining_growth_stages > 0:
				advance_growth_phase()
			else:
				start_villager_phase()
		Phase.villagers:
			if $Timer.is_stopped() and all_villagers_are_done_with_this_step:
				if done_villager_count < len(villagers):
					advance_villager_phase()
				else:
					done_villager_count = 0
					finish_advancement()

func finish_advancement():
	current_phase = Phase.idle
	growth_boost = max(0, floori(0.5 * growth_boost))
	advance_rain()
	advance_beer()
	emit_signal("advancement_done")

# miscellaneous advancement stuff

func reset_cell_tree_distance_map():
	for x in width:
		for y in height:
			cell_tree_distance_map[x][y] = width + height + 1

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
	var growth_stages = base_growth_stages + growth_boost
	if rain_duration > 0:
		growth_stages += 1
	return growth_stages

func advance_rain():
	if rain_duration > 0:
		total_rain_duration += 1
	set_rain(rain_duration - 1)

func set_rain(duration: int):
	rain_duration = max(0, duration)
	update_rain_overlay()

func advance_beer():
	total_beer_level += beer_level
	set_beer(floori(0.5 * beer_level))

func set_beer(amount: int):
	beer_level = amount
	update_beer_overlay()

# UI stuff

func update_rain_overlay():
	if rain_duration > 0:
		$RainOverlay.visible = true
	else:
		$RainOverlay.visible = false

func update_beer_overlay():
	if beer_level > 0:
		$BeerOverlay.visible = true
		$BeerOverlay.modulate.a = min(1, beer_level / 10.0)
	else:
		$BeerOverlay.visible = false

func set_cell_labels(values: Array[Array]):
	if show_cell_labels:
		for x in width:
			for y in height:
				cell_labels[x][y].text = str(values[x][y])

# cell changes

func get_growable_amount(cell_position: Vector2i):
	if is_valid_tile(cell_position):
		return get_building_progress(cell_position) + 10 - get_yield(cell_position)
	else:
		return 0

func get_yield(cell_position: Vector2i):
	if is_forest(cell_position):
		return 10
	elif is_growth(cell_position):
		return get_cell_atlas_coords(0, cell_position).x + 1
	else:
		return 0

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
	if not is_valid_tile(cell_position):
		return null
	
	var previous_yield = get_yield(cell_position)
	if previous_yield != amount:
		if amount > 0 and amount < 10:
			set_growth(cell_position, amount)
		elif amount >= 10:
			set_forest(cell_position)
		else:
			set_plains(cell_position)
		if previous_yield >= 10 and amount < 10:
			update_cell_forest_edges(cell_position)

func get_building_progress(cell_position: Vector2i):
	if is_house(cell_position):
		return 10
	if is_build_site(cell_position):
		return get_cell_atlas_coords(0, cell_position).x + 1
	else:
		return 0

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
	if not is_valid_tile(cell_position):
		return null
	
	var previous_progress = get_building_progress(cell_position)
	if previous_progress != progress:
		if progress > 0 and progress < 10:
			set_build_site(cell_position, progress)
		elif progress >= 10:
			set_house(cell_position)
			if not cell_position in home_cell_villager_map:
				if len(homeless_villagers) > 0:
					var villager = homeless_villagers.pop_back()
					villager.home_cell = cell_position
					home_cell_villager_map[cell_position] = villager
				else:
					spawn_villager(cell_position)
		else:
			set_plains(cell_position)
			despawn_villager_at(cell_position)

func spawn_villager(cell_position: Vector2i):
	var villager: Villager = Villager.instantiate()
	villager.cell_position = cell_position
	villager.home_cell = cell_position
	villager.map = self
	villager.update_position()
	villager.connect("done_acting", _on_villager_done_acting)
	
	home_cell_villager_map[cell_position] = villager
	villagers.append(villager)
	villager.actions = villagers[0].actions
	
	add_child(villager)
	
	if not current_phase == Phase.transitioning:
		total_born_villagers += 1
	highest_villager_count = max(highest_villager_count, len(villagers))
	

func despawn_villager_at(cell_position: Vector2i, also_horst: bool = false):
	if cell_position in home_cell_villager_map:
		var villager = home_cell_villager_map[cell_position]
		despawn_villager(villager, also_horst)

func despawn_villager(villager: Villager, also_horst: bool = true):
	home_cell_villager_map.erase(villager.home_cell)
	if also_horst or not villager.is_devil:
		villagers.erase(villager)
		homeless_villagers.erase(villager)
		remove_child(villager)
		villager.queue_free()
		if not current_phase == Phase.transitioning:
			total_dead_villagers += 1
	else:
		homeless_villagers.append(villager)
		villager.home_cell = null

# miscellaneous functions

func find_closest_cell_of_type(cell_position: Vector2i, types, max_distance: int = 50):
	return find_closest_matching_cell(cell_position, cell_of_type, types, max_distance)

func cell_of_type(cell_position: Vector2i, types):
	return get_cell_source_id(0, cell_position) in types

func find_closest_matching_cell(cell_position: Vector2i, match_function, extra_argument = null, max_distance = 50):
	var closest_matching_cells = find_closest_matching_cells(cell_position, match_function, extra_argument, max_distance)
	if closest_matching_cells != []:
		return closest_matching_cells[randi_range(0, len(closest_matching_cells)-1)]
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
	return is_plains(cell_position) or is_growth(cell_position)

func plant_forest(cell_position: Vector2i):
	if can_plant_forest(cell_position):
		var previous_yield = get_yield(cell_position)
		set_forest(cell_position)
		show_growth_effect(cell_position)
		total_planted_trees += get_yield(cell_position) - previous_yield
		emit_signal("score_changed")
		return true
	else:
		return false

func count_spreadable_spots():
	return count_spots(can_spread_forest)

func can_spread_forest(cell_position: Vector2i):
	return is_forest(cell_position)

func spread_forest(cell_position: Vector2i, tree_amount: int, from_treant: bool = false):
	if can_spread_forest(cell_position):
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
				if from_treant:
					total_trees_from_treants += cell_entry[2]
				else:
					total_spread_trees += cell_entry[2]
			
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
		
		var previous_villager_amount = len(villagers)
		set_building_progress(cell_position, 0)
		for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			set_building_progress(cell_position + diff, 0)
		for diff in [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, -1)]:
			decrease_building_progress(cell_position + diff, 5)
		
		total_lightning_strikes += 1
		total_deaths_to_lightning += previous_villager_amount - len(villagers)
		return true
	else:
		return false

func remove_lightning(lightning_strike: LightningStrike):
	remove_child(lightning_strike)
	lightning_strike.queue_free()

func count_treant_spawn_spots():
	return count_spots(can_spawn_treant)

func can_spawn_treant(cell_position: Vector2i):
	for diff in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
		var cell = cell_position + diff
		if not is_forest(cell):
			return false
	return true

func spawn_treant(cell_position: Vector2i):
	if can_spawn_treant(cell_position):
		var treant: Treant = Treant.instantiate()
		treant.cell_position = cell_position
		treant.map = self
		treant.update_position()
		treant.connect("done_acting", _on_treant_done_acting)
		treant.connect("has_died", despawn_treant)
		treants.append(treant)
		add_child(treant)
		total_treants_spawned += 1
		return true
	else:
		return false

func despawn_treant(treant: Treant):
	treants.erase(treant)
	remove_child(treant)
	treant.queue_free()

func count_druid_spawn_spots():
	return count_spots(can_spawn_druid)

func can_spawn_druid(cell_position: Vector2i):
	return is_forest(cell_position)

func spawn_druid(cell_position: Vector2i):
	if can_spawn_druid(cell_position):
		var druid: Druid = Druid.instantiate()
		druid.cell_position = cell_position
		druid.map = self
		druid.update_position()
		druid.connect("done_acting", _on_druid_done_acting)
		druids.append(druid)
		add_child(druid)
		return true
	else:
		return false

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

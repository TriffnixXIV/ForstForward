extends Creature
class_name Druid

var actions = 0

enum State {idle, moving, planting, tired}
var state = State.idle

# for finding spots
var good_spots
var spot_distance
var value_threshhold

enum CircleState {active, fading, gone}
var circle_state = CircleState.gone

var self_growth = 4
var edge_growth = 2
var corner_growth = 1

signal grown_trees

func _ready():
	update_circle_state()

func prepare_turn(action_amount: int):
	actions = action_amount

func act():
	if actions <= 0:
		return false
	
	update_state()
	match state:
		State.planting:
			set_circle_state(CircleState.active)
			var previous_villager_amount = len(map.villagers.villagers)
			map.druids.trees += map.increase_yield(cell_position, self_growth)
			for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
				map.druids.trees += map.increase_yield(cell_position + diff, edge_growth)
			for diff in [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, -1)]:
				map.druids.trees += map.increase_yield(cell_position + diff, corner_growth)
			state = State.tired
			map.druids.kills += previous_villager_amount - len(map.villagers.villagers)
			emit_signal("grown_trees")
		State.moving:
			move(0)
		State.tired:
			state = State.planting
	
	actions -= 1
	return actions > 0

func update_state():
	set_state(state)

func set_state(new_state: State):
	match new_state:
		State.idle:
			set_state(State.moving)
		State.planting:
			set_state(State.moving)
		State.moving:
			update_target_location()
			if target_location == null:
				state = State.idle
			elif cell_position == target_location:
				state = State.planting
			else:
				state = State.moving
		State.tired:
			pass

func set_circle_trees(amount: int):
	self_growth = amount % 8
	edge_growth = floori(amount / 8.0)
	corner_growth = floori(amount / 8.0)
	while corner_growth > 1 and self_growth < edge_growth and self_growth < 10:
		corner_growth -= 1
		self_growth += 4

func update_circle_state():
	set_circle_state(circle_state)

func _on_timer_timeout():
	advance_circle_state()

func advance_circle_state():
	match circle_state:
		CircleState.active:
			set_circle_state(CircleState.fading)
			$Circle/Timer.start()
		CircleState.fading:
			set_circle_state(CircleState.gone)

func set_circle_state(new_circle_state):
	circle_state = new_circle_state
	match circle_state:
		CircleState.active:
			$Circle.visible = true
			$Circle.modulate.a = 1
			$Circle/Timer.start()
		CircleState.fading:
			$Circle.visible = true
			$Circle.modulate.a = 0.5
		CircleState.gone:
			$Circle.visible = false

func update_target_location():
	find_good_spots()
	if len(good_spots) > 0:
		target_location = good_spots[randi_range(0, len(good_spots) - 1)]
	else:
		target_location = null

func find_good_spots():
	good_spots = []
	spot_distance = 0
	
	var max_value = self_growth + 3 * edge_growth # the highest possible result of the evaluation function
	var max_distance = map.width + map.height
	value_threshhold = max_value - pow(max_distance, 2)
	
	while max_value - pow(spot_distance, 2) > value_threshhold:
		if spot_distance == 0:
			check_cell(cell_position)
		
		for d1 in spot_distance:
			var d2 = spot_distance - d1
			for diff in [Vector2i(d1, d2), Vector2i(-d2, d1), Vector2i(-d1, -d2), Vector2i(d2, -d1)]:
				check_cell(cell_position + diff)
		
		spot_distance += 1

func check_cell(cell: Vector2i):
	var cell_value = evaluate_target_location(cell)
	if cell_value > 0:
		var score = cell_value - pow(spot_distance, 2)
		if score > value_threshhold:
			good_spots = [cell]
			value_threshhold = score
		elif score == value_threshhold:
			good_spots.append(cell)

func evaluate_target_location(cell: Vector2i):
	if not map.is_walkable(cell) or map.get_building_progress(cell) > 0:
		return 0
	else:
		var has_adjacent_forest = false
		var value = 0
		if not map.is_forest(cell):
			value += min(self_growth, map.get_growable_amount(cell))
		else:
			has_adjacent_forest = true
		
		for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			value += min(edge_growth, map.get_growable_amount(cell + diff))
			if map.is_forest(cell + diff):
				has_adjacent_forest = true
		
		for diff in [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, -1)]:
			value += min(corner_growth, map.get_growable_amount(cell + diff))
			if map.is_forest(cell + diff):
				has_adjacent_forest = true
		
		if has_adjacent_forest:
			return min(value, self_growth + 3 * edge_growth)
		else:
			return 0

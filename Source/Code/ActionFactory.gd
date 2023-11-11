extends Node
class_name ActionFactory

var map

var base_action_data = {
	Action.Type.spawn_treant: {
		"unlocked": true,
		"weight": 4,
		"specifier": 1
	},
	Action.Type.spawn_druid: {
		"unlocked": true,
		"weight": 3,
		"specifier": 1
	},
	Action.Type.overgrowth: {
		"unlocked": true,
		"weight": 3,
		"specifier": 2
	},
	Action.Type.spread: {
		"unlocked": true,
		"weight": 3,
		"specifier": 2
	},
	Action.Type.plant: {
		"unlocked": true,
		"weight": 3,
		"specifier": 2
	},
	Action.Type.rain: {
		"unlocked": true,
		"weight": 3,
		"specifier": 3
	},
	Action.Type.lightning_strike: {
		"unlocked": true,
		"weight": 3,
		"specifier": 1
	},
	Action.Type.beer: {
		"unlocked": true,
		"weight": 3,
		"specifier": 1
	}
}

func get_actions(current_round, amount: int = 2):
	var actions = []
	var possible_actions = get_possible_actions(current_round)
	
	var weight_total = 0
	for entry in possible_actions:
		weight_total += entry[0]
	
	while len(actions) < amount:
		var x = randi_range(0, weight_total - 1)
		for i in len(possible_actions):
			var weight = possible_actions[i][0]
			var action = possible_actions[i][1]
			if x < weight:
				actions.append(action)
				possible_actions.remove_at(i)
				weight_total -= weight
				break
			x -= weight
	
	var earlier_type = func (a: Action, b: Action): return a.type < b.type
	actions.sort_custom(earlier_type)
	return actions

func get_possible_actions(current_round):
	var possible_actions = []
	for action_type in len(Action.Type):
		if base_action_data[action_type]["unlocked"]:
			var action_data = get_action_data(action_type, current_round)
			if action_data["is possible"]:
				possible_actions.append([action_data["weight"], action_data["action"]])
	return possible_actions

func get_action_data(action_type, current_round):
	var is_possible = true
	var weight = base_action_data[action_type]["weight"]
	var action = Action.new()
	action.type = action_type
	action.specifier = base_action_data[action_type]["specifier"]
	match action_type:
		Action.Type.spawn_treant:
			var treant_spawn_spots = map.count_treant_spawn_spots()
			weight = floori(len(map.villagers) / 15.0) - len(map.treants) - 3
			is_possible = treant_spawn_spots > 0 and weight > 0
		
		Action.Type.spawn_druid:
			var druid_spawn_spots = map.count_druid_spawn_spots()
			is_possible = druid_spawn_spots > 0
		
		Action.Type.overgrowth:
			action.specifier = 2 + floori(current_round / 15.0)
		
		Action.Type.spread:
			var spreadable_spots = map.count_spreadable_spots()
			is_possible = spreadable_spots > 0
			action.specifier = 40 + 4 * current_round
		
		Action.Type.plant:
			var plantable_spots = map.count_plantable_spots()
			is_possible = plantable_spots > 0
			action.specifier = min(plantable_spots, 2 + floori(current_round / 5.0))
			
			# convert a semi-random number of forests into a spread action
			var converted_forests = randi_range(
				max(0, action.specifier - 10),
				max(0, action.specifier - 4)
			)
			if converted_forests > 0:
				# action.specifier will be between 4 and 10
				action.specifier -= converted_forests
				
				# the spread action will be [20 * number of converted forests] strong
				var spread_action = Action.new()
				spread_action.type = Action.Type.spread
				spread_action.specifier = 20 * converted_forests
				spread_action.infer_needed_progress()
				action.add_action(spread_action)
		
		Action.Type.lightning_strike:
			action.specifier = min(
				2 + floori(map.rain_duration / 3.0),
				floori(len(map.villagers) / 9.0)
			)
			is_possible = map.is_raining() and action.specifier > 0
			weight = 3 + action.specifier
			
			# if the lightning strike count is low in regards to existing villages,
			# give some free rain on top to get the count up next time
			if action.specifier < floori(len(map.villagers) / 9.0):
				var rain_action = Action.new()
				rain_action.type = Action.Type.rain
				rain_action.specifier = 3 + floori(current_round / 15.0)
				rain_action.infer_needed_progress()
				action.add_action(rain_action)
		
		Action.Type.rain:
			action.specifier = 4 + floori(current_round / 10.0)
			weight = 3 - floori(map.rain_duration / action.specifier)
			is_possible = weight > 0
		
		Action.Type.beer:
			action.specifier = 6 + floori(current_round / 10.0)
		
	action.infer_needed_progress()
	return {"is possible": is_possible, "weight": weight, "action": action}

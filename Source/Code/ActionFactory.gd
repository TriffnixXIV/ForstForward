extends Node
class_name ActionFactory

var map: Map

#var occurences = {
#	"spawn_treant": 0,
#	"spawn_druid": 0,
#	"overgrowth": 0,
#	"spread": 0,
#	"plant": 0,
#	"rain": 0,
#	"summon_lightning": 0,
#	"beer": 0
#}

var action_prototypes = {
	Action.Type.spawn_treant:
		ActionPrototype.new(Action.Type.spawn_treant),
	Action.Type.spawn_druid: 
		ActionPrototype.new(Action.Type.spawn_druid),
	Action.Type.overgrowth: 
		ActionPrototype.new(Action.Type.overgrowth),
	Action.Type.spread: 
		ActionPrototype.new(Action.Type.spread),
	Action.Type.plant: 
		ActionPrototype.new(Action.Type.plant),
	Action.Type.rain: 
		ActionPrototype.new(Action.Type.rain),
	Action.Type.lightning_strike: 
		ActionPrototype.new(Action.Type.lightning_strike),
	Action.Type.beer: 
		ActionPrototype.new(Action.Type.beer)
}

func reset():
	for key in action_prototypes:
		action_prototypes[key].reset()

func get_actions(amount: int = 2):
	var actions = []
	var possible_actions = get_possible_actions()
	
	var weight_total = 0
	for entry in possible_actions:
		weight_total += entry[0]
	
#	var printarray = []
#	for entry in possible_actions:
#		printarray.append([entry[0], Action.Type.keys()[entry[1].type]])
#	print(printarray)
	
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
#	printarray = []
#	for action in actions:
#		occurences[Action.Type.keys()[action.type]] += 1
#		printarray.append(Action.Type.keys()[action.type])
#	print(printarray, " ", occurences)
	return actions

func get_possible_actions():
	var possible_actions = []
	for action_type in len(Action.Type):
		if action_prototypes[action_type].unlocked:
			var action_data = get_action_data(action_type)
			if action_data["is possible"]:
				possible_actions.append([action_data["weight"], action_data["action"]])
	return possible_actions

func get_action_data(action_type):
	var is_possible = true
	var weight = action_prototypes[action_type].weight
	var action = Action.new()
	action.type = action_type
	action.strength = action_prototypes[action_type].strength
	action.clicks = action_prototypes[action_type].clicks
	match action_type:
		Action.Type.spawn_treant:
			var treant_spawn_spots = map.count_treant_spawn_spots()
			is_possible = treant_spawn_spots > 0
		
		Action.Type.spawn_druid:
			var druid_spawn_spots = map.count_druid_spawn_spots()
			is_possible = druid_spawn_spots > 0
		
		Action.Type.spread:
			var spreadable_spots = map.count_spreadable_spots()
			is_possible = spreadable_spots > 0
		
		Action.Type.plant:
			var plantable_spots = map.count_plantable_spots()
			is_possible = plantable_spots > 0
			action.clicks = min(plantable_spots, action.clicks)
			
			# convert a semi-random number of forests into a spread action
			var converted_forests = randi_range(
				max(0, action.clicks - 10),
				max(0, action.clicks - 4)
			)
			if converted_forests > 0:
				# plant will be between 4 and 10 forests
				action.clicks -= converted_forests
				
				# the spread action will be [20 * number of converted forests] strong
				var spread_action = Action.new()
				spread_action.type = Action.Type.spread
				spread_action.strength = 20 * converted_forests
				spread_action.clicks = 1
				action.add_action(spread_action)
		
		Action.Type.lightning_strike:
			action.clicks = min(
				action.clicks + floori(map.rain_duration / 3.0),
				floori(len(map.villagers) / 9.0)
			)
			is_possible = map.is_raining() and action.clicks > 0
			
			# if the lightning strike count is low in regards to existing villages,
			# give some free rain on top to get the count up next time
			if action.clicks < floori(len(map.villagers) / 9.0):
				var rain_action = Action.new()
				rain_action.type = Action.Type.rain
				rain_action.strength = 3
				action.add_action(rain_action)
		
		Action.Type.rain:
			weight -= floori(map.rain_duration / action.strength)
			is_possible = weight > 0
	
	return {"is possible": is_possible, "weight": weight, "action": action}

extends Node
class_name ActionFactory

var map: Map

var action_prototypes = {
	Action.Type.spawn_treant:
		ActionPrototype.new(Action.Type.spawn_treant),
	Action.Type.spawn_treantling:
		ActionPrototype.new(Action.Type.spawn_treantling),
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
	Action.Type.frost: 
		ActionPrototype.new(Action.Type.frost)
}

var base_rain_lightning_conversion_unlocked = false
var base_rain_lightning_conversion = 6

var rain_lightning_conversion_unlocked: bool
var rain_lightning_conversion: int

func reset():
	rain_lightning_conversion_unlocked = base_rain_lightning_conversion_unlocked
	rain_lightning_conversion = base_rain_lightning_conversion
	
	for key in action_prototypes:
		action_prototypes[key].reset()

func get_actions(amount: int = 2):
	var actions = []
	var possible_actions = get_possible_actions()
	
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
	action.set_action(action_prototypes[action_type])
	match action_type:
		Action.Type.spawn_treant:
			var treant_spawn_spots = map.count_treant_spawn_spots()
			is_possible = treant_spawn_spots > 0
		
		Action.Type.spawn_treantling:
			var treant_spawn_spots = map.count_treantling_spawn_spots()
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
		
		Action.Type.lightning_strike:
			if rain_lightning_conversion_unlocked:
				action.clicks += floori(map.rain_duration / float(rain_lightning_conversion))
			is_possible = map.is_raining() and action.clicks > 0
		
		Action.Type.rain:
			weight -= floori(map.rain_duration / action.strength)
			is_possible = weight > 0
	
	return {"is possible": is_possible, "weight": weight, "action": action}

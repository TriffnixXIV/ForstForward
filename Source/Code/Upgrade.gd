extends Resource
class_name Upgrade

var value = null
var previous_value = null
var other_values = []

enum Type {none, villager, treant, treantling, druid, growth, spread, plant, rain, lightning, frost}
var type: Type = Type.none

enum Attribute {none, unlock, clicks, strength, actions, minimum,
	lifespan, growth, spread, on_plains, on_buildings, unlock_rain, rain, rain_conversion, frost}
var attribute: Attribute = Attribute.none

func _init(type_: Type = Type.none, attribute_: Attribute = Attribute.none,
			value_ = null, previous_value_ = null, other_values_ = []):
	type = type_
	attribute = attribute_
	value = value_
	previous_value = previous_value_
	other_values = other_values_

func reset():
	type = Type.none
	attribute = Attribute.none
	previous_value = null
	value = null
	other_values = []

func set_upgrade(other: Upgrade):
	type = other.type
	attribute = other.attribute
	previous_value = other.previous_value
	value = other.value
	other_values = other.other_values

func get_text():
	match type:
		Type.treant:
			match attribute:
				Attribute.unlock:
					return "unlock treants"
				Attribute.clicks:
					return "treant spawns\n" + str(previous_value) + " -> " + str(value)
				Attribute.actions:
					if len(other_values) > 0:
						var lifespan_text = "\nlifespan\n" + str(other_values[0]) + " -> " + str(other_values[1])
						return "treant actions\n" + str(previous_value) + " -> " + str(value) + lifespan_text
					else:
						return "treant actions\n" + str(previous_value) + " -> " + str(value)
				Attribute.lifespan:
					return "treant actions\n" + str(previous_value) + " -> " + str(value) + "\ntreants now die after " + str(other_values[0]) + " actions"
				Attribute.spread:
					var lifespan_text = "\nlifespan\n" + str(other_values[0]) + " -> " + str(other_values[1])
					return "treant death spread\n4x" + str(previous_value) + " -> 4x" + str(value) + lifespan_text
		Type.treantling:
			match attribute:
				Attribute.clicks:
					return "treantling spawns\n" + str(previous_value) + " -> " + str(value)
				Attribute.actions:
					var lifespan_text = "\nlifespan\n" + str(other_values[0]) + " -> " + str(other_values[1])
					return "treantling actions\n" + str(previous_value) + " -> " + str(value) + lifespan_text
				Attribute.strength:
					return "treantling strength\n" + str(previous_value) + " -> " + str(value)
				Attribute.spread:
					var lifespan_text = "\nlifespan\n" + str(other_values[0]) + " -> " + str(other_values[1])
					return "treantling death spread\n" + str(previous_value) + " -> " + str(value) + lifespan_text
		Type.druid:
			match attribute:
				Attribute.clicks:
					return "druid spawns\n" + str(previous_value) + " -> " + str(value)
				Attribute.actions:
					return "druid actions\n" + str(previous_value) + " -> " + str(value)
				Attribute.strength:
					return "druid circle trees\n" + str(previous_value) + " -> " + str(value)
		Type.villager:
			match attribute:
				Attribute.actions:
					return "villager actions\n" + str(previous_value) + " -> " + str(value)
		Type.growth:
			match attribute:
				Attribute.strength:
					return "growth\n+" + str(previous_value) + " -> +" + str(value)
				Attribute.minimum:
					return "growth minimum\n" + str(previous_value) + " -> " + str(value)
		Type.spread:
			match attribute:
				Attribute.clicks:
					var clickstr_1 = "" if previous_value == 1 else str(previous_value) + "x "
					var clickstr_2 = "" if value == 1 else str(value) + "x "
					return "spread\n" + clickstr_1 + str(other_values[0]) + " -> " + clickstr_2 + str(other_values[1])
				Attribute.strength:
					var clicks = other_values[0]
					var clickstr = "" if clicks == 1 else str(clicks) + "x "
					return "spread\n" + clickstr + str(previous_value) + " -> " + clickstr + str(value)
				Attribute.on_plains:
					return "enable spreading on all non-buildings"
				Attribute.on_buildings:
					return "enable spreading on buildings"
		Type.plant:
			match attribute:
				Attribute.clicks:
					return "plant\n" + str(previous_value) + " -> " + str(value)
				Attribute.spread:
					return "spread\n" + str(previous_value) + " -> " + str(value) + "\n on every planted forest"
				Attribute.on_buildings:
					return "enable planting on buildings"
		Type.rain:
			match attribute:
				Attribute.strength:
					return "rain\n+" + str(previous_value) + " -> +" + str(value)
				Attribute.growth:
					var previous_decay_rate = other_values[0]
					var new_decay_rate = other_values[1]
					var decay_text = "" if previous_decay_rate == new_decay_rate else "\nrain tickdown rate\n" + str(previous_decay_rate) + " -> " + str(new_decay_rate)
					return "rain growth boost\n+" + str(previous_value) + " -> +" + str(value) + decay_text
				Attribute.frost:
					var previous_decay_rate = other_values[0]
					var new_decay_rate = other_values[1]
					var decay_text = "" if previous_decay_rate == new_decay_rate else "\nrain tickdown rate\n" + str(previous_decay_rate) + " -> " + str(new_decay_rate)
					return "rain frost boost\n+" + str(previous_value) + " -> +" + str(value) + decay_text
		Type.lightning:
			match attribute:
				Attribute.unlock:
					return "unlock lightning"
				Attribute.clicks:
					return "lightning base amount\n" + str(previous_value) + " -> " + str(value)
				Attribute.unlock_rain:
					return "lightning\n+1 for each " + str(value) + " rain duration"
				Attribute.rain_conversion:
					return "lightning\n+1 for each\n" + str(previous_value) + " -> " + str(value) + "\n rain duration"
				Attribute.rain:
					var rainstr_1 = str(-previous_value) if previous_value > 0 else "+" + str(-previous_value)
					var rainstr_2 = str(-value) if value > 0 else "+" + str(-value)
					return "lightning rain\n" + rainstr_1 + " -> " + rainstr_2 + "\nper strike"
		Type.frost:
			match attribute:
				Attribute.strength:
					return "frost\n+" + str(previous_value) + " -> +" + str(value)
				Attribute.minimum:
					return "frost minimum\n" + str(previous_value) + " -> " + str(value)

func apply(map: Map, action_factory: ActionFactory):
	var prototype: ActionPrototype
	match type:
		Type.treant:
			prototype = action_factory.action_prototypes[Action.Type.spawn_treant]
			match attribute:
				Attribute.unlock:	prototype.unlocked = true
				Attribute.clicks:	prototype.clicks = value
				Attribute.actions:
					map.treant_actions = value
					if len(other_values) > 0:
						map.treants.set_lifespan(other_values[1])
				Attribute.lifespan:
					map.treant_has_lifespan = true
					map.treant_actions = value
					map.treants.set_lifespan(other_values[0])
				Attribute.spread:
					map.treant_death_spread = value
					map.treants.set_lifespan(other_values[1])
		Type.treantling:
			prototype = action_factory.action_prototypes[Action.Type.spawn_treantling]
			match attribute:
				Attribute.clicks:	prototype.clicks = value
				Attribute.actions:
					map.treantling_actions = value
					map.treantlings.set_lifespan(other_values[1])
				Attribute.strength:	map.treantling_strength = value
				Attribute.spread:
					map.treantling_death_spread = value
					map.treantlings.set_lifespan(other_values[1])
		Type.druid:
			prototype = action_factory.action_prototypes[Action.Type.spawn_druid]
			match attribute:
				Attribute.clicks:	prototype.clicks = value
				Attribute.actions:	map.druid_actions = value
				Attribute.strength:	map.druid_circle_trees = value
		Type.villager:
			match attribute:
				Attribute.actions:	map.villagers.actions = value
		Type.growth:
			match attribute:
				Attribute.strength:
					prototype = action_factory.action_prototypes[Action.Type.overgrowth]
					prototype.strength = value
				
				Attribute.minimum:	map.min_growth = value
		Type.spread:
			prototype = action_factory.action_prototypes[Action.Type.spread]
			match attribute:
				Attribute.clicks:
					var strength = action_factory.action_prototypes[Action.Type.spread].strength
					var clicks = action_factory.action_prototypes[Action.Type.spread].clicks
					var new_strength = 10 * ceili(((strength * clicks) + 40) / (10.0 * (clicks + 1)))
					prototype.strength = new_strength
					prototype.clicks = value
				
				Attribute.strength:		prototype.strength = value
				Attribute.on_plains:	map.can_spread_on_plains = true
				Attribute.on_buildings:	map.can_spread_on_buildings = true
		Type.plant:
			prototype = action_factory.action_prototypes[Action.Type.plant]
			match attribute:
				Attribute.clicks:		prototype.clicks = value
				Attribute.spread:		prototype.strength = value
				Attribute.on_buildings:	map.can_plant_on_buildings = true
		Type.rain:
			prototype = action_factory.action_prototypes[Action.Type.rain]
			match attribute:
				Attribute.growth:
					map.rain_growth_boost = value
					map.rain_decay_rate = other_values[1]
				Attribute.frost:
					map.rain_frost_boost = value
					map.rain_decay_rate = other_values[1]
				
				Attribute.strength:	prototype.strength = value
		Type.lightning:
			prototype = action_factory.action_prototypes[Action.Type.lightning_strike]
			match attribute:
				Attribute.unlock:			prototype.unlocked = true
				Attribute.clicks:			prototype.clicks = value
				Attribute.unlock_rain:		action_factory.rain_lightning_conversion_unlocked = true
				Attribute.rain_conversion:	action_factory.rain_lightning_conversion = value
				Attribute.rain:				prototype.cost = value
		Type.frost:
			match attribute:
				Attribute.strength:
					prototype = action_factory.action_prototypes[Action.Type.frost]
					prototype.strength = value
				
				Attribute.minimum:	map.min_frost = value
	
	if prototype != null:
		prototype.weight += 1
		prototype.level += 1

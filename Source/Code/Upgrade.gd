extends Resource
class_name Upgrade

var value = null
var previous_value = null
var end_text = ""

enum Type {none, villager, treant, druid, growth, spread, plant, rain, lightning, beer}
var type: Type = Type.none

enum Attribute {none, unlock, clicks, strength, actions, minimum,
	growth, spread, on_buildings, beer}
var attribute: Attribute = Attribute.none

func _init(type_: Type = Type.none, attribute_: Attribute = Attribute.none,
			value_ = null, previous_value_ = null, end_text_: String = ""):
	type = type_
	attribute = attribute_
	value = value_
	previous_value = previous_value_
	end_text = end_text_

func reset():
	type = Type.none
	attribute = Attribute.none
	previous_value = null
	value = null
	end_text = ""

func set_upgrade(other: Upgrade):
	type = other.type
	attribute = other.attribute
	previous_value = other.previous_value
	value = other.value
	end_text = other.end_text

func get_text():
	match type:
		Type.treant:
			match attribute:
				Attribute.unlock:
					return "unlock treants"
				Attribute.clicks:
					return "treant spawns\n" + str(previous_value) + " -> " + str(value)
				Attribute.actions:
					return "treant acions\n" + str(previous_value) + " -> " + str(value)
		Type.druid:
			match attribute:
				Attribute.clicks:
					return "druid spawns\n" + str(previous_value) + " -> " + str(value)
				Attribute.actions:
					return "druid actions\n" + str(previous_value) + " -> " + str(value)
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
					return "spread\n" + end_text
				Attribute.strength:
					return "spread\n" + end_text
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
					return "rain growth boost\n+" + str(previous_value) + " -> +" + str(value)
				Attribute.beer:
					return "rain beer boost\n+" + str(previous_value) + " -> +" + str(value)
		Type.lightning:
			match attribute:
				Attribute.clicks:
					return "lightning base amount\n" + str(previous_value) + " -> " + str(value)
		Type.beer:
			match attribute:
				Attribute.strength:
					return "beer\n+" + str(previous_value) + " -> +" + str(value)

func apply(map: Map, action_factory: ActionFactory):
	var prototype: ActionPrototype
	match type:
		Type.treant:
			prototype = action_factory.action_prototypes[Action.Type.spawn_treant]
			match attribute:
				Attribute.unlock:	prototype.unlocked = true
				Attribute.clicks:	prototype.clicks = value
				Attribute.actions:	map.treant_actions = value
		Type.druid:
			prototype = action_factory.action_prototypes[Action.Type.spawn_treant]
			match attribute:
				Attribute.clicks:	prototype.clicks = value
				Attribute.actions:	map.druid_actions = value
		Type.villager:
			match attribute:
				Attribute.actions:	map.villager_actions = value
		Type.growth:
			prototype = action_factory.action_prototypes[Action.Type.overgrowth]
			match attribute:
				Attribute.strength:	prototype.strength = value
				Attribute.minimum:	map.min_growth_stages = value
		Type.spread:
			prototype = action_factory.action_prototypes[Action.Type.spread]
			match attribute:
				Attribute.clicks:
					var strength = action_factory.action_prototypes[Action.Type.spread].strength
					var clicks = action_factory.action_prototypes[Action.Type.spread].clicks
					var new_strength = 10 * ceili(((strength * clicks) + 40) / (10.0 * (clicks + 1)))
					prototype.strength = new_strength
					prototype.clicks = value
				Attribute.strength:
					prototype.strength = value
		Type.plant:
			prototype = action_factory.action_prototypes[Action.Type.plant]
			match attribute:
				Attribute.clicks:		prototype.clicks = value
				Attribute.spread:		prototype.strength = value
				Attribute.on_buildings:	map.can_plant_on_buildings = true
		Type.rain:
			prototype = action_factory.action_prototypes[Action.Type.rain]
			match attribute:
				Attribute.strength:	prototype.strength = value
				Attribute.growth:	map.rain_growth_boost = value
				Attribute.beer:		map.rain_beer_boost = value
		Type.lightning:
			prototype = action_factory.action_prototypes[Action.Type.lightning_strike]
			match attribute:
				Attribute.clicks:	prototype.clicks = value
		Type.beer:
			prototype = action_factory.action_prototypes[Action.Type.beer]
			match attribute:
				Attribute.strength:	prototype.strength = value
	
	if prototype != null:
		prototype.weight += 1
		prototype.level += 1

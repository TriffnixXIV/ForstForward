extends Resource
class_name Upgrade

var target = null
var attribute = null
var value = null
var previous_value = null

func _init(target_: String, attribute_: String, value_ = null, previous_value_ = null):
	target = target_
	attribute = attribute_
	value = value_
	previous_value = previous_value_

func reset():
	target = null
	attribute = null
	previous_value = null
	value = null

func set_upgrade(other: Upgrade):
	target = other.target
	attribute = other.attribute
	previous_value = other.previous_value
	value = other.value

func get_text():
	match target:
		"Treant":
			match attribute:
				"unlock":
					return "unlock treants"
				"spawn amount":
					return "treant spawns\n" + str(previous_value) + " -> " + str(value)
				"actions":
					return "treant acions\n" + str(previous_value) + " -> " + str(value)
		"Druid":
			match attribute:
				"spawn amount":
					return "druid spawns\n" + str(previous_value) + " -> " + str(value)
				"actions":
					return "druid actions\n" + str(previous_value) + " -> " + str(value)
		"Villager":
			match attribute:
				"actions":
					return "villager actions\n" + str(previous_value) + " -> " + str(value)
		"Growth":
			match attribute:
				"amount":
					return "growth\n+" + str(previous_value) + " -> +" + str(value)
				"minimum":
					return "growth minimum\n" + str(previous_value) + " -> " + str(value)
		"Spread":
			match attribute:
				"amount":
					return "spread\n" + str(previous_value) + " -> " + str(value)
		"Plant":
			match attribute:
				"amount":
					return "plant\n" + str(previous_value) + " -> " + str(value)
		"Rain":
			match attribute:
				"amount":
					return "rain\n+" + str(previous_value) + " -> +" + str(value)
				"growth":
					return "rain growth boost\n+" + str(previous_value) + " -> +" + str(value)
		"Lightning":
			match attribute:
				"amount":
					return "lightning base amount\n" + str(previous_value) + " -> " + str(value)
		"Beer":
			match attribute:
				"amount":
					return "beer\n+" + str(previous_value) + " -> +" + str(value)

func apply(map: Map, action_factory: ActionFactory):
	match target:
		"Treant":
			action_factory.action_prototypes[Action.Type.spawn_treant].weight += 1
			match attribute:
				"unlock":
					action_factory.action_prototypes[Action.Type.spawn_treant].unlocked = true
				"spawn amount":
					action_factory.action_prototypes[Action.Type.spawn_treant].clicks = value
				"actions":
					map.treant_actions = value
		"Druid":
			action_factory.action_prototypes[Action.Type.spawn_druid].weight += 1
			match attribute:
				"spawn amount":
					action_factory.action_prototypes[Action.Type.spawn_druid].clicks = value
				"actions":
					map.druid_actions = value
		"Villager":
			match attribute:
				"actions":
					map.villager_actions = value
		"Growth":
			action_factory.action_prototypes[Action.Type.overgrowth].weight += 1
			match attribute:
				"amount":
					action_factory.action_prototypes[Action.Type.overgrowth].strength = value
				"minimum":
					map.min_growth_stages = value
		"Spread":
			action_factory.action_prototypes[Action.Type.spread].weight += 1
			match attribute:
				"amount":
					action_factory.action_prototypes[Action.Type.spread].strength = value
		"Plant":
			action_factory.action_prototypes[Action.Type.plant].weight += 1
			match attribute:
				"amount":
					action_factory.action_prototypes[Action.Type.plant].clicks = value
		"Rain":
			action_factory.action_prototypes[Action.Type.rain].weight += 1
			match attribute:
				"amount":
					action_factory.action_prototypes[Action.Type.rain].strength = value
				"growth":
					map.rain_growth_boost = value
		"Lightning":
			action_factory.action_prototypes[Action.Type.lightning_strike].weight += 1
			match attribute:
				"amount":
					action_factory.action_prototypes[Action.Type.lightning_strike].clicks = value
		"Beer":
			action_factory.action_prototypes[Action.Type.beer].weight += 1
			match attribute:
				"amount":
					action_factory.action_prototypes[Action.Type.beer].strength = value

extends Action
class_name ActionPrototype

var base_strength: int = 0
var base_clicks: int = 0

var base_unlocked: bool = true
var unlocked: bool = true

var base_weight: int = 3
var weight: int = 3

# used in the upgrade generator to determine upgrade eligibility
# increases with each upgrade
var level: int = 1

func _init(action_type: Type):
	type = action_type
	
	match type:
		Type.spawn_treant:
			base_unlocked = false
			base_weight = 4
			base_clicks = 1
		Type.spawn_druid:
			base_clicks = 1
		Type.overgrowth:
			base_strength = 2
		Type.spread:
			base_clicks = 1
			base_strength = 40
		Type.plant:
			base_clicks = 2
		Type.rain:
			base_strength = 3
		Type.lightning_strike:
			base_clicks = 0
		Type.beer:
			base_strength = 4
	
	reset()

func reset():
	strength = base_strength
	clicks = base_clicks
	unlocked = base_unlocked
	weight = base_weight
	level = 1 if unlocked else 0

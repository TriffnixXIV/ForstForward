extends Node
class_name UpgradeFactory

var map: Map
var action_factory: ActionFactory

var total_life_upgrades = 0
var total_growth_upgrades = 0
var total_weather_upgrades = 0

func reset():
	total_life_upgrades = 0
	total_growth_upgrades = 0
	total_weather_upgrades = 0

func get_upgrades(type: Crystal.Type, amount: int = 2):
	match type:
		Crystal.Type.life: total_life_upgrades += 1
		Crystal.Type.growth: total_growth_upgrades += 1
		Crystal.Type.weather: total_weather_upgrades += 1
	
	var upgrades = []
	var available_upgrades = get_available_upgrades(type)
	available_upgrades.shuffle()
	
	for i in amount:
		upgrades.append(available_upgrades[i])
	
	return upgrades

func get_available_upgrades(type: Crystal.Type):
	var available_upgrades = []
	var strength = 0
	var new_strength = 0
	var clicks = 0
	var _new_clicks = 0
	var prototype: ActionPrototype
	var UT = Upgrade.Type
	var UA = Upgrade.Attribute
	
	match type:
		Crystal.Type.life:
			# treant
			prototype = action_factory.action_prototypes[Action.Type.spawn_treant]
			if not prototype.unlocked:
				if total_life_upgrades >= 5:
					available_upgrades.append(
						Upgrade.new(UT.treant, UA.unlock))
			else:
				clicks = prototype.clicks
				if prototype.level >= 3 * prototype.clicks:
					available_upgrades.append(
						Upgrade.new(UT.treant, UA.clicks, clicks + 1, clicks))
				
				if total_life_upgrades >= map.treant_actions:
					available_upgrades.append(
						Upgrade.new(UT.treant, UA.actions, map.treant_actions + 2, map.treant_actions))
				
				available_upgrades.append(
					Upgrade.new(UT.treant, UA.spread, map.treant_death_spread + 10, map.treant_death_spread))
			
			# treantling
			prototype = action_factory.action_prototypes[Action.Type.spawn_treantling]
			clicks = prototype.clicks
			if prototype.level >= 3 * clicks:
				available_upgrades.append(
					Upgrade.new(UT.treantling, UA.clicks, clicks + 1, clicks))
			
			available_upgrades.append(
				Upgrade.new(UT.treantling, UA.actions, map.treantling_actions + 2, map.treantling_actions))
			
			if prototype.level >= 1 + pow(map.treantling_strength, 2) + map.treantling_strength:
				available_upgrades.append(
					Upgrade.new(UT.treantling, UA.strength, map.treantling_strength + 1, map.treantling_strength))
			
			available_upgrades.append(
				Upgrade.new(UT.treantling, UA.lifespan, map.treantling_lifespan + 5, map.treantling_lifespan))
			
			available_upgrades.append(
				Upgrade.new(UT.treantling, UA.spread, map.treantling_death_spread + 6, map.treantling_death_spread))
			
			# druid
			prototype = action_factory.action_prototypes[Action.Type.spawn_druid]
			clicks = prototype.clicks
			if prototype.level >= 2 + 3 * clicks:
				available_upgrades.append(
					Upgrade.new(UT.druid, UA.clicks, clicks + 1, clicks))
			
			available_upgrades.append(
				Upgrade.new(UT.druid, UA.actions, map.druid_actions + 1, map.druid_actions))
			
			available_upgrades.append(
				Upgrade.new(UT.druid, UA.strength, map.druid_circle_trees + 4, map.druid_circle_trees))
		
		Crystal.Type.growth:
			# overgrowth
			prototype = action_factory.action_prototypes[Action.Type.overgrowth]
			strength = prototype.strength
			if total_growth_upgrades >= floori((pow(strength, 2) + strength) / 2.0):
				available_upgrades.append(
					Upgrade.new(UT.growth, UA.strength, strength + 1, strength))
			
			if total_growth_upgrades >= pow(map.min_growth, 2) + map.min_growth:
				available_upgrades.append(
					Upgrade.new(UT.growth, UA.minimum, map.min_growth + 1, map.min_growth))
			
			# spread
			prototype = action_factory.action_prototypes[Action.Type.spread]
			strength = prototype.strength
			clicks = prototype.clicks
			var clickstr = "" if clicks == 1 else str(clicks) + "x "
			new_strength = strength + 10 * ceili((3 + clicks) / float(clicks))
			available_upgrades.append(
				Upgrade.new(UT.spread, UA.strength, new_strength, strength,
					clickstr + str(strength) + " -> " + clickstr + str(new_strength)))
			
			if total_growth_upgrades >= 5 * clicks:
				new_strength = 10 * ceili(((strength * clicks) + 40) / (10.0 * (clicks + 1)))
				available_upgrades.append(
					Upgrade.new(UT.spread, UA.clicks, clicks + 1, clicks,
						clickstr + str(strength) + " -> " + str(clicks + 1) + "x " + str(new_strength)))
			
			if prototype.level >= 5 and not map.can_spread_on_plains:
				available_upgrades.append(
					Upgrade.new(UT.spread, UA.on_plains))
			
			if prototype.level >= 8 and map.can_spread_on_plains and not map.can_spread_on_buildings:
				available_upgrades.append(
					Upgrade.new(UT.spread, UA.on_buildings))
			
			# plant
			prototype = action_factory.action_prototypes[Action.Type.plant]
			clicks = prototype.clicks
			available_upgrades.append(
				Upgrade.new(UT.plant, UA.clicks, clicks + 2, clicks))
			
			if prototype.level >= 5 and not map.can_plant_on_buildings:
				available_upgrades.append(
					Upgrade.new(UT.plant, UA.on_buildings))
			
			strength = prototype.strength
			if total_growth_upgrades >= 2 + floori(strength / 5.0):
				available_upgrades.append(
					Upgrade.new(UT.plant, UA.spread, strength + 10, strength))
		
		Crystal.Type.weather:
			# rain
			prototype = action_factory.action_prototypes[Action.Type.rain]
			strength = prototype.strength
			available_upgrades.append(
				Upgrade.new(UT.rain, UA.strength, strength + 1, strength))
			
			if prototype.level >= 5 * map.rain_growth_boost:
				available_upgrades.append(
					Upgrade.new(UT.rain, UA.growth, map.rain_growth_boost + 1, map.rain_growth_boost))
			
			if prototype.level >= 3 + 5 * map.rain_frost_boost:
				available_upgrades.append(
					Upgrade.new(UT.rain, UA.frost, map.rain_frost_boost + 1, map.rain_frost_boost))
			
			# lightning
			prototype = action_factory.action_prototypes[Action.Type.lightning_strike]
			if not prototype.unlocked:
				if total_weather_upgrades >= 3:
					available_upgrades.append(
						Upgrade.new(UT.lightning, UA.unlock))
			else:
				clicks = prototype.clicks
				available_upgrades.append(
					Upgrade.new(UT.lightning, UA.clicks, clicks + 1, clicks))
				
				if prototype.level >= 3 + 3 * (prototype.base_cost - prototype.cost):
					strength = prototype.cost
					available_upgrades.append(
						Upgrade.new(UT.lightning, UA.rain, strength - 1, strength))
				
				if not action_factory.rain_lightning_conversion_unlocked:
					if total_weather_upgrades >= 5:
						available_upgrades.append(
							Upgrade.new(UT.lightning, UA.unlock_rain, action_factory.rain_lightning_conversion))
				else:
					strength = action_factory.rain_lightning_conversion
					var diff = max(0, action_factory.base_rain_lightning_conversion - strength)
					if prototype.level >= 5 + floori((pow(diff, 2) + diff) / 2.0) and strength > 1:
						available_upgrades.append(
							Upgrade.new(UT.lightning, UA.rain_conversion, strength - 1, strength))
			
			# frost
			prototype = action_factory.action_prototypes[Action.Type.frost]
			strength = prototype.strength
			if total_weather_upgrades >= floori((pow(prototype.level, 2) + prototype.level) / 2.0):
				available_upgrades.append(
					Upgrade.new(UT.frost, UA.strength, strength + 1, strength))
			
			var cost_variable = map.min_frost + 3
			if total_weather_upgrades >= floori((pow(cost_variable, 2) + cost_variable) / 2.0):
				available_upgrades.append(
					Upgrade.new(UT.frost, UA.minimum, map.min_frost + 1, map.min_frost))
	
	return available_upgrades

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
			if prototype.unlocked == false:
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
			
			# druid
			clicks = action_factory.action_prototypes[Action.Type.spawn_druid].clicks
			if total_life_upgrades >= 2 + 2 * clicks:
				available_upgrades.append(
					Upgrade.new(UT.druid, UA.clicks, clicks + 1, clicks))
				
			available_upgrades.append(
				Upgrade.new(UT.druid, UA.actions, map.druid_actions + 1, map.druid_actions))
			
			# villager
			var lost_actions = max(0, map.base_villager_actions - map.villager_actions)
			if total_life_upgrades >= floori((pow(lost_actions, 2) + lost_actions) / 2.0):
				available_upgrades.append(
					Upgrade.new(UT.villager, UA.actions, map.villager_actions - 1, map.villager_actions))
		
		Crystal.Type.growth:
			# overgrowth
			prototype = action_factory.action_prototypes[Action.Type.overgrowth]
			strength = prototype.strength
			if total_growth_upgrades >= 2 * (strength - prototype.base_strength):
				available_upgrades.append(
					Upgrade.new(UT.growth, UA.strength, strength + 1, strength))
			
			if total_growth_upgrades >= 4 * map.min_growth_stages:
				available_upgrades.append(
					Upgrade.new(UT.growth, UA.minimum, map.min_growth_stages + 1, map.min_growth_stages))
			
			# spread
			prototype = action_factory.action_prototypes[Action.Type.spread]
			strength = prototype.strength
			clicks = prototype.clicks
			var clickstr = "" if clicks == 1 else str(clicks) + "x"
			new_strength = strength + 10 * ceili(4 / float(clicks))
			available_upgrades.append(
				Upgrade.new(UT.spread, UA.strength, new_strength, strength,
					clickstr + str(strength) + " -> " + clickstr + str(new_strength)))
			
			if total_growth_upgrades >= 5 * clicks:
				new_strength = 10 * ceili(((strength * clicks) + 40) / (10.0 * (clicks + 1)))
				available_upgrades.append(
					Upgrade.new(UT.spread, UA.clicks, clicks + 1, clicks,
						clickstr + str(strength) + " -> " + str(clicks + 1) + "x" + str(new_strength)))
			
			# plant
			prototype = action_factory.action_prototypes[Action.Type.plant]
			clicks = prototype.clicks
			available_upgrades.append(
				Upgrade.new(UT.plant, UA.clicks, clicks + 2, clicks))
			
			if prototype.level >= 5:
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
			
			if prototype.level >= 3 + 5 * map.rain_beer_boost:
				available_upgrades.append(
					Upgrade.new(UT.rain, UA.beer, map.rain_beer_boost + 1, map.rain_beer_boost))
			
			# lightning
			clicks = action_factory.action_prototypes[Action.Type.lightning_strike].clicks
			available_upgrades.append(
				Upgrade.new(UT.lightning, UA.clicks, clicks + 1, clicks))
			
			# beer
			prototype = action_factory.action_prototypes[Action.Type.beer]
			strength = prototype.strength
			if total_weather_upgrades >= floori((pow(prototype.level, 2) + prototype.level) / 2.0):
				available_upgrades.append(
					Upgrade.new(UT.beer, UA.strength, strength + 1, strength))
	
	return available_upgrades

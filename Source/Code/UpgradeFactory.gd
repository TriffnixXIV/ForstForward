extends Node
class_name UpgradeFactory

enum Category {life, growth, weather}

var map: Map
var action_factory: ActionFactory

var total_life_upgrades = 0
var total_growth_upgrades = 0
var total_weather_upgrades = 0

func reset():
	total_life_upgrades = 0
	total_growth_upgrades = 0
	total_weather_upgrades = 0

func get_upgrades(category: Category, amount: int = 2):
	match category:
		Category.life: total_life_upgrades += 1
		Category.growth: total_growth_upgrades += 1
		Category.weather: total_weather_upgrades += 1
	
	var upgrades = []
	var available_upgrades = get_available_upgrades(category)
	available_upgrades.shuffle()
	
	for i in amount:
		upgrades.append(available_upgrades[i])
	
	return upgrades

func get_available_upgrades(category: Category):
	var available_upgrades = []
	var strength = 0
	var clicks = 0
	var prototype: ActionPrototype
	
	match category:
		Category.life:
			if action_factory.action_prototypes[Action.Type.spawn_treant].unlocked == false:
				if total_life_upgrades >= 2:
					available_upgrades.append(
						Upgrade.new("Treant", "unlock"))
			else:
				clicks = action_factory.action_prototypes[Action.Type.spawn_treant].clicks
				if total_life_upgrades >= 4 + 4 * clicks:
					available_upgrades.append(
						Upgrade.new("Treant", "spawn amount", clicks + 1, clicks))
				
				available_upgrades.append(
					Upgrade.new("Treant", "actions", map.base_treant_actions + 2, map.base_treant_actions))
			
			clicks = action_factory.action_prototypes[Action.Type.spawn_druid].clicks
			if total_life_upgrades >= 2 + 2 * clicks:
				available_upgrades.append(
					Upgrade.new("Druid", "spawn amount", clicks + 1, clicks))
				
			available_upgrades.append(
				Upgrade.new("Druid", "actions", map.base_druid_actions + 2, map.base_druid_actions))
			
			var lost_actions = map.base_villager_actions - map.villager_actions
			if total_life_upgrades >= floori((pow(lost_actions, 2) + lost_actions) / 2.0):
				available_upgrades.append(
					Upgrade.new("Villager", "actions", map.villager_actions - 1, map.villager_actions))
		
		Category.growth:
			prototype = action_factory.action_prototypes[Action.Type.overgrowth]
			strength = prototype.strength
			if total_growth_upgrades >= 2 * (strength - prototype.base_strength):
				available_upgrades.append(
					Upgrade.new("Growth", "amount", strength + 1, strength))
			
			if total_growth_upgrades >= 4 * map.min_growth_stages:
				available_upgrades.append(
					Upgrade.new("Growth", "minimum", map.min_growth_stages + 1, map.min_growth_stages))
			
			strength = action_factory.action_prototypes[Action.Type.spread].strength
			available_upgrades.append(
				Upgrade.new("Spread", "amount", strength + 40, strength))
			
			clicks = action_factory.action_prototypes[Action.Type.plant].clicks
			available_upgrades.append(
				Upgrade.new("Plant", "amount", clicks + 2, clicks))
		
		Category.weather:
			prototype = action_factory.action_prototypes[Action.Type.rain]
			strength = prototype.strength
			available_upgrades.append(
				Upgrade.new("Rain", "amount", strength + 1, strength))
			
			if total_weather_upgrades >= 5 * map.rain_growth_boost:
				available_upgrades.append(
					Upgrade.new("Rain", "growth", map.rain_growth_boost + 1, map.rain_growth_boost))
			
			clicks = action_factory.action_prototypes[Action.Type.lightning_strike].clicks
			available_upgrades.append(
				Upgrade.new("Lightning", "amount", clicks + 1, clicks))
			
			strength = action_factory.action_prototypes[Action.Type.beer].strength
			available_upgrades.append(
				Upgrade.new("Beer", "amount", strength + 1, strength))
	
	return available_upgrades

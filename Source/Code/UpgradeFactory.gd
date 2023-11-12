extends Node
class_name UpgradeFactory

enum Category {life, growth, weather}

var map: Map
var action_factory: ActionFactory

var total_life_upgrades = 0
var total_growth_upgrades = 0
var total_weather_upgrades = 0

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
	var specifier = 0
	
	match category:
		Category.life:
			#   treants
			if action_factory.base_action_data[Action.Type.spawn_treant]["unlocked"] == false:
				available_upgrades.append(
					Upgrade.new("Treant", "unlock"))
			else:
				specifier = action_factory.base_action_data[Action.Type.spawn_treant]["specifier"]
				if total_life_upgrades >= 4 * specifier:
					available_upgrades.append(
						Upgrade.new("Treant", "spawn amount", specifier + 1, specifier))
				
				available_upgrades.append(
					Upgrade.new("Treant", "actions", map.base_treant_actions + 1, map.base_treant_actions))
			
			#   druids
			specifier = action_factory.base_action_data[Action.Type.spawn_druid]["specifier"]
			if total_life_upgrades >= 3 * specifier:
				available_upgrades.append(
					Upgrade.new("Druid", "spawn amount", specifier + 1, specifier))
				
			available_upgrades.append(
				Upgrade.new("Druid", "actions", map.base_druid_actions + 1, map.base_druid_actions))
			
			#  villagers
			available_upgrades.append(
				Upgrade.new("Villager", "actions", map.base_villager_actions - 1, map.base_villager_actions))
	
		Category.growth:
			specifier = action_factory.base_action_data[Action.Type.overgrowth]["specifier"]
			available_upgrades.append(
				Upgrade.new("Growth", "amount", specifier + 1, specifier))
			
			specifier = action_factory.base_action_data[Action.Type.spread]["specifier"]
			available_upgrades.append(
				Upgrade.new("Spread", "amount", specifier + 20, specifier))
			
			specifier = action_factory.base_action_data[Action.Type.plant]["specifier"]
			available_upgrades.append(
				Upgrade.new("Plant", "amount", specifier + 1, specifier))
		
		Category.weather:
			specifier = action_factory.base_action_data[Action.Type.rain]["specifier"]
			available_upgrades.append(
				Upgrade.new("Rain", "amount", specifier + 1, specifier))
			
			specifier = action_factory.base_action_data[Action.Type.lightning_strike]["specifier"]
			available_upgrades.append(
				Upgrade.new("Lightning", "amount", specifier + 1, specifier))
			
			specifier = action_factory.base_action_data[Action.Type.beer]["specifier"]
			available_upgrades.append(
				Upgrade.new("Beer", "amount", specifier + 1, specifier))
	
	return available_upgrades

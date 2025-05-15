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
	
	var text: String = ""
	var callback: Callable
	var prototype: ActionPrototype
	
	match type:
		Crystal.Type.life:
			# treant
			prototype = action_factory.action_prototypes[Action.Type.spawn_treant]
			if not prototype.unlocked:
				if total_life_upgrades >= 5:
					text = "unlock treants"
					callback = func(_m: Map, _af: ActionFactory, ap: ActionPrototype):
						ap.unlocked = true
					
					available_upgrades.append(Upgrade.new(text, callback, prototype))
			else:
				clicks = prototype.clicks
				if prototype.level >= 3 * prototype.clicks:
					text = "treant spawns\n" + get_change_text(prototype.clicks, 1)
					callback = func(_m: Map, _af: ActionFactory, ap: ActionPrototype):
						ap.clicks = ap.clicks + 1
					
					available_upgrades.append(Upgrade.new(text, callback, prototype))
				
				if not map.treants.has_lifespan:
					if total_life_upgrades >= map.treants.actions:
						text = "treant actions\n" + get_change_text(map.treants.actions, 1)
						callback = func(m: Map, _af: ActionFactory, _ap: ActionPrototype):
							m.treants.actions = m.treants.actions + 1
						
						available_upgrades.append(Upgrade.new(text, callback, prototype))
					
					text = "treant actions\n" + get_change_text(map.treants.actions, map.treants.actions)
					text += "\ntreants now die after " + str(map.treants.actions * 10) + " actions"
					callback = func(m: Map, _af: ActionFactory, _ap: ActionPrototype):
						m.treants.has_lifespan = true
						m.treants.actions = m.treants.actions * 2
						m.treants.set_lifespan(m.treants.actions * 5)
					
					available_upgrades.append(Upgrade.new(text, callback, prototype))
					
				else:
					if total_life_upgrades >= map.treants.actions / 2.0:
						text = "treant actions\n" + get_change_text(map.treants.actions, 2)
						text += "\nlifespan\n" + get_change_text(map.treants.lifespan, 10)
						callback = func(m: Map, _af: ActionFactory, _ap: ActionPrototype):
							m.treants.actions = m.treants.actions + 2
							m.treants.set_lifespan(m.treants.lifespan + 10)
						
						available_upgrades.append(Upgrade.new(text, callback, prototype))
					
					if map.treants.lifespan >= map.treants.actions + 8:
						text = "treant death spread\n4x" + str(map.treants.death_spread) + " -> 4x" + str(map.treants.death_spread + 20)
						text += "\nlifespan\n" + get_change_text(map.treants.lifespan, -8)
						callback = func(m: Map, _af: ActionFactory, _ap: ActionPrototype):
							m.treants.set_death_spread(m.treants.death_spread + 20)
							m.treants.set_lifespan(m.treants.lifespan - 8)
						
						available_upgrades.append(Upgrade.new(text, callback, prototype))
			
			# treantling
			prototype = action_factory.action_prototypes[Action.Type.spawn_treantling]
			clicks = prototype.clicks
			if prototype.level >= 3 * clicks:
				text = "treantling spawns\n" + get_change_text(prototype.clicks, 1)
				callback = func(_m: Map, _af: ActionFactory, ap: ActionPrototype):
					ap.clicks = ap.clicks + 1
				
				available_upgrades.append(Upgrade.new(text, callback, prototype))
			
			text = "treantling actions\n" + get_change_text(map.treantlings.actions, 1)
			text += "\nlifespan\n" + get_change_text(map.treantlings.lifespan, 3)
			callback = func(m: Map, _af: ActionFactory, _ap: ActionPrototype):
				m.treantlings.actions = m.treantlings.actions + 1
				m.treantlings.set_lifespan(m.treantlings.lifespan + 3)
			
			available_upgrades.append(Upgrade.new(text, callback, prototype))
			
			if prototype.level >= 1 + pow(map.treantlings.strength, 2) + map.treantlings.strength:
				text = "treantling strength\n" + get_change_text(map.treantlings.strength, 1)
				callback = func(m: Map, _af: ActionFactory, _ap: ActionPrototype):
					m.treantlings.set_strength(m.treantlings.strength + 1)
				
				available_upgrades.append(Upgrade.new(text, callback, prototype))
			
			if map.treantlings.lifespan >= map.treantlings.actions + 2:
				text = "treantling death spread\n" + get_change_text(map.treantlings.death_spread, 12)
				text += "\nlifespan\n" + get_change_text(map.treantlings.lifespan, -2)
				callback = func(m: Map, _af: ActionFactory, _ap: ActionPrototype):
					m.treantlings.set_death_spread(m.treantlings.death_spread + 12)
					m.treantlings.set_lifespan(m.treantlings.lifespan - 2)
				
				available_upgrades.append(Upgrade.new(text, callback, prototype))
			
			# druid
			prototype = action_factory.action_prototypes[Action.Type.spawn_druid]
			clicks = prototype.clicks
			if prototype.level >= 2 + 3 * clicks:
				text = "druid spawns\n" + get_change_text(prototype.clicks, 1)
				callback = func(_m: Map, _af: ActionFactory, ap: ActionPrototype):
					ap.clicks = ap.clicks + 1
				
				available_upgrades.append(Upgrade.new(text, callback, prototype))
			
			text = "druid actions\n" + get_change_text(map.druids.actions, 1)
			callback = func(m: Map, _af: ActionFactory, _ap: ActionPrototype):
				m.druids.actions = m.druids.actions + 1
			
			available_upgrades.append(Upgrade.new(text, callback, prototype))
			
			text = "druid circle trees\n" + get_change_text(map.druids.circle_trees, 4)
			callback = func(m: Map, _af: ActionFactory, _ap: ActionPrototype):
				m.druids.circle_trees = m.druids.circle_trees + 4
			
			available_upgrades.append(Upgrade.new(text, callback, prototype))
		
		Crystal.Type.growth:
			# overgrowth
			prototype = action_factory.action_prototypes[Action.Type.overgrowth]
			
			strength = prototype.strength
			if total_growth_upgrades >= floori((pow(strength, 2) + strength) / 2.0):
				text = "growth\n+" + str(strength) + " -> +" + str(strength + 1)
				callback = func(_m: Map, _af: ActionFactory, ap: ActionPrototype):
					ap.strength = ap.strength + 1
				
				available_upgrades.append(Upgrade.new(text, callback, prototype))
			
			if total_growth_upgrades >= pow(map.min_growth, 2) + map.min_growth:
				text = "growth minimum\n" + get_change_text(map.min_growth, 1)
				callback = func(m: Map, _af: ActionFactory, _ap: ActionPrototype):
					m.min_growth = m.min_growth + 1
				
				available_upgrades.append(Upgrade.new(text, callback, prototype))
			
			# spread
			prototype = action_factory.action_prototypes[Action.Type.spread]
			strength = prototype.strength
			clicks = prototype.clicks
			
			new_strength = strength + 10 * ceili((3 + clicks) / float(clicks))
			var clickstr = "" if clicks == 1 else str(clicks) + "x "
			text = "spread\n" + clickstr + str(strength) + " -> " + clickstr + str(new_strength)
			callback = func(_m: Map, _af: ActionFactory, ap: ActionPrototype):
				ap.strength = new_strength
			
			available_upgrades.append(Upgrade.new(text, callback, prototype))
			
			if total_growth_upgrades >= 3 * clicks:
				new_strength = 10 * ceili(((strength * clicks) + 40) / (10.0 * (clicks + 1)))
				var clickstr_1 = "" if clicks == 1 else str(clicks) + "x "
				var clickstr_2 = "" if clicks + 1 == 1 else str(clicks + 1) + "x "
				text = "spread\n" + clickstr_1 + str(strength) + " -> " + clickstr_2 + str(new_strength)
				callback = func(_m: Map, _af: ActionFactory, ap: ActionPrototype):
					ap.strength = new_strength
					ap.clicks = ap.clicks + 1
				
				available_upgrades.append(Upgrade.new(text, callback, prototype))
			
			if prototype.level >= 5 and not map.can_spread_on_plains:
				text = "enable spreading on all non-buildings"
				callback = func(m: Map, _af: ActionFactory, _ap: ActionPrototype):
					m.can_spread_on_plains = true
				
				available_upgrades.append(Upgrade.new(text, callback, prototype))
			
			if prototype.level >= 8 and map.can_spread_on_plains and not map.can_spread_on_buildings:
				text = "enable spreading on buildings"
				callback = func(m: Map, _af: ActionFactory, _ap: ActionPrototype):
					m.can_spread_on_buildings = true
				
				available_upgrades.append(Upgrade.new(text, callback, prototype))
			
			# plant
			prototype = action_factory.action_prototypes[Action.Type.plant]
			
			text = "plant\n" + get_change_text(prototype.clicks, 2)
			callback = func(_m: Map, _af: ActionFactory, ap: ActionPrototype):
				ap.clicks = ap.clicks + 2
			
			available_upgrades.append(Upgrade.new(text, callback, prototype))
			
			if prototype.level >= 5 and not map.can_plant_on_buildings:
				text = "enable planting on buildings"
				callback = func(m: Map, _af: ActionFactory, _ap: ActionPrototype):
					m.can_plant_on_buildings = true
				
				available_upgrades.append(Upgrade.new(text, callback, prototype))
			
			strength = prototype.strength
			if total_growth_upgrades >= 2 + floori(strength / 5.0):
				text = "spread\n" + get_change_text(strength, 10) + "\n on every planted forest"
				callback = func(_m: Map, _af: ActionFactory, ap: ActionPrototype):
					ap.strength = ap.strength + 10
				
				available_upgrades.append(Upgrade.new(text, callback, prototype))
		
		Crystal.Type.weather:
			# rain
			prototype = action_factory.action_prototypes[Action.Type.rain]
			strength = prototype.strength
			
			text = "rain\n+" + str(strength) + " -> +" + str(strength + 1)
			callback = func(_m: Map, _af: ActionFactory, ap: ActionPrototype):
				ap.strength = ap.strength + 1
			
			available_upgrades.append(Upgrade.new(text, callback, prototype))
			
			if prototype.level >= 5 * map.rain_growth_boost:
				text = "rain growth boost\n+" + str(map.rain_growth_boost) + " -> +" + str(map.rain_growth_boost + 1)
				text += "" if map.rain_growth_boost % 2 == 0 else "\nrain tickdown rate\n" + get_change_text(map.rain_decay_rate, 1)
				callback = func(m: Map, _af: ActionFactory, _ap: ActionPrototype):
					m.rain_decay_rate = m.rain_decay_rate + (m.rain_growth_boost % 2)
					m.rain_growth_boost = m.rain_growth_boost + 1
				
				available_upgrades.append(Upgrade.new(text, callback, prototype))
			
			if prototype.level >= 3 + 5 * map.rain_frost_boost:
				text = "rain frost boost\n+" + str(map.rain_frost_boost) + " -> +" + str(map.rain_frost_boost + 1)
				text += "" if map.rain_frost_boost % 2 == 0 else "\nrain tickdown rate\n" + get_change_text(map.rain_decay_rate, 1)
				callback = func(m: Map, _af: ActionFactory, _ap: ActionPrototype):
					m.rain_decay_rate = m.rain_decay_rate + (m.rain_frost_boost % 2)
					m.rain_frost_boost = m.rain_frost_boost + 1
				
				available_upgrades.append(Upgrade.new(text, callback, prototype))
			
			# lightning
			prototype = action_factory.action_prototypes[Action.Type.lightning_strike]
			if not prototype.unlocked:
				text = "unlock lightning"
				callback = func(_m: Map, _af: ActionFactory, ap: ActionPrototype):
					ap.unlocked = true
				
				available_upgrades.append(Upgrade.new(text, callback, prototype))
			else:
				clicks = prototype.clicks
				text = "lightning base amount\n" + get_change_text(clicks, 1)
				callback = func(_m: Map, _af: ActionFactory, ap: ActionPrototype):
					ap.clicks = ap.clicks + 1
				
				available_upgrades.append(Upgrade.new(text, callback, prototype))
				
				if prototype.level >= 3 + 3 * (prototype.base_cost - prototype.cost):
					var rainstr_1 = str(-prototype.cost) if prototype.cost > 0 else "+" + str(-prototype.cost)
					var rainstr_2 = str(-(prototype.cost - 1)) if prototype.cost - 1 > 0 else "+" + str(-(prototype.cost - 1))
					text = "lightning rain\n" + rainstr_1 + " -> " + rainstr_2 + "\nper strike"
					callback = func(_m: Map, _af: ActionFactory, ap: ActionPrototype):
						ap.cost = ap.cost - 1
					
					available_upgrades.append(Upgrade.new(text, callback, prototype))
				
				if not action_factory.rain_lightning_conversion_unlocked:
					if total_weather_upgrades >= 5:
						text = "lightning\n+1 for each " + str(action_factory.rain_lightning_conversion) + " rain duration"
						callback = func(_m: Map, af: ActionFactory, _ap: ActionPrototype):
							af.rain_lightning_conversion_unlocked = true
						
						available_upgrades.append(Upgrade.new(text, callback, prototype))
				else:
					strength = action_factory.rain_lightning_conversion
					var diff = max(0, action_factory.base_rain_lightning_conversion - strength)
					if prototype.level >= 5 + floori((pow(diff, 2) + diff) / 2.0) and strength > 1:
						text = "lightning\n+1 for each\n" + get_change_text(action_factory.rain_lightning_conversion, -1) + "\n rain duration"
						callback = func(_m: Map, af: ActionFactory, _ap: ActionPrototype):
							af.rain_lightning_conversion = af.rain_lightning_conversion - 1
						
						available_upgrades.append(Upgrade.new(text, callback, prototype))
			
			# frost
			prototype = action_factory.action_prototypes[Action.Type.frost]
			strength = prototype.strength
			if total_weather_upgrades >= floori((pow(prototype.level, 2) + prototype.level) / 2.0):
				text = "frost\n+" + str(prototype.strength) + " -> +" + str(prototype.strength + 1)
				callback = func(_m: Map, _af: ActionFactory, ap: ActionPrototype):
					ap.strength = ap.strength + 1
				
				available_upgrades.append(Upgrade.new(text, callback, prototype))
			
			var cost_variable = map.min_frost + 3
			if total_weather_upgrades >= floori((pow(cost_variable, 2) + cost_variable) / 2.0):
				text = "frost minimum\n" + get_change_text(map.min_frost, 1)
				callback = func(m: Map, _af: ActionFactory, _ap: ActionPrototype):
					m.min_frost = m.min_frost + 1
				
				available_upgrades.append(Upgrade.new(text, callback, prototype))
	
	return available_upgrades

func get_change_text(value: int, diff: int):
	return str(value) + " -> " + str(value + diff)

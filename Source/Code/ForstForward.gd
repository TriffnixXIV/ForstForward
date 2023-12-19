extends Node2D
class_name Root

var version: String = "v11.1"

var current_round: int = 1

var selected_action: Action
var selection_locked: bool = false

var action_factory: ActionFactory = ActionFactory.new()
var top_action: Action = Action.new()
var bottom_action: Action = Action.new()

var crystal: Crystal

var upgrade_factory: UpgradeFactory = UpgradeFactory.new()
var top_upgrade: Upgrade = Upgrade.new()
var bottom_upgrade: Upgrade = Upgrade.new()
var upgrading: bool = false

var characters_are_transparent: bool = false
var current_map_position

enum GameState {main_menu, level_selection, playing, in_game_menu, post_game}
var game_state = GameState.main_menu

func _ready():
	# initialize the things
	$MapOverlay.visible = true
	$MapOverlay/Version.text = version
	$Map/Overlays/CellHighlight.root = self
	$Map/Overlays/CellHighlight.map = $Map
	action_factory.map = $Map
	upgrade_factory.map = $Map
	upgrade_factory.action_factory = action_factory
	
	top_action.connect("text_changed", update_top_action_text)
	top_action.connect("numbers_changed", update_numbers)
	top_action.connect("advance_success", _on_action_advance_success)
	top_action.connect("advance_failure", _on_action_advance_failure)
	bottom_action.connect("text_changed", update_bottom_action_text)
	bottom_action.connect("numbers_changed", update_numbers)
	bottom_action.connect("advance_success", _on_action_advance_success)
	bottom_action.connect("advance_failure", _on_action_advance_failure)
	
	set_game_state(game_state)

func _process(_delta):
	var mouse_position = get_viewport().get_mouse_position()
	var map_position = get_cell_from_position(mouse_position)
	if map_position != current_map_position:
		current_map_position = map_position
		$Map/Overlays/CellHighlight.update()

func _input(event):
	match game_state:
		GameState.main_menu:
			if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
				quit()
			elif (event is InputEventKey or (event is InputEventMouseButton and not event.button_index == MOUSE_BUTTON_LEFT)) and event.pressed:
				set_game_state(GameState.level_selection)
		
		GameState.level_selection:
			if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
				set_game_state(GameState.main_menu)
			elif (event is InputEventKey or (event is InputEventMouseButton and not event.button_index == MOUSE_BUTTON_LEFT)) and event.pressed:
				if $Map.advancement.current_phase == $Map.advancement.Phase.idle:
					set_game_state(GameState.playing)
		
		GameState.playing:
			if event is InputEventKey and event.pressed:
				match OS.get_keycode_string(event.keycode):
					"R":	restart_run()
#					"S":	skip_round()
					"M":	set_muted(not is_muted())
					"1":	enact_top_option()
					"2":	enact_bottom_option()
				match event.keycode:
					KEY_TAB:	set_character_transparency(true)
					KEY_ESCAPE:	set_game_state(GameState.in_game_menu)
			elif event is InputEventKey and not event.pressed:
				match event.keycode:
					KEY_TAB:	set_character_transparency(false)
			
			if selected_action != null and not selected_action.is_done():
				if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					var cell_position = get_cell_from_position(event.position)
					selected_action.advance($Map, cell_position)
		
		GameState.in_game_menu:
			if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
				set_game_state(GameState.level_selection)
			elif (event is InputEventKey or (event is InputEventMouseButton and not event.button_index == MOUSE_BUTTON_LEFT)) and event.pressed:
				set_game_state(GameState.playing)
		
		GameState.post_game:
			if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
				set_game_state(GameState.main_menu)
			elif (event is InputEventKey or (event is InputEventMouseButton and not event.button_index == MOUSE_BUTTON_LEFT)) and event.pressed:
				set_game_state(GameState.level_selection)

func get_cell_from_position(coords: Vector2i):
	var map_position = $Map.to_local(coords)
	if $Map/Overlays/CellHighlight.is_large():
		map_position.x -= floori($Map.tile_set.tile_size.x / 2.0)
		map_position.y -= floori($Map.tile_set.tile_size.y / 2.0)
	map_position.x = floori(map_position.x / $Map.tile_set.tile_size.x)
	map_position.y = floori(map_position.y / $Map.tile_set.tile_size.y)
	return map_position

func set_character_transparency(boolean: bool):
	characters_are_transparent = boolean
	if characters_are_transparent:
		for creature in $Map.villagers.villagers + $Map.druids.druids + $Map.treants.treants + $Map.treantlings.treantlings:
			creature.modulate.a = 0.2
	else:
		for creature in $Map.villagers.villagers + $Map.druids.druids + $Map.treants.treants + $Map.treantlings.treantlings:
			creature.modulate.a = 1

func set_game_state(state: GameState):
	# round up unfinished business
	var resuming = false
	match game_state:
		GameState.playing:
			if state != GameState.in_game_menu:
				stop_run()
		GameState.in_game_menu:
			resuming = true
	
	# hide everything for now, makes this method shorter
	$MapOverlay/Ornaments.visible = false
	$MapOverlay/MainMenu.visible = false
	$MapOverlay/LevelSelection.visible = false
	$MapOverlay/InGameMenu.visible = false
	$MapOverlay/PostGame.visible = false
	$Sidebar/Links.visible = false
	$Sidebar/Records.visible = false
	$Sidebar/InGameUI.visible = false
	
	# start up other state
	game_state = state
	match game_state:
		GameState.main_menu:
			play_success_sound()
			$MapOverlay/Ornaments.visible = true
			$MapOverlay/MainMenu.visible = true
			$Sidebar/Links.visible = true
			$Map.clear_level()
		GameState.level_selection:
			play_success_sound()
			$MapOverlay/LevelSelection.visible = true
			$Sidebar/Records.visible = true
			$Map.reload_level()
		GameState.playing:
			$Sidebar/InGameUI.visible = true
			if not resuming:
				start_run()
		GameState.in_game_menu:
			play_success_sound()
			$MapOverlay/Ornaments.visible = true
			$MapOverlay/InGameMenu.visible = true
			$Sidebar/Records.visible = true
		GameState.post_game:
			$MapOverlay/PostGame/ToLevelSelection.enable_after(1)
			$MapOverlay/PostGame.visible = true
			$Sidebar/Records.visible = true
	
	update_UI()

func next_turn_step():
	update_UI()
	
	if $Sidebar/InGameUI/BottomOption.has_focus():
		$Sidebar/InGameUI/BottomOption.release_focus()
	if $Sidebar/InGameUI/TopOption.has_focus():
		$Sidebar/InGameUI/TopOption.release_focus()
	
	if crystal != null:
		crystal.set_spark_state(Crystal.SparkState.fading)
		crystal.harvest()
		crystal = null
	
	if len($Map.crystals.fully_grown_crystals) > 0:
		upgrading = true
		next_upgrades()
	else:
		upgrading = false
		next_actions()

func next_upgrades():
	crystal = $Map.crystals.claim_crystal()
	crystal.set_spark_state(Crystal.SparkState.active)
	var new_upgrades = upgrade_factory.get_upgrades(crystal.type)
	
	top_upgrade.set_upgrade(new_upgrades[0])
	bottom_upgrade.set_upgrade(new_upgrades[1])
	
	$Sidebar/InGameUI/TopOption/Label.text = top_upgrade.text
	$Sidebar/InGameUI/TopOption/Sparks.set_modulate_alpha(0.5)
	$Sidebar/InGameUI/TopOption/Sparks.set_crystal(crystal.type)
	$Sidebar/InGameUI/BottomOption/Label.text = bottom_upgrade.text
	$Sidebar/InGameUI/BottomOption/Sparks.set_modulate_alpha(0.5)
	$Sidebar/InGameUI/BottomOption/Sparks.set_crystal(crystal.type)

func next_actions():
	var new_actions = action_factory.get_actions()
	
	top_action.set_action(new_actions[0])
	bottom_action.set_action(new_actions[1])
	
	$Sidebar/InGameUI/TopOption/Sparks.set_modulate_alpha(0.0)
	$Sidebar/InGameUI/BottomOption/Sparks.set_modulate_alpha(0.0)

func update_top_action_text():
	$Sidebar/InGameUI/TopOption/Label.text = top_action.get_full_text()
	$Sidebar/InGameUI/TopOption/Label.label_settings.shadow_color = Crystal.get_color(top_action.get_crystal_type())

func update_bottom_action_text():
	$Sidebar/InGameUI/BottomOption/Label.text = bottom_action.get_full_text()
	$Sidebar/InGameUI/BottomOption/Label.label_settings.shadow_color = Crystal.get_color(bottom_action.get_crystal_type())

func _on_top_option_pressed():
	enact_top_option()

func _on_bottom_option_pressed():
	enact_bottom_option()

func enact_top_option():
	if not $Sidebar/InGameUI/TopOption.disabled:
		if upgrading:
			$Sidebar/InGameUI/TopOption/Sparks.flash()
			apply_upgrade(top_upgrade)
		else:
			if not $Sidebar/InGameUI/TopOption.has_focus():
				$Sidebar/InGameUI/TopOption.grab_focus()
			enact_action(top_action)

func enact_bottom_option():
	if not $Sidebar/InGameUI/BottomOption.disabled:
		if upgrading:
			$Sidebar/InGameUI/BottomOption/Sparks.flash()
			apply_upgrade(bottom_upgrade)
		else:
			if not $Sidebar/InGameUI/BottomOption.has_focus():
				$Sidebar/InGameUI/BottomOption.grab_focus()
			enact_action(bottom_action)

func apply_upgrade(upgrade: Upgrade):
	upgrade.apply($Map, action_factory)
	$Sounds.upgrade()
	next_turn_step()

func enact_action(action: Action):
	selected_action = action
	selected_action.enact($Map)
	
	if action.is_done():
		match selected_action.type:
			Action.Type.rain:	$Map/Advancement/Sounds.grow()
			Action.Type.frost:	$Sounds.frost()
		advance()
	else:
		play_success_sound()
	
	$Map/Overlays/CellHighlight.update()

func _on_action_advance_success():
	if not selection_locked:
		lock_selection()
	
	if game_state == GameState.playing:
		if selected_action.type != Action.Type.lightning_strike:
			play_success_sound() if not selected_action.is_done() else null
			match selected_action.type:
				Action.Type.spawn_treant:		$Map/Advancement/Sounds.chop()
				Action.Type.spawn_treantling:	$Map/Advancement/Sounds.chop()
				Action.Type.spawn_druid:		$Map/Advancement/Sounds.grow()
		
		if selected_action.is_done():
			advance()
		$Map/Overlays/CellHighlight.update()

func _on_action_advance_failure():
	if $Map.is_valid_tile(current_map_position):
		play_failure_sound()

func lock_selection(full_lock: bool = false):
	selection_locked = true
	
	$Sidebar/InGameUI/TopOption.disabled = true
	$Sidebar/InGameUI/BottomOption.disabled = true
	
	if full_lock:
		$Sidebar/InGameUI/TopOption.set_focus_mode(Control.FOCUS_NONE)
		$Sidebar/InGameUI/BottomOption.set_focus_mode(Control.FOCUS_NONE)
	else:
		if selected_action == bottom_action:
			$Sidebar/InGameUI/TopOption.set_focus_mode(Control.FOCUS_NONE)
		else:
			$Sidebar/InGameUI/BottomOption.set_focus_mode(Control.FOCUS_NONE)

func unlock_selection():
	selection_locked = false
	
	$Sidebar/InGameUI/TopOption.disabled = false
	$Sidebar/InGameUI/TopOption.set_focus_mode(Control.FOCUS_ALL)
	$Sidebar/InGameUI/BottomOption.disabled = false
	$Sidebar/InGameUI/BottomOption.set_focus_mode(Control.FOCUS_ALL)

func skip_round():
	if $Map.advancement.current_phase == $Map.advancement.Phase.idle:
		$Sidebar/InGameUI/TopOption.disabled = true
		$Sidebar/InGameUI/BottomOption.disabled = true
		advance()

func advance():
	lock_selection(true)
	if selected_action != null:
		$Map.crystals.add_progress(selected_action.get_crystal_type(), 2)
		match selected_action:
			top_action:
				$Sidebar/InGameUI/TopOption/Sparks.set_crystal(top_action.get_crystal_type())
				$Sidebar/InGameUI/TopOption/Sparks.flash()
			bottom_action:
				$Sidebar/InGameUI/BottomOption/Sparks.set_crystal(bottom_action.get_crystal_type())
				$Sidebar/InGameUI/BottomOption/Sparks.flash()
	
	selected_action = null
	
	if game_state == GameState.playing:
		update_UI()
		
		$Sidebar/InGameUI/TopOption.set_focus_mode(Control.FOCUS_NONE)
		$Sidebar/InGameUI/TopOption/Label.text = ""
		$Sidebar/InGameUI/TopOption/Label.label_settings.shadow_color = Color(0, 0, 0, 0.8)
		
		$Sidebar/InGameUI/BottomOption.set_focus_mode(Control.FOCUS_NONE)
		$Sidebar/InGameUI/BottomOption/Label.text = ""
		$Sidebar/InGameUI/BottomOption/Label.label_settings.shadow_color = Color(0, 0, 0, 0.8)
		$Map.advancement.start()

func _on_map_score_changed():
	update_score()

func _on_advancement_step_done():
	update_score()
	update_numbers()

func _on_advancement_done():
	start_next_round()

func start_next_round():
	if len($Map.crystals.fully_grown_crystals) > 0:
		$Sounds.upgrade()
	else:
		play_advance_sound()
	
	current_round += 1
	next_turn_step()
	unlock_selection()

func update_UI():
	$Map/Overlays/CellHighlight.update()
	match game_state:
		GameState.main_menu:
			pass
		GameState.level_selection:
			update_level_change_stuff()
			update_highscores()
			reset_highscore_highlighting()
		GameState.playing:
			update_round()
			update_score()
			update_numbers()
		GameState.post_game:
			update_stats()
			update_highscores()

func update_level_change_stuff():
	if $Map.current_level <= 0:
		$MapOverlay/LevelSelection/PrevLevelButton.visible = false
	else:
		$MapOverlay/LevelSelection/PrevLevelButton.visible = true
	
	if $Map.current_level >= $Map/Levels.get_child_count() - 1:
		$MapOverlay/LevelSelection/NextLevelButton.visible = false
	else:
		$MapOverlay/LevelSelection/NextLevelButton.visible = true
	
	$MapOverlay/LevelSelection/LevelName.text = $Map.level_name

func update_highscores():
	$Sidebar/Records/Forst/Fastest/Number.text = str($Map.save_data.fastest_win) if $Map.save_data.fastest_win != -1 else "--"
	$Sidebar/Records/Forst/Slowest/Number.text = str($Map.save_data.slowest_win) if $Map.save_data.slowest_win != -1 else "--"
	$Sidebar/Records/Horst/Fastest/Number.text = str($Map.save_data.fastest_loss) if $Map.save_data.fastest_loss != -1 else "--"
	$Sidebar/Records/Horst/Slowest/Number.text = str($Map.save_data.slowest_loss) if $Map.save_data.slowest_loss != -1 else "--"

func reset_highscore_highlighting():
	$Sidebar/Records/Forst/Fastest/Number.label_settings.shadow_color = Color(0, 0, 0, 0.8)
	$Sidebar/Records/Forst/Slowest/Number.label_settings.shadow_color = Color(0, 0, 0, 0.8)
	$Sidebar/Records/Horst/Fastest/Number.label_settings.shadow_color = Color(0, 0, 0, 0.8)
	$Sidebar/Records/Horst/Slowest/Number.label_settings.shadow_color = Color(0, 0, 0, 0.8)

func update_numbers():
	$Sidebar/InGameUI/NumberContainer/Numbers/Villagers/Label.text = str(len($Map/Villagers.villagers))
	$Sidebar/InGameUI/NumberContainer/Numbers/Villagers/Label.label_settings.shadow_color = Color(0, 0, 0, 0.8)
	$Sidebar/InGameUI/NumberContainer/Numbers/Frost/Label.text = str($Map.get_coldness())
	$Sidebar/InGameUI/NumberContainer/Numbers/Frost/Label.label_settings.shadow_color = Color(0, 0, 0, 0.8) if $Map.get_coldness() == $Map.min_frost else Color(0.5, 1, 1, 1) if $Map.frost_boost > 0 else Color(0, 0.5, 1, 1)
	$Sidebar/InGameUI/NumberContainer/Numbers/Rain/Label.text = str($Map.rain_duration)
	$Sidebar/InGameUI/NumberContainer/Numbers/Rain/Label.label_settings.shadow_color = Color(0, 0.5, 1, 1) if $Map.is_raining() else Color(0, 0, 0, 0.8)
	$Sidebar/InGameUI/NumberContainer/Numbers/GrowthStages/Label.text = str($Map.get_growth_stages())
	$Sidebar/InGameUI/NumberContainer/Numbers/GrowthStages/Label.label_settings.shadow_color = Color(0, 0, 0, 0.8) if $Map.get_growth_stages() == $Map.min_growth else Color(0, 1, 0, 1) if $Map.growth_boost > 0 else Color(0, 0.5, 1, 1)
	$Sidebar/InGameUI/NumberContainer/Numbers/LifeUpgrades/Label.text = str(upgrade_factory.total_life_upgrades)
	$Sidebar/InGameUI/NumberContainer/Numbers/LifeUpgrades/Label.label_settings.shadow_color = Color(0, 0, 0, 0.8)
	$Sidebar/InGameUI/NumberContainer/Numbers/GrowthUpgrades/Label.text = str(upgrade_factory.total_growth_upgrades)
	$Sidebar/InGameUI/NumberContainer/Numbers/GrowthUpgrades/Label.label_settings.shadow_color = Color(0, 0, 0, 0.8)
	$Sidebar/InGameUI/NumberContainer/Numbers/WeatherUpgrades/Label.text = str(upgrade_factory.total_weather_upgrades)
	$Sidebar/InGameUI/NumberContainer/Numbers/WeatherUpgrades/Label.label_settings.shadow_color = Color(0, 0, 0, 0.8)
	$Sidebar/InGameUI/NumberContainer/Numbers/Druids/Label.text = str(len($Map/Druids.druids))
	$Sidebar/InGameUI/NumberContainer/Numbers/Druids/Label.label_settings.shadow_color = Color(0, 0, 0, 0.8)
	$Sidebar/InGameUI/NumberContainer/Numbers/Treants/Label.text = str(len($Map/Treants.treants))
	$Sidebar/InGameUI/NumberContainer/Numbers/Treants/Label.label_settings.shadow_color = Color(0, 0, 0, 0.8)

func update_score():
	var score = $Map.get_score()
	if score == 0:
		lose_game()
	elif score == $Map.highest_possible_score and len($Map/Villagers.villagers) <= $Map/Villagers.horst_amount:
		win_game()
	$Sidebar/InGameUI/CoreStats/Score.text = str(score) + " trees"

func update_round():
	$Sidebar/InGameUI/CoreStats/Round.text = "round " + str(current_round)

func update_stats():
	var stats = $MapOverlay/PostGame/Stats
	var stat_array: Array[String] = [
		str($Map.villagers.chops) + " tree" + ("s" if $Map.villagers.chops != 1 else "") + " chopped",
		str($Map.villagers.highest_count) + " peak population",
		str($Map.villagers.born) + " villager" + ("s" if $Map.villagers.born != 1 else "") + " born",
		str($Map.villagers.died) + " villager" + ("s" if $Map.villagers.died != 1 else "") + " died",
		str($Map.treants.kills) + " death" + ("s" if $Map.treants.kills != 1 else "") + " to treants",
		str($Map.treantlings.kills) + " death" + ("s" if $Map.treantlings.kills != 1 else "") + " to treantlings",
		str($Map.druids.kills) + " death" + ("s" if $Map.druids.kills != 1 else "") + " to druids",
		str($Map.deaths_to_lightning) + " death" + ("s" if $Map.deaths_to_lightning != 1 else "") + " to lightning",
		str($Map.total_coldness) + " total frost level",
		str($Map.actions_lost_to_frost) + " action" + ("s" if $Map.actions_lost_to_frost != 1 else "") + " lost to frost"
	]
	stats.update_stats(stats.Type.Horst, stat_array)
	
	stat_array = [
		str($Map.grown_trees) + " tree" + ("s" if $Map.grown_trees != 1 else "") + " grown",
		str($Map.planted_trees) + " tree" + ("s" if $Map.planted_trees != 1 else "") + " planted",
		str($Map.spread_trees) + " tree" + ("s" if $Map.spread_trees != 1 else "") + " spread",
		str($Map.treants.spawns) + " treant" + ("s" if $Map.treants.spawns != 1 else "") + " spawned",
		str($Map.treants.trees) + " tree" + ("s" if $Map.treants.trees != 1 else "") + " from treants",
		str($Map.treantlings.spawns) + " treantling" + ("s" if $Map.treantlings.spawns != 1 else "") + " spawned",
		str($Map.treantlings.trees) + " tree" + ("s" if $Map.treantlings.trees != 1 else "") + " from treantlings",
		str($Map.druids.spawns) + " druid" + ("s" if $Map.druids.spawns != 1 else "") + " spawned",
		str($Map.druids.trees) + " tree" + ("s" if $Map.druids.trees != 1 else "") + " from druids",
		str($Map.total_growth_stages) + " growth stage" + ("s" if $Map.total_growth_stages != 1 else "") + "",
		str($Map.total_rain_duration) + " round" + ("s" if $Map.total_rain_duration != 1 else "") + " of rain",
		str($Map.total_lightning_strikes) + " lightning strike" + ("s" if $Map.total_lightning_strikes != 1 else "") + " called",
	]
	stats.update_stats(stats.Type.Forst, stat_array)

func win_game():
	if game_state == GameState.playing:
		$Sounds/Victory.play()
		
		$MapOverlay/PostGame/Title.label_settings.shadow_color = Color(0, 1, 0, 1)
		$MapOverlay/PostGame/Title.text = $Map.level_name + " is at peace once more"
		$MapOverlay/PostGame/Message.label_settings.shadow_color = Color(0, 1, 0, 1)
		$MapOverlay/PostGame/Message.text = "rekt Horst in " + str(current_round) + " rounds"
		
		if $Map.save_data.fastest_win == -1 or current_round < $Map.save_data.fastest_win:
			$Map.save_data.fastest_win = current_round
			$Sidebar/Records/Forst/Fastest/Number.label_settings.shadow_color = Color(0, 1, 0, 1)
			$Map.save_player_data()
		elif current_round == $Map.save_data.fastest_win:
			$Sidebar/Records/Forst/Fastest/Number.label_settings.shadow_color = Color(0.5, 1, 0, 1)
		
		if $Map.save_data.slowest_win == -1 or current_round > $Map.save_data.slowest_win:
			$Map.save_data.slowest_win = current_round
			$Sidebar/Records/Forst/Slowest/Number.label_settings.shadow_color = Color(0, 1, 0, 1)
			$Map.save_player_data()
		elif current_round == $Map.save_data.slowest_win:
			$Sidebar/Records/Forst/Slowest/Number.label_settings.shadow_color = Color(0.5, 1, 0, 1)
		
		$MapOverlay/LevelSelection/Message.label_settings.shadow_color = Color(0, 1, 0, 1)
		$MapOverlay/LevelSelection/Message.text = "another forest to protect, peace to restore"
		
		set_game_state(GameState.post_game)

func lose_game():
	if game_state == GameState.playing:
		$Sounds/Lose.play()
		
		$MapOverlay/PostGame/Title.label_settings.shadow_color = Color(1, 0, 0, 1)
		$MapOverlay/PostGame/Title.text = $Map.level_name + " is doomed to be civilized"
		$MapOverlay/PostGame/Message.label_settings.shadow_color = Color(1, 0, 0, 1)
		$MapOverlay/PostGame/Message.text = "rekt by Horst in " + str(current_round) + " rounds"
		
		if $Map.save_data.slowest_loss == -1 or current_round > $Map.save_data.slowest_loss:
			$Map.save_data.slowest_loss = current_round
			$Sidebar/Records/Horst/Slowest/Number.label_settings.shadow_color = Color(0, 1, 0, 1)
			$Map.save_player_data()
		elif current_round == $Map.save_data.slowest_loss:
			$Sidebar/Records/Horst/Slowest/Number.label_settings.shadow_color = Color(0.5, 1, 0, 1)
		
		if $Map.save_data.fastest_loss == -1 or current_round < $Map.save_data.fastest_loss:
			$Map.save_data.fastest_loss = current_round
			$Sidebar/Records/Horst/Fastest/Number.label_settings.shadow_color = Color(0, 1, 0, 1)
			$Map.save_player_data()
		elif current_round == $Map.save_data.fastest_loss:
			$Sidebar/Records/Horst/Fastest/Number.label_settings.shadow_color = Color(0.5, 1, 0, 1)
		
		$MapOverlay/LevelSelection/Message.label_settings.shadow_color = Color(1, 0, 0, 1)
		$MapOverlay/LevelSelection/Message.text = "Horst wants to cut down more forests"
		
		set_game_state(GameState.post_game)

func start_run():
	play_success_sound()
	
	action_factory.reset()
	upgrade_factory.reset()
	current_round = 1
	next_turn_step()
	
	$Map/Overlays/CellHighlight.update()
	_on_map_transition_done()

func restart_run():
	stop_run()
	play_success_sound()
	
	action_factory.reset()
	upgrade_factory.reset()
	$Map.reload_level()
	
	current_round = 1
	next_turn_step()
	
	$Map/Overlays/CellHighlight.update()

func _on_map_transition_done():
	if game_state == GameState.playing:
		unlock_selection()
		$Map/Overlays/CellHighlight.update()

func _on_pathing_progress_changed(progress: float):
	$MapOverlay/PathingProgress.visible = progress > 0.0 and progress < 1.0
	$MapOverlay/PathingProgress.value = progress

func stop_run():
	selected_action = null
	lock_selection(true)
	$Map.stop()

func _on_reset_records_pressed():
	play_success_sound()
	$Map.save_data = SaveData.new()
	update_highscores()
	$Map.save_player_data()

func _on_record_mute_button_pressed():
	set_muted($Sidebar/Records/Buttons/MuteButton.button_pressed)

func _on_in_game_mute_button_pressed():
	set_muted($Sidebar/InGameUI/CoreStats/MuteButton.button_pressed)

func set_muted(boolean: bool):
	AudioServer.set_bus_mute(0, boolean)
	$Sidebar/Records/Buttons/MuteButton.button_pressed = boolean
	$Sidebar/InGameUI/CoreStats/MuteButton.button_pressed = boolean
	if not boolean:
		play_success_sound()

func is_muted():
	return AudioServer.is_bus_mute(0)

func play_advance_sound():
	$Sounds/HighPlant.play()

func play_success_sound():
	$Sounds/MidPlant.play()

func play_failure_sound():
	$Sounds/LowPlant.play()

func _on_prev_level_button_pressed():
	play_success_sound()
	$Map.set_level($Map.current_level - 1)
	update_UI()

func _on_next_level_button_pressed():
	play_success_sound()
	$Map.set_level($Map.current_level + 1)
	update_UI()

func _on_to_main_pressed():
	set_game_state(GameState.main_menu)

func _on_to_level_selection_pressed():
	set_game_state(GameState.level_selection)

func _on_start_game_pressed():
	set_game_state(GameState.playing)

func _on_resume_button_pressed():
	play_success_sound()
	set_game_state(GameState.playing)

func _on_reset_button_pressed():
	set_game_state(GameState.playing)
	restart_run()

func _on_run_info_pressed():
	play_failure_sound()

func _on_exit_pressed():
	quit()

func quit():
	get_tree().quit()

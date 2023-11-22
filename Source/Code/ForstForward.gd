extends Node2D

var version = "v9 dev"

var current_round = 1
var score = 0

var selected_action: Action
var selection_locked = false

var action_factory: ActionFactory = ActionFactory.new()
var top_action: Action = Action.new()
var bottom_action: Action = Action.new()

var upgrade_factory: UpgradeFactory = UpgradeFactory.new()
var top_upgrade: Upgrade = Upgrade.new()
var bottom_upgrade: Upgrade = Upgrade.new()
var upgrading = false

var characters_are_transparent
var current_map_position

enum GameState {main_menu, level_selection, playing, in_game_menu, post_game}
var game_state = GameState.main_menu

func _ready():
	# initialize the things
	$MapOverlay/Version.text = version
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
		update_highlight()

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
				if $Map.current_phase == $Map.Phase.idle:
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
	if $Map/CellHighlight.is_large():
		map_position.x -= floori($Map.tile_set.tile_size.x / 2.0)
		map_position.y -= floori($Map.tile_set.tile_size.y / 2.0)
	map_position.x = floori(map_position.x / $Map.tile_set.tile_size.x)
	map_position.y = floori(map_position.y / $Map.tile_set.tile_size.y)
	return map_position

func update_highlight():
	update_hightlight_visibility()
	if $Map/CellHighlight.visible:
		update_highlight_position()
		update_highlight_color()

func update_hightlight_visibility():
	if current_map_position != null and $Map.is_valid_tile(current_map_position) and game_state == GameState.playing and $Map.current_phase == $Map.Phase.idle:
		$Map/CellHighlight.visible = true
	else:
		$Map/CellHighlight.visible = false

func update_highlight_position():
	update_highlight_color()
	if $Map.is_valid_tile(current_map_position) and game_state == GameState.playing and $Map.current_phase == $Map.Phase.idle:
		$Map/CellHighlight.position.x = current_map_position.x * $Map.tile_set.tile_size.x
		$Map/CellHighlight.position.y = current_map_position.y * $Map.tile_set.tile_size.y

func update_highlight_color():
	if selected_action == null:
		$Map/CellHighlight.set_normal()
		$Map/CellHighlight.set_neutral()
	else:
		var valid_click_target = false
		match selected_action.get_active_type():
			Action.Type.spawn_treant:
				valid_click_target = $Map.can_spawn_treant(current_map_position)
			Action.Type.spawn_treantling:
				valid_click_target = $Map.can_spawn_treantling(current_map_position)
			Action.Type.spawn_druid:
				valid_click_target = $Map.can_spawn_druid(current_map_position)
			Action.Type.plant:
				valid_click_target = $Map.can_plant_forest(current_map_position)
			Action.Type.spread:
				valid_click_target = $Map.can_spread_forest(current_map_position)
			Action.Type.lightning_strike:
				valid_click_target = $Map.can_lightning_strike(current_map_position)
		
		match selected_action.get_active_type():
			Action.Type.spawn_treant:
				$Map/CellHighlight.set_large()
			_:
				$Map/CellHighlight.set_normal()
		
		if valid_click_target:
			$Map/CellHighlight.set_positive()
		else:
			$Map/CellHighlight.set_negative()

func set_character_transparency(boolean: bool):
	characters_are_transparent = boolean
	if characters_are_transparent:
		for creature in $Map.villagers + $Map.druids + $Map.treants + $Map.treantlings:
			creature.modulate.a = 0.2
	else:
		for creature in $Map.villagers + $Map.druids + $Map.treants + $Map.treantlings:
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
	$MapOverlay/MainMenu.visible = false
	$MapOverlay/LevelSelection.visible = false
	$MapOverlay/InGameMenu.visible = false
	$MapOverlay/PostGame.visible = false
	$Sidebar/Records.visible = false
	$Sidebar/InGameUI.visible = false
	
	# start up other state
	game_state = state
	match game_state:
		GameState.main_menu:
			play_success_sound()
			$MapOverlay/MainMenu.visible = true
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
			$MapOverlay/InGameMenu.visible = true
			$Sidebar/Records.visible = true
		GameState.post_game:
			$MapOverlay/PostGame/ToLevelSelection.enable_after(1)
			$MapOverlay/PostGame.visible = true
			$Sidebar/Records.visible = true
	
	update_UI()

func next_turn_step():
	update_UI()
	if $Sidebar/InGameUI/Options/Bottom/Button.has_focus():
		$Sidebar/InGameUI/Options/Bottom/Button.release_focus()
	if $Sidebar/InGameUI/Options/Top/Button.has_focus():
		$Sidebar/InGameUI/Options/Top/Button.release_focus()
	if len($Map.crystal_manager.fully_grown_crystals) > 0:
		upgrading = true
		next_upgrades()
	else:
		upgrading = false
		next_actions()

func next_upgrades():
	var crystal_type = $Map.crystal_manager.claim_crystal()
	var new_upgrades = upgrade_factory.get_upgrades(crystal_type)
	
	top_upgrade.set_upgrade(new_upgrades[0])
	bottom_upgrade.set_upgrade(new_upgrades[1])
	
	var spark_color = null
	match crystal_type:
		Crystal.Type.life:		spark_color = ButtonSparks.SparkColor.yellow
		Crystal.Type.growth:	spark_color = ButtonSparks.SparkColor.green
		Crystal.Type.weather:	spark_color = ButtonSparks.SparkColor.blue
	
	$Sidebar/InGameUI/Options/Top/Button/Label.text = top_upgrade.get_text()
	$Sidebar/InGameUI/Options/Top/Button/Sparks.visible = true
	$Sidebar/InGameUI/Options/Top/Button/Sparks.set_color(spark_color)
	$Sidebar/InGameUI/Options/Bottom/Button/Label.text = bottom_upgrade.get_text()
	$Sidebar/InGameUI/Options/Bottom/Button/Sparks.visible = true
	$Sidebar/InGameUI/Options/Bottom/Button/Sparks.set_color(spark_color)

func next_actions():
	var new_actions = action_factory.get_actions()
	
	top_action.set_action(new_actions[0])
	bottom_action.set_action(new_actions[1])
	$Sidebar/InGameUI/Options/Top/Button/Sparks.visible = false
	$Sidebar/InGameUI/Options/Bottom/Button/Sparks.visible = false

func update_top_action_text():
	$Sidebar/InGameUI/Options/Top/Button/Label.text = top_action.get_full_text()
	$Sidebar/InGameUI/Options/Top/Button/Label.label_settings.shadow_color = Crystal.get_color(top_action.get_crystal_type())

func update_bottom_action_text():
	$Sidebar/InGameUI/Options/Bottom/Button/Label.text = bottom_action.get_full_text()
	$Sidebar/InGameUI/Options/Bottom/Button/Label.label_settings.shadow_color = Crystal.get_color(bottom_action.get_crystal_type())

func _on_top_option_pressed():
	enact_top_option()

func _on_bottom_option_pressed():
	enact_bottom_option()

func enact_top_option():
	if not $Sidebar/InGameUI/Options/Top/Button.disabled:
		if upgrading:
			apply_upgrade(top_upgrade)
		else:
			if not $Sidebar/InGameUI/Options/Top/Button.has_focus():
				$Sidebar/InGameUI/Options/Top/Button.grab_focus()
			enact_action(top_action)

func enact_bottom_option():
	if not $Sidebar/InGameUI/Options/Bottom/Button.disabled:
		if upgrading:
			apply_upgrade(bottom_upgrade)
		else:
			if not $Sidebar/InGameUI/Options/Bottom/Button.has_focus():
				$Sidebar/InGameUI/Options/Bottom/Button.grab_focus()
			enact_action(bottom_action)

func apply_upgrade(upgrade: Upgrade):
	upgrade.apply($Map, action_factory)
	play_success_sound()
	next_turn_step()

func enact_action(action: Action):
	selected_action = action
	selected_action.enact($Map)
	
	if action.is_done():
		advance()
	else:
		play_success_sound()
	
	update_highlight()

func _on_action_advance_success():
	if not selection_locked:
		lock_selection()
	
	if game_state == GameState.playing:
		if selected_action.is_done():
			advance()
		elif selected_action.type != Action.Type.lightning_strike:
			play_success_sound()
		
		update_highlight()

func _on_action_advance_failure():
	if $Map.is_valid_tile(current_map_position):
		play_failure_sound()

func lock_selection(full_lock: bool = false):
	selection_locked = true
	
	$Sidebar/InGameUI/Options/Top/Button.disabled = true
	$Sidebar/InGameUI/Options/Bottom/Button.disabled = true
	
	if full_lock:
		$Sidebar/InGameUI/Options/Top/Button.set_focus_mode(Control.FOCUS_NONE)
		$Sidebar/InGameUI/Options/Bottom/Button.set_focus_mode(Control.FOCUS_NONE)
	else:
		if selected_action == bottom_action:
			$Sidebar/InGameUI/Options/Top/Button.set_focus_mode(Control.FOCUS_NONE)
		else:
			$Sidebar/InGameUI/Options/Bottom/Button.set_focus_mode(Control.FOCUS_NONE)

func unlock_selection():
	selection_locked = false
	
	$Sidebar/InGameUI/Options/Top/Button.disabled = false
	$Sidebar/InGameUI/Options/Top/Button.set_focus_mode(Control.FOCUS_ALL)
	$Sidebar/InGameUI/Options/Bottom/Button.disabled = false
	$Sidebar/InGameUI/Options/Bottom/Button.set_focus_mode(Control.FOCUS_ALL)

func skip_round():
	if $Map.current_phase == $Map.Phase.idle:
		$Sidebar/InGameUI/Options/Top/Button.disabled = true
		$Sidebar/InGameUI/Options/Bottom/Button.disabled = true
		advance()

func advance():
	lock_selection(true)
	if selected_action != null:
		$Map.crystal_manager.add_progress(selected_action.get_crystal_type(), 2)
	
	selected_action = null
	
	if game_state == GameState.playing:
		update_UI()
		
		$Sidebar/InGameUI/Options/Top/Button.set_focus_mode(Control.FOCUS_NONE)
		$Sidebar/InGameUI/Options/Top/Button/Label.text = ""
		$Sidebar/InGameUI/Options/Top/Button/Label.label_settings.shadow_color = Color(0, 0, 0, 0.8)
		
		$Sidebar/InGameUI/Options/Bottom/Button.set_focus_mode(Control.FOCUS_NONE)
		$Sidebar/InGameUI/Options/Bottom/Button/Label.text = ""
		$Sidebar/InGameUI/Options/Bottom/Button/Label.label_settings.shadow_color = Color(0, 0, 0, 0.8)
		$Map.advance()

func _on_map_score_changed():
	update_score()

func _on_map_advancement_step_done():
	update_score()
	update_numbers()

func _on_map_advancement_done():
	start_next_round()

func start_next_round():
	current_round += 1
	next_turn_step()
	unlock_selection()

func update_UI():
	update_highlight()
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
	
	if $Map.current_level >= len($Map.levels) - 1:
		$MapOverlay/LevelSelection/NextLevelButton.visible = false
	else:
		$MapOverlay/LevelSelection/NextLevelButton.visible = true
	
	$MapOverlay/LevelSelection/LevelName.text = $Map.level_name

func update_highscores():
	$Sidebar/Records/FastestWin.text = "fastest win\n" + str($Map.save_data.fastest_win) + " rounds"
	$Sidebar/Records/SlowestWin.text = "slowest win\n" + str($Map.save_data.slowest_win) + " rounds"
	$Sidebar/Records/SlowestLoss.text = "slowest loss\n" + str($Map.save_data.slowest_loss) + " rounds"
	$Sidebar/Records/FastestLoss.text = "fastest loss\n" + str($Map.save_data.fastest_loss) + " rounds"
	if $Map.save_data.fastest_win == -1: $Sidebar/Records/FastestWin.text = "fastest win\n--"
	if $Map.save_data.slowest_win == -1: $Sidebar/Records/SlowestWin.text = "slowest win\n--"
	if $Map.save_data.slowest_loss == -1: $Sidebar/Records/SlowestLoss.text = "slowest loss\n--"
	if $Map.save_data.fastest_loss == -1: $Sidebar/Records/FastestLoss.text = "fastest loss\n--"

func reset_highscore_highlighting():
	$Sidebar/Records/FastestWin.label_settings.shadow_color = Color(0, 0, 0, 0.8)
	$Sidebar/Records/SlowestWin.label_settings.shadow_color = Color(0, 0, 0, 0.8)
	$Sidebar/Records/SlowestLoss.label_settings.shadow_color = Color(0, 0, 0, 0.8)
	$Sidebar/Records/FastestLoss.label_settings.shadow_color = Color(0, 0, 0, 0.8)

func update_numbers():
	$Sidebar/InGameUI/NumberContainer/Numbers/Villagers/Label.text = str(len($Map.villagers))
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
	$Sidebar/InGameUI/NumberContainer/Numbers/Druids/Label.text = str(len($Map.druids))
	$Sidebar/InGameUI/NumberContainer/Numbers/Druids/Label.label_settings.shadow_color = Color(0, 0, 0, 0.8)
	$Sidebar/InGameUI/NumberContainer/Numbers/Treants/Label.text = str(len($Map.treants))
	$Sidebar/InGameUI/NumberContainer/Numbers/Treants/Label.label_settings.shadow_color = Color(0, 0, 0, 0.8)

func update_score():
	score = $Map.get_score()
	if score == 0:
		lose_game()
	elif score == $Map.highest_possible_score:
		win_game()
	$Sidebar/InGameUI/CoreStats/Score.text = str(score) + " trees"

func update_round():
	$Sidebar/InGameUI/CoreStats/Round.text = "round " + str(current_round)

func update_stats():
	$MapOverlay/PostGame/Stats/Horst/TreesFelled.text = str($Map.total_felled_trees) + " trees felled"
	$MapOverlay/PostGame/Stats/Horst/MaxHorsts.text = str($Map.highest_villager_count) + " highest number of villagers"
	$MapOverlay/PostGame/Stats/Horst/Births.text = str($Map.total_born_villagers) + " villagers born"
	$MapOverlay/PostGame/Stats/Horst/Deaths.text = str($Map.total_dead_villagers) + " villagers died"
	$MapOverlay/PostGame/Stats/Horst/DeathsTreant.text = str($Map.total_deaths_to_treants) + " deaths to treants"
	$MapOverlay/PostGame/Stats/Horst/DeathsLightning.text = str($Map.total_deaths_to_lightning) + " deaths to lightning"
	$MapOverlay/PostGame/Stats/Horst/Frost.text = str($Map.total_coldness) + " total frost level"
	$MapOverlay/PostGame/Stats/Horst/FrostActions.text = str($Map.actions_lost_to_frost) + " actions lost to frost"
	
	$MapOverlay/PostGame/Stats/Forst/Trees.text = str($Map.total_grown_trees) + " trees grown"
	$MapOverlay/PostGame/Stats/Forst/Plant.text = str($Map.total_planted_trees) + " trees planted"
	$MapOverlay/PostGame/Stats/Forst/Spread.text = str($Map.total_spread_trees) + " trees spread"
	$MapOverlay/PostGame/Stats/Forst/Druids.text = str(len($Map.druids)) + " druids spawned"
	$MapOverlay/PostGame/Stats/Forst/DruidTrees.text = str($Map.total_trees_from_druids) + " trees from druids"
	$MapOverlay/PostGame/Stats/Forst/Treants.text = str($Map.total_treants_spawned) + " treants spawned"
	$MapOverlay/PostGame/Stats/Forst/TreantTrees.text = str($Map.total_trees_from_treants) + " trees from treants"
	$MapOverlay/PostGame/Stats/Forst/Growth.text = str($Map.total_growth_stages) + " growth stages"
	$MapOverlay/PostGame/Stats/Forst/Rain.text = str($Map.total_rain_duration) + " rounds of rain"
	$MapOverlay/PostGame/Stats/Forst/Lightning.text = str($Map.total_lightning_strikes) + " lightning strikes called"

func win_game():
	if game_state == GameState.playing:
		$VictorySound.play()
		
		$MapOverlay/PostGame/Title.label_settings.shadow_color = Color(0, 1, 0, 1)
		$MapOverlay/PostGame/Title.text = $Map.level_name + " is at peace once more"
		$MapOverlay/PostGame/Message.label_settings.shadow_color = Color(0, 1, 0, 1)
		$MapOverlay/PostGame/Message.text = "rekt Horst in " + str(current_round) + " rounds"
		
		if $Map.save_data.fastest_win == -1 or current_round < $Map.save_data.fastest_win:
			$Map.save_data.fastest_win = current_round
			$Sidebar/Records/FastestWin.label_settings.shadow_color = Color(0, 1, 0, 1)
			$Map.save_player_data()
		elif current_round == $Map.save_data.fastest_win:
			$Sidebar/Records/FastestWin.label_settings.shadow_color = Color(0.5, 1, 0, 1)
		
		if $Map.save_data.slowest_win == -1 or current_round > $Map.save_data.slowest_win:
			$Map.save_data.slowest_win = current_round
			$Sidebar/Records/SlowestWin.label_settings.shadow_color = Color(0, 1, 0, 1)
			$Map.save_player_data()
		elif current_round == $Map.save_data.slowest_win:
			$Sidebar/Records/SlowestWin.label_settings.shadow_color = Color(0.5, 1, 0, 1)
		
		$MapOverlay/LevelSelection/Message.label_settings.shadow_color = Color(0, 1, 0, 1)
		$MapOverlay/LevelSelection/Message.text = "another forest to protect, peace to restore"
		
		set_game_state(GameState.post_game)

func lose_game():
	if game_state == GameState.playing:
		$LoseSound.play()
		
		$MapOverlay/PostGame/Title.label_settings.shadow_color = Color(1, 0, 0, 1)
		$MapOverlay/PostGame/Title.text = $Map.level_name + " is doomed to be civilized"
		$MapOverlay/PostGame/Message.label_settings.shadow_color = Color(1, 0, 0, 1)
		$MapOverlay/PostGame/Message.text = "rekt by Horst in " + str(current_round) + " rounds"
		
		if $Map.save_data.slowest_loss == -1 or current_round > $Map.save_data.slowest_loss:
			$Map.save_data.slowest_loss = current_round
			$Sidebar/Records/SlowestLoss.label_settings.shadow_color = Color(0, 1, 0, 1)
			$Map.save_player_data()
		elif current_round == $Map.save_data.slowest_loss:
			$Sidebar/Records/SlowestLoss.label_settings.shadow_color = Color(0.5, 1, 0, 1)
		
		if $Map.save_data.fastest_loss == -1 or current_round < $Map.save_data.fastest_loss:
			$Map.save_data.fastest_loss = current_round
			$Sidebar/Records/FastestLoss.label_settings.shadow_color = Color(0, 1, 0, 1)
			$Map.save_player_data()
		elif current_round == $Map.save_data.fastest_loss:
			$Sidebar/Records/FastestLoss.label_settings.shadow_color = Color(0.5, 1, 0, 1)
		
		$MapOverlay/LevelSelection/Message.label_settings.shadow_color = Color(1, 0, 0, 1)
		$MapOverlay/LevelSelection/Message.text = "Horst wants to cut down more forests"
		
		set_game_state(GameState.post_game)

func start_run():
	play_success_sound()
	
	action_factory.reset()
	upgrade_factory.reset()
	current_round = 1
	next_turn_step()
	
	update_highlight()
	_on_map_transition_done()

func restart_run():
	stop_run()
	play_success_sound()
	
	action_factory.reset()
	upgrade_factory.reset()
	$Map.reload_level()
	
	current_round = 1
	next_turn_step()
	
	update_highlight()

func _on_map_transition_done():
	if game_state == GameState.playing:
		unlock_selection()
		update_highlight()

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
	$HighPlantSound.play()

func play_success_sound():
	$MidPlantSound.play()

func play_failure_sound():
	$LowPlantSound.play()

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

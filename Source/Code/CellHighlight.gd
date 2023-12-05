extends Sprite2D

var positive_highlight: Texture2D = preload("res://Images/Highlights/GreenHighlight.png")
var neutral_highlight: Texture2D = preload("res://Images/Highlights/Highlight.png")
var negative_highlight: Texture2D = preload("res://Images/Highlights/RedHighlight.png")
var large_positive_highlight: Texture2D = preload("res://Images/Highlights/LargeGreenHighlight.png")
var large_neutral_highlight: Texture2D = preload("res://Images/Highlights/LargeHighlight.png")
var large_negative_highlight: Texture2D = preload("res://Images/Highlights/LargeRedHighlight.png")

enum Size {normal, large}
var size = Size.normal

var root: Root
var map: Map

func update():
	update_visibility()
	if visible:
		update_position()
		update_color()

func update_visibility():
	visible = position_is_valid() and states_are_proper()

func update_position():
	position.x = root.current_map_position.x * map.tile_set.tile_size.x
	position.y = root.current_map_position.y * map.tile_set.tile_size.y

func update_color():
	if root.selected_action == null:
		set_normal()
		set_neutral()
	else:
		var valid_click_target = root.selected_action.can_be_performed_on(map, root.current_map_position)
		
		match root.selected_action.get_active_type():
			Action.Type.spawn_treant:
				set_large()
			_:
				set_normal()
		
		set_positive() if valid_click_target else set_negative()

func position_is_valid():
	return root.current_map_position != null and map.is_valid_tile(root.current_map_position)

func states_are_proper():
	return root.game_state == root.GameState.playing and map.advancement.current_phase == map.advancement.Phase.idle

func is_large():
	return size == Size.large

func set_normal():
	size = Size.normal

func set_large():
	size = Size.large

func set_neutral():
	match size:
		Size.normal:	texture = neutral_highlight
		Size.large:		texture = large_neutral_highlight

func set_positive():
	match size:
		Size.normal:	texture = positive_highlight
		Size.large:		texture = large_positive_highlight

func set_negative():
	match size:
		Size.normal:	texture = negative_highlight
		Size.large:		texture = large_negative_highlight

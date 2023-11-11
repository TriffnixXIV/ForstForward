extends Sprite2D

@export var positive_highlight: Texture2D
@export var neutral_highlight: Texture2D
@export var negative_highlight: Texture2D
@export var large_positive_highlight: Texture2D
@export var large_neutral_highlight: Texture2D
@export var large_negative_highlight: Texture2D

enum Size {normal, large}
var size = Size.normal

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

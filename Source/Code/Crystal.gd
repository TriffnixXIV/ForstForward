extends Node2D
class_name Crystal

@export var life_crystal_stages: Array[Texture2D]
@export var growth_crystal_stages: Array[Texture2D]
@export var weather_crystal_stages: Array[Texture2D]

enum Type {life, growth, weather}
var type: Type

var map: Map
var cell_position: Vector2i
var progress: int

signal cracked

func grow():
	if map.is_forest(cell_position):
		progress = min(4, progress + 1)
		update_texture()
	else:
		emit_signal("cracked", self)

func is_grown():
	return progress == 4

func update_texture():
	match type:
		Type.life:		$Sprite.texture = life_crystal_stages[progress]
		Type.growth:	$Sprite.texture = growth_crystal_stages[progress]
		Type.weather:	$Sprite.texture = weather_crystal_stages[progress]

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

func grow(amount: int = 1):
	if map.is_forest(cell_position):
		progress += amount
		update_texture()
	else:
		emit_signal("cracked", self)

func is_grown():
	return progress >= 8

func harvest():
	if is_grown():
		progress -= 8
		update_texture()

func update_texture():
	var index = min(4, floori(progress / 2.0))
	match type:
		Type.life:		$Sprite.texture = life_crystal_stages[index]
		Type.growth:	$Sprite.texture = growth_crystal_stages[index]
		Type.weather:	$Sprite.texture = weather_crystal_stages[index]

extends Node2D
class_name Crystal

enum Type {life, growth, weather}
var type: Type

var map: Map
var cell_position: Vector2i
var progress: int

enum SparkState {active, fading, gone}
var spark_state = SparkState.gone

signal cracked

func _ready():
	update_spark_state()

func set_type(crystal_type: Type):
	type = crystal_type
	match type:
		Type.life:		$Sparks.texture = preload("res://Images/Crystals/SparksYellow.png")
		Type.growth:	$Sparks.texture = preload("res://Images/Crystals/SparksGreen.png")
		Type.weather:	$Sparks.texture = preload("res://Images/Crystals/SparksBlue.png")
	update_texture()

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
	var x = 20 * min(4, floori(progress / 2.0))
	match type:
		Type.life:		$Sprite.region_rect = Rect2(x, 0, 20, 20)
		Type.growth:	$Sprite.region_rect = Rect2(x, 20, 20, 20)
		Type.weather:	$Sprite.region_rect = Rect2(x, 40, 20, 20)

static func get_color(crystal_type: Crystal.Type):
	match crystal_type:
		Type.life:		return Color(1, 1, 0, 1)
		Type.growth:	return Color(0, 1, 0, 1)
		Type.weather:	return Color(0, 0.5, 1, 1)

func update_spark_state():
	set_spark_state(spark_state)

func _on_timer_timeout():
	advance_spark_state()

func advance_spark_state():
	match spark_state:
		SparkState.active:
			set_spark_state(SparkState.fading)
		SparkState.fading:
			set_spark_state(SparkState.gone)

func set_spark_state(new_spark_state):
	spark_state = new_spark_state
	match spark_state:
		SparkState.active:
			$Sparks.visible = true
			$Sparks.modulate.a = 1
		SparkState.fading:
			$Sparks.visible = true
			$Sparks.modulate.a = 0.5
			$Sparks/Timer.start()
		SparkState.gone:
			$Sparks.visible = false
			$Sparks/Timer.stop()

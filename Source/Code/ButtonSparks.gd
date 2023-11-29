extends TextureRect
class_name ButtonSparks

@export var green_spark_texture: Texture2D
@export var blue_spark_texture: Texture2D
@export var purple_spark_texture: Texture2D
@export var yellow_spark_texture: Texture2D

enum SparkColor {green, blue, purple, yellow}

var base_modulate: float

func set_crystal(crystal_type: Crystal.Type):
	match crystal_type:
		Crystal.Type.life:		set_color(ButtonSparks.SparkColor.yellow)
		Crystal.Type.growth:	set_color(ButtonSparks.SparkColor.green)
		Crystal.Type.weather:	set_color(ButtonSparks.SparkColor.blue)

func set_color(color: SparkColor):
	match color:
		SparkColor.green:	texture = green_spark_texture
		SparkColor.blue:	texture = blue_spark_texture
		SparkColor.purple:	texture = purple_spark_texture
		SparkColor.yellow:	texture = yellow_spark_texture

func set_modulate_alpha(modulate_alpha):
	base_modulate = modulate_alpha
	if $Timer.is_stopped():
		modulate.a = base_modulate

func flash():
	$Timer.start()
	flip_h = true
	base_modulate = modulate.a
	modulate.a = 1.0

func _on_timer_timeout():
	modulate.a = max(base_modulate, modulate.a - 0.5)
	flip_h = false
	if base_modulate < modulate.a:
		$Timer.start()

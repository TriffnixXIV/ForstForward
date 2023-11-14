extends TextureRect
class_name ButtonSparks

@export var green_spark_texture: Texture2D
@export var blue_spark_texture: Texture2D
@export var purple_spark_texture: Texture2D
@export var yellow_spark_texture: Texture2D

enum SparkColor {green, blue, purple, yellow}

func set_color(color: SparkColor):
	match color:
		SparkColor.green:	texture = green_spark_texture
		SparkColor.blue:	texture = blue_spark_texture
		SparkColor.purple:	texture = purple_spark_texture
		SparkColor.yellow:	texture = yellow_spark_texture

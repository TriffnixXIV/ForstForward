extends Node2D
class_name GrowthEffect

var progress = 0
var needed_progress = 2

signal complete

func _ready():
	$Timer.start()

func _on_timer_timeout():
	advance()

func advance():
	progress += 1
	$Sprite.flip_h = not $Sprite.flip_h
	if progress >= needed_progress:
		$Sprite.visible = false
		emit_signal("complete", self)
	else:
		$Sprite.modulate.a = 1 - (float(progress) / float(needed_progress))
		$Timer.start()

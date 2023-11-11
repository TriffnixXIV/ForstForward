extends Node2D
class_name Blast

var progress = 0
var needed_progress = 2

var visual_finished = false
var sound_finished = false

signal complete

func activate():
	$Sound.play()
	$Timer.start()

func _on_timer_timeout():
	advance()

func advance():
	progress += 1
	$Sprite.flip_h = not $Sprite.flip_h
	if progress >= needed_progress:
		$Sprite.visible = false
		visual_finished = true
		check_completion()
	else:
		$Sprite.modulate.a = 1 - (float(progress) / float(needed_progress))
		$Timer.start()

func _on_sound_finished():
	sound_finished = true
	check_completion()

func check_completion():
	if visual_finished and sound_finished:
		emit_signal("complete", self)

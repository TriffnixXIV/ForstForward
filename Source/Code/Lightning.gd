extends Node2D
class_name LightningStrike

var progress = 0
var needed_progress = 2

var visual_finished = false
var sound_finished = false

signal complete

#func _input(event):
#	if event is InputEventMouseButton:
#		summon()

func summon():
	play_sound()
	$Timer.start()

func _on_timer_timeout():
	advance()

func advance():
	progress += 1
	$Sprite.flip_h = not $Sprite.flip_h
	if progress == needed_progress:
		$Sprite.visible = false
		visual_finished = true
		check_completion()
	else:
		$Sprite.modulate.a = 1 - (float(progress) / float(needed_progress))
		$Timer.start()

func play_sound():
	match randi_range(1, 3):
		1: $Sound1.play()
		2: $Sound2.play()
		3: $Sound3.play()

func _on_sound_finished():
	sound_finished = true
	check_completion()

func check_completion():
	if visual_finished and sound_finished:
		emit_signal("complete", self)

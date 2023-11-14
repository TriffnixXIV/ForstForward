extends TextureButton

func enable_after(seconds):
	disabled = true
	$Timer.start(seconds)

func _on_timer_timeout():
	disabled = false

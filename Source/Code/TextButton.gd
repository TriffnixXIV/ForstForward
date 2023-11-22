extends TextureButton

func _on_mouse_entered():
	$Label.label_settings.shadow_offset = Vector2i(1, 2)

func _on_mouse_exited():
	$Label.label_settings.shadow_offset = Vector2i(1, 1)

func _on_button_down():
	$Label.label_settings.shadow_color.a = 0.0

func _on_button_up():
	$Label.label_settings.shadow_color.a = 1.0

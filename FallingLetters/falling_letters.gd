extends Label

func drop_letters(dropping_text:String, label_theme:Theme, letters_position: Vector2):
	var screen_size = get_window().size
	
	# Drop time is fraction of screen size
	var drop_time = 1.5 - (letters_position.y / screen_size.y)
	
	text = dropping_text
	theme = label_theme
	global_position = letters_position
	var tween = create_tween()
	tween.set_ease(tween.EASE_OUT)
	tween.set_trans(tween.TRANS_BOUNCE)
	tween.tween_property(self, "global_position:y", screen_size.y, drop_time)
	tween.tween_callback(queue_free).set_delay(drop_time)
	var rotate_tween = create_tween()
	rotate_tween.tween_property(self, "rotation_degrees",45, drop_time)
	show()

extends Window

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	size = DisplayServer.screen_get_size()
	
func drop_letters(dropping_text:String, label_theme:Theme, letters_position: Vector2):
	show()
	
	var screen_size = DisplayServer.screen_get_size()
	# Drop time is fraction of screen size
	var drop_time = 1.5 - (letters_position.y / screen_size.y)
	
	var the_letters: Label = Label.new()
	add_child(the_letters)
	the_letters.text = dropping_text
	the_letters.theme = label_theme
	the_letters.global_position = letters_position
	var tween = create_tween()
	tween.set_ease(tween.EASE_OUT)
	tween.set_trans(tween.TRANS_BOUNCE)
	tween.tween_property(the_letters, "position:y", size.y, drop_time)
	tween.tween_callback(queue_free).set_delay(drop_time)
	var rotate_tween = create_tween()
	rotate_tween.tween_property(the_letters, "rotation_degrees",45, drop_time)

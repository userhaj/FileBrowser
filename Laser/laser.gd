extends Window


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	size = DisplayServer.screen_get_size()
	#DisplayServer.window_set_size(screen_size)
	#DisplayServer.window_set_position(Vector2i(0, 0))
	pass

func shoot_laser(start: Vector2, end: Vector2):
	$LaserNode2D.shoot_laser(start, end)

func _on_timer_timeout() -> void:
	queue_free()

extends Node
class_name Animate

static func drop_window(old_window: Window):
	var viewport = old_window.get_viewport()
	var fake_window = Window.new()
	var growth_factor = 3
	fake_window.size = old_window.size * growth_factor
	fake_window.position = old_window.position - fake_window.size / growth_factor
	fake_window.set_flag(Window.FLAG_BORDERLESS, true)
	fake_window.set_flag(Window.FLAG_TRANSPARENT, true)
	fake_window.set_flag(Window.FLAG_MAXIMIZE_DISABLED, true)
	fake_window.set_flag(Window.FLAG_MINIMIZE_DISABLED, true)
	fake_window.set_flag(Window.FLAG_NO_FOCUS, true)
	fake_window.set_flag(Window.FLAG_RESIZE_DISABLED, true)
	fake_window.set_flag(Window.FLAG_ALWAYS_ON_TOP, true)
	var main_window = old_window.get_tree().root
	main_window.add_child.call_deferred(fake_window)
	
	# Create static screenshot of original window
	var image = TextureRect.new()
	image.pivot_offset = old_window.size/2
	image.texture = ImageTexture.create_from_image(viewport.get_texture().get_image())
	fake_window.add_child(image)
	image.position = fake_window.size/growth_factor
	fake_window.show()

	var screen_size = DisplayServer.screen_get_size()
	# Drop time is fraction of screen size
	var drop_time = 1.4 - 1.35 * (old_window.position.y / screen_size.y)
	var tween = fake_window.create_tween()
	tween.set_ease(tween.EASE_OUT)
	tween.set_trans(tween.TRANS_BOUNCE)
	tween.tween_property(fake_window, "position:y", screen_size.y, drop_time)
	tween.tween_callback(fake_window.queue_free).set_delay(drop_time)
	var rotate_tween = fake_window.create_tween()
	rotate_tween.tween_property(image, "rotation_degrees",45, drop_time)

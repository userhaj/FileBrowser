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

# Reparents control onto window, falls off screen and frees resource
# If non-visible, slowly fades into visibility while dropping
static func drop_control_free(control: Control):
	var control_size = control.size
	var control_screen_position = control.get_screen_position()
	var fake_window = Window.new()
	fake_window.set_flag(Window.FLAG_BORDERLESS, true)
	fake_window.set_flag(Window.FLAG_TRANSPARENT, true)
	fake_window.set_flag(Window.FLAG_MAXIMIZE_DISABLED, true)
	fake_window.set_flag(Window.FLAG_MINIMIZE_DISABLED, true)
	fake_window.set_flag(Window.FLAG_NO_FOCUS, true)
	fake_window.set_flag(Window.FLAG_RESIZE_DISABLED, true)
	fake_window.set_flag(Window.FLAG_ALWAYS_ON_TOP, true)
	var main_window = control.get_tree().root
	main_window.add_child.call_deferred(fake_window)
	await fake_window.ready
	control.reparent(fake_window)
	if not control.visible:
		control.visible = true
		fade_in(control)
	fake_window.show()

	var screen_size = DisplayServer.screen_get_size()
	# Drop time is fraction of screen size
	var drop_time = 1.4 - 1.35 * (control.position.y / screen_size.y)
	var tween = fake_window.create_tween()
	tween.set_ease(tween.EASE_OUT)
	tween.set_trans(tween.TRANS_BOUNCE)
	tween.tween_property(fake_window, "position:y", screen_size.y, drop_time)
	tween.tween_callback(fake_window.queue_free).set_delay(drop_time)
	control.pivot_offset = control.size / 2
	var rotate_tween = fake_window.create_tween()
	rotate_tween.tween_property(control, "rotation_degrees",5, drop_time)
	control.position = Vector2()
	fake_window.size = control_size
	fake_window.position = control_screen_position
	
	


# Fade control from transparent to non-transparent
static func fade_in(control: Control, time: float=1):
	fade(control, time, 0, 1)


# Fade control from non-transparent to transparent
static func fade_out(control: Control, time: float=1):
	fade(control, time, 1, 0)


static func fade(control: Control, time: float, start_transparency:float, end_transparency:float):
	var tween = control.create_tween()
	tween.set_trans(tween.TRANS_LINEAR)
	control.modulate.a = start_transparency
	tween.tween_property(control, "modulate:a", end_transparency, time)

# Quickly rotate the control back and forth
static func wiggle(control: Control, degrees:float = -10, time:float = 0.75):
	if control:
		if not control.is_node_ready():
			await control.ready
		# Add animation minimal to folders
		control.pivot_offset = control.size/2
		var rot = control.create_tween()
		rot.set_trans(Tween.TRANS_ELASTIC)
		rot.set_ease(Tween.EASE_OUT)
		control.set_rotation_degrees(degrees)
		rot.tween_property.call_deferred(control, "rotation_degrees", 0, time)
	

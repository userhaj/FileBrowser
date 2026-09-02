extends Node
class_name ClickEffects

var favorite_colors = [ 
	Color.YELLOW, 
	Color.SKY_BLUE, 
	Color.MEDIUM_PURPLE, 
	Color.WEB_GREEN, 
	Color.KHAKI,
	Color.FIREBRICK
	]

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		# Laser effect on mouse button
		var end_laser = get_window().get_mouse_position()
		var start_laser
		var star_degrees_start
		var star_degrees_end
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				# Shoot laser Toward the Left
				start_laser = get_window().size
				star_degrees_start = 180
				star_degrees_end = 270
			MOUSE_BUTTON_RIGHT:
				# Shoot laser toward right
				start_laser = Vector2(0, get_window().size.y)
				star_degrees_start = 270
				star_degrees_end = 359
			MOUSE_BUTTON_MIDDLE:
				#Shoot laser up from middle
				start_laser = Vector2(get_window().size.x/2, get_window().size.y)
				star_degrees_start = 235
				star_degrees_end = 305
			MOUSE_BUTTON_XBUTTON1: # Back mouse button
				# Laser from right side toward left, stars go left+down
				start_laser = Vector2(get_window().size.x, get_window().size.y/2)
				star_degrees_start = 90
				star_degrees_end = 180
			MOUSE_BUTTON_XBUTTON2: # Forward mouse button
				# Laser from left side toward right, stars go right+down
				start_laser = Vector2(0, get_window().size.y/2)
				star_degrees_start = 1
				star_degrees_end = 90
		effect_laser_and_stars(start_laser, end_laser, star_degrees_start, star_degrees_end)


func effect_laser_and_stars(start, end, star_degrees_start, star_degrees_end):
	if start and end and star_degrees_start and star_degrees_end:
		var laser = preload("res://FileBrowser/Effects/laser_draw_node_2d.gd").new()
		get_window().add_child(laser)
		laser.shoot_laser(start, end, favorite_colors[randi_range(0,favorite_colors.size()-1)] - Color(0,0,0,0.3), 0.2)
		for i in range(3):
			# Shoot Stars toward the Left
			var star = preload("res://FileBrowser/Effects/bounce_off_star.gd").new()
			get_window().add_child(star)
			star.global_position = get_window().get_mouse_position()
			star.shoot_star(randi_range(star_degrees_start,star_degrees_end), 200, 2, 24, randi_range(2,10), favorite_colors[randi_range(0,favorite_colors.size()-1)])

extends Node
var favorite_colors = [ 
	Color.YELLOW, 
	Color.SKY_BLUE, 
	Color.MEDIUM_PURPLE, 
	Color.WEB_GREEN, 
	Color.KHAKI,
	Color.FIREBRICK
	]

func _input(event):
	# Handle drag icon event
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			
			# Shoot Laster Toward the Left
			var laser = preload("res://Laser/laser_draw_node_2d.gd").new()
			get_window().add_child(laser)
			var lower_right = get_window().size
			var mouse_pos = get_window().get_mouse_position()
			laser.shoot_laser(lower_right, mouse_pos, favorite_colors[randi_range(0,favorite_colors.size()-1)] - Color(0,0,0,0.3), 0.2)
			
			for i in range(3):
				# Shoot Stars toward the Left
				var star = preload("res://FileBrowser/Effects/bounce_off_star.gd").new()
				get_window().add_child(star)
				star.global_position = get_window().get_mouse_position()
				star.shoot_star(randi_range(180,270), 200, 2, 24, randi_range(2,10), favorite_colors[randi_range(0,favorite_colors.size()-1)])
			
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			var laser = preload("res://Laser/laser_draw_node_2d.gd").new()
			get_window().add_child(laser)
			var lower_right = get_window().size
			var lower_left = Vector2(0, lower_right.y)
			var mouse_pos = get_window().get_mouse_position()
			laser.shoot_laser(lower_left, mouse_pos, favorite_colors[randi_range(0,favorite_colors.size()-1)] - Color(0,0,0,0.3), 0.2)
			
			# Shoot Stars toward the Right
			for i in range(3):
				var star = preload("res://FileBrowser/Effects/bounce_off_star.gd").new()
				get_window().add_child(star)
				star.global_position = get_window().get_mouse_position()
				star.shoot_star(randi_range(270,359), 200, 2, 24, randi_range(2,10), favorite_colors[randi_range(0,favorite_colors.size()-1)])
			

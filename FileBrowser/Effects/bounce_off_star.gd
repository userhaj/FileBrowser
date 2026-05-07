extends CustomStar

var favorite_colors = [ 
	Color.YELLOW, 
	Color.SKY_BLUE, 
	Color.MEDIUM_PURPLE, 
	Color.WEB_GREEN, 
	Color.KHAKI,
	Color.FIREBRICK
	]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func random_bounce_star(star_width=24) -> Node2D:
	return bounce_off_star( -star_width * randi_range(7,10), 
		star_width* randi_range(-5,5), 
		2,
		star_width,
		randi_range(2,10),
		favorite_colors[randi_range(0,favorite_colors.size()-1)]
		)

func bounce_off_star(y_move, x_move, time, star_width=24, star_points=5, star_color: Color = Color.YELLOW):
	set_star(star_points, star_width/2, star_width/4, star_color, 3)
	fade_throw(self, y_move, x_move, time)

	

func fade_throw(object: Node2D, throw_y=100, throw_x=50, throw_time=2):
	var tween_move_x = object.create_tween()
	tween_move_x.set_trans(Tween.TRANS_LINEAR)
	tween_move_x.tween_property(self, "global_position:x", throw_x, throw_time).as_relative()
	
	var tween_move_y = object.create_tween()
	tween_move_y.set_trans(Tween.TRANS_EXPO)
	tween_move_y.set_ease(Tween.EASE_OUT)
	tween_move_y.tween_property(self, "global_position:y", throw_y, throw_time).as_relative()
	
	 #Hide and delete object
	var tween_hide = object.create_tween()
	tween_hide.set_trans(Tween.TRANS_EXPO)
	tween_hide.set_ease(Tween.EASE_OUT)
	tween_hide.tween_property(self, "modulate",Color(1,1,1,0), throw_time)
	tween_hide.tween_callback(queue_free).set_delay(throw_time)
	
	# Rotate object
	var tween_rotate = get_tree().create_tween()
	tween_rotate.set_trans(Tween.TRANS_LINEAR)
	tween_rotate.set_ease(Tween.EASE_OUT)
	tween_rotate.tween_property(object, "global_rotation_degrees", -180 * sign(throw_x) * sign(throw_y), throw_time)

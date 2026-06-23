extends Node2D

var start_laser: Vector2 = Vector2(0.0, 0.0)
var end_laser: Vector2 = Vector2(0.0, 0.0)
var laser_color: Color = Color.RED
var outline_color: Color = Color.BLACK
var width: int = 10

func shoot_laser(start_vector: Vector2, end_vector: Vector2, color: Color=Color.DARK_RED, time=0.5) -> void:
	laser_color = color
	start_laser = start_vector
	end_laser = end_vector
	self.show()
	var tween = create_tween()
	tween.set_ease(tween.EASE_OUT)
	tween.tween_property(self, "modulate", Color(1,1,1,1), 0.05)
	tween.tween_property(self, "modulate", Color(1,1,1,0), time).set_delay(0.1)
	tween.tween_callback(queue_free).set_delay(time)

func _draw():
	draw_circle(start_laser, width/1.5, outline_color)
	draw_circle(start_laser, width/2.0, laser_color)
	draw_circle(end_laser, width/1.5, outline_color)
	draw_circle(end_laser, width/2.0, laser_color)
	draw_line(start_laser, end_laser, outline_color, width*1.5)
	draw_line(start_laser, end_laser, laser_color, width)

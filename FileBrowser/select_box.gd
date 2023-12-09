extends Control
class_name SelectBox

# Emits Rect2 of selection on mouse up
signal selected_area(area: Rect2)

var is_selecting = false
var start_pos: Vector2

func _gui_input(event):
	# On mouse click create highlighted area
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == 1:
			# Create highlight
			_start_selecting(event.position)
		elif event.is_released():
			# Set final selection and remove highlight
			_stop_selecting()

func _start_selecting(start_position: Vector2):
	# Show higlighting rect
	$SelectColorRect.set_position(start_position)
	self.start_pos = start_position
	is_selecting = true
	$SelectColorRect.show()

func _stop_selecting():
	selected_area.emit($SelectColorRect.get_global_rect())
	# Stop showing highlighting rect
	self.is_selecting = false
	$SelectColorRect.hide()
	# Notify others of final rect
	
	

func _process(_delta):
	if is_selecting:
		var mouse_pos = get_local_mouse_position() - self.start_pos
		if mouse_pos.x < 0 and mouse_pos.y < 0:
			$SelectColorRect.position = get_local_mouse_position()
			$SelectColorRect.size = abs(mouse_pos)
		elif mouse_pos.x < 0 and mouse_pos.y > 0:
			$SelectColorRect.position.x = get_local_mouse_position().x
			$SelectColorRect.position.y = self.start_pos.y
			$SelectColorRect.size.x = self.start_pos.x - get_local_mouse_position().x
			$SelectColorRect.size.y = get_local_mouse_position().y - self.start_pos.y
		elif mouse_pos.x > 0 and mouse_pos.y < 0:
			$SelectColorRect.position.x = self.start_pos.x
			$SelectColorRect.position.y = get_local_mouse_position().y
			$SelectColorRect.size.x = get_local_mouse_position().x - self.start_pos.x
			$SelectColorRect.size.y = self.start_pos.y - get_local_mouse_position().y
		else:
			$SelectColorRect.position = self.start_pos
			$SelectColorRect.set_size(mouse_pos)

extends Control
class_name SelectBox

# Emits Rect2 of selection on mouse up
signal selected_area(area: Rect2)

var is_selecting = false
var start_pos: Vector2

var _select_on_next_drag = false
var _select_on_next_drag_start

func start_selecting(start_position: Vector2):
	# Show higlighting rect
	$SelectColorRect.set_position(start_position)
	self.start_pos = start_position
	is_selecting = true
	$SelectColorRect.show()

func start_selecting_on_drag(start_position: Vector2):
	_select_on_next_drag = true
	_select_on_next_drag_start = start_position

func stop_selecting():
	if self.is_selecting:
		selected_area.emit($SelectColorRect.get_global_rect())
		# Stop showing highlighting rect
		self.is_selecting = false
		$SelectColorRect.size = Vector2(0,0)
		$SelectColorRect.hide()

func cancel_select():
	self.is_selecting = false
	$SelectColorRect.hide()

func _input(event: InputEvent) -> void:
	if _select_on_next_drag:
		if event is InputEventMouseMotion:
			if get_local_mouse_position().distance_to(_select_on_next_drag_start) > 16:
				_select_on_next_drag = false
				start_selecting(_select_on_next_drag_start)
		if event is InputEventMouseButton and not event.is_pressed():
			_select_on_next_drag = false
	
	if self.is_selecting:
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

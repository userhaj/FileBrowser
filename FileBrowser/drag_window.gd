extends Window

signal files_dragged(files:PackedStringArray)

func _process(_delta):
	position = DisplayServer.mouse_get_position() - size/2
	if Input.is_key_pressed(KEY_SHIFT) and not $Labels/MoveLabel.is_visible_in_tree():
		$Labels/CopyLabel.hide()
		$Labels/MoveLabel.show()
	elif not Input.is_key_pressed(KEY_SHIFT) and not $Labels/CopyLabel.is_visible_in_tree():
		$Labels/MoveLabel.hide()
		$Labels/CopyLabel.show()
	
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		end_drag()

func add_control(control:Control):
	$MovingObjects.add_child(control)
	control.modulate.a = 0.5
	

func end_drag():
	# Notify of files if there are files
	if get_child_count() > 0:
		var files = PackedStringArray()
		for child: FolderLargeIconButton in $MovingObjects.get_children():
			files.append(child.get_abs_path())
			child.queue_free()
		emit_signal("files_dragged", files)
		var mouse_pos = get_mouse_position()+ Vector2(get_position_with_decorations())
		var dropped_window_id = DisplayServer.get_window_at_screen_position(mouse_pos)
		dropped_files_emitter(files, dropped_window_id)
	hide()

# When godot adds drag and drop this needs to be changed
# Emit files dropped on the window they were dropped on
func dropped_files_emitter(files, window_id):
	# Only perform fake drag if real drag unavailable
	if(not get_window().has_method("drag_files")):
		if window_id == get_tree().root.get_window_id():
			get_tree().root.emit_signal("files_dropped", files)

func _on_visibility_changed():
	size = Vector2((64 * get_child_count()) * 2, size.y)
	# Godot 4 requires this call after window is visible to gain transparency
	if visible:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true, get_window_id())
	
	# Position children to show each
	for child: Control in $MovingObjects.get_children():
		child.position = Vector2(get_window().size)/2 - child.size/2
	
	
		

extends Node
class_name FileBrowsingController
# Handles browsing history code, change_directory signal is a user requested action

# The path the browser is currently viewing
var current_path: String
# Folders to go to when going "Back"
var folder_past_list: Array[String] = []
# Folders to go to when going "Forward"
var folder_future_list: Array[String] = []

signal change_directory(new_directory: String)

func goto_parent_folder():
	var new_path = self.current_path.get_base_dir()
	set_directory(new_path)

# Call to emit change_directory and update history
func set_directory(new_path: String, clear_forward_history: bool=true):
	
	# Ignore blank
	if new_path:
		# Update folder history (if not already there)
		if folder_past_list.size() > 0:
			if folder_past_list.back() != new_path:
				if current_path:
					folder_past_list.append(current_path)
		else:
			if current_path:
				folder_past_list.append(current_path)
		
		if clear_forward_history:
			folder_future_list.clear()
			
		current_path = new_path
		# Notify connected of change request
		change_directory.emit(current_path)

# Handle history back request, including change directory emission
func history_back():
	if folder_past_list:
		if folder_future_list.size() > 0:
			if folder_future_list.back() != current_path:
				folder_future_list.append(current_path)
		else:
			folder_future_list.append(current_path)
		current_path = folder_past_list.pop_back()
		change_directory.emit(current_path)

# Handle history forward request
func history_forward():
	if folder_future_list:
		set_directory(folder_future_list.pop_back(), false)


func _shortcut_input(event: InputEvent) -> void:
	# Handle hotkey forward/back buttons
	var parent = get_parent()
	if parent is CanvasItem and parent.is_visible_in_tree():
		# Capture and perform go back history
		# Left key
		if event is InputEventKey and event.key_label == Key.KEY_LEFT:
			if event.is_pressed():
				# While alt is being held down
				if Input.is_key_pressed(KEY_ALT):
					history_back()
					get_viewport().set_input_as_handled()
		
		if event is InputEventKey and event.key_label == Key.KEY_RIGHT:
			if event.is_pressed():
				# While alt is being held down
				if Input.is_key_pressed(KEY_ALT):
					history_forward()
					get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	# Handle Mouse forward/back buttons
	var parent = get_parent()
	if parent is CanvasItem and parent.is_visible_in_tree():
		if event is InputEventMouseButton:
			if event.button_index == 8 and event.is_pressed():
				history_back()
				get_viewport().set_input_as_handled()
			if event.button_index == 9 and event.is_pressed():
				history_forward()
				get_viewport().set_input_as_handled()
	

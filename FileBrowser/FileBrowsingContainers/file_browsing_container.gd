extends Control
class_name FileBrowsingContainer
# An example of require components for each File Browser control

# All file browsing objects contain methods below

signal folder_changed(path: String)

func get_directory() -> String:
	return String()

func set_directory(path: String):
	pass

func refresh():
	pass
	
func get_selected_paths() -> Array[String]:
	return Array()

# Allow outside controls to theme/animate and keep consistency
func get_popup_menus() -> Array[PopupMenu]:
	return Array()

# Adds a menu option to the file menu
func add_menu_command(menu_text: String, emoji_icon: String, action: Callable, menu_for_filetype:FilePopupMenu.FILETYPE_FLAG):
	pass

# Location of file/folders in gui
func get_global_file_area_rect() -> Rect2:
	# Assumes part of container has unknown controls, this area is only files
	return Rect2()


### START HOW DRAG AND DROP OF FILES ARE HANDLED ###
# Drop is done by OS window dropping to be consistent with OS

# Hands drag of objects to Godot
func _get_drag_data(at_position: Vector2) -> Variant:
	# if (file(s) are found at_position):
		# Set a picture for godot to drag 
		#set_drag_preview(VBOX OF LABELS OF ITEMS DRAGGED)
	#	return PackedStringArray() # Of absolute file paths
	#else:
		#return null
	return null

# Godot uses this to decide mouse cursor (drag or forbidden symbol)
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Verify paths are being dragged, and allow dropping
	if typeof(data) == TYPE_PACKED_STRING_ARRAY:
		for path: String in data:
			if not path.is_absolute_path():
				return false
		# Allow dropping on objects
		# Place code here if more actions need to allow drop
		return true
	# Drop disallowed 
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	# Hand-off dropping to OS
	if typeof(data) == TYPE_PACKED_STRING_ARRAY:
		# This is the same signal that would occur should an OS drag and drop occur
		get_window().emit_signal("files_dropped", data)

### END HOW DRAG AND DROP OF FILES ARE HANDLED ###

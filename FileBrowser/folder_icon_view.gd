extends Control
class_name FolderIconView
## Used to contain folder.tscn in an icon style view

# TODO Handle Delete File/Folder

signal file_clicked(file_path: String)
signal folder_changed(folder_path: String)

var _folder_size: float = 64.0
var _full_directory_path: String
@onready var _folder_container: HFlowContainer = $SelectBox/ScrollContainer/HFlowContainer
@onready var _thread_queue := ThreadQueue.new()

# Dragging tracking variables
var _is_dragging: bool = false
var _click_start_position: Vector2
var _click_start_object: Node

func _ready():
	get_window().files_dropped.connect(files_dropped)

func files_dropped(files: PackedStringArray):
	var mouse_pos: Vector2 = get_local_mouse_position()
	var is_mouse_over_self = mouse_pos.x >= 0 and mouse_pos.y >= 0 and mouse_pos.x <= $".".size.x and mouse_pos.y <= $".".size.y
	if len(files) > 0 and is_mouse_over_self:
		var drop_point = get_global_mouse_position()
		var target = get_object_at_point(drop_point)
		var target_folder = target.path if target != null else _full_directory_path
		var file_transfer = preload("res://FileBrowser/file_transfer_window.tscn").instantiate()
		file_transfer.hide()
		file_transfer.connect("tree_exiting", refresh)
		add_child(file_transfer)
		if Input.is_key_pressed(KEY_SHIFT):
			file_transfer.copy(files, target_folder)
		else:
			file_transfer.move(files, target_folder)
	
func _input(event):
	# Handle drag icon event
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			self._click_start_position = get_global_mouse_position()
			var folder = get_object_at_point(self._click_start_position)
			# If you did not click a folder, do nothing
			if null != folder:
				self._click_start_object = folder
				$SelectBox.cancel_select()
			else:
				$SelectBox.start_selecting(get_local_mouse_position())
	if event is InputEventMouseButton and not event.pressed:
		self._is_dragging = false
		self._click_start_position = Vector2()
		self._click_start_object = null
		$DragWindow.end_drag()
		if event.is_released() and $SelectBox.is_selecting:
			$SelectBox.stop_selecting()
	
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# If clicked on an object and not yet
		if self._click_start_object and not self._is_dragging:
			if not $DragWindow.visible:
				# Add selected items to drag
				for folder in get_selected_objects():
					var folder_copy = folder.duplicate()
					folder_copy.path = folder.path
					$DragWindow.add_control(folder_copy)
				# If the start object is not selected, include it too
				if not self._click_start_object.is_selected:
					var folder_copy = self._click_start_object.duplicate()
					folder_copy.path = self._click_start_object.path
					$DragWindow.add_control(folder_copy)
				$DragWindow.show()
	if event is InputEventKey and Input.is_key_pressed(KEY_F5):
		refresh()

# Current working directory
func get_directory() -> String:
	return self._full_directory_path

# Adds folder to current view. DOES NOT EDIT FILE SYSTEM
func add_folder_button(folder: FolderLargeIconButton):
	self._folder_container.call_deferred("add_child", folder)

# Returns an array of all folders/files buttons
func get_folder_buttons() -> Array[Node]:
	return self._folder_container.get_children()

# Change current directoy, removes all icons and adds icons for full_path
func set_directory(full_path: String):
	self._full_directory_path = full_path.simplify_path()
	refresh()
	emit_signal("folder_changed", full_path)

# Clears Children, Adds folder/files based on current directory
func refresh():
	# Remove current directory content
	clear()
	# Add folders to view
	for directory in DirAccess.get_directories_at(self._full_directory_path ):
			var button = preload("res://FileBrowser/folder.tscn").instantiate()
			button.set_thread_queue(self._thread_queue)
			var path = self._full_directory_path  + "/" + directory
			button.pressed.connect(set_directory.bind(path))
			button.set_path(path, "📁")
			var icon_size = get_folder_size()
			button.custom_minimum_size = Vector2(icon_size, icon_size)
			add_folder_button(button)

	# Add files to view
	for file_name in DirAccess.get_files_at(self._full_directory_path ):
			var button = preload("res://FileBrowser/folder.tscn").instantiate()
			button.set_thread_queue(self._thread_queue)
			var file_path = self._full_directory_path  + "/" + file_name
			button.pressed.connect(emit_signal.bind("file_clicked", file_path))
			button.set_path(file_path)
			var icon_size = get_folder_size()
			button.custom_minimum_size = Vector2(icon_size, icon_size)
			var extension = file_path.get_extension()
			if button.is_image_extension(extension):
				button.set_image(file_path)
			add_folder_button(button)

# Exclusive select in area, Inclusive select area when shift or ctrl is held down
func select_children_by_area(area: Rect2):
	# Call select on folder in an area
	for child: TextureButton in get_folder_buttons():
		# Guarantee object is selectable
		if child.has_method("select"):
			if child.get_global_rect().intersects(area, true):
				child.select()
			elif (not Input.is_key_pressed(KEY_SHIFT) 
					and not Input.is_key_pressed(KEY_CTRL)):
				child.deselect()

# Calls deselect on all folders in view
func deselect_all_children():
	for child: FolderLargeIconButton in get_folder_buttons():
		# Guarantee object is deselectable
		if child.has_method("deselect"):
			child.deselect()

# Call select on child under position
func select_child_by_point(target_position: Vector2):
	var area = Rect2(target_position, Vector2(1,1))  # Single pixel area/point
	for child: FolderLargeIconButton in get_folder_buttons():
		# Guarantee object is selectable
		if child.has_method("select"):
			if child.get_global_rect().intersects(area, true):
				child.select()

# True if item under point is_selected, or false if no child
func is_selected_point(target_position: Vector2) -> bool:
	var area = Rect2(target_position, Vector2(1,1))  # Single pixel area/point
	for child: FolderLargeIconButton in get_folder_buttons():
		# Guarantee object is selectable
		if child.has_method("select"):
			if child.get_global_rect().intersects(area, true):
				return child.is_selected
	return false

# Returns true if any item is_selected
func is_any_selected() -> bool:
	for child in get_children():
		if child.has_method("select"):
			if child.is_selected:
				return true
	return false

# Returns Array of paths in current directory
func get_selected_paths() -> Array[String]:
	var all_paths: Array[String] = []
	for child in get_folder_buttons():
		if child.has_method("select"):
			if child.is_selected:
				all_paths.append(child.get_abs_path())
	return all_paths

# Returns array of selected objects(Folders/Files)
func get_selected_objects() -> Array[Control]:
	var all_objects: Array[Control] = []
	for child: Control in get_folder_buttons():
		if child.has_method("select"):
			if child.is_selected:
				all_objects.append(child)
	return all_objects

# Gets path under position
func get_path_at_point(target_position: Vector2) -> String:
	var path := ""
	var area = Rect2(target_position, Vector2(1,1))  # Single pixel area/point
	for child in get_folder_buttons():
		if child.has_method("select"):
			if child.get_global_rect().intersects(area, true):
				path = child.get_abs_path()
	return path

# Gets folder/file object under position
func get_object_at_point(target_position: Vector2) -> Node:
	var area = Rect2(target_position, Vector2(1,1))  # Single pixel area/point
	for child in get_folder_buttons():
		if child.has_method("select"):
			if child.get_global_rect().intersects(area, true):
				return child
	return null

# Set square size of all folders in view
func set_folder_size(custom_size: float):
	self._folder_size = custom_size
	# Set folder/file square size
	for child:Control in get_folder_buttons():
		child.custom_minimum_size = Vector2(custom_size, custom_size)

# Square size of folder object
func get_folder_size() -> float:
	return self._folder_size

# Removes all folder buttons from view (File system not touched)
func clear():
	# Remove all folders/files
	for child in get_folder_buttons():
		child.queue_free()

extends Control
class_name FolderIconView
## Used to contain folder.tscn in an icon style view

# TODO Handle Delete File/Folder

signal file_clicked(file_path: String)
signal folder_changed(folder_path: String)

var _folder_size: int = 64
var _full_directory_path: String
@onready var _folder_container: HFlowContainer = $SelectBox/ScrollContainer/HFlowContainer


func get_directory() -> String:
	return self._full_directory_path

# Adds folder to current view. DOES NOT EDIT FILE SYSTEM
func add_folder_button(folder: FolderLargeIconButton):
	self._folder_container.call_deferred("add_child", folder)

func get_folder_buttons() -> Array[Node]:
	return self._folder_container.get_children()

func set_directory(full_path: String, emit_folder_changed: bool = true):
	self._full_directory_path = full_path.simplify_path()
	refresh()
	if emit_folder_changed:
		emit_signal("folder_changed", full_path)

# Clears Children, Adds folder/files based on current directory
func refresh():
	# Remove current directory content
	clear()
	# Add folders to view
	for directory in DirAccess.get_directories_at(self._full_directory_path ):
			var button = preload("res://FileBrowser/folder.tscn").instantiate()
			var path = self._full_directory_path  + "/" + directory
			button.pressed.connect(set_directory.bind(path, true))
			button.set_path(path, "📁")
			var icon_size = get_folder_size()
			button.custom_minimum_size = Vector2(icon_size, icon_size)
			add_folder_button(button)

	# Add files to view
	for file_name in DirAccess.get_files_at(self._full_directory_path ):
			var button = preload("res://FileBrowser/folder.tscn").instantiate()
			var file_path = self._full_directory_path  + "/" + file_name
			button.pressed.connect(emit_signal.bind("file_clicked", file_path))
			button.set_path(file_path)
			var icon_size = get_folder_size()
			button.custom_minimum_size = Vector2(icon_size, icon_size)
			var extension = file_path.get_extension()
			if button.is_image_extension(extension):
				button.set_image(file_path)
			add_folder_button(button)

# TODO Hand key press in different method.
# Inclusive select area when shift or ctrl is held down
func select_children_by_area(area: Rect2):
	# Calls select on folder in an area
	for child: TextureButton in get_folder_buttons():
		# Guarantee object is selectable
		if child.has_method("select"):
			if child.get_global_rect().intersects(area, true):
				child.select()
			elif (not Input.is_key_pressed(KEY_SHIFT) 
					and not Input.is_key_pressed(KEY_CTRL)):
				child.deselect()

func deselect_all_children():
	# Calls select on folder in an area
	for child: FolderLargeIconButton in get_folder_buttons():
		# Guarantee object is selectable
		if child.has_method("deselect"):
			child.deselect()
	

# Call select on child under position
func select_child_by_point(position: Vector2):
	var area = Rect2(position, Vector2(1,1))  # Single pixel area/point
	for child: FolderLargeIconButton in get_folder_buttons():
		# Guarantee object is selectable
		if child.has_method("select"):
			if child.get_global_rect().intersects(area, true):
				child.select()

func is_selected_point(position: Vector2):
	var area = Rect2(position, Vector2(1,1))  # Single pixel area/point
	for child: FolderLargeIconButton in get_folder_buttons():
		# Guarantee object is selectable
		if child.has_method("select"):
			if child.get_global_rect().intersects(area, true):
				return child.is_selected

func is_any_selected():
	# Returns true if anything is selected
	for child in get_children():
		if child.has_method("select"):
			if child.is_selected:
				return true
	return false

func get_selected_paths():
	var all_paths := []
	for child in get_folder_buttons():
		if child.has_method("select"):
			if child.is_selected:
				all_paths.append(child.get_abs_path())
	return all_paths

func get_path_at_point(position: Vector2):
	var path := ""
	var area = Rect2(position, Vector2(1,1))  # Single pixel area/point
	for child in get_folder_buttons():
		if child.has_method("select"):
			if child.get_global_rect().intersects(area, true):
				path = child.get_abs_path()
	return path

func set_folder_size(custom_size: float):
	self._folder_size = custom_size
	# Set folder/file square size
	for child:Control in get_folder_buttons():
		child.custom_minimum_size = Vector2(custom_size, custom_size)

func get_folder_size():
	return self._folder_size

func clear():
	# Remove all folders/files
	for child in get_folder_buttons():
		child.queue_free()

func _on_h_flow_container_resized():
	self._folder_container.custom_minimum_size.y = self._folder_container.size.y

extends Control
class_name FolderIconView
## Used to contain folder.tscn in an icon style view

# TODO Handle Delete File/Folder

@warning_ignore("unused_signal")
signal file_clicked(file_path: String)
signal folder_changed(folder_path: String)

var _folder_size: float = 64.0
var _full_directory_path: String
@onready var _folder_container: HFlowContainer = $SelectBox/ScrollContainer/HFlowContainer
@onready var _thread_queue := ThreadQueue.new()
@onready var ctrl_f_line_edit_plus: LineEditPlus = $CtrlFPanelContainer/HBoxContainer/CtrlFLineEditPlus
@onready var ctrl_f_exit_button: Button = $CtrlFPanelContainer/HBoxContainer/CtrlFExitButton
@onready var ctrl_f_panel_container: PanelContainer = $CtrlFPanelContainer
@onready var file_popup_menu: PopupMenu = $FilePopupMenu

@export var show_hidden_files: bool = true

const FOLDER = preload("uid://d4fyh375x0gay")
const FILE_TRANSFER_WINDOW = preload("uid://5bl4nmd56lgq")


# Dragging tracking variables
var _is_dragging: bool = false
var _click_start_position: Vector2
var _click_start_object: Node

const SAVE_FILEPATH = "user://GDFileBrowserIconView.cfg"

func _ready():
	get_window().files_dropped.connect(files_dropped)
	var config = ConfigFile.new()
	var err = config.load(SAVE_FILEPATH)
	if err == OK:
		var folder_size = config.get_value("folder_icon_view", "_folder_size")
		set_folder_size(folder_size)

	ctrl_f_exit_button.pressed.connect(ctrl_f_panel_container.hide)

func files_dropped(files: PackedStringArray):
	if visible:
		var mouse_pos: Vector2 = get_local_mouse_position()
		var is_mouse_over_self = mouse_pos.x >= 0 and mouse_pos.y >= 0 and mouse_pos.x <= $".".size.x and mouse_pos.y <= $".".size.y
		if len(files) > 0 and is_mouse_over_self:
			var target: FolderLargeIconButton = get_object_at_point(mouse_pos)
			var target_folder: String = target.path if target != null else _full_directory_path
			var file_transfer = FILE_TRANSFER_WINDOW.instantiate()
			file_transfer.hide()
			file_transfer.connect("tree_exiting", refresh)
			get_tree().root.add_child(file_transfer)
			if Input.is_key_pressed(KEY_SHIFT):
				file_transfer.move(files, target_folder)
			else:
				file_transfer.copy(files, target_folder)
	
func _input(event):
	# Handle drag icon event
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and \
		# Prevent starting SelectBox outside of file area
		get_global_file_area_rect().has_point(get_global_mouse_position()):
			self._click_start_position = get_local_mouse_position()
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
		if event.is_released() and $SelectBox.is_selecting:
			$SelectBox.stop_selecting()
	
	if event is InputEventKey and Input.is_key_pressed(KEY_F5):
		refresh()
	
	# Swap show hidden files when ctrl+H pressed
	if event is InputEventKey and Input.is_key_pressed(KEY_H) and \
	not event.is_echo() and event.ctrl_pressed:
		show_hidden_files = not show_hidden_files
		refresh()
	
	# Idetify if mouse over folder icon view (self)
	var has_mouse_focus = get_rect().has_point(get_local_mouse_position())
	# Handle Ctrl+MouseScroll as Icon resize
	if event is InputEventMouseButton and event.ctrl_pressed and has_mouse_focus:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_folder_size(_folder_size * 1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_folder_size(_folder_size * 0.9)
			
	# Ctrl F Search input handling
	if event is InputEventKey and event.pressed and event.keycode == KEY_F and event.ctrl_pressed:
		ctrl_f_panel_container.show()
		# Prevent 'f' from typing into search
		accept_event()
		# Target search for typing
		ctrl_f_line_edit_plus.grab_focus()
	# User hit escape
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		ctrl_f_panel_container.hide()
		# TODO Use focus to determine search or deselect
		deselect_all_children()
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_F2:
		if visible:
			var objects = get_selected_objects()
			if objects.size() == 1:
				if objects[0].has_method("start_rename"):
					objects[0].start_rename()

func _unhandled_input(event: InputEvent) -> void:
	# Launch selected files when hitting ENTER
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ENTER:
			var selected_paths = PackedStringArray(get_selected_paths())
			$RunFileConfirmationDialog.set_files_to_open(selected_paths)
			$RunFileConfirmationDialog.position = get_screen_transform() * get_local_mouse_position()
			$RunFileConfirmationDialog.popup()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var selected_paths = PackedStringArray(get_selected_paths())
			if selected_paths.size() < 1:
				selected_paths = PackedStringArray([_full_directory_path])
			$FilePopupMenu.pre_popup(selected_paths)
			$FilePopupMenu.position = get_screen_transform() * get_local_mouse_position()
			$FilePopupMenu.call_deferred("popup")
			accept_event()
	

# Current working directory
func get_directory() -> String:
	return self._full_directory_path

# Adds folder to current view. DOES NOT EDIT FILE SYSTEM
func add_folder_button(folder: FolderLargeIconButton):
	$SelectBox/ScrollContainer/HFlowContainer.call_deferred("add_child", folder)

# Returns an array of all folders/files buttons
func get_folder_buttons() -> Array[Node]:
	return self._folder_container.get_children() if _folder_container else []

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
	var dir_access = DirAccess.open(self._full_directory_path)
	if dir_access:
		dir_access.include_hidden = show_hidden_files
		for directory in dir_access.get_directories():
			var button = FOLDER.instantiate()
			button.set_thread_queue(self._thread_queue)
			var path = self._full_directory_path + "/" + directory
			button.double_clicked.connect(set_directory.bind(path))
			# Force allow left and right click
			button.button_mask = MOUSE_BUTTON_MASK_LEFT + MOUSE_BUTTON_MASK_RIGHT
			button.button_down.connect(button.select)
			button.set_path(path, "📁")
			var icon_size = get_folder_size()
			button.custom_minimum_size = Vector2(icon_size, icon_size)
			add_folder_button(button)

	# Add files to view
	if dir_access:
		dir_access.include_hidden = show_hidden_files
		for file_name in dir_access.get_files():
			var button = FOLDER.instantiate()
			button.set_thread_queue(self._thread_queue)
			var file_path = self._full_directory_path + "/" + file_name
			button.double_clicked.connect(emit_signal.bind("file_clicked", file_path))
			# Force allow left and right click
			button.button_mask = MOUSE_BUTTON_MASK_LEFT + MOUSE_BUTTON_MASK_RIGHT
			button.button_down.connect(button.select)
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
	var area = Rect2(target_position, Vector2(1, 1)) # Single pixel area/point
	for child: FolderLargeIconButton in get_folder_buttons():
		# Guarantee object is selectable
		if child.has_method("select"):
			if child.get_global_rect().intersects(area, true):
				child.select()

# True if item under point is_selected, or false if no child
func is_selected_point(target_position: Vector2) -> bool:
	var area = Rect2(target_position, Vector2(1, 1)) # Single pixel area/point
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
	var area = Rect2(target_position, Vector2(1, 1)) # Single pixel area/point
	for child: Control in get_folder_buttons():
		if child.has_method("select"):
			if child.get_rect().intersects(area, true):
				path = child.get_abs_path()
	return path

# Gets folder/file object under position
func get_object_at_point(target_position: Vector2) -> FolderLargeIconButton:
	var area = Rect2(target_position, Vector2(1, 1)) # Single pixel area/point
	for child: Control in get_folder_buttons():
		if child.has_method("select"):
			if child.get_rect().intersects(area, true):
				return child
	return null

# Set square size of all folders in view
func set_folder_size(custom_size: float):
	# Minimum size 64, errors occur below this size
	if custom_size < 64:
		return
		
	self._folder_size = custom_size
	# Set folder/file square size
	for child: Control in get_folder_buttons():
		child.custom_minimum_size = Vector2(custom_size, custom_size)
	save_settings()
	
func save_settings():
	var config = ConfigFile.new()
	config.set_value("folder_icon_view", "_folder_size", _folder_size)
	config.save(SAVE_FILEPATH)
	
	
# Square size of folder object
func get_folder_size() -> float:
	return self._folder_size

# Removes all folder buttons from view (File system not touched)
func clear():
	# Remove all folders/files
	for child in get_folder_buttons():
		child.queue_free()

func _on_ctrl_f_line_edit_plus_text_changed(new_text: String) -> void:
	for child: FolderLargeIconButton in get_folder_buttons():
		if (child.has_method("get_abs_path")):
			if new_text.to_lower() in child.get_abs_path().get_file().to_lower():
				child.select()
			else:
				child.deselect()

func _get_drag_data(at_position: Vector2) -> Variant:
	var initial_drag_item: FolderLargeIconButton = get_object_at_point(at_position)
	# If drag started at nothing, do nothing
	if not initial_drag_item:
		return null
	
	# Get selected folders/files
	var selected: Array[String] = get_selected_paths()
	if selected.size() < 1:
		selected = [initial_drag_item.path]
	
	# Use OS instead of Godot for drag and drop (if available)
	if get_window().has_method("drag_files"):
		get_window().drag_files(PackedStringArray(selected))
	else:
		return PackedStringArray(selected)
	
	return null

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Verify paths are being dragged, and allow dropping
	if typeof(data) == TYPE_PACKED_STRING_ARRAY:
		for path: String in data:
			if not path.is_absolute_path():
				return false
		return true
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	# Hand-off dropping to OS
	if typeof(data) == TYPE_PACKED_STRING_ARRAY:
		get_window().emit_signal("files_dropped", data)


# Location of file/folders in gui
func get_global_file_area_rect() -> Rect2:
	# Remove width of scroll bar
	var bar_width = _get_v_scroll_bar_width()

	# Adjust rect
	var file_rect = get_global_rect()
	file_rect.size.x -= bar_width
	
	return file_rect
	

func _get_v_scroll_bar_width() -> int:
	# Sum margins of scrollbar to get width
	# Object hides scroll bar access, must make sacrificial bar to get proper width
	var temp_scroll = VScrollBar.new()
	add_child(temp_scroll)
	var style_box = temp_scroll.get_theme_stylebox("scroll")
	remove_child(temp_scroll)
	return style_box.content_margin_left + style_box.content_margin_right


func _on_file_clicked(file_path: String) -> void:
	$RunFileConfirmationDialog.set_files_to_open(PackedStringArray([file_path]))
	$RunFileConfirmationDialog.position = get_screen_transform() * get_local_mouse_position()
	$RunFileConfirmationDialog.popup()

func add_menu_command(menu_text: String, emoji_icon: String, action: Callable, menu_for_filetype: FilePopupMenu.FILETYPE_FLAG):
	$FilePopupMenu.add_menu_command(menu_text, emoji_icon, action, menu_for_filetype)

extends Tree
## Allows selection of folder from tree
## Each TreeItem is a folder
## Each TreeItem metadata is full path
## Each TreeItem text is folder name
##
## folder_selected emits with full path to folder

# TODO Add targeted folder path updating (update on new folder creation)

signal folder_changed(folder_path: String)
@onready var old_min_width = {0:128, 1: 128}
var _full_directory_path: String
@onready var tree_root: TreeItem = create_item()
var column_titles = ["Name", "Size"]
@onready var folder: Label = $SubViewport/PanelContainer/Label

var dragging_resize_column: int = -1

# TODO get icons from outside self
var icons : Dictionary = {"dll": "📚", "txt": "🗒️", "exe": "🚀", "conf": "⚙️",\
 "ini": "⚙️", "py": "🐍", "pyw": "🐍", "url": "🕸️", "htm": "🕸️", "html": "🕸️",\
"lnk": "🔗", "ods": "📊", "xls": "📊", "xlsx": "📊", "json": "📔", "jar": "☕",\
"properties": "⚙️", "mkv": "🎞️", "webm": "🎞️", "flv": "🎞️", "3g2": "🎞️", \
"3gp": "🎞️", "amv": "🎞️", "asf": "🎞️", "avi": "🎞️", "gifv": "🎞️", "m4v": "🎞️",\
 "mov": "🎞️", "qt": "🎞️", "mpg": "🎞️", "mpeg": "🎞️", "mts": "🎞️", "m2ts": "🎞️",\
 "ts": "🎞️", "ogv": "🎞️", "rmvb": "🎞️", "wmv": "🎞️", "mp4": "🎞️", "mp3": "🎵",\
"wav": "🎵", "jpg": "🖼️", "png": "🖼️", "gif": "🖼️", "zip": "🗜️", "rar": "🗜️", \
"x86_64": "🚀", "pdf": "🖨️", "ogg": "🎵", "c": "🌊", "cpp": "🌊", "sh": "🐚", \
"desktop": "🖥️", "h": "🗣️", "so": "🎁", "md": "🗒️", "drawio": "📝", "bin": "💿",\
"iso": "💿", "stl": "🧵", "gcode": "🧵", "arm64": "🦾", "svg": "🖼️",\
 "hpp": "🗣️", "cfg": "⚙️", "apk": "🤖", "docx": "🗒️", "ppt": "📽️"}


# Returns folder path of tree item or "" if mouse is elsewhere
func folder_at_mouse() -> String:
	var item = $".".get_item_at_position(get_local_mouse_position())
	return String() if item == null else item.get_metadata(0)

func _input(event):
	if event is InputEventKey and Input.is_key_pressed(KEY_F1):
		var arr = get_expanded_folders()
		print(arr)
		refresh()
	
	# Resize column width
	if dragging_resize_column > -1:
		var width =  get_local_mouse_position().x
		var starting_x = 0
		for i in range(dragging_resize_column):
			starting_x += get_column_width(i)
		set_column_custom_minimum_width(dragging_resize_column, width - starting_x + get_scroll().x)
		
		# Stop resizing on mouse release
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			dragging_resize_column = -1

func _gui_input(event: InputEvent) -> void:
	# On column click, start column resize
	if event is InputEventMouse and event.is_pressed():
		if get_local_mouse_position().y <= _get_title_row_height():
			dragging_resize_column = get_column_at_position(Vector2(event.position.x, _get_title_row_height()+1))


func _ready():
	columns = column_titles.size()
	
	# Handle dropped files
	get_window().files_dropped.connect(files_dropped)

	for i in range(column_titles.size()):
		set_column_title(i, column_titles[i])
		set_column_expand(i, false)
		set_column_custom_minimum_width(i, old_min_width.get(i, 128))
	set_column_expand(0, true)

func files_dropped(files: PackedStringArray):
	# TODO simplify file drop action.
	var target_folder = folder_at_mouse()
	# If there are files and a folder under the mouse
	if len(files) > 0 and len(target_folder) > 0:
		var file_transfer = preload("res://FileBrowser/file_transfer_window.tscn").instantiate()
		file_transfer.hide()
		file_transfer.connect("tree_exiting", refresh)
		add_child(file_transfer)
		if Input.is_key_pressed(KEY_SHIFT):
			file_transfer.move(files, target_folder)
		else:
			file_transfer.copy(files, target_folder)
			

# Change current directoy, removes all icons and adds icons for full_path
func set_directory(full_path: String):
	self._full_directory_path = full_path.simplify_path()
	refresh()
	emit_signal("folder_changed", full_path)

# Clears Children, Adds folder/files based on current directory
func refresh():
	# Remove current directory content
	clear()
	$".".clear()
	# Add each drive
	tree_root = $".".create_item()
	tree_root.set_text(0, "root")
	$".".hide_root = true
	
	for directory in DirAccess.get_directories_at(self._full_directory_path):
		_create_folder(tree_root, _full_directory_path.path_join(directory))
	
	for file in DirAccess.get_files_at(self._full_directory_path):
		_create_file(tree_root, _full_directory_path.path_join(file))
	
	for dir_tree_item: TreeItem in tree_root.get_children():
		_add_sub_folder(dir_tree_item)
	
	# Add animation minimal to folders
	folder.pivot_offset = Vector2(8, 8)
	var rot = create_tween()
	rot.set_trans(Tween.TRANS_ELASTIC)
	rot.set_ease(Tween.EASE_OUT)
	folder.rotation_degrees = -15
	rot.tween_property(folder, "rotation_degrees", 0, 0.75)

# Returns list of expanded folders in tree
func get_expanded_folders() -> Array[String]:
	var arr: Array[String] = []
	_expanded_folders($".".get_root(), arr)
	return arr

func _expanded_folders(tree_item: TreeItem, array: Array):
	var next: TreeItem = tree_item.get_next_visible() if tree_item else null
	if next:
		if not next.collapsed:
			array.append(next.get_metadata(0))
		_expanded_folders(next, array)

func _on_item_collapsed(item:TreeItem):
	# When expanded, add folders to subfolders of expanded tree
	if not item.collapsed:
		if item.get_child_count() > 0:
			for folder in item.get_children():
				if folder.get_child_count() == 0:
					_add_sub_folder(folder)


func _add_sub_folder(tree_item: TreeItem):
	# Create TreeItems for all subfolders of given TreeItem
	var path = tree_item.get_metadata(0)
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var full_path = path.path_join(file_name)
			# If folder, create TreeItem folder
			if DirAccess.dir_exists_absolute(full_path):
				# Adding child is not animation/thread safe, must call deferred
				$".".call_deferred("_create_folder", tree_item, full_path)
			elif FileAccess.file_exists(full_path):
				$".".call_deferred("_create_file", tree_item, full_path)
			# Check next folder
			file_name = dir.get_next()


func _create_folder(base_tree_item, full_path: String):
	# Create folder TreeItem with saved path
	var new_tree_item: TreeItem = $".".create_item(base_tree_item)
	new_tree_item.collapsed = true
	new_tree_item.set_text(0, full_path.get_file()) # On folders get_file() gets last folder name
	new_tree_item.set_metadata(0, full_path)
	var dirAcc = DirAccess.open(full_path)
	if dirAcc:
		dirAcc.include_hidden = true
		var dirCount = dirAcc.get_directories_at(full_path).size()
		var fileCount = dirAcc.get_files_at(full_path).size()
		new_tree_item.set_text(1, str(dirCount + fileCount)+" objects")
	new_tree_item.set_icon(0, $SubViewport.get_texture())

func _create_file(base_tree_item, full_path: String):
	# Create folder TreeItem with saved path
	var new_tree_item: TreeItem = $".".create_item(base_tree_item)
	new_tree_item.collapsed = true
	new_tree_item.set_text(0, full_path.get_file()) # On folders get_file() gets last folder name
	new_tree_item.set_metadata(0, full_path)
	new_tree_item.set_text(1, str(FileAccess.get_size(full_path)) + " bytes")
	
	# Find icon to use based on extension
	var ext: String = full_path.get_extension()
	var icon_emoji: String = icons.get(ext, "📄")
	# Get the previously memory loaded texture if available
	var subview = get_node_or_null(icon_emoji)
	if not subview: # Icon not in memory
		# Load emoji to texture object
		subview = preload("res://FileBrowser/sub_viewport_single_label.tscn").instantiate()
		subview.set_text(icon_emoji)
		# Set name as emoji for easy get/null on line above
		subview.name = icon_emoji
		# Label>Subview>Texture>Tree Item texture only work if added and "visible"
		add_child(subview)
	# Set icon using same texture/memory for all same emojis
	new_tree_item.set_icon(0, subview.get_texture())
	

func _on_column_title_clicked(column: int, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		accept_event()
		var mouse = DisplayServer.mouse_get_position()
		$PopupMenu.position = mouse
		$PopupMenu.popup()


func _on_popup_menu_id_pressed(id: int) -> void:
	var col_index = id
	var menu_index = id - 1
	var is_checked = not $PopupMenu.is_item_checked(menu_index)
	$PopupMenu.set_item_checked(menu_index, is_checked)
	if is_checked:
		set_column_expand(col_index, true)
		set_column_custom_minimum_width(col_index, old_min_width.get(col_index, 1))
		set_column_title(col_index, column_titles[col_index])
	else:
		set_column_expand(col_index, false)
		old_min_width.set(col_index, get_column_width(col_index))
		set_column_custom_minimum_width(col_index, 0)
		set_column_title(col_index, "")
		

func get_selected_tree_items() -> Array[TreeItem]:
	var selected: Array[TreeItem] = []
	var next_selected = get_next_selected(null)
	while next_selected:
		selected.append(next_selected)
		next_selected = get_next_selected(next_selected)
	return selected

func _on_item_activated() -> void:
	# Get multi selected items
	var selected = get_selected_tree_items()
	
	# Action if single folder was activated
	if selected.size() == 1:
		var full_path = selected[0].get_metadata(0)
		if DirAccess.dir_exists_absolute(full_path):
			set_directory(full_path)

func _get_drag_data(at_position: Vector2) -> Variant:
	# If drag started at nothing, do nothing
	if not get_item_at_position(at_position):
		return null
	
	# Get selected folders/files
	var selected: Array[TreeItem] = get_selected_tree_items()
	var folders: = []
	if selected.size() > 0:
		for select: TreeItem in selected:
			var full_path = path_from_TreeItem(select)
			folders.append(full_path)
	
	if folders:
		# Use OS instead of Godot for drag and drop (if available)
		if get_window().has_method("drag_files"):
			get_window().drag_files(PackedStringArray(folders))
		else:
			return PackedStringArray(folders)
	return null

# Prevent cancel mouse icon
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
		get_tree().root.emit_signal("files_dropped", data)
	

func path_from_TreeItem(given_item: TreeItem) -> String:
	return given_item.get_metadata(0)

# Returns Array of paths in current directory
func get_selected_paths() -> Array[String]:
	var all_paths: Array[String] = []
	var selected = get_selected_tree_items()
	for child in selected:
		all_paths.append(path_from_TreeItem(child))
	return all_paths

# Location of file/folders in gui
func get_global_file_area_rect() -> Rect2:
	# Remove height of title row
	var title_row_height = _get_title_row_height()
	
	# Remove width of scroll bar
	var bar_width = _get_v_scroll_bar_width()

	# Adjust rect
	var file_rect = get_global_rect()
	file_rect.position.y += title_row_height
	file_rect.size.y -= title_row_height
	file_rect.size.x -= bar_width
	
	return file_rect

func _get_title_row_height() -> int:
	var root_y = get_item_area_rect(get_root()).position.y
	var scroll_y = get_scroll().y
	var title_row_height = root_y + scroll_y
	return title_row_height
	

func _get_v_scroll_bar_width() -> int:
	# Sum margins of scrollbar to get width
	# Object hides scroll bar access, must make sacrificial bar to get proper width
	var temp_scroll = VScrollBar.new()
	add_child(temp_scroll)
	var style_box = temp_scroll.get_theme_stylebox("scroll")
	remove_child(temp_scroll)
	return style_box.content_margin_left + style_box.content_margin_right

	

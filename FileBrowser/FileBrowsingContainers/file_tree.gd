extends Tree
class_name FileTree
## Allows selection of folder from tree
## Each TreeItem is a folder
## Each TreeItem metadata is full path
## Each TreeItem text is folder name
##
## folder_selected emits with full path to folder

# TODO Add targeted folder path updating (update on new folder creation)

@export var show_folders: bool = true
@export var show_files: bool = true
# Will only allow viewing of OS folders from  OS.get_drive_name
@export var only_show_drives: bool = false
@export var always_fit_name: bool = false
@export var show_hidden_files: bool = true
@onready var file_popup_menu: PopupMenu = $FilePopupMenu


signal folder_changed(folder_path: String)
@onready var old_min_width = {0:128, 1: 128}
var _full_directory_path: String
var tree_root: TreeItem
var column_titles = ["Name", "Size"]
var _fold_structure = {}
var _sort_column = 0
var _is_sort_ascending = true
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

const SUB_VIEWPORT_SINGLE_LABEL = preload("uid://cnrjg1q6m5y36")
const FILE_TRANSFER_WINDOW = preload("uid://5bl4nmd56lgq")


# Returns folder path of tree item or "" if mouse is elsewhere
func folder_at_mouse() -> String:
	var item = get_item_at_position(get_local_mouse_position())
	var path = ""
	# Handle dropping on empty space
	if item == null:
		if get_global_file_area_rect().has_point(get_global_mouse_position()):
			path = _full_directory_path
	# Normal drop on file or folder
	else:
		path = item.get_metadata(0)
	# Guarantee folder path (Not a file)
	if path and FileAccess.file_exists(path):
		path = path.get_base_dir()
	return path

func _input(event):
	# Handle rename hotkey F2
	if event is InputEventKey and Input.is_key_pressed(KEY_F2):
		var selected_trees: Array[TreeItem] = get_selected_tree_items()
		if selected_trees.size() > 0:
			for tree_item in selected_trees:
				tree_item.set_editable(0, true)
			edit_selected(false)
			for tree_item in selected_trees:
				tree_item.set_editable(0, false)
	
	# Handle refresh hotkey F5
	if event is InputEventKey and Input.is_key_pressed(KEY_F5) and not event.is_echo():
		refresh()
	
	# Swap show hidden files when ctrl+H pressed
	if event is InputEventKey and Input.is_key_pressed(KEY_H) and \
	not event.is_echo() and event.ctrl_pressed:
		show_hidden_files = not show_hidden_files
		refresh()

	# Deselect all on escape
	if event is InputEventKey and Input.is_key_pressed(KEY_ESCAPE) and \
	not event.is_echo():
		if visible:
			deselect_all()

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


func _unhandled_input(event: InputEvent) -> void:
	# Select all Ctrl+A
	if event is InputEventKey and Input.is_key_pressed(KEY_A) and \
	not event.is_echo() and event.ctrl_pressed:
		if visible:
			var tree_item = get_root().get_first_child()
			while tree_item:
				tree_item.select(0)
				tree_item = tree_item.get_next_visible()

func _gui_input(event: InputEvent) -> void:
	# On column click, start column resize
	if event is InputEventMouse and event.is_pressed():
		if get_local_mouse_position().y <= _get_title_row_height():
			dragging_resize_column = get_column_at_position(Vector2(event.position.x, _get_title_row_height()+1))


func _ready():
	columns = column_titles.size()
	call_thread_safe("_set_column_titles")
	
	enable_drag_unfolding = true

func _enter_tree() -> void:
	# Handle dropped files
	get_window().files_dropped.connect(files_dropped)
	

func _set_column_titles():
	for i in range(min(column_titles.size(), columns)):
		set_column_title(i, column_titles[i])
		set_column_expand(i, false)
		set_column_custom_minimum_width(i, old_min_width.get(i, 128))
	set_column_expand(0, true)

func files_dropped(files: PackedStringArray):
	if visible:
		# TODO simplify file drop action.
		var target_folder = folder_at_mouse()
		# If there are files and a folder under the mouse
		if len(files) > 0 and len(target_folder) > 0:
			var file_transfer = FILE_TRANSFER_WINDOW.instantiate()
			file_transfer.hide()
			file_transfer.connect("tree_exiting", refresh)
			# Add to main window to avoid closure with sub_windows/popup
			get_tree().root.add_child(file_transfer)
			if Input.is_key_pressed(KEY_SHIFT):
				file_transfer.move(files, target_folder)
			else:
				file_transfer.copy(files, target_folder)
			

# Change current directoy, removes all icons and adds icons for full_path
func set_directory(full_path: String):
	$FileBrowsingController.set_directory(full_path)
	$FolderPoller.only_poll_folder(full_path)


# Current working directory
func get_directory() -> String:
	return _full_directory_path
	

# Used by FileBrowingController signal to update directory
func _full_directory_path_setter(full_path:String):
	if not only_show_drives: # never actually change folders!
		self._full_directory_path = full_path.simplify_path()
	refresh()
	emit_signal("folder_changed", full_path)

# Save collapsed tree structure
func _fill_fold(tree_item: TreeItem):
	while tree_item:
		var path = path_from_TreeItem(tree_item)
		_fold_structure.set(path, tree_item.collapsed)
		if not tree_item.collapsed:
			_fill_fold(tree_item.get_first_child())
		tree_item = tree_item.get_next()

	
# Clears Children, Adds folder/files based on current directory
func refresh():
	# Save scroll to restore point after refresh
	var original_scroll = get_scroll()
	var scroll_to_tree_item = get_item_at_position(Vector2(size.x/2,size.y-5))
	var scroll_to_path = path_from_TreeItem(scroll_to_tree_item) if scroll_to_tree_item else ""
	
	if tree_root:
		# Get current fold structure (is folder expanded?)
		_fold_structure.clear()
		var tree_item = get_root().get_first_child()
		_fill_fold(tree_item)
	
	if only_show_drives:
		show_default_os_drives()
	else:
		# Remove current directory content
		clear()
		
		if not tree_root:
			tree_root = create_item()
			tree_root.set_text(0, "root")
		hide_root = true
		
		
		if show_folders:
			var dir_access = DirAccess.open(self._full_directory_path)
			if dir_access:
				dir_access.include_hidden = show_hidden_files
				for directory in dir_access.get_directories():
					_create_folder.call_deferred(tree_root, _full_directory_path.path_join(directory))
		
		if show_files:
			var dir_access = DirAccess.open(self._full_directory_path)
			if dir_access:
				dir_access.include_hidden = show_hidden_files
				for file in dir_access.get_files():
					_create_file.call_deferred(tree_root, _full_directory_path.path_join(file))
		
		# Sort again on refresh
		_sort_tree.call_deferred(get_root(), _sort_column, _is_sort_ascending)
	
	# Set scroll to where it was recorded before
	if scroll_to_path:
		_scroll_vector2_near_path.call_deferred(original_scroll, scroll_to_path)


# Godot only allows scrolling to items, no manual control of scroll bar
# But all items are cleared and remade, attempt to scroll to closest point
func _scroll_vector2_near_path(scroll_position: Vector2, path:String):
	var tree_item = _tree_item_from_path(path)
	if tree_item:
		scroll_to_item(tree_item.get_prev())
		if get_scroll().y < scroll_position.y:
			scroll_to_item(tree_item)
	
func _tree_item_from_path(filepath: String)->TreeItem:
	var tree_item = get_root().get_first_child()
	while tree_item:
		var path = path_from_TreeItem(tree_item)
		if path == filepath:
			return tree_item
		else:
			tree_item = tree_item.get_next_in_tree()
	return tree_item

func _sort_tree(tree_item, sort_column: int, is_ascending: bool=true):
	# default to first column if incorrect column given
	sort_column = sort_column if sort_column < columns else 0
	if tree_item:
		var items: Array[TreeItem] = tree_item.get_children()
		if is_ascending:
			items.sort_custom(func(a,b): return a.get_text(sort_column).naturalnocasecmp_to(b.get_text(sort_column)) < 0 )
		else:
			items.sort_custom(func(a,b): return a.get_text(sort_column).naturalnocasecmp_to(b.get_text(sort_column)) > 0 )
		for index in range(items.size()-1):
			items[index+1].move_after(items[index])
		
		for child in items:
			if child is TreeItem:
				_sort_tree(child, sort_column, is_ascending)


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
			for folder_path in item.get_children():
				item.remove_child(folder_path)
			_add_sub_folder(item)
		_sort_tree.call_deferred(item, _sort_column, _is_sort_ascending)
		
		$FolderPoller.add_folder_to_poll(path_from_TreeItem(item))
	else:
		var folder_path = path_from_TreeItem(item)
		if folder_path:
			$FolderPoller.erase(folder_path)


func _add_sub_folder(tree_item: TreeItem):
	# Create TreeItems for all subfolders of given TreeItem
	var path = tree_item.get_metadata(0)
	if path:
		var dir = DirAccess.open(path)
		if dir:
			dir.include_hidden = show_hidden_files
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name:
				var full_path = path.path_join(file_name)
				# If folder, create TreeItem folder
				if show_folders and DirAccess.dir_exists_absolute(full_path):
					# Adding child is not animation/thread safe, must call deferred
					call_deferred("_create_folder", tree_item, full_path)
				elif show_files and FileAccess.file_exists(full_path):
					call_deferred("_create_file", tree_item, full_path)
				# Check next folder
				file_name = dir.get_next()

# Create a TreeItem folder on given TreeItem
func _create_folder(base_tree_item, full_path: String, label_full_path: bool=false):
	# Create folder TreeItem with saved path
	var new_tree_item: TreeItem = create_item(base_tree_item)
	new_tree_item.collapsed = true
	var label_text = full_path if label_full_path else full_path.get_file()
	if label_text == "": # Unix / has no folder name
		label_text = "/"
	new_tree_item.set_text(0, label_text) # On folders get_file() gets last folder name
	new_tree_item.set_metadata(0, full_path)
	var dirAcc = DirAccess.open(full_path)
	var folder_contents_count = 0
	if dirAcc:
		dirAcc.include_hidden = true
		var dir_count = dirAcc.get_directories().size()
		var file_count = dirAcc.get_files().size()
		folder_contents_count = dir_count + file_count
		# Set size column size
		var size_column_index = column_titles.find("Size")
		if size_column_index >= 0 and size_column_index < columns: # Only set size if it exists
			new_tree_item.set_text(size_column_index, str(folder_contents_count)+" objects")
	new_tree_item.set_icon(0, create_get_subview_label("📁").get_texture())
	
	# Create place holder item on folders with sub-content
	if folder_contents_count > 0:
		create_item(new_tree_item)
	
	# Uncollapse if saved as open folder
	new_tree_item.collapsed = _fold_structure.get(full_path, true)
	
	# Optional no-trim of folder/file names
	if always_fit_name:
		new_tree_item.set_text_overrun_behavior(0, TextServer.OVERRUN_NO_TRIMMING)

# Create a TreeItem file on given TreeItem
func _create_file(base_tree_item, full_path: String):
	# Create folder TreeItem with saved path
	var new_tree_item: TreeItem = create_item(base_tree_item)
	new_tree_item.collapsed = true
	new_tree_item.set_text(0, full_path.get_file()) # On folders get_file() gets last folder name
	new_tree_item.set_metadata(0, full_path)
	var file_size := FileAccess.get_size(full_path)
	# Ignore -1 error and report as 0 bytes
	file_size = file_size if file_size >= 0 else 0
	new_tree_item.set_text(1, str(file_size) + " bytes")
	
	# Find icon to use based on extension
	var ext: String = full_path.get_extension()
	var icon_emoji: String = icons.get(ext, "📄")
	# Get the previously memory loaded texture if available
	var subview = create_get_subview_label(icon_emoji)
	# Set icon using same texture/memory for all same emojis
	new_tree_item.set_icon(0, subview.get_texture())
	if always_fit_name:
		new_tree_item.set_text_overrun_behavior(0, TextServer.OVERRUN_NO_TRIMMING)

# Returns subview with given emoji, makes new subview if not yet made
func create_get_subview_label(emoji: String):
	var subview = get_node_or_null(emoji)
	if not subview: # Icon not in memory
		# Load emoji to texture object
		subview = SUB_VIEWPORT_SINGLE_LABEL.instantiate()
		subview.set_text(emoji)
		# Set name as emoji for easy get/null on line above
		subview.name = emoji
		# Label>Subview>Texture>Tree Item texture only work if added and "visible"
		add_child(subview)
	return subview

func _on_column_title_clicked(_column: int, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		accept_event()
		var mouse = DisplayServer.mouse_get_position()
		$PopupMenu.position = mouse
		$PopupMenu.popup()
	# Left click
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		# Double click action
		if $TimerDoubleClick.is_stopped(): # Single click detected
			$TimerDoubleClick.start() # Timer to detect double click
		else:
			_is_sort_ascending = not _is_sort_ascending
			_sort_tree(get_root(), _column, _is_sort_ascending)


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

# File/Folder run action
func _on_item_activated() -> void:
	# Get multi selected items
	var selected = get_selected_tree_items()
	
	# Action if single folder was activated
	if selected.size() == 1:
		var full_path = selected[0].get_metadata(0)
		if full_path and DirAccess.dir_exists_absolute(full_path):
			set_directory(full_path)
			return
	
	if selected.size() > 0:
		$RunFileConfirmationDialog.set_files_to_open(PackedStringArray(get_selected_paths()))
		$RunFileConfirmationDialog.position = get_screen_transform() * get_local_mouse_position()
		$RunFileConfirmationDialog.popup()

func _get_drag_data(at_position: Vector2) -> Variant:
	# If drag started at nothing, do nothing
	if not get_item_at_position(at_position):
		return null
	
	
	# Get selected folders/files
	var selected: Array[TreeItem] = get_selected_tree_items()
	var folders: = []
	if selected.size() > 0:
		var label_box = VBoxContainer.new()
		for select: TreeItem in selected:
			var full_path = path_from_TreeItem(select)
			folders.append(full_path)
			
			# Create drag visibility
			var label = Label.new()
			label.text = full_path.get_file()
			#label_box.add_child(label)
			var icon = TextureRect.new()
			# TODO Error handling on no icon?
			icon.texture = select.get_icon(0)
			var hbox = HBoxContainer.new()
			hbox.add_child(icon)
			hbox.add_child(label)
			label_box.add_child(hbox)
			
		set_drag_preview(label_box)
	
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
		# Allow dropping on objects
		set_drop_mode_flags(DROP_MODE_ON_ITEM)
		return true
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	# Hand-off dropping to OS
	if typeof(data) == TYPE_PACKED_STRING_ARRAY:
		get_window().emit_signal("files_dropped", data)
	

func path_from_TreeItem(given_item: TreeItem) -> String:
	var path = given_item.get_metadata(0)
	if path:
		return path
	return ""

func set_path_on_TreeItem(tree_item: TreeItem, new_path: String):
	tree_item.set_metadata(0, new_path)

# Returns Array of paths in current directory
func get_selected_paths() -> Array[String]:
	var all_paths: Array[String] = []
	var selected = get_selected_tree_items()
	for child in selected:
		if child:
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

# The sets tree to OS level drives available. See DirAccess.get_drive_name()
func show_default_os_drives():
	# Remove current directory content
	clear()
	# Add each drive
	tree_root = create_item()
	tree_root.set_text(0, "root")
	hide_root = true
	var drive_count = DirAccess.get_drive_count()
	for drive_index in range(drive_count):
		var drive_name = DirAccess.get_drive_name(drive_index)
		_create_folder.call_deferred(tree_root, drive_name)
		$FolderPoller.add_folder_to_poll(drive_name)


func _on_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		var selected_paths = PackedStringArray(get_selected_paths())
		$FilePopupMenu.pre_popup(selected_paths)
		$FilePopupMenu.position = get_screen_transform() * mouse_position
		$FilePopupMenu.popup()


func _on_empty_clicked(click_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		var selected_paths = PackedStringArray(get_selected_paths())
		if selected_paths.size() < 1:
			selected_paths = PackedStringArray([_full_directory_path])
		$FilePopupMenu.pre_popup(selected_paths)
		$FilePopupMenu.position = get_screen_transform() * click_position
		$FilePopupMenu.popup()
		

func _on_item_edited() -> void:
	# Find edited TreeItem(s) and update them
	var selected_trees: Array[TreeItem] = get_selected_tree_items()
	if selected_trees.size() > 0:
		for tree_item in selected_trees:
			var path = path_from_TreeItem(tree_item)
			var true_object_name = path.get_file()
			var shown_name = tree_item.get_text(0)
			if true_object_name != shown_name:
				var new_path = path.get_base_dir().path_join(shown_name)
				var rename_attempt = DirAccess.rename_absolute(path, new_path)
				# Fix tree_item path with new renamed path
				if rename_attempt == OK:
					set_path_on_TreeItem(tree_item, new_path)
				# On failure revert to original name
				else:
					tree_item.set_text(0, true_object_name)

func add_menu_command(menu_text: String, emoji_icon: String, action: Callable, menu_for_filetype:FilePopupMenu.FILETYPE_FLAG):
	if not is_node_ready():
		await ready
	file_popup_menu.add_menu_command(menu_text, emoji_icon, action, menu_for_filetype)

func get_popup_menus():
	return [file_popup_menu, $PopupMenu]

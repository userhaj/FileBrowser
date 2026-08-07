extends Control

@onready var folder_view: FolderIconView = $PanelContainer/VBoxContainer/HSplitContainer/FolderIconView
@onready var current_path: String = DirAccess.get_drive_name(0)
@onready var current_path_line_edit: LineEditPlus = $PanelContainer/VBoxContainer/MenuHBoxContainer/CurrentPathLineEdit
@onready var file_button: Button = $PanelContainer/VBoxContainer/MenuHBoxContainer/FileButton
@onready var view_menu_button = $PanelContainer/VBoxContainer/MenuHBoxContainer/ViewButton
@onready var folder_tree: Tree = $PanelContainer/VBoxContainer/HSplitContainer/PanelContainer/VSplitContainer/FileTree
@onready var bookmarks: BookmarkItemList = $PanelContainer/VBoxContainer/HSplitContainer/PanelContainer/VSplitContainer/PanelContainer/BookmarkItemList
@onready var bookmark_container = $PanelContainer/VBoxContainer/HSplitContainer/PanelContainer/VSplitContainer/PanelContainer
@onready var file_tree: Tree = $PanelContainer/VBoxContainer/HSplitContainer/FileTree

var settings_file_name = "user://SETTINGS.cfg"

var is_shoot_laser_left: bool = true

# Folders to go to when going "Back"
var folder_past_list = []
# Folders to go to when going "Forward"
var folder_future_list = []

func _ready():
	set_current_path(current_path.simplify_path())
	visual_load()
	folder_tree.show_default_os_drives()
	folder_tree.columns = 1
	$PanelContainer/VBoxContainer/MenuHBoxContainer/FolderSizeHSlider.value = folder_view._folder_size
	
func visual_load():
	var config: ConfigFile = ConfigFile.new()
	var err = config.load(settings_file_name)
	if err == OK:
		$PanelContainer/VBoxContainer/HSplitContainer.split_offsets = config.get_value("display", "$PanelContainer/VBoxContainer/HSplitContainer.split_offsets", 216)
		$PanelContainer/VBoxContainer/HSplitContainer/PanelContainer/VSplitContainer.split_offsets = config.get_value("display", "$PanelContainer/VBoxContainer/HSplitContainer.split_offsets", 156)

func visual_save():
	var config: ConfigFile = ConfigFile.new()
	config.set_value("display", "$PanelContainer/VBoxContainer/HSplitContainer.split_offsets", $PanelContainer/VBoxContainer/HSplitContainer.split_offsets)
	config.set_value("display", "$PanelContainer/VBoxContainer/HSplitContainer/PanelContainer/VSplitContainer.split_offsets", $PanelContainer/VBoxContainer/HSplitContainer/PanelContainer/VSplitContainer.split_offsets)
	config.save(settings_file_name)

func set_current_path(full_path: String):
	# Set current path
	self.current_path = full_path.simplify_path()
	current_path_line_edit.text = self.current_path
	if self.current_path != self.folder_view.get_directory():
		self.folder_view.set_directory(self.current_path)
	if self.current_path != file_tree._full_directory_path:
		file_tree.set_directory(self.current_path)
	
	
	# Update folder history (if not already there)
	if folder_past_list.size() > 0:
		if folder_past_list.back() != self.current_path:
			folder_past_list.append(self.current_path)
	else:
		folder_past_list.append(self.current_path)

		
func _on_up_dir_button_pressed():
	var new_path = self.current_path.get_base_dir()
	set_current_path(new_path)
	
func _file_menu():
	# Create file menu below file button
	var true_location = Vector2(get_window().position) + self.file_button.position
	var x_pos = true_location.x
	# Bottom of button
	var y_pos = true_location.y + self.file_button.size.y
	
	# Popup file menu
	var below_file_menu =  Vector2(x_pos, y_pos)
	file_popup_menu_popup(below_file_menu)

func file_popup_menu_popup(new_position: Vector2):
	var paths = PackedStringArray(get_selected_paths())
	accept_event()
	
	
func new_folder(folder_name: String):
	DirAccess.make_dir_absolute(self.current_path + "/" + folder_name)
	# Update to show new folder
	set_current_path(self.current_path)


# Actions for bookmarking
func ask_bookmark_selected_items():
	var paths = get_selected_paths()
	if len(paths) == 0:
		# TODO Make this a popup warning
		print("No items selected")
	else:
		for path in paths:
			if DirAccess.dir_exists_absolute(path):
				bookmarks.add_folder(path)



func _on_h_slider_value_changed(value):
	self.folder_view.set_folder_size(value)

func history_back():
	if folder_past_list.size() > 0:
		var past_folder = folder_past_list.pop_back()
		while past_folder == current_path and folder_past_list.size() > 0:
			past_folder = folder_past_list.pop_back()
		folder_future_list.append(current_path)
		set_current_path(past_folder)

func history_forward():
	if folder_future_list.size() > 0:
		set_current_path(folder_future_list.pop_back())


func get_selected_paths():
	var mouse = get_global_mouse_position()
	var is_tree_files_selected = file_tree.get_global_rect().has_point(mouse)
	if is_tree_files_selected:
		return file_tree.get_selected_paths()
	else:
		return folder_view.get_selected_paths()
		
	

func _input(event: InputEvent) -> void:
	# Capture and perform go back history
	# Left key
	if event is InputEventKey and event.key_label == Key.KEY_LEFT:
		if event.is_pressed():
			# While alt is being held down
			if Input.is_key_pressed(KEY_ALT):
				history_back()
	
	if event is InputEventKey and event.key_label == Key.KEY_RIGHT:
		if event.is_pressed():
			# While alt is being held down
			if Input.is_key_pressed(KEY_ALT):
				history_forward()
				accept_event()
	
	# On F2 rename file if only 1 is selected
	if event is InputEventKey and event.key_label == Key.KEY_F2:
			if event.is_pressed() and not event.is_echo():
				var selected_folders = self.folder_view.get_selected_objects()
				if selected_folders.size() == 1:
					selected_folders[0].start_rename()
	
	if event is InputEventMouseButton:
		if event.button_index == 8 and event.is_pressed():
			history_back()
		if event.button_index == 9 and event.is_pressed():
			history_forward()


func _on_view_button_pressed():
	# Create view menu below view button
	var true_location = self.view_menu_button.position + Vector2(get_window().position)
	var x_pos = true_location.x
	# Bottom of button
	var y_pos = true_location.y + self.view_menu_button.size.y
	$ViewPopupMenu.popup()
	$ViewPopupMenu.position = Vector2(x_pos, y_pos)
	


func _on_view_popup_menu_id_pressed(id):
	match id:
		0:
			var idx = $ViewPopupMenu.get_item_index(id)
			self.folder_tree.visible = not self.folder_tree.visible
			$ViewPopupMenu.set_item_checked(idx, self.folder_tree.visible)
		1:
			var idx = $ViewPopupMenu.get_item_index(id)
			self.current_path_line_edit.visible = not self.current_path_line_edit.visible
			$ViewPopupMenu.set_item_checked(idx, self.current_path_line_edit.visible)
		2:
			var idx = $ViewPopupMenu.get_item_index(id)
			self.bookmark_container.visible = not self.bookmark_container.visible
			$ViewPopupMenu.set_item_checked(idx, self.bookmark_container.visible)
		3:
			var idx = $ViewPopupMenu.get_item_index(id)
			self.file_tree.visible = not self.file_tree.visible
			$ViewPopupMenu.set_item_checked(idx, self.file_tree.visible)
		4:
			var idx = $ViewPopupMenu.get_item_index(id)
			self.folder_view.visible = not self.folder_view.visible
			$ViewPopupMenu.set_item_checked(idx, self.folder_view.visible)

# Settings clicked
func _on_settings_button_pressed() -> void:
	popup_true_centered($SettingsWindow, get_window())

# Place first window centered on second window
func popup_true_centered(popup: Window, window: Window):
	# Popup above everything else (prevent hidden pop under)
	popup.popup()
	# Center on window, Must be done after shown on screen
	popup.position = window.position + Vector2i(window.size - popup.size) / 2
	

func _on_current_path_line_edit_text_submitted(new_text: String) -> void:
	set_current_path(new_text)


func _on_refresh_button_pressed() -> void:
	folder_view.refresh()
	folder_tree.refresh()
	file_tree.refresh()


func _on_v_split_container_drag_ended() -> void:
	pass # Replace with function body.

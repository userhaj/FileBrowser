extends Control

@onready var folder_view: FolderIconView = $PanelContainer/VBoxContainer/HSplitContainer/FolderIconView
@onready var current_path: String = DirAccess.get_drive_name(0)
@onready var current_path_line_edit: LineEditPlus = $PanelContainer/VBoxContainer/PathHBoxContainer/CurrentPathLineEdit
@onready var file_popup_menu: PopupMenu = $FilePopupMenu
@onready var file_button: Button = $PanelContainer/VBoxContainer/MenuHBoxContainer/FileButton
@onready var view_menu_button = $PanelContainer/VBoxContainer/MenuHBoxContainer/ViewButton
@onready var folder_tree: Tree = $PanelContainer/VBoxContainer/HSplitContainer/FolderTree

var is_shoot_laser_left: bool = true

# Folders to go to when going "Back"
var folder_past_list = []
# Folders to go to when going "Forward"
var folder_future_list = []

func _ready():
	set_current_path(current_path.simplify_path())
	self.folder_view.file_clicked.connect(_run_file)
	

func set_current_path(full_path: String):
	# Set current path
	self.current_path = full_path.simplify_path()
	current_path_line_edit.text = self.current_path
	if self.current_path != self.folder_view.get_directory():
		self.folder_view.set_directory(self.current_path)
	
	
	# Update folder history (if not already there)
	if folder_past_list.size() > 0:
		if folder_past_list.back() != self.current_path:
			folder_past_list.append(self.current_path)
	else:
		folder_past_list.append(self.current_path)
	
func _run_file(file_path: String):
	$RunFileConfirmationDialog.dialog_text = "Confirm run file:\n" + file_path
	$RunFileConfirmationDialog.popup_centered()
	$RunFileConfirmationDialog.position = DisplayServer.mouse_get_position()
	if $RunFileConfirmationDialog.confirmed.is_connected(OS.shell_open):
		$RunFileConfirmationDialog.confirmed.disconnect(OS.shell_open)
	$RunFileConfirmationDialog.confirmed.connect(OS.shell_open.bind(file_path))
	
		
func _on_up_dir_button_pressed():
	var new_path = self.current_path.get_base_dir()
	set_current_path(new_path)
	
func _file_menu():
	# Create file menu below file button
	var true_location = Vector2(get_window().position) + self.file_button.position
	var x_pos = true_location.x
	# Bottom of button
	var y_pos = true_location.y + self.file_button.size.y
	#var pos = Vector2(+ , 0)
	self.file_popup_menu.position = Vector2(x_pos, y_pos)
	self.file_popup_menu.popup()
	accept_event()
	
func new_folder(folder_name: String):
	DirAccess.make_dir_absolute(self.current_path + "/" + folder_name)
	# Update to show new folder
	set_current_path(self.current_path)

func _on_file_popup_menu_id_pressed(id):
	match id:
		0:  # New Folder
			$NewFolderConfirmationDialog.popup_centered()
			$NewFolderConfirmationDialog.position = DisplayServer.mouse_get_position()
			$NewFolderConfirmationDialog/NewFolderLineEdit.grab_focus()
		1:  # New File
			$NewFileConfirmationDialog.popup_centered()
			$NewFileConfirmationDialog.position = DisplayServer.mouse_get_position()
			$NewFileConfirmationDialog/NewFileLineEdit.grab_focus()
		2:  # Trash Item(s)
			ask_trash_selected_items()

# Creates text on confirmation dialog about trashing files
func ask_trash_selected_items():
	var paths = self.folder_view.get_selected_paths()
	if len(paths) == 0:
		# TODO Make this a popup warning
		print("No items selected")
	elif len(paths) < 5:
		var path_string = "\n".join(paths)
		$TrashFileConfirmationDialog.dialog_text = "Trash File:\n" + path_string
		$TrashFileConfirmationDialog.popup_centered()
		$TrashFileConfirmationDialog.position = DisplayServer.mouse_get_position()
	else:
		$TrashFileConfirmationDialog.dialog_text = "Trash " + str(len(paths)) + " files?"
		$TrashFileConfirmationDialog.popup_centered()
		$TrashFileConfirmationDialog.position = DisplayServer.mouse_get_position()

# Create new folder for given text
func _on_new_folder_confirmation_dialog_confirmed():
	# Action to create new folder
	new_folder($NewFolderConfirmationDialog/NewFolderLineEdit.text)
	# Clear text from popup for reuse
	$NewFolderConfirmationDialog/NewFolderLineEdit.text = ""
	# Show Changes
	self.folder_view.refresh()

# Sends each selected item to trash
func trash_selected():
	var paths = self.folder_view.get_selected_paths()
	for path in paths:
		OS.move_to_trash(path)
	self.folder_view.refresh()

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
		

func _on_gui_input(event):
	# Show menu on right click
	if event is InputEventMouseButton and not event.is_echo():
		# Is right clicked
		if event.pressed and event.button_index == 2:
			var mouse_position = get_global_mouse_position()
			# Additive select when holding shift or already selected
			if (Input.is_key_pressed(KEY_SHIFT) 
					or Input.is_key_pressed(KEY_CTRL)
					or self.folder_view.is_selected_point(mouse_position)):
				self.folder_view.select_child_by_point(mouse_position)
			# Exclusive select on single folder right click (not empty space)
			elif 0 != len(self.folder_view.get_path_at_point(mouse_position)):
				self.folder_view.deselect_all_children()
				self.folder_view.select_child_by_point(mouse_position)
				
			#Popups fix issue https://github.com/godotengine/godot/issues/87875
			self.file_popup_menu.position =  mouse_position + Vector2(get_window().position)
			self.file_popup_menu.popup()
			accept_event()

# Create new file with given file name
func _on_new_file_confirmation_dialog_confirmed():
	
	var new_file_name = $NewFileConfirmationDialog/NewFileLineEdit.text
	if not FileAccess.file_exists(self.current_path.path_join(new_file_name)):
		FileAccess.open(self.current_path.path_join(new_file_name), FileAccess.WRITE)
		self.folder_view.refresh()


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
			self.folder_tree.visible = not self.folder_tree.visible
			$ViewPopupMenu.set_item_checked(0, self.folder_tree.visible)
		1:
			self.current_path_line_edit.visible = not self.current_path_line_edit.visible
			$ViewPopupMenu.set_item_checked(1, self.current_path_line_edit.visible)

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

extends Control

@onready var folder_view: FolderIconView = $VBoxContainer/HSplitContainer/FolderIconView
@onready var current_path: String = DirAccess.get_drive_name(0)
@onready var current_path_line_edit: LineEdit = $VBoxContainer/PathHBoxContainer/CurrentPathLineEdit
@onready var file_popup_menu: PopupMenu = $FilePopupMenu
@onready var file_button: Button = $VBoxContainer/MenuHBoxContainer/FileButton
@onready var view_menu_button = $VBoxContainer/MenuHBoxContainer/ViewButton
@onready var folder_tree: Tree = $VBoxContainer/HSplitContainer/FolderTree


func _ready():
	set_current_path(current_path.simplify_path())
	self.folder_view.file_clicked.connect(_run_file)

func set_current_path(full_path: String):
	self.current_path = full_path.simplify_path()
	current_path_line_edit.text = self.current_path
	if self.current_path != self.folder_view.get_directory():
		self.folder_view.set_directory(self.current_path)
	
func _run_file(file_path: String):
	$RunFileConfirmationDialog.dialog_text = "Confirm run file:\n" + file_path
	$RunFileConfirmationDialog.popup_centered()
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
	self.file_popup_menu.show()
	
func new_folder(folder_name: String):
	DirAccess.make_dir_absolute(self.current_path + "/" + folder_name)
	# Update to show new folder
	set_current_path(self.current_path)

func _on_file_popup_menu_id_pressed(id):
	match id:
		0:  # New Folder
			$NewFolderConfirmationDialog.popup_centered()
		1:  # New File
			$NewFileConfirmationDialog.popup_centered()
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
	else:
		$TrashFileConfirmationDialog.dialog_text = "Trash " + str(len(paths)) + " files?"
		$TrashFileConfirmationDialog.popup_centered()

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


func _on_gui_input(event):
	# Show menu on right click
	if event is InputEventMouseButton:
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
				
			#Popups 
			self.file_popup_menu.position =  mouse_position + Vector2(get_window().position)
			self.file_popup_menu.show()

# Create new file with given file name
func _on_new_file_confirmation_dialog_confirmed():
	
	var new_file_name = $NewFileConfirmationDialog/NewFileLineEdit.text
	if not FileAccess.file_exists(self.current_path.path_join(new_file_name)):
		FileAccess.open(self.current_path.path_join(new_file_name), FileAccess.WRITE)
		self.folder_view.refresh()


func _on_view_button_pressed():
	# Create vuew menu below view button
	var true_location = self.view_menu_button.position + Vector2(get_window().position)
	var x_pos = true_location.x
	# Bottom of button
	var y_pos = true_location.y + self.view_menu_button.size.y
	#var pos = Vector2(+ , 0)
	$ViewPopupMenu.position = Vector2(x_pos, y_pos)
	$ViewPopupMenu.show()


func _on_view_popup_menu_id_pressed(id):
	match id:
		0:
			self.folder_tree.visible = not self.folder_tree.visible
			$ViewPopupMenu.set_item_checked(0, self.folder_tree.visible)
		1:
			self.current_path_line_edit.visible = not self.current_path_line_edit.visible
			$ViewPopupMenu.set_item_checked(1, self.current_path_line_edit.visible)

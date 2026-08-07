extends PopupMenu

# TYPICAL popup looks like this:
# if mouse_button_index == MOUSE_BUTTON_RIGHT:
#	var selected_paths = PackedStringArray(get_selected_paths())
#	$FilePopupMenu.pre_popup(selected_paths)
#	$FilePopupMenu.position = get_screen_transform() * mouse_position
#	$FilePopupMenu.popup()

enum {NEW_FOLDER, NEW_FILE, OPEN, OPEN_WITH, BOOKMARK, TRASH}
var icons: Dictionary = {NEW_FOLDER: "📁", NEW_FILE: "📄", OPEN: "🚀", \
	OPEN_WITH: "👯", BOOKMARK: "📘", TRASH: "🗑️"}

# Call whenever new file/colder created or deleted
signal files_changed
@onready var new_folder_confirmation = $NewFolderConfirmationDialog
@onready var trash_file_confirmation_dialog: ConfirmationDialog = $TrashFileConfirmationDialog
@onready var new_file_confirmation_dialog: ConfirmationDialog = $NewFileConfirmationDialog


var is_ready: bool = true
var files: PackedStringArray

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_setup()
	
	add_submenu_node_item("Open With",$FileOpenWithPopupMenu, OPEN_WITH)
	set_item_icon(get_item_index(OPEN_WITH), _texture_from_text("👯‍♀️"))
	set_item_index(get_item_index(OPEN_WITH),OPEN_WITH-1)
	
func _setup():
	# A popup calling a popup causes glitches. 
	# New popups must be same level and removed on tree_exit
	new_folder_confirmation.reparent.call_deferred(get_parent())
	trash_file_confirmation_dialog.reparent.call_deferred(get_parent())
	new_file_confirmation_dialog.reparent.call_deferred(get_parent())
	
	new_folder_confirmation.confirmed.connect(files_changed.emit)
	new_file_confirmation_dialog.confirmed.connect(files_changed.emit)
	trash_file_confirmation_dialog.confirmed.connect(files_changed.emit)
	
	# Set icons on menu
	for index in range(item_count):
		var icon = icons.get(get_item_id(index), "")
		if icon:
			set_item_icon(index, _texture_from_text(icon))

func _texture_from_text(text:String) -> ViewportTexture:
	var subview = get_node_or_null(text)
	if not subview :
		subview  = preload("res://FileBrowser/sub_viewport_single_label.tscn").instantiate()
		subview.set_text(text)
		subview.name = text
		add_child(subview)
	return subview.get_texture()
	

func _teardown():
	new_folder_confirmation.queue_free()
	trash_file_confirmation_dialog.queue_free()
	new_file_confirmation_dialog.queue_free()


# Must call to set paths for methods
func pre_popup(new_paths: PackedStringArray):
	files = new_paths
	# Disable actions when selection multiple files
	if(new_paths.size() == 1):
		for i in item_count:
			set_item_disabled(get_item_index(i), false)
		$FileOpenWithPopupMenu.setup(new_paths[0])
	else:
		set_item_disabled(get_item_index(OPEN_WITH), true)
		set_item_disabled(get_item_index(NEW_FOLDER), true)
		set_item_disabled(get_item_index(NEW_FILE), true)
	
	# Trashing is allowed as long as more than one thing is selected
	if new_paths.size() > 0:
		set_item_disabled(get_item_index(TRASH), false)


func _on_id_pressed(id: int) -> void:
	var base_folder_path = ""
	if files.size() > 0:
		base_folder_path = files[0]
		if FileAccess.file_exists(base_folder_path): # Pass folder, not file!
			base_folder_path = base_folder_path.get_base_dir()
	var mouse_target_position = Vector2i(get_screen_transform() * get_mouse_position()) if is_embedded() else DisplayServer.mouse_get_position()
	match id:
		TRASH:
			trash_file_confirmation_dialog.position = mouse_target_position
			trash_file_confirmation_dialog.ask_trash_files(files)
		NEW_FOLDER:
			new_folder_confirmation.set_target_parent_folder(base_folder_path)
			new_folder_confirmation.position = mouse_target_position
			new_folder_confirmation.popup()
		NEW_FILE:
			new_file_confirmation_dialog.set_target_parent_folder(base_folder_path)
			new_file_confirmation_dialog.position = mouse_target_position
			new_file_confirmation_dialog.popup()
			
			

func _on_tree_exiting() -> void:
	_teardown()

# Creates text on confirmation dialog about trashing files
func ask_trash_selected_items():
	if len(files) == 0:
		# TODO Make this a popup warning
		print("No items selected")
	elif len(files) < 5:
		var path_string = "\n".join(files)
		trash_file_confirmation_dialog.dialog_text = "Trash File:\n" + path_string
		trash_file_confirmation_dialog.popup_centered()
		trash_file_confirmation_dialog.position = DisplayServer.mouse_get_position()
	else:
		trash_file_confirmation_dialog.dialog_text = "Trash " + str(len(files)) + " files?"
		trash_file_confirmation_dialog.popup_centered()
		trash_file_confirmation_dialog.position = DisplayServer.mouse_get_position()

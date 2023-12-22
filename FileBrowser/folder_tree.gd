extends Tree
## Allows selection of folder from tree
## Each TreeItem is a folder
## Each TreeItem metadata is full path
## Each TreeItem text is folder name
##
## folder_selected emits with full path to folder

# TODO Add targeted folder path updating (update on new folder creation)

signal folder_selected(full_path:String)

# Returns folder path of tree item or "" if mouse is elsewhere
func folder_at_mouse() -> String:
	var item = $".".get_item_at_position(get_local_mouse_position())
	return String() if item == null else item.get_metadata(0)

func _input(event):
	if event is InputEventKey and Input.is_key_pressed(KEY_F1):
		var arr = get_expanded_folders()
		print(arr)
		refresh()

func _ready():
	refresh()
	# Handle dropped files
	get_window().files_dropped.connect(files_dropped)

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
			file_transfer.copy(files, target_folder)
		else:
			file_transfer.move(files, target_folder)

func refresh():
	$".".clear()
	# Add each drive
	var tree_root: TreeItem = $".".create_item()
	tree_root.set_text(0, "root")
	$".".hide_root = true
	var drive_count = DirAccess.get_drive_count()
	for drive_index in range(drive_count):
		var drive_name = DirAccess.get_drive_name(drive_index) + "/"
		var drive_tree: TreeItem = $".".create_item(tree_root)
		drive_tree.set_text(0, drive_name)  # Visible folder name
		drive_tree.set_metadata(0, drive_name)  # Full path
		drive_tree.collapsed = true  # Hide subfolders hidden
		_add_sub_folder(drive_tree)  # Add hidden subfolders

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
			# Check next folder
			file_name = dir.get_next()
	else:
		print("Folder Access Denied: " + path)


func _create_folder(base_tree_item, full_path: String):
	# Create folder TreeItem with saved path
	var new_tree_item: TreeItem = $".".create_item(base_tree_item)
	new_tree_item.set_text(0, full_path.get_file()) # On folders get_file() gets last folder name
	new_tree_item.set_metadata(0, full_path)
	new_tree_item.collapsed = true


func _on_item_selected():
	var full_path = $".".get_selected().get_metadata(0)
	emit_signal("folder_selected", full_path)

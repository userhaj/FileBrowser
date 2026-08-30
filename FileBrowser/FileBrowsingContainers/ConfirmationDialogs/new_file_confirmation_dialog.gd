extends ConfirmationDialog

var path_to_folder_parent: String = ""

func set_target_parent_folder(full_target_parent_folder_path: String):
	if full_target_parent_folder_path.is_absolute_path():
		path_to_folder_parent = full_target_parent_folder_path
		$VBoxContainer/Label.text = "Target Folder:\n" + path_to_folder_parent


func _on_confirmed() -> void:
	var full_path = path_to_folder_parent.path_join($VBoxContainer/NewFileLineEdit.text)
	if not FileAccess.file_exists(full_path):
		FileAccess.open(full_path, FileAccess.WRITE)


func _on_about_to_popup() -> void:
	if path_to_folder_parent == "":
		push_error("Called popup 'New File Confirmation Dialog' without target folder path")
		hide.call_deferred()


func _on_visibility_changed() -> void:
	if visible:
		$VBoxContainer/NewFileLineEdit.grab_focus()
	else:
		$VBoxContainer/NewFileLineEdit.clear.call_deferred()

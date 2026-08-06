extends ConfirmationDialog
class_name NewFolderConfirmationDialog

var path_to_folder_parent: String = ""

func set_target_parent_folder(full_target_parent_folder_path: String):
	if full_target_parent_folder_path.is_absolute_path():
		path_to_folder_parent = full_target_parent_folder_path
		$VBoxContainer/Label.text = "Target Folder:\n" + path_to_folder_parent
	
	
func _on_confirmed() -> void:
	var full_path = path_to_folder_parent.path_join($VBoxContainer/NewFolderLineEdit.text)
	DirAccess.make_dir_absolute(full_path)
	path_to_folder_parent = ""


func _on_about_to_popup() -> void:
	if path_to_folder_parent == "":
		push_error("Called popup 'New Folder Confirmation Dialog' without target folder path")
		hide.call_deferred()

func _on_visibility_changed() -> void:
	if visible:
		$VBoxContainer/NewFolderLineEdit.grab_focus()

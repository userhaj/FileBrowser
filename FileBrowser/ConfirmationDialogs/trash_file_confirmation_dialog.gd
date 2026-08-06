extends ConfirmationDialog

@onready var _files_to_trash := PackedStringArray()

func ask_trash_files(files_to_trash: PackedStringArray):
	_files_to_trash = files_to_trash
	if len(files_to_trash) == 0:
		push_error("TrashFileConfrimationDialog.ask_trash_files() called on empty file list")
	elif len(files_to_trash) < 5:
		var path_string = "\n".join(files_to_trash)
		dialog_text = "Trash File:\n" + path_string
		popup()
	else:
		dialog_text = "Trash " + str(len(files_to_trash)) + " files?"
		popup()

func _on_confirmed() -> void:
	for path in _files_to_trash:
		OS.move_to_trash(path)

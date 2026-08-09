extends ConfirmationDialog

var _files: PackedStringArray

func set_files_to_open(files_to_open: PackedStringArray):
	_files = files_to_open


func _on_about_to_popup() -> void:
	var plural = "s" if _files.size()>1 else ""
	dialog_text = "Confirm run file%s:\n" % plural + "\n".join(_files)


func _on_confirmed() -> void:
	for file in _files:
		OS.shell_open(file)

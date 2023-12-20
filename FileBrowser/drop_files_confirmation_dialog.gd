extends ConfirmationDialog

var _target_folder: String
var _dropped_files: PackedStringArray

func _ready():
	$".".add_button("Move Files", false, "MOVE")

func files_dropped(files: PackedStringArray, target_folder: String):
	self._target_folder = target_folder
	self._dropped_files = files
	$".".title = "Target folder: " + target_folder
	$".".dialog_text = ""
	for child in $".".get_children():
		child.queue_free()
	if len(files) < 5:
		$".".dialog_text = "\n".join(files)
	else:
		var vbox := VBoxContainer.new()
		var scroll := ScrollContainer.new()
		scroll.add_child(vbox)
		$".".add_child(scroll)
		for file in files:
			var label := Label.new()
			label.text = file
			vbox.add_child(label)
		scroll.custom_minimum_size = Vector2(0,vbox.get_child(0).get_line_height() *4)
	$".".popup()
	$".".position = get_mouse_position() + Vector2(get_window().position)


# Action on copied button
func _on_confirmed():
	for file: String in _dropped_files:
		var target_location = self._target_folder.path_join(file.get_file())
		if file.simplify_path() == target_location.simplify_path():
					continue
		var dir_access := DirAccess.open(_target_folder)
		dir_access.copy(file, target_location)

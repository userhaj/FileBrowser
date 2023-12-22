extends Window

func copy(files, target_folder):
	show()
	FileActions.copy(files, target_folder, update_percent, $FileActionErrorPopups.user_handle_error, $FileActionErrorPopups.get_choice)

func move(files, target_folder):
	# Can not move files to folder they are in, or a subfolder of self
	var from_folder = files[0].get_base_dir()
	if from_folder != target_folder and not(target_folder in files):
		FileActions.move(files, target_folder, update_percent, $FileActionErrorPopups.user_handle_error, $FileActionErrorPopups.get_choice)
	emit_signal("close_requested")

# Sets percentage label and closes window at 100%
func update_percent(percent: float):
	$PercentLabel.text = "%0.1f" % (percent * 100) + "%"
	if (percent * 100) >= 100:
		emit_signal("close_requested")

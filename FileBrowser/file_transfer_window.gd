extends Window

func copy(files, target_folder):
	FileActions.copy(files, target_folder, update_percent, $FileActionErrorPopups.user_handle_error, $FileActionErrorPopups.get_choice)

func move(files, target_folder):
	FileActions.move(files, target_folder, update_percent, $FileActionErrorPopups.user_handle_error, $FileActionErrorPopups.get_choice)

# Sets percentage label and closes window at 100%
func update_percent(percent: float):
	$PercentLabel.text = "%0.1f" % (percent * 100) + "%"
	if (percent * 100) >= 100:
		emit_signal("close_requested")

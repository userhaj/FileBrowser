extends Window

var _target_folder = ""
var _files = []
enum TransferType {Move, Copy}
var _transfer_type: TransferType

func get_user_confirmation():
	# REQUIRES _target_folder, _files, _transfer_type to be set first!
	
	var action_string = TransferType.find_key(_transfer_type)
	$ConfirmationDialog.title = "Confirm %s Files" % action_string
	$ConfirmationDialog.ok_button_text = action_string
	var dialog = "Confirm %s files:\n" % action_string
	
	# Create a list of all files to be transfered
	var all_file_names = ""
	for file in _files:
			all_file_names += file + "\n"
	
	# Add files if there is only a few
	if _files.size() < 5:
		dialog += all_file_names
	# Else tell user about files count and where the files are from
	else:
		dialog += str(_files.size())
		dialog += " files from: " + _files[0].get_base_dir()
	
	dialog += "\nTo:\n" + _target_folder

	$ConfirmationDialog.dialog_text = dialog
	$ConfirmationDialog.get_label().tooltip_text = all_file_names
	$ConfirmationDialog.get_ok_button().tooltip_text = all_file_names
	$ConfirmationDialog.get_window()
	$ConfirmationDialog.popup_centered()


func copy(files, target_folder):
	show() # Fixes secondary pop window transparent draw bug
	_files = files
	_target_folder = target_folder
	_transfer_type = TransferType.Copy
	get_user_confirmation()
	

func move(files, target_folder):
	show() # Fixes secondary pop window transparent draw bug
	_files = files
	_target_folder = target_folder
	_transfer_type = TransferType.Move
	get_user_confirmation()


# Sets percentage label and closes window at 100%
func update_percent(percent: float):
	$PercentLabel.text = "%0.1f" % (percent * 100) + "%"
	if (percent * 100) >= 100:
		emit_signal("close_requested")


func _on_confirmation_dialog_canceled() -> void:
	# User cancelled file transfer
	emit_signal("close_requested")


func _on_confirmation_dialog_confirmed() -> void:
	# Perform action on user confirmation
	if _transfer_type == TransferType.Move:
		# Can not move files to folder they are in, or are a subfolder of self
		var from_folder = _files[0].get_base_dir()
		if from_folder != _target_folder and not(_target_folder in _files):
			FileActions.move(_files, _target_folder, update_percent, $FileActionErrorPopups.user_handle_error, $FileActionErrorPopups.get_choice)
	else:
		FileActions.copy(_files, _target_folder, update_percent, $FileActionErrorPopups.user_handle_error, $FileActionErrorPopups.get_choice)

extends Control

var choice: FileActions.FileResponseRequest = FileActions.FileResponseRequest.CANCEL

func _ready():
	$DuplicateFileAcceptDialog.add_button("Rename", false, "RENAME")
	$DuplicateFileAcceptDialog.add_button("Overwrite", false, "OVERWRITE")

func user_handle_error(err: Error, file: String, semaphore: Semaphore = Semaphore.new()):
	match err:
		ERR_ALREADY_EXISTS:
			$DuplicateFileAcceptDialog.dialog_text = "File Already Exists: " + file
			$DuplicateFileAcceptDialog.popup_centered()
			await $DuplicateFileAcceptDialog.visibility_changed
			semaphore.post()
	
	return self.choice

func get_choice():
	return choice

func _on_duplicate_file_accept_dialog_custom_action(action):
	match action:
		"RENAME":
			self.choice = FileActions.FileResponseRequest.RENAME
		"OVERWRITE":
			self.choice = FileActions.FileResponseRequest.OVERWRITE
	
	$DuplicateFileAcceptDialog.hide()

extends Node
class_name FileActions

enum FileResponseRequest {CANCEL, RENAME, OVERWRITE, SKIP, RENAME_ALL, OVERWRITE_ALL, SKIP_ALL}

static func move(files: PackedStringArray, target_folder: String, percent_callback: Callable, error_ask_user: Callable, error_get_response: Callable):
	var thread := Thread.new()
	thread.start(FileActions._copy.bind(files, target_folder, percent_callback, error_ask_user, error_get_response, thread, true))

static func copy(files: PackedStringArray, target_folder: String, percent_callback: Callable, error_ask_user: Callable, error_get_response: Callable):
	var thread := Thread.new()
	thread.start(FileActions._copy.bind(files, target_folder, percent_callback, error_ask_user, error_get_response, thread))

static func _copy(files: PackedStringArray, target_folder: String, percent_callback: Callable, error_ask_user: Callable, error_get_response: Callable, thread: Thread, is_move: bool = false):
	# TODO handle errors
	var file_count = float(len(files))
	var files_complete = 0.0
	for file: String in files:
		# If from is same as to in "move", do nothing
		if file.get_base_dir().simplify_path() == target_folder.simplify_path():
			break
			
		var target_location = target_folder.path_join(file.get_file())
		
		# If file exists, overwrite it or rename current?
		if FileAccess.file_exists(target_location):
			var semaphore := Semaphore.new()
			error_ask_user.call_deferred(ERR_ALREADY_EXISTS, target_location, semaphore)
			semaphore.wait()
			var response: FileResponseRequest = error_get_response.call()
			
			match response:
				# If cancel, stop all files
				FileResponseRequest.CANCEL:
					break
				# Rename by appending #
				FileResponseRequest.RENAME:
					target_location = FileActions.nearest_available_name(target_location)
				# Move on to next file
				FileResponseRequest.SKIP:
					continue
				# Overwrite old file
				FileResponseRequest.OVERWRITE:
					pass

		var dir_access := DirAccess.open(target_folder)
		var err = dir_access.copy(file, target_location)
		if err == OK:
			if is_move:
				# TODO Items SHOULD be removed, but use trash until all bugs fixed
				#dir_access.remove(file)
				OS.move_to_trash(file)
		
		# Notify completion percent
		files_complete += 1.0
		percent_callback.call_deferred(files_complete / file_count)
	
	# Wrap up to 100%
	percent_callback.call_deferred(1.0)
	# Call cleanup code on thread
	FileActions._end_thread.call_deferred(thread)



# Provides numbered filename that is available
static func nearest_available_name(file_path: String):
	var new_name = file_path
	var count = 1
	while FileAccess.file_exists(new_name):
		new_name = file_path.get_basename() + str(count) + "." + file_path.get_extension()
		count += 1
	return new_name
	
# Call finish code on any thread USAGE: FileActions._end_thread.call_deferred(thread)
static func _end_thread(thread: Thread):
	thread.wait_to_finish()

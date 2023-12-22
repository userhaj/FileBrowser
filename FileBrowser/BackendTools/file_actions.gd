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
		# Is it a file or a directory?
		var is_file = FileAccess.file_exists(file)
		
		# Is the target folder and the base folder the same?
		var is_file_in_target = file.get_base_dir().simplify_path() == target_folder.simplify_path()
		if is_file_in_target:
			# If from is same as to in "move", do nothing
			if is_move:
				break
		
		var target_location = target_folder.path_join(file.get_file())
		
		# If file exists, overwrite it or rename current?
		if FileAccess.file_exists(target_location) or DirAccess.dir_exists_absolute(target_location):
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
					# Rename target on request
					if is_file:
						target_location = FileActions.nearest_available_name(target_location)
					else:
						target_location = FileActions.nearest_available_dir_name(target_location)
				# Move on to next file
				FileResponseRequest.SKIP:
					continue
				# Overwrite old file
				FileResponseRequest.OVERWRITE:
					pass
		# Recursively copy all folders
		if not is_file:
			# Copy Internal Files
			var all_dirs = all_sub_directories_at(file)
			var target_dirs = all_dirs.duplicate()
			replace_array(file, target_location, target_dirs)
			for index in range(len(all_dirs)):
				copy_files(all_dirs[index], target_dirs[index])
			
		
		if is_file:
			var dir_access := DirAccess.open(target_folder)
			var err = dir_access.copy(file, target_location)
			if err == OK:
				if is_move:
					# TODO Items SHOULD be removed, but use trash until all bugs fixed
					#dir_access.remove(file)
					OS.move_to_trash(file)
		else:
			var err_array: Array = copy_files(file, target_location)
			var error_sum = err_array.reduce(func(accum, number): return accum + number)
			if error_sum == 0:
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
	# TODO Handle non-extension files
	var new_name = file_path
	var count = 1
	while FileAccess.file_exists(new_name):
		new_name = file_path.get_basename() + str(count) + "." + file_path.get_extension()
		count += 1
	return new_name

# Provides numbered filename that is available
static func nearest_available_dir_name(dir_path: String):
	#TODO Handle / or \ at end of dir_path
	var new_name = dir_path
	var count = 1
	while DirAccess.dir_exists_absolute(new_name):
		new_name = dir_path + str(count)
		count += 1
	return new_name

# Call finish code on any thread USAGE: FileActions._end_thread.call_deferred(thread)
static func _end_thread(thread: Thread):
	thread.wait_to_finish()

# Recursively get all directories in folder
static func all_sub_directories_at(path: String) -> Array[String]:
	var array: Array[String] = []
	_all_sub_directories_at(path, array)
	return array

# Recursively get all directories in folder, appends to given array
static func _all_sub_directories_at(path: String, array: Array):
	for dir in DirAccess.get_directories_at(path):
		array.append(path.path_join(dir))
		_all_sub_directories_at(path.path_join(dir), array)

# Recursively get all directories in folder, appends to given array
static func all_sub_files_at(path: String) -> Array[String]:
	var array: Array[String] = []
	_all_sub_files_at(path, array)
	return array

# Recursively get all directories in folder, appends to given array
static func _all_sub_files_at(path: String, array: Array):
	for dir in DirAccess.get_files_at(path):
		array.append(path.path_join(dir))
		_all_sub_files_at(path.path_join(dir), array)

# Replaces all occurrences of what inside the string with the given forwhat, for every item in array
static func replace_array(what: String, forwhat: String, array: Array[String]):
	for index in range(len(array)):
		array[index] = array[index].replace(what, forwhat)

# Shallow copy just files from one folder to target
static func copy_files(originating_dir: String, target_dir: String)-> Array[Error]:
	if not DirAccess.dir_exists_absolute(target_dir):
		DirAccess.make_dir_recursive_absolute(target_dir)
	var errors: Array[Error] = []
	var dir_access := DirAccess.open(originating_dir)
	for file in dir_access.get_files():
		var err = dir_access.copy(originating_dir.path_join(file), target_dir.path_join(file))
		errors.append(err)
	return errors

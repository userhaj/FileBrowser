extends Node
class_name FolderPoller

signal folder_changed(folder_path: String)

var target_folders = {}


var _poll_speed: float = 3
# Seconds between poll
@export var poll_speed: float = _poll_speed:
	get:
		return _poll_speed
	set(value):
		_poll_speed = value
		if not is_node_ready():
			await ready
		_poll_timer.wait_time = value

var _stored_data: Dictionary = {}
@onready var _poll_timer: Timer = Timer.new()

func _ready() -> void:
	add_child(_poll_timer)
	poll_speed = poll_speed
	_poll_timer.start()
	_poll_timer.timeout.connect(_poll)

# Poll a single folder, clear all previous from polling
func only_poll_folder(folder_path: String):
	add_folder_to_poll(folder_path, true)

func add_folder_to_poll(folder_path: String, clear_previous: bool=false):
	if clear_previous:
		clear()
	var full_path = folder_path.simplify_path()
	target_folders.set(full_path, 0)
	_stored_data.set(full_path, {})
	var files_and_folders = Array(DirAccess.get_files_at(full_path)).map(func(element): return full_path.path_join(element))
	files_and_folders.append_array(Array(DirAccess.get_directories_at(full_path)).map(func(element): return full_path.path_join(element)))
	for file_path in files_and_folders:
		var modified = FileAccess.get_modified_time(file_path)
		_stored_data[full_path].set(file_path, modified)


# Remove all folders from polling
func clear():
	target_folders.clear()
	_stored_data.clear()


# Remove folder from polling (Filesystem not touched)
func erase(folder: String):
	target_folders.erase(folder)
	_stored_data.erase(folder)

func _poll():
	# Check every asked for folder
	for folder: String in target_folders:
		var polled_files: = Array(DirAccess.get_files_at(folder)).map(func(element): return folder.path_join(element))
		var polled_dirs: = Array(DirAccess.get_directories_at(folder)).map(func(element): return folder.path_join(element))
		var file_and_dir_count = polled_files.size() + polled_dirs.size()
		# Get structure last seen
		var seen_held_files: Dictionary = _stored_data.get(folder, {})
		
		# All polled files have been seen
		if not seen_held_files.has_all(polled_files) or \
		# All polled folders have been seen
		not seen_held_files.has_all(polled_dirs) or \
		# There is no new files to see
		seen_held_files.keys().size() != file_and_dir_count:
			_folder_change_detected(folder)
			return
		
		# Modified time has not changed on any seen file paths
		for seen_path in seen_held_files.keys():
			var modified = FileAccess.get_modified_time(seen_path)
			var stored_modified = _stored_data[folder].get(seen_path, "")
			if stored_modified != modified:
				_folder_change_detected(folder)
				return


# Emits signal and resets path contents to avoid re-trigger on next poll
func _folder_change_detected(folder_path: String):
	# Erase and re-add folder to reset stored seen contents
	erase(folder_path)
	add_folder_to_poll(folder_path)
	# Notify of detection
	folder_changed.emit(folder_path)
			

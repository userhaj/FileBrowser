extends PopupMenu

enum AppProperties {PATH, NAME, MIME_TYPES}
var mimes: Dictionary = {}
var LINUX_SHARE_FOLDERS = []
var APP_CACHE_FILEPATH = "user://appcache"

func _ready() -> void:
	# Only find default apps once, then used saved defaults
	var last_edit = FileAccess.get_modified_time(APP_CACHE_FILEPATH)
	var current_time = Time.get_unix_time_from_system()
	# true if more than 24 hours have passed
	var is_app_cache_old= (current_time - last_edit) > (24*60*60)
	
	# Update old mimes
	if is_app_cache_old:
		if "nux" in OS.get_name():
			var thread = Thread.new()
			thread.start(linux_find_mimes)
	else: # Use saved default files
		_load_app_cache()

func get_mime_type(absolute_file_path: String)->String:
	if "nux" in OS.get_name():
		return linux_file_mime_type_get(absolute_file_path)
	
	return absolute_file_path.get_extension()

# Save mimes dictionary to file
func _save_app_cache():
		var app_cache = FileAccess.open(APP_CACHE_FILEPATH, FileAccess.WRITE)
		app_cache.store_line(JSON.stringify(mimes))
		app_cache.close()
		
		
# Load mimes dictionary from file
func _load_app_cache() -> bool:
		var app_cache = FileAccess.open(APP_CACHE_FILEPATH, FileAccess.READ)
		var json = JSON.new()
		var json_string = app_cache.get_line()
		var parsed = json.parse(json_string)
		if not parsed == OK:
			app_cache.close()
			return false
			
		if typeof(json.data) == TYPE_DICTIONARY:
			mimes = json.data
			app_cache.close()
			return true
			
		app_cache.close()
		return false
	

# Add all possible running programs for file and file path to popup
func setup(absolute_file_path: String):
	clear(true)
	# File to be opened
	add_item(absolute_file_path)
	set_item_as_separator(0, true)
	var mime_type
	# Linux menu open with
	if "nux" in OS.get_name():
		mime_type = linux_file_mime_type_get(absolute_file_path)
	elif "Windows" in OS.get_name():
		var id = hash("Windows")
		add_item("Show Open With Options", id)
		var windows_path = PackedStringArray([absolute_file_path.replace("/", "\\")])
		var open_with_call = OS.open_with_program.bind("openwith.exe", windows_path)
		set_item_metadata(get_item_index(id), open_with_call)
		
	for app in mimes.get(mime_type, ""):
		add_open_with_menu_item(app, absolute_file_path)
	# Treat everything as possible to open with plain text editor
	if mime_type != "text/plain":
		add_separator()
		for app in mimes.get("text/plain", ""):
			add_open_with_menu_item(app, absolute_file_path)


# Add a nice named callable that runs file_to_open to self popup menu
func add_open_with_menu_item(app: Dictionary, file_to_open: String):
	var nice_name = app.get(str(AppProperties.NAME))
	add_item(nice_name)
	var index = item_count-1
	var run_app_callable: Callable 
	if "nux" in OS.get_name(): # Set linux version
		run_app_callable = linux_run_desktop_file.bind(app.get(str(AppProperties.PATH)), file_to_open)
	set_item_metadata(index, run_app_callable)


# Run open_file using a given .desktop file
func linux_run_desktop_file(desktop_file: String, open_file: String):
	var _pid = OS.create_process("gio", PackedStringArray(["launch", desktop_file, open_file]), true)


# Gets system mimetype for given file
func linux_file_mime_type_get(file_path: String) -> String:
	var output = []
	OS.execute("xdg-mime", ["query", "filetype", file_path], output)
	if output.size() > 0:
		return output[0].replace("\n", "").replace("\t", "").replace("\r", "")
	else:
		return ""


# Gets simple name found in *.desktop file
func linux_app_name_from_desktop_file(desktop_file_name: String) -> String:
	var output = []
	OS.execute("sed", ["-n", "s/^Name=//p", desktop_file_name], output)
	if output.size() > 0:
		output = output[0].split("\n")[0]
	return output


# Reads *.desktop file and provides mimetypes written in file
func linux_mime_types_from_desktop_file(desktop_file_path: String) -> PackedStringArray:
	var output = []
	OS.execute("sed", ["-n", "s/^MimeType=//p", desktop_file_path], output)
	if output.size() > 0:
		output = output[0].replace("\n", "").replace("\t", "").replace("\r", "").split(";")
	return output


# Fills mimes dictionary
func linux_find_mimes():
	var app_folders = get_linux_app_folder()
	for folder in app_folders:
		for full_app_path in linux_apps_in_directory_recursive(folder):
				var app_name = linux_app_name_from_desktop_file(full_app_path)
				var new_mimes = linux_mime_types_from_desktop_file(full_app_path)
				for mime: String in new_mimes:
					if mime.length() > 0:
						var app_dict = {str(AppProperties.PATH): full_app_path,
										str(AppProperties.NAME): app_name}
						if self.mimes.has(mime):
							self.mimes[mime].append(app_dict)
						else:
							self.mimes.set(mime, [app_dict])
	_save_app_cache.call_deferred()

func linux_apps_in_directory_recursive(directory: String):
	var folders = []
	OS.execute("find", [directory, "-type", "f", "-name", "*.desktop"], folders)
	if folders.size() > 0:
		folders = str(folders[0]).split("\n")
	return folders

func get_linux_app_folder():
	# Follow specifications here:https://specifications.freedesktop.org/basedir/latest/
	var folders = []
	OS.execute("echo", ["$XDG_DATA_DIRS"], folders)
	if folders.size() > 0:
		folders = str(folders[0]).replace("\n", "").split(":")
	return folders

func _on_index_pressed(index: int) -> void:
	var item_callable: Callable = get_item_metadata(index)
	item_callable.call()

extends PopupMenu

enum AppProperties {PATH, NAME, MIME_TYPES}
var mimes: Dictionary = {}
var LINUX_SHARE_FOLDERS = []

func _ready() -> void:
	if "nux" in OS.get_name():
		var thread = Thread.new()
		thread.start(linux_find_mimes)

func popup_absolute_filepath(absolute_file_path: String):
	clear(true)
	var index = 0
	# File to be opened
	add_item(absolute_file_path)
	set_item_as_separator(0, true)
	
	# Place Menu
	popup()
	position = DisplayServer.mouse_get_position()
	
	# Linux menu open with
	if "nux" in OS.get_name():
		var mime_type = linux_file_mime_type_get(absolute_file_path)
		for app in mimes.get(mime_type, ""):
			index += 1
			add_open_with_menu_item(index, app, absolute_file_path)
		# Treat everything as possible to open with plain text editor
		if mime_type != "text/plain":
			for app in mimes.get("text/plain", ""):
				index += 1
				add_open_with_menu_item(index, app, absolute_file_path)
	else:
		clear(true)
		hide()

func add_open_with_menu_item(index, app, file_to_open):
	var nice_name = app.get(AppProperties.NAME)
	add_item(nice_name)
	var run_app_callable = linux_run_desktop_file.bind(app.get(AppProperties.PATH), file_to_open)
	set_item_metadata(index, run_app_callable)

func linux_run_desktop_file(desktop_file, open_file):
	print(desktop_file)
	print(open_file)
	var pid = OS.create_process("gio", PackedStringArray(["launch", desktop_file, open_file]), true)
	print(pid)

func linux_file_mime_type_get(file_path: String):
	var output = []
	OS.execute("xdg-mime", ["query", "filetype", file_path], output)
	if output.size() > 0:
		return output[0].replace("\n", "").replace("\t", "").replace("\r", "")
	else:
		return ""

func linux_app_name_from_desktop_file(desktop_file_name: String):
	var output = []
	OS.execute("sed", ["-n", "s/^Name=//p", desktop_file_name], output)
	if output.size() > 0:
		output = output[0].split("\n")[0]
	return output

func linux_mime_types_from_desktop_file(desktop_file_path: String):
	var output = []
	OS.execute("sed", ["-n", "s/^MimeType=//p", desktop_file_path], output)
	if output.size() > 0:
		output = output[0].replace("\n", "").replace("\t", "").replace("\r", "").split(";")
	return output

func linux_find_mimes():
	var app_folders = get_linux_app_folder()
	for folder in app_folders:
		for full_app_path in linux_apps_in_directory_recursive(folder):
				var app_name = linux_app_name_from_desktop_file(full_app_path)
				var new_mimes = linux_mime_types_from_desktop_file(full_app_path)
				for mime: String in new_mimes:
					if mime.length() > 0:
						var app_dict = {AppProperties.PATH: full_app_path,
										AppProperties.NAME: app_name}
						if self.mimes.has(mime):
							self.mimes[mime].append(app_dict)
						else:
							self.mimes.set(mime, [app_dict])

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

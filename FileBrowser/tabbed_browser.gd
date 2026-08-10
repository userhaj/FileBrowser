extends TabContainer

signal folder_changed(path: String)

enum menu{NEW_TAB, SET_VIEW}

func _init() -> void:
	# Add OS base dir as default tab
	var default_browser = preload("res://FileBrowser/file_tree.tscn").instantiate()
	new_tab(DirAccess.get_drive_name(0), default_browser)

	var pop = PopupMenu.new()
	pop.add_item("New Tab")
	pop.add_item("Change View")
	pop.index_pressed.connect(_menu_handle)
	add_child(pop)
	set_popup(pop)
	
	get_tab_bar().tab_close_pressed.connect(_handle_close_tab)

func _handle_close_tab(tab: int):
	if get_tab_count() > 1:
		get_tab_control(tab).queue_free()

func _menu_handle(index: int):
	match index:
		menu.NEW_TAB:
			var default_browser = preload("res://FileBrowser/file_tree.tscn").instantiate()
			new_tab(DirAccess.get_drive_name(0), default_browser)
		menu.SET_VIEW:
			swap_view()

func swap_view():
	var old_control = get_current_tab_control()
	var old_index = get_tab_idx_from_control(old_control)
	old_index = old_index if old_index < get_tab_count() else get_tab_count() -1
	var new_control
	if old_control is FileTree:
		new_control = preload("res://FileBrowser/folder_icon_view.tscn").instantiate()
	else:
		new_control = preload("res://FileBrowser/file_tree.tscn").instantiate()
	new_tab(old_control.get_directory(), new_control)
	old_control.queue_free()
	move_child(new_control, old_index)
	current_tab = old_index
	

func new_tab(path: String, control):
	add_child(control)
	var index = get_tab_idx_from_control(control)
	index = index if index < get_tab_count() else get_tab_count() - 1
	set_tab_title(index, path.get_file())
	control.folder_changed.connect(_set_folder_as_tab_title, CONNECT_APPEND_SOURCE_OBJECT)
	control.set_directory(path)
	control.folder_changed.connect(folder_changed.emit)
	current_tab = index


func _set_folder_as_tab_title(path: String, control: Control):
	var index = get_tab_idx_from_control(control)
	index = index if index < get_tab_count() else get_tab_count() - 1
	var folder = path.get_file() if path.get_file() else "/"
	set_tab_title(index, folder)
	set_tab_tooltip(index, path)

# Pass set_directory call on to current tab
func set_directory(path: String):
	var tab = get_current_tab_control()
	if tab.has_method("set_directory"):
		tab.set_directory(path)


func get_directory() -> String:
	var tab = get_current_tab_control()
	if tab.has_method("get_directory"):
		return tab.get_directory()
	return ""


func _on_tab_changed(tab: int) -> void:
	var control = get_tab_control(tab)
	if control.has_method("get_directory"):
		folder_changed.emit(control.get_directory())

func refresh():
	var control = get_current_tab_control()
	if control and control.has_method("refresh"):
		control.refresh()

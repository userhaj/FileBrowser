extends TabContainer
class_name FileTabContainer

signal folder_changed(path: String)
# Provides tab control on creation
signal new_tab_created(control: Control)

enum menu{NEW_TAB, SET_VIEW}

const FILE_TREE = preload("uid://byylub0x8vqh0")
const FOLDER_ICON_VIEW = preload("uid://c3celv4vu6p5t")
var _default_file_browsing_container = FILE_TREE


# Menus added to each new tab, each array is called on add_menu_command()
var _menu_commands: Array[Array] = [
	# Allow inner browser to open new tab through FilePopupMenu
	["Open In New Tab", "📂", _create_new_tabs, FilePopupMenu.FILETYPE_FLAG.SINGLE_FOLDER | FilePopupMenu.FILETYPE_FLAG.MULITPLE_FOLDER | FilePopupMenu.FILETYPE_FLAG.MIXED_FILES_FOLDERS]
]

func _init() -> void:
	var pop = PopupMenu.new()
	pop.add_item("New Tab")
	pop.add_item("Change View")
	pop.index_pressed.connect(_menu_handle)
	add_child(pop)
	set_popup(pop)
	
	get_tab_bar().tab_close_pressed.connect(_handle_close_tab)

func _ready() -> void:
	# Add OS base dir as default tab
	if get_tab_count() < 1:
		new_tab(DirAccess.get_drive_name(0), _default_file_browsing_container.instantiate())

func _handle_close_tab(tab: int):
	if get_tab_count() > 1:
		var closing_tab = get_tab_control(tab)
		closing_tab.queue_free()

func _menu_handle(index: int):
	match index:
		menu.NEW_TAB:
			_create_new_tab()
		menu.SET_VIEW:
			swap_view()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		if _mouse_at_empty_tab_bar():
			_create_new_tab()

func _unhandled_input(event: InputEvent) -> void:
		# Close current tab
	if event is InputEventKey and Input.is_key_pressed(KEY_W) and \
	not event.is_echo() and event.ctrl_pressed:
		get_tab_bar().tab_close_pressed.emit(current_tab)
				
func _create_new_tab(path: String=""):
	path = path if path else get_directory()
	new_tab(path, _default_file_browsing_container.instantiate())

func _create_new_tabs(paths: Array[String]):
	for path in paths:
		if DirAccess.dir_exists_absolute(path):
			_create_new_tab(path)


func _mouse_at_empty_tab_bar() -> bool:
	var tab_bar = get_tab_bar()
	var tab_bar_rect = tab_bar.get_rect()
	var mouse_pos = tab_bar.get_local_mouse_position()
	if tab_bar_rect.has_point(mouse_pos):
		var hit_tab = false
		for tab_idx in tab_bar.tab_count:
			var tab_rect = tab_bar.get_tab_rect(tab_idx)
			if tab_rect.has_point(mouse_pos):
				hit_tab = true
				break
		if not hit_tab:
			return true
	return false

func swap_view():
	var old_control = get_current_tab_control()
	var old_index = get_tab_idx_from_control(old_control)
	var new_control
	if old_control is FileTree:
		new_control = FOLDER_ICON_VIEW.instantiate()
	else:
		new_control = FILE_TREE.instantiate()
	
	new_tab(old_control.get_directory(), new_control)
	old_control.free()
	move_child.call_deferred(new_control, old_index+2)
	set_deferred("current_tab", old_index)
	

func new_tab(path: String, control):
	add_child(control)
	var index = get_tab_idx_from_control(control)
	index = index if index < get_tab_count() else get_tab_count() - 1
	set_tab_title(index, path.get_file())
	control.folder_changed.connect(_set_folder_as_tab_title, CONNECT_APPEND_SOURCE_OBJECT)
	control.set_directory(path)
	control.folder_changed.connect(folder_changed.emit)
	current_tab = index
	# Add custom tabbed behavior
	for menu_commmand in _menu_commands:
		control.add_menu_command.bindv(menu_commmand).call()
	
	# Notify of new tab
	new_tab_created.emit(control)


func _set_folder_as_tab_title(path: String, control: Control):
	var index = get_tab_idx_from_control(control)
	index = index if index < get_tab_count() else get_tab_count() - 1
	var folder = path.get_file() if path.get_file() else "/"
	set_tab_title(index, folder)
	set_tab_tooltip(index, path)

# Pass set_directory call on to current tab
func set_directory(path: String):
	var tab = get_current_tab_control()
	if tab and tab.has_method("set_directory"):
		tab.set_directory(path)
	else:
		new_tab(path, _default_file_browsing_container.instantiate())


func get_directory() -> String:
	var tab = get_current_tab_control()
	if tab and tab.has_method("get_directory"):
		return tab.get_directory()
	return ""


func _on_tab_changed(tab: int) -> void:
	var control = get_tab_control(tab)
	if control and control.has_method("get_directory"):
		folder_changed.emit(control.get_directory())

func refresh():
	var control = get_current_tab_control()
	if control and control.has_method("refresh"):
		control.refresh()

func add_menu_command(menu_text: String, emoji_icon: String, action: Callable, menu_for_filetype:FilePopupMenu.FILETYPE_FLAG):
	# Add command for future opened tabs
	_menu_commands.append([menu_text, emoji_icon, action, menu_for_filetype])
	# Add command to open tabs
	for tab in get_tab_count():
		get_tab_control(tab).add_menu_command(menu_text, emoji_icon, action, menu_for_filetype)


func get_popup_menus() -> Array[PopupMenu]:
	return get_current_tab_control().get_popup_menus()

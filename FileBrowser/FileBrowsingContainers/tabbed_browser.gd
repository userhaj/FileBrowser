extends TabContainer
class_name FileTabContainer

signal folder_changed(path: String)
# Provides tab control on creation
signal new_tab_created(control: Control)

const FILE_TREE = preload("uid://byylub0x8vqh0")
const FOLDER_ICON_VIEW = preload("uid://c3celv4vu6p5t")
var _default_file_browsing_container = FILE_TREE
const SUB_VIEWPORT_SINGLE_LABEL = preload("uid://cnrjg1q6m5y36")

var directory: String:
	get = get_directory, set = set_directory

var tab_pop_up: PopupMenu
enum TABPOPUP{NEW_TAB, CHANGE_VIEW, CLOSE_TAB}
var tab_popup_icons = {TABPOPUP.NEW_TAB: "📂", TABPOPUP.CHANGE_VIEW: "👀", TABPOPUP.CLOSE_TAB: "❌"}
var _id_callables = {}


# Menus added to each new tab, each array is called on add_menu_command()
var menu_commands: Array[Array] = [
	# Allow inner browser to open new tab through FilePopupMenu
	["Open In New Tab", "📂", _create_new_tabs, FilePopupMenu.FILETYPE_FLAG.SINGLE_FOLDER | FilePopupMenu.FILETYPE_FLAG.MULITPLE_FOLDER | FilePopupMenu.FILETYPE_FLAG.MIXED_FILES_FOLDERS],
	["Change View", "👀", swap_view.unbind(1), FilePopupMenu.FILETYPE_FLAG.ALL]
]

func _init() -> void:
	tab_pop_up = PopupMenu.new()
	for key in TABPOPUP.keys():
		tab_pop_up.add_icon_item(SubViewPortSingleLabel.texture_from_text(tab_popup_icons[TABPOPUP[key]], self),key.capitalize())
	tab_pop_up.index_pressed.connect(_menu_handle)
	add_child(tab_pop_up)
	set_popup(tab_pop_up)
	
	get_tab_bar().tab_close_pressed.connect(_handle_close_tab)
	get_tab_bar().gui_input.connect(_tab_bar_gui_input)

func _ready() -> void:
	# Add OS base dir as default tab
	if get_tab_count() < 1:
		new_tab("", _default_file_browsing_container.instantiate())

func _handle_close_tab(tab: int):
	if get_tab_count() > 1:
		var closing_tab = get_tab_control(tab)
		closing_tab.queue_free()

func _menu_handle(index: int):
	var tab_index = tab_pop_up.get_meta("Tab")
	match index:
		TABPOPUP.NEW_TAB:
			_create_new_tab()
		TABPOPUP.CHANGE_VIEW:
			swap_view(tab_index)
		TABPOPUP.CLOSE_TAB:
			if tab_index < 0:
				_handle_close_tab(get_tab_count()-1)
			else:
				_handle_close_tab(tab_index)
	
	var id = tab_pop_up.get_item_id(index)
	if _id_callables.has(id):
		if tab_index < 0:
			tab_index = get_tab_count()-1
		var file_browsing_control = get_tab_control(tab_index)
		if file_browsing_control and file_browsing_control.has_method("get_directory"):
			_id_callables[id].bind(PackedStringArray([file_browsing_control.get_directory()])).call()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		if _mouse_at_empty_tab_bar():
			_create_new_tab()

func _tab_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		var mouse_pos = get_tab_bar().get_local_mouse_position()
		tab_pop_up.set_meta("Tab", -1)
		for index in get_tab_count():
			if get_tab_bar().get_tab_rect(index).has_point(mouse_pos):
				tab_pop_up.set_meta("Tab", index)
				break
		tab_pop_up.position=get_tab_bar().get_screen_transform() * mouse_pos
		tab_pop_up.popup()
				

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

func swap_view(tab_index=-1):
	var old_control = get_current_tab_control() if tab_index < 0 else get_tab_control(tab_index)
	var new_control
	if old_control is FileTree:
		new_control = FOLDER_ICON_VIEW.instantiate()
	else:
		new_control = FILE_TREE.instantiate()
	
	new_tab(old_control.get_directory(), new_control, old_control)
	
	
func new_tab(path: String, control: Control, old_control=null):
	# Add new control at place of old control (or just add new)
	if not old_control:
		add_child(control)
	else:
		old_control.add_sibling(control)
		old_control.queue_free()
	var index = get_tab_idx_from_control(control)
	index = index if index < get_tab_count() else get_tab_count() - 1
	set_tab_title(index, path.get_file())
	control.folder_changed.connect(_set_folder_as_tab_title, CONNECT_APPEND_SOURCE_OBJECT)
	if path:
		control.set_directory(path)
	control.folder_changed.connect(folder_changed.emit)
	current_tab = index
	# Add custom tabbed behavior
	for menu_commmand in menu_commands:
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
	menu_commands.append([menu_text, emoji_icon, action, menu_for_filetype])
	# Add command to open tabs
	for tab in get_tab_count():
		get_tab_control(tab).add_menu_command(menu_text, emoji_icon, action, menu_for_filetype)
	
	if menu_for_filetype | FilePopupMenu.FILETYPE_FLAG.SINGLE_FOLDER:
		var id = ResourceUID.create_id() & 0xFFFFFF  # Guarantee 24bits id
		_id_callables.set(id, action)
		tab_pop_up.add_icon_item(SubViewPortSingleLabel.texture_from_text(emoji_icon, self), menu_text, id)


func get_popup_menus() -> Array:
	var popup_menus = get_current_tab_control().get_popup_menus()
	if popup_menus:
		popup_menus.append(tab_pop_up)
		return popup_menus
	return [tab_pop_up]

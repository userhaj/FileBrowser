extends ItemList
class_name BookmarkItemList

signal folder_selected(full_path:String)

const SAVE_FILE: String = "user://Settings"
var last_item_clicked: int = -1
@onready var popup_menu: PopupMenu = $PopupMenu
var _id_callables = {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Load saved bookmarks
	var config = ConfigFile.new()
	var err = config.load(SAVE_FILE)
	if err == OK:
		if config.has_section("bookmark"):
			var all_bookmarks = config.get_section_keys("bookmark")
			for path in all_bookmarks:
				add_folder(path)
	popup_menu.add_icon_item(SubViewPortSingleLabel.texture_from_text("❌", self), "Unbookmark", 0)
			

func _get_drag_data(at_position: Vector2) -> Variant:
	return get_item_at_position(at_position)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_INT or typeof(data) == TYPE_PACKED_STRING_ARRAY

func _drop_data(at_position: Vector2, data: Variant) -> void:
	match typeof(data): 
		TYPE_INT:
			move_item(data, get_item_at_position(at_position))
		TYPE_PACKED_STRING_ARRAY:
			for path: String in data:
				if DirAccess.dir_exists_absolute(path):
					add_folder(path)

	# Re-write save file with new order
	_save_all_bookmarks()

func _save_all_bookmarks():
	var config = ConfigFile.new()
	var err = config.load(SAVE_FILE)
	if err == OK:
		for idx in range(item_count):
			config.set_value("bookmark", get_item_tooltip(idx), idx)
	config.save(SAVE_FILE)

func _save_path_to_settings(full_path: String, index: int):
	var config = ConfigFile.new()
	var err = config.load(SAVE_FILE)
	if err == OK:
		config.set_value("bookmark", full_path, index)
	config.save(SAVE_FILE)


func _remove_path_from_settings(full_path: String):
	var config = ConfigFile.new()
	var err = config.load(SAVE_FILE)
	if err == OK:
		config.erase_section_key("bookmark", full_path)
	config.save(SAVE_FILE)

func add_folder(path:String):
	var folder_name = path.get_basename().get_file()
	# Short name added as visible item
	add_item(folder_name)
	# Full path saved as tooltip
	set_item_tooltip(item_count-1, path)
	
	_save_path_to_settings(path, item_count-1)

func _on_item_clicked(_index: int, at_position: Vector2, mouse_button_index: int) -> void:
	last_item_clicked = get_item_at_position(at_position)
	# On right click offer bookmark removal
	if mouse_button_index == 2:
		$PopupMenu.popup()
		$PopupMenu.position = DisplayServer.mouse_get_position()
		

func _on_popup_menu_index_pressed(index: int) -> void:
	# User chose "unbookmark"
	if index == 0:
		# # Multi line bookmark removal
		#for bookmark_index in get_selected_items():
			#_remove_path_from_settings(get_item_tooltip(bookmark_index))
			#remove_item(bookmark_index)
		_remove_path_from_settings(get_item_tooltip(last_item_clicked))
		remove_item(last_item_clicked)

func _on_item_selected(index: int) -> void:
	folder_selected.emit(get_item_tooltip(index))
	
func add_menu_command(menu_text: String, emoji_icon: String, action: Callable, menu_for_filetype:FilePopupMenu.FILETYPE_FLAG):
	var id = ResourceUID.create_id() & 0xFFFFFF  # Guarantee 24bits id
	_id_callables.set(id, action)
	popup_menu.add_icon_item(SubViewPortSingleLabel.texture_from_text(emoji_icon, self), menu_text, id)


func _on_popup_menu_id_pressed(id: int) -> void:
	if _id_callables.has(id):
		_id_callables.get(id).bind(PackedStringArray([get_item_tooltip(last_item_clicked)])).call()

func get_popup_menus() -> Array:
	return [popup_menu]

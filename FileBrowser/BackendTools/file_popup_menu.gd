extends PopupMenu

enum {NEW_FOLDER, NEW_FILE, OPEN, OPEN_WITH, BOOKMARK, TRASH}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_submenu_node_item("Open With",$FileOpenWithPopupMenu, OPEN_WITH)
	set_item_icon(get_item_index(OPEN_WITH), $SubViewportPeopleBunny.get_texture())
	set_item_index(get_item_index(OPEN_WITH),OPEN_WITH-1)
	

# Must call to set paths for methods
func pre_popup(new_paths: PackedStringArray = PackedStringArray()):
	# Disable Open With if more than one item selected
	if(new_paths.size() == 1):
		set_item_disabled(get_item_index(OPEN_WITH), false)
		$FileOpenWithPopupMenu.setup(new_paths[0])
	else:
		set_item_disabled(get_item_index(OPEN_WITH), true)

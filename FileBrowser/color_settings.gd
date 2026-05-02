extends Control

const SAVE_FILEPATH = "user://GDFileBrowserColors.cfg"

const THEME_DEFAULT = {
	"Icon View Background": {
		"name": "panel", 
		"theme_type": "ScrollContainer", 
		"theme_path": "res://FileBrowser/Themes/folder_icon_view_theme.tres",
		"default": Color(0.198, 0.198, 0.198, 1.0)
		},
	"Folder Tree Background": {
		"name": "panel", 
		"theme_type": "Tree", 
		"theme_path": "res://FileBrowser/Themes/folder_tree_theme.tres",
		"default": Color(0.212, 0.212, 0.212, 1.0)
		},
	"Adjustable Divider Background": {
		"name": "split_bar_background", 
		"theme_type": "HSplitContainer", 
		"theme_path": "res://FileBrowser/Themes/base_theme.tres",
		"default": Color(0.212, 0.212, 0.212, 1.0)
		},
	"Base App Background": {
		"name": "panel", 
		"theme_type": "PanelContainer", 
		"theme_path": "res://FileBrowser/Themes/base_theme.tres",
		"default": Color(0.339, 0.339, 0.339, 1.0)
		}
		}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_colors()

func set_color(setting_name: String, color: Color):
	# New Test Content
	var flat_box: StyleBoxFlat = StyleBoxFlat.new()
	flat_box.bg_color = color
	var theme_path = THEME_DEFAULT[setting_name]["theme_path"]
	var new_theme: Theme = load(theme_path)
	new_theme.set_stylebox(THEME_DEFAULT[setting_name]["name"], THEME_DEFAULT[setting_name]["theme_type"], flat_box )
	ResourceSaver.save(new_theme, THEME_DEFAULT[setting_name]["theme_path"])
	

func load_colors():
	var config: ConfigFile = ConfigFile.new()
	var err = config.load(SAVE_FILEPATH)
	if err == OK:
		for ui_name in THEME_DEFAULT.keys():
			var ui_color = config.get_value("Colors", ui_name, "")
			# If color is not found, use default
			if ui_color == "":
				ui_color = THEME_DEFAULT[ui_name]["default"]
			
			var single_color_gui = preload("res://FileBrowser/Color/single_color_choice_gui.tscn").instantiate()
			single_color_gui.setup(ui_name, ui_color)
			single_color_gui.connect("color_changed", a_color_changed)
			$ScrollContainer/VBoxContainer.add_child(single_color_gui)
	else:
		# If opening config failed, save a new config
		for ui_name in THEME_DEFAULT.keys():
			config.set_value("Color", ui_name, THEME_DEFAULT[ui_name]["default"])
		config.save(SAVE_FILEPATH)

func a_color_changed(color: Color, ui_name: String):
	set_color(ui_name, color)

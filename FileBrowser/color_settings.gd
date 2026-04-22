extends Control

signal color_changed()

const SAVE_FILEPATH = "user://GDFileBrowserColors.cfg"

const COLOR_DEFAULT = {
	"Icon View Background": Color(0.198, 0.198, 0.198, 1.0), 
	"Icon View Font": Color(0.784, 0.784, 0.784, 1.0)
	}

var color_values: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_colors()

func load_colors():
	var config: ConfigFile = ConfigFile.new()
	var err = config.load(SAVE_FILEPATH)
	if err == OK:
		for ui_name in COLOR_DEFAULT.keys():
			var ui_color = config.get_value("Colors", ui_name, "")
			# If color is not found, use default
			if ui_color == "":
				ui_color = COLOR_DEFAULT[ui_name]
			
			var single_color_gui = preload("res://FileBrowser/Color/single_color_choice_gui.tscn").instantiate()
			single_color_gui.setup(ui_name, ui_color)
			single_color_gui.connect("color_changed", a_color_changed)
			$VBoxContainer.add_child(single_color_gui)
	else:
		# If opening config failed, save a new config
		for ui_name in COLOR_DEFAULT.keys():
			config.set_value("Color", ui_name, COLOR_DEFAULT[ui_name])
		config.save(SAVE_FILEPATH)

func a_color_changed(_color: Color):
	emit_signal("color_changed")

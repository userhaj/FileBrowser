extends Node

const SAVE_FILEPATH = "user://GDFileBrowserColors.cfg"

func get_color(ui_name: String, default_color: Color):
	var config: ConfigFile = ConfigFile.new()
	var err = config.load(SAVE_FILEPATH)
	if err == OK:
		var ui_color = config.get_value("Colors", ui_name, "")
		if ui_color == "":
			return default_color
		else:
			return ui_color
	else:
		return default_color

func save_color(ui_name: String, color: Color):
	var config: ConfigFile = ConfigFile.new()
	config.set_value("Color", ui_name, color)
	config.save(SAVE_FILEPATH)

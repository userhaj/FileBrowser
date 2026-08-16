extends Control

@onready var v_box_container: VBoxContainer = $ScrollContainer/VBoxContainer
@onready var edit_theme: Theme = get_tree().root.get_theme()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_value_guis()

func _on_visibility_changed() -> void:
	if visible and v_box_container:
		for child in v_box_container.get_children():
			v_box_container.remove_child(child)
		load_value_guis()

func load_value_guis():
	edit_theme = get_tree().root.get_theme()
	if edit_theme:
		# Add default font size gui
		var default_font_size_gui: SingleNumberChoice = preload("res://FileBrowser/Settings/single_number_choice.tscn").instantiate()
		default_font_size_gui.setup("Font Size", edit_theme.default_font_size, "Default")
		v_box_container.add_child(default_font_size_gui)
		default_font_size_gui.value_changed.connect(_set_default_font_size)
		
		for type_name in edit_theme.get_constant_type_list():
			for constant_name in edit_theme.get_constant_list(type_name):
				var style_edit_gui: SingleNumberChoice = preload("res://FileBrowser/Settings/single_number_choice.tscn").instantiate()
				var const_value = edit_theme.get_constant(constant_name, type_name)
				style_edit_gui.setup(constant_name, const_value, type_name)
				v_box_container.add_child(style_edit_gui)
				style_edit_gui.value_changed.connect(_constant_change)
				
		
		for type_name in edit_theme.get_font_size_type_list():
			for constant_name in edit_theme.get_font_size_list(type_name):
				var style_edit_gui: SingleNumberChoice = preload("res://FileBrowser/Settings/single_number_choice.tscn").instantiate()
				var const_value = edit_theme.get_font_size(constant_name, type_name)
				style_edit_gui.setup(constant_name, const_value, type_name)
				v_box_container.add_child(style_edit_gui)
				style_edit_gui.value_changed.connect(_font_size_change)
		
		
						

func _set_default_font_size(value, _ui_name, _theme_name):
	edit_theme.default_font_size = value
			
func _constant_change(value, ui_name, theme_name):
	edit_theme.set_constant(ui_name, theme_name, value)
	# Save theme file
	_save_theme()
						

func _font_size_change(value, ui_name, theme_name):
	edit_theme.set_font_size(ui_name, theme_name, int(value))
	_save_theme()

func _save_theme():
	# Save theme file
	if edit_theme.has_meta("file_path"):
		var theme_path: String = edit_theme.get_meta("file_path")
		# res:// is readonly, must change to userpath
		if "res://" in theme_path:
			theme_path = "user://" + theme_path.get_file()
		ResourceSaver.save(edit_theme, theme_path)

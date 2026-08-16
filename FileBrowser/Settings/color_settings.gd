extends Control

@onready var v_box_container: VBoxContainer = $ScrollContainer/VBoxContainer
@onready var edit_theme: Theme = get_tree().root.get_theme()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_colors()

func _on_visibility_changed() -> void:
	if visible and v_box_container:
		for child in v_box_container.get_children():
			v_box_container.remove_child(child)
		load_colors()

func load_colors():
	edit_theme = get_tree().root.get_theme()
	if edit_theme:
		for type_name in edit_theme.get_type_list():
			for style_box_name in edit_theme.get_stylebox_list(type_name):
				var style_box = edit_theme.get_stylebox(style_box_name, type_name)
				if style_box is StyleBoxFlat:
						var style_edit_gui: SingleColorChoiceGui = preload("res://FileBrowser/Color/single_color_choice_gui.tscn").instantiate()
						var ui_color = style_box.bg_color
						style_edit_gui.setup(style_box_name, ui_color, type_name)
						v_box_container.add_child(style_edit_gui)
						style_edit_gui.color_changed.connect(_color_changed_style_box)
			
			for font_name in edit_theme.get_font_list(type_name):
					var style_edit_gui: SingleColorChoiceGui = preload("res://FileBrowser/Color/single_color_choice_gui.tscn").instantiate()
					var ui_color = edit_theme.get_color("font_color", type_name)
					style_edit_gui.setup(font_name, ui_color, type_name)
					v_box_container.add_child(style_edit_gui)
					style_edit_gui.color_changed.connect(_color_changed_color_only)
			
			for color_name in edit_theme.get_color_list(type_name):
				if color_name == "font_color":
					var style_edit_gui: SingleColorChoiceGui = preload("res://FileBrowser/Color/single_color_choice_gui.tscn").instantiate()
					var ui_color = edit_theme.get_color("font_color", type_name)
					style_edit_gui.setup(color_name, ui_color, type_name)
					v_box_container.add_child(style_edit_gui)
					style_edit_gui.color_changed.connect(_color_changed_color_only)
						
						
func _color_changed_color_only(color, ui_name, theme_name):
	edit_theme.set_color(ui_name, theme_name, color)
	# Save theme file
	if edit_theme.has_meta("file_path"):
		var theme_path: String = edit_theme.get_meta("file_path")
		
		# res:// is readonly, must change to userpath
		if "res://" in theme_path:
			theme_path = "user://" + theme_path.get_file()
			ResourceSaver.save(edit_theme, theme_path)
						

func _color_changed_style_box(color, ui_name, theme_name):
	var box = edit_theme.get_stylebox(ui_name, theme_name)
	if box.has_method("set_bg_color"):
		box.bg_color = color
		edit_theme.set_stylebox(ui_name, theme_name, box)
		# Save theme file
		if edit_theme.has_meta("file_path"):
			var theme_path: String = edit_theme.get_meta("file_path")
			
			# res:// is readonly, must change to userpath
			if "res://" in theme_path:
				theme_path = "user://" + theme_path.get_file()
			ResourceSaver.save(edit_theme, theme_path)

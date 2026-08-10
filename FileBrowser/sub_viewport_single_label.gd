extends SubViewport
# Used as a way to convert text into a texture
@onready var label: Label = $PanelContainer/Label
@export var text = "":
	set(value):
		set_text(value)
	

func _ready() -> void:
	# Themes do not cross SubViewport, must force theme following
	_copy_root_theme()
	get_tree().root.theme_changed.connect(_copy_root_theme)
	
func _copy_root_theme():
	var theme_resource: Theme = get_tree().root.get_theme()
	if theme_resource:
		$PanelContainer.set_theme(theme_resource)
		$PanelContainer/Label.label_settings.font = theme_resource.get_font("font", "EmojiFont")
		$PanelContainer/Label.label_settings.font_size = theme_resource.get_font_size("font_size", "EmojiFont")
		$PanelContainer/Label.label_settings.font_color = theme_resource.get_color("font_color", "EmojiFont")



func set_text(new_text: String):
	$PanelContainer/Label.text = new_text

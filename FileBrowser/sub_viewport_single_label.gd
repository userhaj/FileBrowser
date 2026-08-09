extends SubViewport
# Used as a way to convert text into a texture
@onready var label: Label = $PanelContainer/Label

func _ready() -> void:
	# Themes do not cross SubViewport, must force theme following
	_copy_root_theme()
	get_tree().root.theme_changed.connect(_copy_root_theme)
	
func _copy_root_theme():
	var theme_resource = get_tree().root.get_theme()
	$PanelContainer.set_theme(theme_resource)
	

func set_text(new_text: String):
	$PanelContainer/Label.text = new_text

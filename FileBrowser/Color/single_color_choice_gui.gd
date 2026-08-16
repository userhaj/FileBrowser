extends HBoxContainer
class_name SingleColorChoiceGui
signal color_changed(color: Color, ui_name: String, theme_type: String)

var default_value: Color
var theme_type: String
var ui_name: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func set_default(value: Color):
	self.default_value = value

func setup(ui_visual_name: String, default: Color, theme_type_name: String="")-> void:
	self.ui_name = ui_visual_name
	self.theme_type = theme_type_name
	$Label.text = "%s/%s" % [theme_type, ui_visual_name]
	self.default_value = default
	$ColorPickerButton.color = default

func _on_color_picker_button_color_changed(color: Color) -> void:
	color_changed.emit(color, self.ui_name, self.theme_type)


func _on_button_reset_pressed() -> void:
	# Set color to default value
	$ColorPickerButton.color = self.default_value

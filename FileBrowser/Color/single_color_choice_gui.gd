extends HBoxContainer
signal color_changed(color: Color, ui_name: String)

var default_value: Color
var ui_name: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func set_default(color: Color):
	self.default_value = color

func setup(ui_visual_name: String, default: Color)-> void:
	self.ui_name = ui_visual_name
	$Label.text = ui_visual_name
	self.default_value = default
	$ColorPickerButton.color = default

func _on_color_picker_button_color_changed(color: Color) -> void:
	emit_signal("color_changed", color, self.ui_name)


func _on_button_reset_pressed() -> void:
	# Set color to default value
	$ColorPickerButton.color = self.default_value
	# Emit notification of change
	$ColorPickerButton.emit_signal("color_changed", $ColorPickerButton.color)

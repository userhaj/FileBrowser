extends HBoxContainer
class_name SingleNumberChoice
signal value_changed(value: float, ui_name: String, theme_type: String)

var default_value: float
var theme_type: String
var ui_name: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func set_default(value: float):
	self.default_value = value

func setup(ui_visual_name: String, default: float, theme_type_name: String="")-> void:
	self.ui_name = ui_visual_name
	self.theme_type = theme_type_name
	$Label.text = "%s/%s" % [theme_type, ui_visual_name]
	self.default_value = default
	$SpinBox.value  = default



func _on_button_reset_pressed() -> void:
	# Set color to default value
	$SpinBox.value = self.default_value


func _on_spin_box_value_changed(value: float) -> void:
	value_changed.emit(value, ui_name, theme_type)

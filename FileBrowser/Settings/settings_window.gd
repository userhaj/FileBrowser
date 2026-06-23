extends Window


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var color_settings = preload("res://FileBrowser/Settings/color_settings.tscn").instantiate()
	$HBoxContainer/Control.add_child(color_settings)


func _on_button_colors_pressed() -> void:
	for child in $HBoxContainer/Control.get_children():
		$HBoxContainer/Control.remove_child(child)
		
	var color_settings = preload("res://FileBrowser/Settings/color_settings.tscn").instantiate()
	$HBoxContainer/Control.add_child(color_settings)


func _on_close_requested() -> void:
	hide()


func _on_button_access_pressed() -> void:
	for child in $HBoxContainer/Control.get_children():
		$HBoxContainer/Control.remove_child(child)
		
		
	var accessibility_settings = preload("res://FileBrowser/Settings/accessibility_settings.tscn").instantiate()
	$HBoxContainer/Control.add_child(accessibility_settings)

extends Window


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var color_settings = preload("res://FileBrowser/color_settings.tscn").instantiate()
	$HBoxContainer/Control/ScrollContainer/VBoxContainer.add_child(color_settings)


func _on_button_colors_pressed() -> void:
	for child in $HBoxContainer/Control/ScrollContainer/VBoxContainer.get_children():
		$HBoxContainer/Control/ScrollContainer/VBoxContainer.remove_child(child)
	var color_settings = preload("res://FileBrowser/color_settings.tscn").instantiate()
	$HBoxContainer/Control/ScrollContainer/VBoxContainer.add_child(color_settings)


func _on_close_requested() -> void:
	queue_free()

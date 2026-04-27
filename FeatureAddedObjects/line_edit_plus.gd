extends LineEdit
class_name LineEditPlus

signal text_position_changed(pos: Vector2)

func _enter_tree() -> void:
	connect("text_changed", text_position_changed_callable)

#func gui_input_text_entry_position(event: InputEvent):
	#if event is InputEventKey and event.is_pressed() and event.key_label != KEY_ENTER and event.key_label != KEY_SHIFT:
		#emit_signal("text_changed_position", get_position_of_last_character())
	#pass

func get_position_of_last_character():
	var font = get_theme_font("font")
	var font_size = get_theme_font_size("font_size")
	var entry_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var last_char_pos = Vector2(entry_size.x + get_scroll_offset(), entry_size.y/2)
	
	return Vector2(get_window().position) + global_position + last_char_pos
	
func text_position_changed_callable(new_text: String):
	emit_signal("text_position_changed", get_position_of_last_character())
	

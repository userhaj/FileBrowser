extends LineEdit
class_name LineEditPlus

signal text_position_changed(pos: Vector2)
var text_before_delete: String
var is_need_drop: bool= false

func _enter_tree() -> void:
	connect("text_changed", text_position_changed_callable)
	connect("text_changed", animate_action)
	connect("gui_input", _on_gui_input)

#func gui_input_text_entry_position(event: InputEvent):
	#if event is InputEventKey and event.is_pressed() and event.key_label != KEY_ENTER and event.key_label != KEY_SHIFT:
		#emit_signal("text_changed_position", get_position_of_last_character())
	#pass

func get_position_of_last_character(is_position_below_character=false):
	var font = get_theme_font("font")
	var font_size = get_theme_font_size("font_size")
	var entry_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	
	var y_offset = entry_size.y/2 if is_position_below_character else 0
		
	var last_char_pos = Vector2(entry_size.x + get_scroll_offset(), y_offset)
	
	return Vector2(get_window().position) + global_position + last_char_pos
	
func text_position_changed_callable(_new_text: String):
	emit_signal("text_position_changed", get_position_of_last_character(true))

func animate_action(_new_text: String):
	if is_need_drop:
		is_need_drop = false
		var letter_fall: Window = preload("res://FallingLetters/falling_letters.tscn").instantiate()
		var length_deleted_string: int = text_before_delete.length() - text.length()
		var first_index: int = self.text_before_delete.length()-length_deleted_string
		var letters: String = self.text_before_delete.substr(first_index, length_deleted_string)
		add_child(letter_fall)
		letter_fall.drop_letters(letters, theme, get_position_of_last_character())



func _on_gui_input(event):
	if event is InputEventKey and event.key_label == Key.KEY_BACKSPACE:
		if event.is_pressed():
			text_before_delete = text
			is_need_drop = true
		

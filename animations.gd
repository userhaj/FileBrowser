extends Node
class_name ControlAnimations

func drop_down(control):
	var tween = create_tween()
	tween.tween_property(control, "position:y", 4000, 10.0)
	tween.play()

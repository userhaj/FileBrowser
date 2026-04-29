extends Window

func _init() -> void:
	visible = false
	borderless = true
	always_on_top = true
	transparent = true
	transparent_bg = true
	unfocusable = true
	mouse_passthrough = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	size = DisplayServer.screen_get_size()
	position = Vector2i(0.0, 0.0)
	show()

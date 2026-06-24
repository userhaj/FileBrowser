extends AudioStreamPlayer2D
class_name AudioStreamPlayer2DWindowMovement

var last_window_position: Vector2i
var is_window_dragging: bool
var tolerance: float = 0.25
var tolerance_timer: Timer
var listner: AudioListener2D

var pitch_timer: Timer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	last_window_position = DisplayServer.window_get_position()
	is_window_dragging = false
	tolerance_timer = Timer.new()
	tolerance_timer.one_shot = true
	add_child(tolerance_timer)
	stream_paused = true
	listner = AudioListener2D.new()
	
	# Needed to prevent instant playing on launch
	var one_sec_timer = Timer.new()
	add_child(one_sec_timer)
	one_sec_timer.start(1)
	one_sec_timer.timeout.connect(func(): self.playing = true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Get latest windows position
	var current_position: Vector2i = DisplayServer.window_get_position()
	# Find if window has moved
	is_window_dragging = current_position != last_window_position
	

	if is_window_dragging:
		_center_listener()
		_pos_self_ratio_window_center()
		stream_paused = false
		tolerance_timer.start(tolerance)
	elif not is_window_dragging and tolerance_timer.is_stopped():
		stream_paused = true
		
	last_window_position = current_position

func _center_listener():
	get_window().size
	listner.position = get_window().size / 2

func _pos_self_ratio_window_center():
	position = get_window().position * get_window().size / DisplayServer.screen_get_size()

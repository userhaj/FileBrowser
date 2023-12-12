extends TextureButton
class_name FolderLargeIconButton

var path: String
var is_selected: bool = false
const ICON_DIMENSION: float = 35  # Is square size of folder text icon
var hover_label: Label
var set_image_thread: Thread
var is_image_set: bool = false
var image_path: String
var _thread_queue: ThreadQueue
var _set_image_non_queue_thread: Thread

func _ready():
	_icon_scale()

# Optional work queue
func set_thread_queue(thread_queue: ThreadQueue):
	self._thread_queue = thread_queue

func _icon_scale():
	# Resize folder icon to be size of parent
	if $ImageLabel:
		var height = $".".get_rect().size.y
		var width = $".".get_rect().size.x
		var text_height = $NameLabel.get_line_height()
		var scale_y = (height - text_height) / 27
		var scale_x = width / (ICON_DIMENSION - 4)
		var scale_amount =  Vector2(scale_x, scale_y)
		$ImageLabel.scale = scale_amount
		$VisibleOnScreenNotifier2D.scale = scale_amount

static func is_image_extension(extension: String):
	return extension.to_lower() in ["png", "svg", "bmp", "jpg", "ktx", "tga", "webp"]

func set_image(full_path: String):
	self.image_path = full_path
	self.is_image_set = true
	if self._thread_queue:
		self._thread_queue.enqueue(_image_texture_from_path.bind(self.image_path, $VisibleOnScreenNotifier2D.is_on_screen), set_image_texture)
	else:
		self._set_image_non_queue_thread = Thread.new()
		self._set_image_non_queue_thread.start(_set_image_thread_work.bind(self.image_path, $VisibleOnScreenNotifier2D.is_on_screen))


func _set_image_thread_work(full_path: String, is_on_screen: Callable):
	var image_texture: ImageTexture = _image_texture_from_path(full_path, is_on_screen)
	call_deferred("_end_non_queue_thread", image_texture)

func _end_non_queue_thread(image_texture: ImageTexture):
	set_image_texture(image_texture)
	_set_image_non_queue_thread.wait_to_finish()
	

func _apply_texture_image_icon():
	if is_image_set and (null == $TextureRect.texture):
		set_image(image_path)
		

func _remove_texture_image_icon():
	$TextureDeleteTimer.start()
	
func _texture_delete():
	# If memory is not low, reset delete timer
	if not _is_low_memory():
		$TextureDeleteTimer.start()
		return
	# Only delete if not on screen
	if not $VisibleOnScreenNotifier2D.is_on_screen():
		$ImageLabel.show()
		$TextureRect.texture = null

# Check if 80%+ of memory is used
func _is_low_memory():
	var mem_info = OS.get_memory_info()
	var target_low_percent = 0.2
	var free_mem_percent = float(mem_info["free"]) / float(mem_info["physical"])
	return free_mem_percent < target_low_percent

func _slow_show(control: Control):
	var tween = create_tween()
	control.modulate.a = 0
	control.show()
	tween.tween_property(control, "modulate:a", 1.0, 0.25)

func _slow_hide(control: Control):
	var tween = create_tween()
	control.modulate.a = 1
	control.show()
	tween.tween_property(control, "modulate:a", 0.0, 0.25)
	

# Creat an image texture, if texture is on screen
func _image_texture_from_path(full_path: String, is_on_screen: Callable):
	var extension:String = full_path.get_extension()
	if FolderLargeIconButton.is_image_extension(extension) && is_on_screen.call():
		var image = Image.load_from_file(full_path)
		
		# Reduce image size to save ram, procesing speed
		var image_width = float(image.get_size().x)
		var target_width = 1024.0
		if image_width > target_width:
			var image_scale = target_width / image_width
			image.resize(target_width, image.get_size().y * image_scale)
		
		# Create texture
		var new_texture = ImageTexture.create_from_image(image)
		return new_texture
	return null

func set_image_texture(new_texture: ImageTexture):
	if null == new_texture:
		return
		#_remove_texture_image_icon()
	else:
		if $TextureRect:
			$TextureRect.texture = new_texture
			_slow_show($TextureRect)
			$ImageLabel.hide()

func select():
	self.is_selected = true
	$SelectColorRect.show()

func deselect():
	self.is_selected = false
	$SelectColorRect.hide()

func _on_resized():
	_icon_scale()

func set_path(abs_path: String, text_icon: String = ""):
	# Sanitize path
	self.path = abs_path.simplify_path()
	var last_index = self.path.get_slice_count("/") - 1
	# Update folder name
	$NameLabel.text = self.path.get_slice("/", last_index)
	$NameLabel.tooltip_text = $NameLabel.text
	if text_icon != "":
		$ImageLabel.text = text_icon
	elif self.path.get_extension() != "":
		# Create unique default icons for each extension here
		$ImageLabel.text = "📄"

func get_abs_path():
	return self.path
	

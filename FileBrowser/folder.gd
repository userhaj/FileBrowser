extends TextureButton
class_name FolderLargeIconButton

var path: String
var is_selected: bool = false
const ICON_DIMENSION: float = 35  # Is square size of folder text icon
var hover_label: Label
var set_image_thread: Thread
var is_image_set: bool = false
var image_path: String

func _ready():
	_icon_scale()

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

func is_image_extension(extension: String):
	return extension.to_lower() in ["png", "svg", "bmp", "jpg", "ktx", "tga", "webp"]


func set_image(full_path: String):
	self.image_path = full_path
	self.is_image_set = true

func _apply_texture_image_icon():
	if is_image_set:
		self.set_image_thread = Thread.new()
		self.set_image_thread.start(_set_image_thread.bind(self.image_path, $VisibleOnScreenNotifier2D.is_on_screen))

func _remove_texture_image_icon():
	set_image_thread
	$TextureRect.texture = null


func _set_image_thread(full_path: String, is_on_screen: Callable):
	var extension:String = full_path.get_extension()
	var file = FileAccess.open(full_path, FileAccess.READ)
	if FileAccess.get_open_error() == OK && is_on_screen.call():
		var buffer = file.get_buffer(file.get_length())
		var image = Image.new()
		if is_image_extension(extension) && is_on_screen.call():
			var error = image.call("load_"+extension.to_lower()+"_from_buffer", buffer)
			if error != OK:
				call_deferred("set_image_end_thread")
				return
			image.compress(Image.COMPRESS_S3TC)
		else:
			call_deferred("set_image_end_thread")
		var new_texture = ImageTexture.create_from_image(image)
		call_deferred("set_image_texture", new_texture)
	else:
		call_deferred("set_image_end_thread")

func set_image_texture(new_texture: Texture):
	$TextureRect.texture = new_texture
	$ImageLabel.hide()
	set_image_end_thread()

func set_image_end_thread():
	set_image_thread.wait_to_finish()

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
	

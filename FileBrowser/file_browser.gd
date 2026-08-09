extends Control


@onready var current_path: String = DirAccess.get_drive_name(0)
@onready var current_path_line_edit: LineEditPlus = $PanelContainer/VBoxContainer/MenuHBoxContainer/CurrentPathLineEdit
@onready var file_button: Button = $PanelContainer/VBoxContainer/MenuHBoxContainer/FileButton
@onready var view_menu_button = $PanelContainer/VBoxContainer/MenuHBoxContainer/ViewButton
@onready var folder_tree: Tree = $PanelContainer/VBoxContainer/HSplitContainer/PanelContainer/VSplitContainer/FileTree
@onready var bookmarks: BookmarkItemList = $PanelContainer/VBoxContainer/HSplitContainer/PanelContainer/VSplitContainer/PanelContainer/BookmarkItemList
@onready var bookmark_container = $PanelContainer/VBoxContainer/HSplitContainer/PanelContainer/VSplitContainer/PanelContainer
@onready var file_menu: MenuButton = $PanelContainer/VBoxContainer/MenuHBoxContainer/FileButton
@onready var tabbed_browser: TabContainer = $PanelContainer/VBoxContainer/HSplitContainer/TabbedBrowser


var settings_file_name = "user://SETTINGS.cfg"

var is_shoot_laser_left: bool = true

# Folders to go to when going "Back"
var folder_past_list = []
# Folders to go to when going "Forward"
var folder_future_list = []

func _ready():
	set_current_path(current_path.simplify_path())
	visual_load()
	folder_tree.show_default_os_drives()
	folder_tree.columns = 1
	
	file_menu.get_popup().id_pressed.connect(_handle_file_menu)
	
enum file_menu_options{NEW_WINDOW, QUIT}
func _handle_file_menu(id: int):
	match id:
		file_menu_options.NEW_WINDOW:
			var new_window = Window.new()
			new_window.size = Vector2(640, 480)
			new_window.title = get_window().title + " 🪵"
			new_window.position = get_window().position * 1.1
			get_tree().root.add_child(new_window)
			new_window.close_requested.connect(new_window.queue_free)
			var new_file_browser = preload("res://FileBrowser/file_browser.tscn").instantiate()
			new_window.add_child(new_file_browser)
			new_window.show()
		file_menu_options.QUIT:
			get_tree().quit()

# Loads from save file window posititions
func visual_load():
	var config: ConfigFile = ConfigFile.new()
	var err = config.load(settings_file_name)
	if err == OK:
		$PanelContainer/VBoxContainer/HSplitContainer.split_offsets = config.get_value("display", "$PanelContainer/VBoxContainer/HSplitContainer.split_offsets", 216)
		$PanelContainer/VBoxContainer/HSplitContainer/PanelContainer/VSplitContainer.split_offsets = config.get_value("display", "$PanelContainer/VBoxContainer/HSplitContainer.split_offsets", 156)

# Saves window positioning to user folder file 
func visual_save():
	var config: ConfigFile = ConfigFile.new()
	config.set_value("display", "$PanelContainer/VBoxContainer/HSplitContainer.split_offsets", $PanelContainer/VBoxContainer/HSplitContainer.split_offsets)
	config.set_value("display", "$PanelContainer/VBoxContainer/HSplitContainer/PanelContainer/VSplitContainer.split_offsets", $PanelContainer/VBoxContainer/HSplitContainer/PanelContainer/VSplitContainer.split_offsets)
	config.save(settings_file_name)

func set_current_path(full_path: String):
	# Set current path
	self.current_path = full_path.simplify_path()
	current_path_line_edit.text = self.current_path
	if self.current_path != self.tabbed_browser.get_directory():
		self.tabbed_browser.set_directory(self.current_path)

		
func _on_up_dir_button_pressed():
	var new_path = self.current_path.get_base_dir()
	set_current_path(new_path)


func _on_h_slider_value_changed(value):
	self.folder_view.set_folder_size(value)


func _on_view_button_pressed():
	# Create view menu below view button
	var true_location = self.view_menu_button.position + Vector2(get_window().position)
	var x_pos = true_location.x
	# Bottom of button
	var y_pos = true_location.y + self.view_menu_button.size.y
	$ViewPopupMenu.popup()
	$ViewPopupMenu.position = Vector2(x_pos, y_pos)


func _on_view_popup_menu_id_pressed(id):
	match id:
		0:
			var idx = $ViewPopupMenu.get_item_index(id)
			self.folder_tree.visible = not self.folder_tree.visible
			$ViewPopupMenu.set_item_checked(idx, self.folder_tree.visible)
		1:
			var idx = $ViewPopupMenu.get_item_index(id)
			self.current_path_line_edit.visible = not self.current_path_line_edit.visible
			$ViewPopupMenu.set_item_checked(idx, self.current_path_line_edit.visible)
		2:
			var idx = $ViewPopupMenu.get_item_index(id)
			self.bookmark_container.visible = not self.bookmark_container.visible
			$ViewPopupMenu.set_item_checked(idx, self.bookmark_container.visible)
		3:
			var idx = $ViewPopupMenu.get_item_index(id)
			self.tabbed_browser.visible = not self.tabbed_browser.visible
			$ViewPopupMenu.set_item_checked(idx, self.tabbed_browser.visible)



# Settings clicked
func _on_settings_button_pressed() -> void:
	popup_true_centered($SettingsWindow, get_window())


# Place first window centered on second window
func popup_true_centered(popup: Window, window: Window):
	# Popup above everything else (prevent hidden pop under)
	popup.popup()
	# Center on window, Must be done after shown on screen
	popup.position = window.position + Vector2i(window.size - popup.size) / 2
	

func _on_current_path_line_edit_text_submitted(new_text: String) -> void:
	set_current_path(new_text)


func _on_refresh_button_pressed() -> void:
	tabbed_browser.refresh()

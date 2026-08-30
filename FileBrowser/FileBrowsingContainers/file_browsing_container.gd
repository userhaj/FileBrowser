extends Control
class_name FileBrowsingContainer
# An example of require components for each File Browser control

# All file browsing objects contain methods below

signal folder_changed(path: String)

func get_directory():
	pass

func set_directory(path: String):
	pass

func refresh():
	pass

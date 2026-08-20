extends Node
class_name FileBrowserNode

# All file browsing objects contain methods below

signal folder_changed(path: String)

func get_directory():
	pass

func set_directory(path: String):
	pass

func refresh():
	pass

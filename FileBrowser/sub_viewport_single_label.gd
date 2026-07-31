extends SubViewport
# Used as a way to convert text into a texture

func set_text(new_text: String):
	$PanelContainer/Label.text = new_text

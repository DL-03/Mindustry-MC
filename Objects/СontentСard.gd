extends Button


var ContentEditor: Node
var ModEditor: Node


var contentClass: ContentClass:
	set = _set_contentClass
func _set_contentClass(value):
	contentClass = value
	
	
	$HBoxContainer/VBoxContainer/HBoxContainer2/Path.text = str(contentClass.Path).substr(0, str(contentClass.Path).length()-("."+str((contentClass.Path.get_extension()).to_upper())).length())
	$HBoxContainer/VBoxContainer/HBoxContainer2/Type.text = "."+str((contentClass.Path.get_extension()).to_upper())


	
	$HBoxContainer/MarginContainer/ObjectIcon.ModEditor = ModEditor
	$HBoxContainer/MarginContainer/ObjectIcon.Path = contentClass.Path
	#contentClass.content_loaded.connect(_content_loaded)
	
	if contentClass.Data != null:
		if typeof(contentClass.Data) == TYPE_DICTIONARY:
			if "name" in contentClass.Data:
				$HBoxContainer/VBoxContainer/Name.real_text = str(contentClass.Data["name"])
				pass
			else:
				$HBoxContainer/VBoxContainer/Name.real_text = "[red]none"
				pass



func _on_pressed():
	ContentEditor.open_from_path(contentClass)

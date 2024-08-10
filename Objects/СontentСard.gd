extends Button


var ContentEditor: Node
var ModEditor: Node

func _data_changed():
	contentClass = contentClass
func _file_deleted():
	queue_free()
	
var contentClass: ContentClass:
	set = _set_contentClass
func _set_contentClass(value):
	if contentClass != null:
		contentClass.data_changed.disconnect(_data_changed)
		contentClass.file_deleted.disconnect(_file_deleted)
	value.data_changed.connect(_data_changed)
	value.file_deleted.connect(_file_deleted)
	contentClass = value
	
	
	$HBoxContainer/VBoxContainer/HBoxContainer2/Path.real_text = str(contentClass.Path).substr(0, str(contentClass.Path).length()-("."+str((contentClass.Path.get_extension()).to_upper())).length())
	$HBoxContainer/VBoxContainer/HBoxContainer2/Path.real_tooltip_text = contentClass.Path
	$HBoxContainer/VBoxContainer/HBoxContainer2/Type.text = "."+str((contentClass.Path.get_extension()).to_upper())


	
	$HBoxContainer/MarginContainer/ObjectIcon.modClass = ModEditor.modClass
	$HBoxContainer/MarginContainer/ObjectIcon.contentClass = contentClass
	
	
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




func _on_delete_pressed():
	get_node("/root/Main/RenameDuplicateWindow").open(contentClass, 0)
func _on_rename_pressed():
	get_node("/root/Main/RenameDuplicateWindow").open(contentClass, 1)
func _on_duplicate_pressed():
	get_node("/root/Main/RenameDuplicateWindow").open(contentClass, 2)

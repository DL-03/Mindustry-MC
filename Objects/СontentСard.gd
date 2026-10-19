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
	
	$HBoxContainer/VBoxContainer/FilePathElement.path = contentClass.Path

	
	#$HBoxContainer/MarginContainer/ObjectIcon.modClass = ModEditor.modClass
	$HBoxContainer/ObjectIcon.contentClass = contentClass
	
	
	#contentClass.content_loaded.connect(_content_loaded)
	
	if contentClass.Data != null:
		if typeof(contentClass.Data) == TYPE_DICTIONARY:
			if "name" in contentClass.Data:
				$HBoxContainer/VBoxContainer/Name.real_text = "[emb][UI.YELLOW]"+str(contentClass.Data["name"])
				#$HBoxContainer/VBoxContainer/Name.real_tooltip_text = str(contentClass.Data["name"])
				pass
			else:
				$HBoxContainer/VBoxContainer/Name.real_text = "[emb][UI.RED]none"
				pass


func _on_pressed():
	ContentEditor.open_from_path(contentClass)




func _on_delete_pressed():
	$/root/Main/Windows/RenameDuplicateWindow.open(contentClass, 0)
func _on_rename_pressed():
	$/root/Main/Windows/RenameDuplicateWindow.open(contentClass, 1)
func _on_duplicate_pressed():
	$/root/Main/Windows/RenameDuplicateWindow.open(contentClass, 2)

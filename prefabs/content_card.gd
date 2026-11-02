extends Button


var ContentEditor: Node
var ModEditor: Node
var _actions_popup: PopupPanel

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
	
	#$HBoxContainer/VBoxContainer/FilePathElement.path = contentClass.Path

	
	#$HBoxContainer/MarginContainer/ObjectIcon.modClass = ModEditor.modClass
	$HBoxContainer/ObjectIcon.contentClass = contentClass
	
	
	#contentClass.content_loaded.connect(_content_loaded)
	
	if contentClass.Data != null:
		if typeof(contentClass.Data) == TYPE_DICTIONARY:
			var _name = ""
			if "name" in contentClass.Data:
				if contentClass.Data["name"] == "":
					_name = contentClass.Path.get_file()
				else:
					_name = contentClass.Data["name"]
			else:
				_name = contentClass.Path.get_file()
			$HBoxContainer/Name.real_text = "[emb][UI.YELLOW]"+_name

func _on_pressed():
	ContentEditor.open_from_path(contentClass)



func _on_delete_pressed():
	_hide_actions_popup()
	$/root/Main/Windows/RenameDuplicateWindow.open(contentClass, 0)
func _on_rename_pressed():
	$/root/Main/Windows/RenameDuplicateWindow.open(contentClass, 1)
	_hide_actions_popup()
func _on_duplicate_pressed():
	$/root/Main/Windows/RenameDuplicateWindow.open(contentClass, 2)
	_hide_actions_popup()


func _on_copy_relative_path_pressed():
	var mp = contentClass.modClass.Path.simplify_path()
	var cp = contentClass.Path.simplify_path()
	var _text = cp.erase(0, len(cp)-(len(cp)-len(mp)))
	DisplayServer.clipboard_set(_text)
	Notifications.info("|PathCopied|!")
	_hide_actions_popup()

func _on_copy_absolute_path_pressed():
	DisplayServer.clipboard_set(contentClass.Path)
	Notifications.info("|PathCopied|!")
	_hide_actions_popup()

func _on_open_in_explorer_pressed():
	OS.shell_show_in_file_manager(contentClass.Path)
	_hide_actions_popup()

func _hide_actions_popup() -> void:
	$PopupMindTooltip.untip()


func _on_actions_pressed() -> void:
	$PopupMindTooltip.tip()

func _on_popup_mind_tooltip_tooltip_will_show(tooltip: Node) -> void:
	tooltip.clear_connections()
	tooltip.connect("delete", _on_delete_pressed)
	tooltip.connect("rename", _on_rename_pressed)
	tooltip.connect("_duplicate", _on_duplicate_pressed)
	tooltip.connect("copy_relative_path", _on_copy_relative_path_pressed)
	tooltip.connect("copy_absolute_path", _on_copy_absolute_path_pressed)
	tooltip.connect("open_in_explorer", _on_open_in_explorer_pressed)
	
	var mp = contentClass.modClass.Path.simplify_path()
	var cp = contentClass.Path.simplify_path()
	var _text = cp.erase(0, len(cp)-(len(cp)-len(mp)))
	tooltip.crp_tooltip.tooltip_text = "[emb][font_size=12]"+_text
	tooltip.cap_tooltip.tooltip_text = "[emb][font_size=12]"+contentClass.Path

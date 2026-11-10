extends VBoxContainer


@export var ModEditor: Node
@export var Tabs: Node
@export var Editors: Node



@export var SaveButton: Node







func get_only_filename(path):
	return path.get_file().substr(0, -1+path.get_file().length()-path.get_file().get_extension().length())


func select_tab(_tab):
	for i in Tabs.get_children():
		if not i.tab: return
		if not i.tab.is_node_ready():
			await i.tab.ready
		i.tab.disabled = false
		if i.ContentFrame != null:
			i.ContentFrame.visible = false

	if not _tab.tab: return
	if not _tab.tab.is_node_ready():
		await _tab.tab.ready
	_tab.tab.disabled = true
	SaveButton.disabled = false
	if _tab.ContentFrame != null:
		_tab.ContentFrame.visible = true
		SaveButton.disabled = not _tab.ContentFrame.needSave

func open_from_path(_contentClass):
	for i in Tabs.get_children():
		if i.contentClass == _contentClass:
			select_tab(i)
			return
		
	
	
	var tab = preload("res://scenes/content_editor/content_tab_button.tscn").instantiate()
	tab.ModEditor = ModEditor
	tab.RootNode = self
	tab.contentClass = _contentClass
	Tabs.add_child(tab)
	select_tab(tab)


func close_mod(mod_class: ModClass) -> void:
	for tab: Node in Tabs.get_children():
		var content_class: ContentClass = tab.contentClass
		if not is_instance_valid(content_class) or content_class.modClass != mod_class:
			continue
		if is_instance_valid(tab.ContentFrame):
			tab.ContentFrame.queue_free()
		tab.queue_free()



func save_content(_contentClass):
	for i in Tabs.get_children():
		if i.contentClass == _contentClass:
			if not i.ContentFrame.prepare_text_for_save():
				return
			if i.ContentFrame.needSave:
				var data: Dictionary = i.contentClass.Data.duplicate(true)
				for key: String in i.ContentFrame.writeData:
					var value: Variant = i.ContentFrame.writeData[key]
					if value == null:
						data.erase(key)
					else:
						data[key] = value

				if not i.contentClass.save_data(
					data,
					i.ContentFrame.get_source_text_override(),
					i.ContentFrame.has_visual_changes_after_text_edit()
				):
					return

				i.ContentFrame.writeData.clear()
				i.ContentFrame.clear_source_text_override()
				i.ContentFrame.needSave = false
				SaveButton.disabled = true


func _on_save_pressed():
	for i in Tabs.get_children():
		if i.ContentFrame.visible:
			save_content(i.contentClass)

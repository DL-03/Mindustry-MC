extends Button


var ModEditor: Node

var RootNode = null
var ContentFrame = null






func _data_changed():
	contentClass = contentClass
func _file_deleted():
	if ContentFrame != null:
		ContentFrame.queue_free()
	self.queue_free()

var contentClass: ContentClass:
	set = _set_contentClass
func _set_contentClass(value):
	if contentClass != null:
		contentClass.data_changed.disconnect(_data_changed)
		contentClass.file_deleted.disconnect(_file_deleted)
	value.data_changed.connect(_data_changed)
	value.file_deleted.connect(_file_deleted)
	
	contentClass = value
	
	
	if contentClass != null:
		if typeof(contentClass.FullData) == TYPE_DICTIONARY:
			if contentClass.FileType == "mod":
				if contentClass.FullData["displayName"] != "":
					NameLabel.real_text = contentClass.FullData["displayName"]
				else:
					if "name" in contentClass.FullData:
						NameLabel.real_text = contentClass.FullData["name"]
					else:
						NameLabel.real_text = "[UI.RED]None"
			else:
				if "name" in contentClass.FullData:
					NameLabel.real_text = contentClass.FullData["name"]
				else:
					NameLabel.real_text = "[UI.RED]None"
			
		
	
	if ContentFrame == null:
		ContentFrame = preload("res://Objects/ForEditor/content_frame_rect.tscn").instantiate()
		RootNode.Editors.add_child(ContentFrame)
	#ContentFrame.setPath(Path)
	ContentFrame.ModEditor = ModEditor
	ContentFrame.RootNode = RootNode
	ContentFrame.contentClass = contentClass
	ContentFrame.TabButton = self
	#$HBoxContainer/MarginContainer/ObjectIcon.modClass = ModEditor.modClass
	$MarginContainer/HBoxContainer/Icon.contentClass = contentClass
		
	
	RootNode.select_tab(self)

@export var NameLabel: Node

func get_only_filename(path):
	return path.get_file().substr(0, -1+path.get_file().length()-path.get_file().get_extension().length())




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_pressed():
	RootNode.select_tab(self)




func NSC_CancelButton():
	get_node("/root/Main/Windows/NeedSaveContent").hide()
	get_node("/root/Main/Windows/NeedSaveContent/Panel/MarginContainer/VBoxContainer/HBoxContainer/Cancel").pressed.disconnect(NSC_CancelButton)
	get_node("/root/Main/Windows/NeedSaveContent/Panel/MarginContainer/VBoxContainer/HBoxContainer/Discard").pressed.disconnect(NSC_DiscardButton)
	get_node("/root/Main/Windows/NeedSaveContent/Panel/MarginContainer/VBoxContainer/HBoxContainer/Save").pressed.disconnect(NSC_SaveButton)
func NSC_DiscardButton():
	get_node("/root/Main/Windows/NeedSaveContent").hide()
	get_node("/root/Main/Windows/NeedSaveContent/Panel/MarginContainer/VBoxContainer/HBoxContainer/Cancel").pressed.disconnect(NSC_CancelButton)
	get_node("/root/Main/Windows/NeedSaveContent/Panel/MarginContainer/VBoxContainer/HBoxContainer/Discard").pressed.disconnect(NSC_DiscardButton)
	get_node("/root/Main/Windows/NeedSaveContent/Panel/MarginContainer/VBoxContainer/HBoxContainer/Save").pressed.disconnect(NSC_SaveButton)
	if ContentFrame != null:
		ContentFrame.queue_free()
	self.queue_free()
	
	RootNode.SaveButton.disabled = true
	
func NSC_SaveButton():
	get_node("/root/Main/Windows/NeedSaveContent").hide()
	get_node("/root/Main/Windows/NeedSaveContent/Panel/MarginContainer/VBoxContainer/HBoxContainer/Cancel").pressed.disconnect(NSC_CancelButton)
	get_node("/root/Main/Windows/NeedSaveContent/Panel/MarginContainer/VBoxContainer/HBoxContainer/Discard").pressed.disconnect(NSC_DiscardButton)
	get_node("/root/Main/Windows/NeedSaveContent/Panel/MarginContainer/VBoxContainer/HBoxContainer/Save").pressed.disconnect(NSC_SaveButton)
	
	RootNode.save_content(contentClass)
	
	if ContentFrame != null:
		ContentFrame.queue_free()
	self.queue_free()


func _on_close_pressed():
	if ContentFrame != null:
		
		if ContentFrame.needSave:
			get_node("/root/Main/Windows/NeedSaveContent/Panel/MarginContainer/VBoxContainer/InfoLabel").real_text = "|NeedSaveContent.InfoLabel.text1| <" + contentClass.Data["name"] + ">|NeedSaveContent.InfoLabel.text2|"
			get_node("/root/Main/Windows/NeedSaveContent/Panel/MarginContainer/VBoxContainer/HBoxContainer/Cancel").pressed.connect(NSC_CancelButton)
			get_node("/root/Main/Windows/NeedSaveContent/Panel/MarginContainer/VBoxContainer/HBoxContainer/Discard").pressed.connect(NSC_DiscardButton)
			get_node("/root/Main/Windows/NeedSaveContent/Panel/MarginContainer/VBoxContainer/HBoxContainer/Save").pressed.connect(NSC_SaveButton)
			get_node("/root/Main/Windows/NeedSaveContent").show()
		else:
			ContentFrame.queue_free()
			self.queue_free()
	else:
		self.queue_free()


func _on_margin_container_resized():
	custom_minimum_size.x = $MarginContainer.size.x
	size.x = 0
	
	
func _on_h_box_container_resized():
	$MarginContainer.size.x = 0

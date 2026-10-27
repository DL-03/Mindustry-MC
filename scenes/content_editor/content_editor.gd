extends Control

var TabButton = null

var ModEditor: Node
var RootNode: Node

@export var _TabContainer: TabContainer

var contentClass: ContentClass:
	set = _set_contentClass


func _ready() -> void:
	_TabContainer.set_tab_title(0, LocalizationAPI.translate_text("|Editor|"))
	_TabContainer.set_tab_title(1, LocalizationAPI.translate_text("|Textures|"))
	
	LocalizationAPI.global_language_changed.connect(
		func():
			_TabContainer.set_tab_title(0, LocalizationAPI.translate_text("|Editor|"))
			_TabContainer.set_tab_title(1, LocalizationAPI.translate_text("|Textures|"))
	)


var writeData = {}



func _data_changed():
	contentClass = contentClass


var needSave = false:
	set = _set_needSave

func _set_needSave(value):
	needSave = value
	
	upd_needSave()

func upd_needSave():
	RootNode.SaveButton.disabled = not needSave
	if TabButton != null:
		TabButton.ElementChanges.visible = needSave

func changed_data(key,value):
	if key in contentClass.FullData:
		if typeof(contentClass.FullData[key]) == typeof(value):
			if contentClass.FullData[key] == value:
				if key in writeData:
					writeData.erase(key)
					print("[ContentEditor][changed_data]1[WriteData]: ",writeData)
					print("[ContentEditor][changed_data]1[FullData]: ",contentClass.FullData)

					needSave = len(writeData) > 0
					
					return

	writeData.merge({key:value}, true)
	print("[ContentEditor][changed_data]2[WriteData]: ",writeData)
	print("[ContentEditor][changed_data]2[FullData]: ",contentClass.FullData)

	
	$TabContainer/Editor/d1.text = str(writeData)
	$TabContainer/Editor/d2.text = str(contentClass.Data)

	needSave = len(writeData) > 0
		




func _SpriteBank_updated():
	$TabContainer/Textures/ScrollContainer/Flow/MarginContainer/ObjectIcon.contentClass = contentClass
	
	
	for i in $TabContainer/Textures/ScrollContainer/Flow.get_children():
		if i != $TabContainer/Textures/ScrollContainer/Flow.get_child(0):
			i.queue_free()
	
	
	
	var s = preload("res://scenes/content_editor/texture_preview.tscn").instantiate()
	$TabContainer/Textures/ScrollContainer/Flow.add_child(s)
	
	if contentClass.FileType == "mod":
		s.get_node("TextureRect").texture = contentClass.modClass.get_mod_icon()
	else:
		s.get_node("TextureRect").texture = ModEditor.modClass.get_sprite(get_only_filename(contentClass.Path))
	s.get_node("Label").text = get_only_filename(contentClass.Path)
	
	if contentClass.ContentType in ["Drill"]:
		var st = preload("res://scenes/content_editor/texture_preview.tscn").instantiate()
		$TabContainer/Textures/ScrollContainer/Flow.add_child(st)
		
		st.get_node("TextureRect").texture = ModEditor.modClass.get_sprite(get_only_filename(contentClass.Path)+"-rotator")
		st.get_node("Label").text = get_only_filename(contentClass.Path)+"-rotator"
		
		
		var stt = preload("res://scenes/content_editor/texture_preview.tscn").instantiate()
		$TabContainer/Textures/ScrollContainer/Flow.add_child(stt)
		
		stt.get_node("TextureRect").texture = ModEditor.modClass.get_sprite(get_only_filename(contentClass.Path)+"-top")
		stt.get_node("Label").text = get_only_filename(contentClass.Path)+"-top"
	if contentClass.ContentType in ["Conveyor"]:
		
		
		
		for r in [0,1,2,3]:
			for f in [0,1,2,3]:
				var sk = preload("res://scenes/content_editor/texture_preview.tscn").instantiate()
				$TabContainer/Textures/ScrollContainer/Flow.add_child(sk)
				
				sk.get_node("TextureRect").texture = ModEditor.modClass.get_sprite(get_only_filename(contentClass.Path)+"-"+str(r)+"-"+str(f))
				sk.get_node("Label").text = get_only_filename(contentClass.Path)+"-"+str(r)+"-"+str(f)
	




func _set_contentClass(value):
	if contentClass != null:
		contentClass.data_changed.disconnect(_data_changed)
		contentClass.modClass.SpriteBank_updated.disconnect(_SpriteBank_updated)
	value.data_changed.connect(_data_changed)
	value.modClass.SpriteBank_updated.connect(_SpriteBank_updated)
	
	contentClass = value
	
	writeData = {}
	
	$TabContainer/Editor/HBoxContainer/ContentType.text = "ContentType: " + str(contentClass.ContentType)
	
	for i in $TabContainer/Editor/MarginContainer/ScrollContainer/MarginContainer/Panel/Content.get_children():
		i.queue_free()
	
	
	if typeof(contentClass.FullData) == TYPE_DICTIONARY:
		var DATA = contentClass.FullData
		print(DATA)
		
		var _FlowContainer: HFlowContainer
		for i in DATA.keys():
			if i != "type":
			
				var s = preload("uid://cnsmx158sf2fa").instantiate()
				var _data = DATA[i]
				s.Name = str(i)
				s.RootContentFrame = self
				
				if typeof(DATA[i]) == TYPE_BOOL:
					s.Type = "Boolean"
				elif i == "description":
					s.Type = "MultiString"
				elif i == "category":
					s.Type = "Category"
				elif i in ["color", "flameColor", "mapColor", "outlineColor", "lightColor", "heatColor", "lightningColor", "flashColor"]:
					s.Type = "Color"
				else:
					s.Type = "String"
					
				s.Data = _data
				
				if contentClass.DefaultData != null:
					if i in contentClass.DefaultData:
						s.DefaultData = contentClass.DefaultData[i]
						s.get_node("Actions").hide()
				
				
				if s.Type == "Boolean":
					if _FlowContainer == null:
						_FlowContainer = HFlowContainer.new()
						$TabContainer/Editor/MarginContainer/ScrollContainer/MarginContainer/Panel/Content.add_child(_FlowContainer)
						_FlowContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
						_FlowContainer.add_theme_constant_override("separation", 20)
					_FlowContainer.add_child(s)
				else:
					if _FlowContainer != null:
						_FlowContainer = null
				
					$TabContainer/Editor/MarginContainer/ScrollContainer/MarginContainer/Panel/Content.add_child(s)
	
	upd_needSave()
	_SpriteBank_updated()
	
func get_only_filename(path):
	return path.get_file().substr(0, -1+path.get_file().length()-path.get_file().get_extension().length())

var _FlowContainer: HFlowContainer
func create_input(key, value):
	var s = preload("uid://cnsmx158sf2fa").instantiate()
	s.Name = str(key)
	s.RootContentFrame = self

	if typeof(value) == TYPE_BOOL:
		s.Type = "Boolean"
	elif key == "description":
		s.Type = "MultiString"
	elif key == "category":
		s.Type = "Category"
	elif key in ["color", "flameColor", "mapColor", "outlineColor", "lightColor", "heatColor", "lightningColor", "flashColor"]:
		s.Type = "Color"
	else:
		s.Type = "String"

	s.Data = value

	if contentClass.DefaultData != null:
		if key in contentClass.DefaultData:
			s.DefaultData = contentClass.DefaultData[key]



	if s.Type == "Boolean":
		if _FlowContainer == null:
			_FlowContainer = HFlowContainer.new()
			$TabContainer/Editor/MarginContainer/ScrollContainer/MarginContainer/Panel/Content.add_child(_FlowContainer)
			_FlowContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_FlowContainer.add_theme_constant_override("separation", 20)
		_FlowContainer.add_child(s)
	else:
		if _FlowContainer != null:
			_FlowContainer = null

		$TabContainer/Editor/MarginContainer/ScrollContainer/MarginContainer/Panel/Content.add_child(s)


func _on_create_key_pressed():
	$/root/Main/Windows/ContentEditorKeyActions.create(self)

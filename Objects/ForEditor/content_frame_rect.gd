extends Control

var TabButton = null

var ModEditor: Node
var RootNode: Node


var contentClass: ContentClass:
	set = _set_contentClass





var writeData = {}



func _data_changed():
	contentClass = contentClass

func _ready():
	pass
func _process(delta):
	pass


var needSave = false:
	set = _set_needSave

func _set_needSave(value):
	needSave = value
	
	RootNode.SaveButton.disabled = not needSave
func changed_data(key,value):
	if key in contentClass.FullData:
		if typeof(contentClass.FullData[key]) == typeof(value):
			if contentClass.FullData[key] == value:
				if key in writeData:
					writeData.erase(key)
					print("S ",writeData,contentClass.FullData)
					

					needSave = len(writeData) > 0
					
					return

	writeData.merge({key:value}, true)
	print(writeData,contentClass.FullData)
	
	$TabContainer/Editor/d1.text = str(writeData)
	$TabContainer/Editor/d2.text = str(contentClass.Data)

	needSave = len(writeData) > 0
		



func _set_contentClass(value):
	if contentClass != null:
		contentClass.data_changed.disconnect(_data_changed)
	value.data_changed.connect(_data_changed)
	
	
	contentClass = value
	
	writeData = {}
	
	$TabContainer/Editor/HBoxContainer/ContentType.text = "ContentType: " + str(contentClass.ContentType)
	
	for i in $TabContainer/Editor/MarginContainer/ScrollContainer/MarginContainer/Panel.get_children():
		i.queue_free()
	
	
	if typeof(contentClass.FullData) == TYPE_DICTIONARY:
		var DATA = contentClass.FullData
		
		
		var _FlowContainer: HFlowContainer
		for i in DATA.keys():
			if i != "type":
			
				var s = preload("res://Objects/ForEditor/ContentConfig_Widget.tscn").instantiate()
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
				
				
				
				if s.Type == "Boolean":
					if _FlowContainer == null:
						_FlowContainer = HFlowContainer.new()
						$TabContainer/Editor/MarginContainer/ScrollContainer/MarginContainer/Panel.add_child(_FlowContainer)
						_FlowContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
						_FlowContainer.add_theme_constant_override("separation", 20)
					_FlowContainer.add_child(s)
				else:
					if _FlowContainer != null:
						_FlowContainer = null
				
					$TabContainer/Editor/MarginContainer/ScrollContainer/MarginContainer/Panel.add_child(s)
	
	
	#$TabContainer/Textures/ScrollContainer/Flow/MarginContainer/ObjectIcon.modClass = ModEditor.modClass
	$TabContainer/Textures/ScrollContainer/Flow/MarginContainer/ObjectIcon.contentClass = contentClass
	
	
	
	var s = preload("res://Objects/ForEditor/Icons_Textures.tscn").instantiate()
	$TabContainer/Textures/ScrollContainer/Flow.add_child(s)
	
	if contentClass.FileType == "mod":
		if FileAccess.file_exists(ModEditor.modClass.Path+"icon.png"):
			var image = Image.new()
			image.load(ModEditor.modClass.Path+"icon.png")
			var t = ImageTexture.new()
		
			var Icon = t.create_from_image(image)

			s.get_node("TextureRect").texture = Icon
	else:
		s.get_node("TextureRect").texture = ModEditor.modClass.get_sprite(get_only_filename(contentClass.Path))
	s.get_node("Label").text = get_only_filename(contentClass.Path)
	
	if contentClass.ContentType in ["Drill"]:
		var st = preload("res://Objects/ForEditor/Icons_Textures.tscn").instantiate()
		$TabContainer/Textures/ScrollContainer/Flow.add_child(st)
		
		st.get_node("TextureRect").texture = ModEditor.modClass.get_sprite(get_only_filename(contentClass.Path)+"-rotator")
		st.get_node("Label").text = get_only_filename(contentClass.Path)+"-rotator"
		
		
		var stt = preload("res://Objects/ForEditor/Icons_Textures.tscn").instantiate()
		$TabContainer/Textures/ScrollContainer/Flow.add_child(stt)
		
		stt.get_node("TextureRect").texture = ModEditor.modClass.get_sprite(get_only_filename(contentClass.Path)+"-top")
		stt.get_node("Label").text = get_only_filename(contentClass.Path)+"-top"
	if contentClass.ContentType in ["Conveyor"]:
		
		
		
		for r in [0,1,2,3]:
			for f in [0,1,2,3]:
				var sk = preload("res://Objects/ForEditor/Icons_Textures.tscn").instantiate()
				$TabContainer/Textures/ScrollContainer/Flow.add_child(sk)
				
				sk.get_node("TextureRect").texture = ModEditor.modClass.get_sprite(get_only_filename(contentClass.Path)+"-"+str(r)+"-"+str(f))
				sk.get_node("Label").text = get_only_filename(contentClass.Path)+"-"+str(r)+"-"+str(f)
	
	
func get_only_filename(path):
	return path.get_file().substr(0, -1+path.get_file().length()-path.get_file().get_extension().length())

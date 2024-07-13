extends Control

var TabButton = null


var RootNode: Node


var contentClass: ContentClass:
	set = _set_contentClass
func _set_contentClass(value):
	contentClass = value
	
	
	
	if typeof(contentClass.Data) == TYPE_DICTIONARY:
		var DATA = {}
		var DefaultData = {}
		if contentClass.FileType == "mod":
			DefaultData = ContentManager.get_content("mod")
			
			
			DATA = contentClass.Data
			
			if DefaultData != null:
				DATA = DefaultData.duplicate()
				DATA.merge(contentClass.Data, true)
			print(DATA)
		else:
			var _type
			if "type" in contentClass.Data:
				_type = contentClass.Data["type"]
			DefaultData = ContentManager.get_content(_type)
			
			
			DATA = contentClass.Data
			
			if DefaultData != null:
				DATA = DefaultData.duplicate()
				DATA.merge(contentClass.Data, true)
			print(DATA)
		
		
		var _FlowContainer: HFlowContainer
		for i in DATA.keys():
			
			
			var s = preload("res://Objects/ForEditor/ContentConfig_Widget.tscn").instantiate()
			var _data = DATA[i]
			s.Name = str(i)
			
			if typeof(DATA[i]) == TYPE_BOOL:
				s.Type = "Boolean"
			elif i == "description":
				s.Type = "MultiString"
			elif i in ["color", "flameColor", "mapColor", "outlineColor", "lightColor", "heatColor", "lightningColor", "flashColor"]:
				s.Type = "Color"
			else:
				s.Type = "String"
				
			s.Data = _data
			
			if DefaultData != null:
				if i in DefaultData:
					s.DefaultData = DefaultData[i]
			
			
			
			if s.Type == "Boolean":
				if _FlowContainer == null:
					_FlowContainer = HFlowContainer.new()
					$ScrollContainer/MarginContainer/Panel.add_child(_FlowContainer)
					_FlowContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					_FlowContainer.add_theme_constant_override("separation", 20)
				_FlowContainer.add_child(s)
			else:
				if _FlowContainer != null:
					_FlowContainer = null
			
				$ScrollContainer/MarginContainer/Panel.add_child(s)

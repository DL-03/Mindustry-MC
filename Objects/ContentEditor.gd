extends VBoxContainer


@export var ModEditor: Node
@export var Tabs: Node
@export var Editors: Node



@export var SaveButton: Node







func get_only_filename(path):
	return path.get_file().substr(0, -1+path.get_file().length()-path.get_file().get_extension().length())


func select_tab(_tab):
	for i in Tabs.get_children():
		i.disabled = false
		if i.ContentFrame != null:
			i.ContentFrame.visible = false
	_tab.disabled = true
	SaveButton.disabled = false
	if _tab.ContentFrame != null:
		_tab.ContentFrame.visible = true
		SaveButton.disabled = not _tab.ContentFrame.needSave

func open_from_path(_contentClass):
	for i in Tabs.get_children():
		if i.contentClass == _contentClass:
			select_tab(i)
			return
		
	
	
	var tab = preload("res://Objects/ForEditor/TabContent_Button.tscn").instantiate()
	tab.ModEditor = ModEditor
	tab.RootNode = self
	tab.contentClass = _contentClass
	Tabs.add_child(tab)




# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func save_content(_contentClass):
	for i in Tabs.get_children():
		if i.contentClass == _contentClass:
			if i.ContentFrame.needSave:
				i.ContentFrame.needSave = false
				
				#i.contentClass.WriteData = i.ContentFrame.writeData
				
				var _data = i.contentClass.Data.duplicate()
				_data.merge(i.ContentFrame.writeData, true)
				
				
				var defaultData = i.contentClass.DefaultData
				
				print("_D: ", _data)
				print("DD: ", defaultData)
				
				
				
				
				for k in _data.keys():
					if k in defaultData:
						if typeof(_data[k]) == typeof(defaultData[k]):
							if _data[k] == defaultData[k]:
								_data.erase(k)
				
				i.contentClass.WriteData = _data
				
				SaveButton.disabled = true


func _on_save_pressed():
	for i in Tabs.get_children():
		if i.ContentFrame.visible:
			save_content(i.contentClass)

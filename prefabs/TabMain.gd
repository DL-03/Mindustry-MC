extends PanelContainer

var ContentFrame = null

@onready var tab = $Tab
@onready var AllTabButtons = get_parent()

var modClass: ModClass:
	set = _set_modClass

func _ready() -> void:
	reset()
	tab.show()

func _set_modClass(value):
	modClass = value
	
	if modClass == null:
		return
	
	var IconElement = tab.get_node_or_null("MarginContainer/HBoxContainer/Icon")
	
	if IconElement:
		IconElement.show()
		IconElement.texture = modClass.get_mod_icon()
	else:
		IconElement.hide()
	
	var LabelElement = tab.get_node_or_null("MarginContainer/HBoxContainer/Label")
	
	if LabelElement:
		if modClass.ModContentClass.FullData["displayName"] == "":
			LabelElement.real_text = "[emb]"+modClass.ModContentClass.FullData["name"]
		else:
			LabelElement.real_text = "[emb]"+modClass.ModContentClass.FullData["displayName"]
		
	modClass.ModContentClass.data_changed.connect(func():
		if modClass.ModContentClass.FullData["displayName"] == "":
			LabelElement.real_text = "[emb]"+modClass.ModContentClass.FullData["name"]
		else:
			LabelElement.real_text = "[emb]"+modClass.ModContentClass.FullData["displayName"]
		
		if IconElement:
			IconElement.show()
			IconElement.texture = modClass.get_mod_icon()
		else:
			IconElement.hide()
		)
func reset():
	ContentFrame = null
	modClass = null
	
	var IconElement = tab.get_node_or_null("MarginContainer/HBoxContainer/Icon")
	if IconElement:
		IconElement.hide()

	var LabelElement = tab.get_node_or_null("MarginContainer/HBoxContainer/Label")
	if LabelElement:
		LabelElement.real_text = "[emb][UI.YELLOW]|Explorer|"



func _on_tab_pressed() -> void:
	for i in AllTabButtons.get_children():
		i.tab.disabled = false
		if i.ContentFrame != null:
			i.ContentFrame.visible = false
			
	tab.disabled = true
	if ContentFrame != null:
		ContentFrame.visible = true
		$/root/Main/V1/ModManager.visible = false
	else:
		$/root/Main/V1/ModManager.visible = true


func _on_tab_close() -> void:
	if AllTabButtons.get_child_count() == 1:
		if AllTabButtons.get_child(0).ContentFrame == null:
			return
		else:
			ContentFrame.Close()
			reset()
			$/root/Main/V1/ModManager.show()
			return


	if ContentFrame == null:
		tab.disabled = false
		for i in AllTabButtons.get_children():
			if i != self:
				if not i.tab.disabled:
					i.tab.pressed.emit()
					i.tab.disabled = true
		queue_free()
	else:
		var err = ContentFrame.Close()
		if err == 1:
			pass
		else:
			pass
			
		
		if AllTabButtons.get_child_count() == 1:
			reset()
			$/root/Main/V1/ModManager.show()
			return
		else:
			tab.disabled = false
			for i in AllTabButtons.get_children():
				if i != self:
					if not i.tab.disabled:
						i.tab.pressed.emit()
						i.tab.disabled = true
			queue_free()

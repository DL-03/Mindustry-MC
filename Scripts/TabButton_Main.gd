@tool
extends Button


var ContentFrame = null






var modClass: ModClass:
	set = _set_modClass

func _set_modClass(value):
	modClass = value
	
	if modClass == null:
		return
	$MarginContainer/HBoxContainer/Icon.show()
	if modClass.ModContentClass.FullData["displayName"] == "":
		$MarginContainer/HBoxContainer/Text.real_text = modClass.ModContentClass.FullData["name"]
	else:
		$MarginContainer/HBoxContainer/Text.real_text = modClass.ModContentClass.FullData["displayName"]
	$MarginContainer/HBoxContainer/Icon.texture = modClass.get_mod_icon()
	
	modClass.ModContentClass.data_changed.connect(func():
		if modClass.ModContentClass.FullData["displayName"] == "":
			$MarginContainer/HBoxContainer/Text.real_text = modClass.ModContentClass.FullData["name"]
		else:
			$MarginContainer/HBoxContainer/Text.real_text = modClass.ModContentClass.FullData["displayName"]
		$MarginContainer/HBoxContainer/Icon.texture = modClass.get_mod_icon()
		)
func reset():
	ContentFrame = null
	modClass = null
	
	$MarginContainer/HBoxContainer/Icon.hide()
	$MarginContainer/HBoxContainer/Text.real_text = "[UI.YELLOW]|Main.UpPanel.Tab.Explorer.text|"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	custom_minimum_size.x = $MarginContainer.size.x
	size.x = 0
	pass


func _on_pressed():
	var AllTabButtons = $/root/Main/V1/UpPanel/TabsPanel/MarginContainer/ScrollContainer/MarginContainer/HBoxContainer/Tabs
	for i in AllTabButtons.get_children():
		i.disabled = false
		if i.ContentFrame != null:
			i.ContentFrame.visible = false
			
	self.disabled = true
	if ContentFrame != null:
		ContentFrame.visible = true
		$/root/Main/V1/ModManager.visible = false
	else:
		$/root/Main/V1/ModManager.visible = true


func _on_margin_container_resized():
	custom_minimum_size.x = $MarginContainer.size.x
	size.x = 0


func _on_close_pressed():
	var AllTabButtons = $/root/Main/V1/UpPanel/TabsPanel/MarginContainer/ScrollContainer/MarginContainer/HBoxContainer/Tabs
	
	if AllTabButtons.get_child_count() == 1:
		if AllTabButtons.get_child(0).ContentFrame == null:
			return
		else:
			ContentFrame.Close()
			reset()
			$/root/Main/V1/ModManager.show()
			return


	if ContentFrame == null:
		disabled = false
		for i in AllTabButtons.get_children():
			if i != self:
				if not i.disabled:
					i.pressed.emit()
					i.disabled = true
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
			disabled = false
			for i in AllTabButtons.get_children():
				if i != self:
					if not i.disabled:
						i.pressed.emit()
						i.disabled = true
			queue_free()

	


func _on_h_box_container_resized():
	$MarginContainer.size.x = 0

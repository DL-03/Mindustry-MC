extends HBoxContainer
class_name MindCategory


signal data_changed


var Data = "":
	set = _set_Data

func _set_Data(value):
	Data = value.to_lower()
	
	
	for i in $HFlowContainer.get_children():
		i.disabled = false
	
	if $HFlowContainer.has_node(Data):
		$HFlowContainer.get_node(Data).disabled = true
		
		$Panel/HBoxContainer/Icon.real_text = $HFlowContainer.get_node(Data).real_text_icon_left
		$Panel/HBoxContainer/Text.real_text = $HFlowContainer.get_node(Data).name
		
		var t = $Panel/HBoxContainer/Icon.get_theme_stylebox("normal")
		$Panel/HBoxContainer/Icon.add_theme_stylebox_override("normal",t)

		t.border_color = COLORS.get_color("UI.GREEN")
	

	else:
		Data = ""
	
		$Panel/HBoxContainer/Icon.real_text = "-"
		$Panel/HBoxContainer/Text.real_text = "None"
		
		var t = $Panel/HBoxContainer/Icon.get_theme_stylebox("normal")
		$Panel/HBoxContainer/Icon.add_theme_stylebox_override("normal",t)

		t.border_color = COLORS.get_color("UI.RED")

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in $HFlowContainer.get_children():
		i.pressed.connect(func():
			Data = i.name
			
			data_changed.emit(Data)
			)
		i.mouse_entered.connect(func():
			$Panel/HBoxContainer/Icon.real_text = i.real_text_icon_left
			$Panel/HBoxContainer/Text.real_text = i.name
			
			var t = $Panel/HBoxContainer/Icon.get_theme_stylebox("normal")
			$Panel/HBoxContainer/Icon.add_theme_stylebox_override("normal",t)
			if i.disabled:
				t.border_color = COLORS.get_color("UI.GREEN")
			else:
				t.border_color = COLORS.get_color("UI.GRAY")
			)
		i.mouse_exited.connect(func():
			var t = $Panel/HBoxContainer/Icon.get_theme_stylebox("normal")
			$Panel/HBoxContainer/Icon.add_theme_stylebox_override("normal",t)
			
			if $HFlowContainer.has_node(Data):
				$Panel/HBoxContainer/Icon.real_text = $HFlowContainer.get_node(Data).real_text_icon_left
				$Panel/HBoxContainer/Text.real_text = Data
				t.border_color = COLORS.get_color("UI.GREEN")
			else:
				$Panel/HBoxContainer/Icon.real_text = "0"
				$Panel/HBoxContainer/Text.real_text = "None"
				t.border_color = COLORS.get_color("UI.RED")
			)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

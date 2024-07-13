extends Button


var ContentFrame = null

func reset():
	ContentFrame = null
	text = ""
	icon = null

# Called when the node enters the scene tree for the first time.
func _ready():
	reset()
	
	var AllTabButtons = $/root/Main/V1/HBoxContainer/Panel/MarginContainer/ScrollContainer/MarginContainer2/HBoxContainer
	for i in AllTabButtons.get_children():
		i.disabled = false
		if i.ContentFrame != null:
			i.ContentFrame.visible = false
	self.disabled = true
	$/root/Main/V1/ModManager.visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func _on_pressed():
	var AllTabButtons = $/root/Main/V1/HBoxContainer/Panel/MarginContainer/ScrollContainer/MarginContainer2/HBoxContainer
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

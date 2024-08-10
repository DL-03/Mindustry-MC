extends Panel



var Messages = []


func info(text):
	pass
func debug(text):
	pass
func error(text):
	pass



func SummonMessage(text="", _type=0):
	var s = preload("res://Objects/MindustryTextLabel.tscn").instantiate()
	
	if _type == 0:
		s.real_text = text
	elif _type == 1:
		s.real_text = "[UI.YELLOW](DEBUG): "+text
	elif _type == 2:
		s.real_text = "[UI.RED](ERROR): "+text
	
	s.text_aligment = 1
	s.scroll_active = false
	s.text_vertical_aligment = 1
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.add_theme_constant_override("outline_size", 20)
	#$VBoxContainer.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	s.fit_content = true
	$VBoxContainer.add_child(s)
	$VBoxContainer.move_child(s,0)
	s.custom_minimum_size.x = s.size.x
	var f = max(50,s.get_content_height()+20)
	s.fit_content = false
	
	
	

	
	

	
	
	Messages.append({"label":s, "type":_type, "time":6, "size.y": f})

func update_messages():
	for i in Messages:
		
		
		
		if i["time"] <= 0:
			i["label"].custom_minimum_size.y = max(0, i["label"].custom_minimum_size.y-0.5)
			
			if i["label"].custom_minimum_size.y <= 0:
				i["label"].queue_free()
				Messages.erase(i)
		else:
			i["time"] -= 0.01
			
			i["label"].custom_minimum_size.y = min(i["size.y"], i["label"].custom_minimum_size.y+0.5)
			
			
	
	await get_tree().create_timer(0.01).timeout.connect(update_messages)
			

# Called when the node enters the scene tree for the first time.
func _ready():
	await update_messages()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	size = $VBoxContainer.size + Vector2(40, 0)
	position.x = get_parent().size.x/2-size.x/2

extends Control



var list_images = []


var volume_icon = preload("res://resources/icons/volume.png")
var mute_icon = preload("res://resources/icons/mute.png")

# Called when the node enters the scene tree for the first time.



func _ready():
	
	#$Label.text = OS.get_data_dir()
	
	var dir = DirAccess.open("res://resources/icons/bgs")
	#print(get_all_files(path))
	#dir = null
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			
			
			if file_name.get_extension() != "import":
				list_images.append("res://resources/icons/bgs/"+file_name)
			file_name = dir.get_next()
	
	_on_new_tab_pressed()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	for i in $Node2D.get_children():
		i.position += Vector2(1,-1)
		if i.position.y <= -200:
			i.position += Vector2(-size.y-400,size.y+400)



func _on_audio_stream_player_2d_finished():
	$AudioStreamPlayer2D.play()
	#$TextureRect.texture = ImageTexture.create_from_image(Image.load_from_file(list_images[randi_range(0,len(list_images)-1)]))

	
	
	

func _on_button_pressed():
	$AudioStreamPlayer2D.playing = not $AudioStreamPlayer2D.playing
	if $AudioStreamPlayer2D.playing:
		$Button.icon = volume_icon
		#$TextureRect.texture = ImageTexture.create_from_image(Image.load_from_file(list_images[randi_range(0,len(list_images)-1)]))

	else:
		$Button.icon = mute_icon
	
	


func _on_label_mouse_entered():
	pass # Replace with function body.


func _on_settings_pressed():
	$SettingsWindow.show()


func _on_close_pressed():
	var AllTabButtons = $/root/Main/V1/HBoxContainer/Panel/MarginContainer/ScrollContainer/MarginContainer2/HBoxContainer/HBoxContainer
	
	if AllTabButtons.get_child_count() == 1:
		if AllTabButtons.get_child(0).ContentFrame == null:
			return
		else:
			pass

	for i in AllTabButtons.get_children():
		if i.disabled:
			if i.ContentFrame == null:
				
				
				i.free()
				AllTabButtons.get_children()[-1].pressed.emit()
			else:
				var err = i.ContentFrame.Close()
				if err == 1:
					pass
				else:
					pass
					
				
				if AllTabButtons.get_child_count() == 1:
					i.reset()
					$/root/Main/V1/ModManager.show()
				else:
					i.free()
					AllTabButtons.get_children()[-1].pressed.emit()
					
					
				
			
			break


func _on_new_tab_pressed():
	var AllTabButtons = $/root/Main/V1/HBoxContainer/Panel/MarginContainer/ScrollContainer/MarginContainer2/HBoxContainer/HBoxContainer
	

	for i in AllTabButtons.get_children():
		if i.disabled:
			i.disabled = false
			if i.ContentFrame != null:
				i.ContentFrame.hide()
			break
					
				
	var c = preload("res://Objects/TabButton_Main.tscn").instantiate()
	c.disabled = true
	AllTabButtons.add_child(c)
	
	$/root/Main/V1/ModManager.show()

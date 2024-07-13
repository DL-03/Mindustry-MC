extends Button


var ModEditor: Node

var RootNode = null
var ContentFrame = null



var contentClass: ContentClass:
	set = _set_contentClass
func _set_contentClass(value):
	contentClass = value
	
	
	if contentClass != null:
		if typeof(contentClass.Data) == TYPE_DICTIONARY:
			if contentClass.FileType == "mod":
				if "displayName" in contentClass.Data:
					NameLabel.real_text = contentClass.Data["displayName"]
				else:
					if "name" in contentClass.Data:
						NameLabel.real_text = contentClass.Data["name"]
					else:
						NameLabel.real_text = "[red]null"
			else:
				if "name" in contentClass.Data:
					NameLabel.real_text = contentClass.Data["name"]
				else:
					NameLabel.real_text = "[red]null"
			
		
	
	if ContentFrame == null:
		ContentFrame = preload("res://Objects/ForEditor/content_frame_rect.tscn").instantiate()
		RootNode.Editors.add_child(ContentFrame)
	#ContentFrame.setPath(Path)
	ContentFrame.contentClass = contentClass
	if contentClass.FileType == "mod":
		if FileAccess.file_exists(ModEditor.ModPath+"icon.png"):
			var image = Image.new()
			image.load(ModEditor.ModPath+"icon.png")
			var t = ImageTexture.new()
		
			var Icon = t.create_from_image(image)

			$HBoxContainer/MarginContainer/TextureRect.texture = Icon
		
	else:
		$HBoxContainer/MarginContainer/TextureRect.texture = ModEditor.get_sprite(get_only_filename(contentClass.Path))
		
	
	RootNode.select_tab(self)

@export var NameLabel: Node

func get_only_filename(path):
	return path.get_file().substr(0, -1+path.get_file().length()-path.get_file().get_extension().length())




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if $HBoxContainer != null:
		custom_minimum_size.x = $HBoxContainer.size.x


func _on_pressed():
	RootNode.select_tab(self)



func _on_h_box_container_resized():
	pass


func _on_Close_pressed():
	if ContentFrame != null:
		ContentFrame.queue_free()
	self.queue_free()

extends TextureRect


var rotator_speed = 80
var conveyor_speed = 1
var conveyor_frame = 0



func _SpriteBank_updated():
	if FileAccess.file_exists(contentClass.Path):
		if contentClass.modClass != null:
			if contentClass.FileType == "mod":
				if FileAccess.file_exists(contentClass.modClass.Path+"/icon.png"):
					var image = Image.new()
					image.load(contentClass.modClass.Path+"/icon.png")
					var t = ImageTexture.new()
				
					var Icon = t.create_from_image(image)

					texture = Icon
			
			else:
				texture = contentClass.modClass.get_sprite(get_only_filename(contentClass.Path))
				$Rotator.texture = contentClass.modClass.get_sprite(get_only_filename(contentClass.Path)+"-rotator")
				$Top.texture = contentClass.modClass.get_sprite(get_only_filename(contentClass.Path)+"-top")
			
		material = material.duplicate()
		material.set_shader_parameter("water_effect", false)
		$Rotator.hide()
		$Top.hide()
		

		if contentClass.FullData != null:
			if typeof(contentClass.FullData) == TYPE_DICTIONARY:
				if contentClass.ContentType == "Drill":
					$Rotator.show()
					$Top.show()
					
					if "drillTime" in contentClass.FullData:
						rotator_speed = 360/(contentClass.FullData["drillTime"]/100)
				if contentClass.ContentType in ["Conveyor", "ArmoredConveyor"]:
					if "speed" in contentClass.FullData:
						conveyor_speed = contentClass.FullData["speed"]
				if contentClass.ContentType == "Floor":
					if "isLiquid" in contentClass.FullData:
						material.set_shader_parameter("water_effect", contentClass.FullData["isLiquid"])





var contentClass: ContentClass:
	set = _set_contentClass

func _set_contentClass(value):
	if contentClass != null:
		contentClass.modClass.SpriteBank_updated.disconnect(_SpriteBank_updated)
	contentClass = value
	if contentClass != null:
		contentClass.modClass.SpriteBank_updated.connect(_SpriteBank_updated)
	
	_SpriteBank_updated()
	



func get_only_filename(path):
	return path.get_file().substr(0, -1+path.get_file().length()-path.get_file().get_extension().length())






func update_conveyor():
	if contentClass != null:
		if contentClass.ContentType in ["Conveyor", "ArmoredConveyor"]:
			if conveyor_frame > 2:
				conveyor_frame = 0
			else:
				conveyor_frame += 1
			
			texture = contentClass.modClass.get_sprite(get_only_filename(contentClass.Path)+"-0-"+str(conveyor_frame))
			
			await get_tree().create_timer((1/((140*conveyor_speed)/3))/8).timeout.connect(update_conveyor)
		

# Called when the node enters the scene tree for the first time.
func _ready():
	await update_conveyor()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	
	if contentClass != null:
		if contentClass.ContentType == "Drill":
			$Rotator.set_rotation_degrees($Rotator.get_rotation_degrees()-(60*delta))
			$Rotator.pivot_offset = $Rotator.size/2
			

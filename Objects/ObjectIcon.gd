extends AspectRatioContainer


var rotator_speed = 80
var conveyor_speed = 1
var conveyor_frame = 0


var ModEditor = null

var Path = "":
	set = _set_Path
var Data = null:
	set = _set_Data
var File = null:
	set = _set_File


func _set_Data(value):
	
	$Main.material = $Main.material.duplicate()
	$Main.material.set_shader_parameter("water_effect", false)
	$Main/Rotator.hide()
	$Top.hide()
	
	Data = value
	if Data != null:
		if typeof(Data) == TYPE_DICTIONARY:
			#print("TRU",Data)
			if "type" in Data:
				if Data["type"] == "Drill":
					$Main/Rotator.show()
					$Top.show()
					
					if "drillTime" in Data:
						rotator_speed = 360/(Data["drillTime"]/100)
				if Data["type"] in ["StackConveyor1","Conveyor"]:
					if "speed" in Data:
						conveyor_speed = Data["speed"]
				if Data["type"] == "Floor":
					if "isLiquid" in Data:
						$Main.material.set_shader_parameter("water_effect", Data["isLiquid"])

	
	
func _set_File(value):
	File = value
	
	
	
	if Path.get_extension() == "json":
		Data = JSON.parse_string(File.get_as_text())
	elif Path.get_extension() == "hjson":
		Data = HJSON.parse_string(File.get_as_text())


func get_only_filename(path):
	return path.get_file().substr(0, -1+path.get_file().length()-path.get_file().get_extension().length())


func _set_Path(_path):
	_path = _path.simplify_path()
	if Path != _path:
		if FileAccess.file_exists(_path):
			Path = _path
			
			if ModEditor != null:
				$Main.texture = ModEditor.get_sprite(get_only_filename(Path))
				$Main/Rotator.texture = ModEditor.get_sprite(get_only_filename(Path)+"-rotator")
				$Top.texture = ModEditor.get_sprite(get_only_filename(Path)+"-top")
			#ContentFrame.setPath(Path)
			File = FileAccess.open(Path, FileAccess.READ)
			
			#RootNode.select_tab(self)



func update_conveyor():
	if Data != null:
		if "type" in Data:
			if Data["type"] in ["StackConveyor1","Conveyor"]:
				if conveyor_frame > 2:
					conveyor_frame = 0
				else:
					conveyor_frame += 1
				
				$Main.texture = ModEditor.get_sprite(get_only_filename(Path)+"-0-"+str(conveyor_frame))
				
				await get_tree().create_timer((1/((140*conveyor_speed)/3))/8).timeout.connect(update_conveyor)
			

# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	
	
	await update_conveyor()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	
	if Data != null:
		if "type" in Data:
			if Data["type"] == "Drill":
				$Main/Rotator.set_rotation_degrees($Main/Rotator.get_rotation_degrees()-(60*delta))
				$Main/Rotator.pivot_offset = $Main/Rotator.size/2
			

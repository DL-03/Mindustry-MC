class_name ContentClass
extends Node



var ModEditor: Node


signal content_loaded
signal content_closed



var Path = "":
	set = _set_Path
var File = null:
	set = _set_File
var Data = null:
	set = _set_Data
var FullData = null

var FileType = ""
var ContentType = ""


func _set_Path(_path):
	if typeof(_path) == TYPE_STRING:
		_path = _path.simplify_path()
		if Path != _path:
			if FileAccess.file_exists(_path):
				Path = _path
				File = FileAccess.open(Path, FileAccess.READ)
				if len(_path.substr(1+len(ModEditor.ModPath.simplify_path())).split("/")) > 1:
					FileType = _path.substr(1+len(ModEditor.ModPath.simplify_path())).split("/")[1]
				#print("SUM:",_path.substr(1+len(ModEditor.ModPath.simplify_path())))
				if _path.substr(1+len(ModEditor.ModPath.simplify_path())) == "mod.json":
					FileType = "mod"
				if _path.substr(1+len(ModEditor.ModPath.simplify_path())) == "mod.hjson":
					FileType = "mod"
				#print(FileType)

func _set_File(value):
	File = value

	if Path.get_extension() == "json":
		Data = JSON.parse_string(File.get_as_text())
		return
	elif Path.get_extension() == "hjson":
		Data = HJSON.parse_string(File.get_as_text())
		return
	File = null

	#ModEditor.ContentBank.erase(self)
	#queue_free()


func _set_Data(value):
	
	Data = value
	if Data != null:
		if typeof(Data) == TYPE_DICTIONARY:
			var _type
			if "type" in Data:
				ContentType = Data["type"]
				_type = Data["type"]
			var example_data = ContentManager.get_content(_type)
			
			
			var DATA = Data
			
			if example_data != null:
				DATA = example_data.duplicate()
				DATA.merge(Data, true)
			FullData = DATA
			content_loaded.emit()
		#else:
			#ModEditor.ContentBank.erase(self)
			#queue_free()
	#else:
		#ModEditor.ContentBank.erase(self)
		#queue_free()
	#if Data == null:
	#	ModEditor.ContentBank.erase(self)
	#	queue_free()
	


func get_only_filename(path):
	return path.get_file().substr(0, -1+path.get_file().length()-path.get_file().get_extension().length())




# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


#DirectoryWatcher

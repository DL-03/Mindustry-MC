class_name ContentClass
extends Node




var modClass: ModClass


signal content_loaded
signal content_closed
signal data_changed

signal file_deleted





func rename_filename(new_name):
	FileOperations.rename(Path, Path.substr(0,len(Path)-len(Path.get_file())).simplify_path() + "/" + new_name + "." + Path.get_extension())
func duplicate_file(new_name):
	FileOperations.Copy(Path, Path.substr(0,len(Path)-len(Path.get_file())).simplify_path() + "/" + new_name + "." + Path.get_extension())
func delete():
	FileOperations.Delete(Path)

var Path = "":
	set = _set_Path
var File = null:
	set = _set_File
var Data = null:
	set = _set_Data
var FullData = null
var DefaultData = null
var WriteData = {}:
	set = _set_WriteData


func _set_WriteData(value):
	WriteData = {}
	
	Data = value
	
	#if FileAccess.file_exists(Path):
	var fileAccess = FileAccess.open(Path,FileAccess.WRITE)
	
	if Path.get_extension() == "json":
		fileAccess.store_string(JSON.stringify(value))
	elif Path.get_extension() == "hjson":
		fileAccess.store_string(HJSON.stringify(value))
	
	fileAccess.close()
	

var FileType = ""
var ContentType = ""


func _set_Path(_path):
	if typeof(_path) == TYPE_STRING:
		_path = _path.simplify_path()
		if Path != _path:
			Path = _path
			if FileAccess.file_exists(_path):
				Path = _path
				
				

				if len(_path.substr(1+len(modClass.Path.simplify_path())).split("/")) > 1:
					FileType = _path.substr(1+len(modClass.Path.simplify_path())).split("/")[1]
				if _path.substr(1+len(modClass.Path.simplify_path())) == "mod.json":
					FileType = "mod"
				if _path.substr(1+len(modClass.Path.simplify_path())) == "mod.hjson":
					FileType = "mod"
				
				
				if FileType == "liquids":
					ContentType = "Liquid"
				elif FileType == "mod":
					ContentType = "mod"
				elif FileType == "items":
					ContentType = "Item"
				File = FileAccess.open(Path, FileAccess.READ)
func create(path, type):
	Path = path
	
	if type in ["Items", "Liquids"]:
		WriteData = {"name":get_only_filename(path)}
	else:
		WriteData = {"name":get_only_filename(path),"type":type}

func _set_File(value):
	File = value

	if Path.get_extension() == "json":
		Data = JSON.parse_string(File.get_as_text())
		File.close()
		return
	elif Path.get_extension() == "hjson":
		Data = HJSON.parse_string(File.get_as_text())
		File.close()
		return
	File.close()
	File = null

	#ModEditor.ContentBank.erase(self)
	#queue_free()


func _set_Data(value):
	
	Data = value
	if Data != null:
		if typeof(Data) == TYPE_DICTIONARY:
			if "type" in Data:
				ContentType = Data["type"]
			
			var DATA = {}

			DefaultData = ContentManager.get_content(ContentType)
			
			
			DATA = Data
			
			if DefaultData != null:
				DATA = DefaultData.duplicate()
				DATA.merge(Data, true)

			FullData = DATA
			data_changed.emit()
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
	file_deleted.connect(func(): queue_free())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


#DirectoryWatcher

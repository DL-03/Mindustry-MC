class_name ContentClass
extends Node


var modClass: ModClass
var has_changes = false    # Если есть изменения > true для архивов


signal content_loaded
signal content_closed
signal data_changed

signal file_deleted


func _ready():
	file_deleted.connect(queue_free)


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


func set_path(path: String):
	path = path.simplify_path()



func _set_WriteData(value):
	WriteData = {}
	
	Data = value
	
	#if FileAccess.file_exists(Path):
	if not DirAccess.dir_exists_absolute( Path.substr(0, len(Path)-len(Path.get_file())) ):
		DirAccess.make_dir_recursive_absolute( Path.substr(0, len(Path)-len(Path.get_file())) )
	var fileAccess = FileAccess.open(Path,FileAccess.WRITE)
	
	if Path.get_extension() == "json":
		fileAccess.store_string(JSON.stringify(value))
	elif Path.get_extension() == "hjson":
		fileAccess.store_string(HJSON.stringify(value))
	
	fileAccess.close()
	

var FileType = ""
var ContentType: ContentCore.ContentType
var ClassType = ""


func _set_Path(_path):
	if typeof(_path) == TYPE_STRING:
		_path = _path.simplify_path()
		if Path != _path:
			Path = _path
			if FileAccess.file_exists(_path):
				Path = _path

				if len(_path.substr(1+len(modClass.Path.simplify_path())).split("/")) > 1:
					FileType = _path.substr(1+len(modClass.Path.simplify_path())).split("/")[1]

				if _path.substr(1+len(modClass.Path)) in ["mod.json", "mod.hjson"]:
					ContentType = ContentCore.ContentType.MOD
					ClassType = "mod"
				elif FileType in ContentCore.ContentTypePath.values():
					ContentType = ContentCore.ContentTypePath.find_key(FileType)
				
				File = FileAccess.open(Path, FileAccess.READ)
func create(path, type, class_type):
	Path = path
	
	WriteData = {"name":get_only_filename(path),"type":class_type}


func _set_File(value):
	File = value

	if Path.get_extension() == "json":
		Data = HJSON.parse_string(File.get_as_text())
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
	if typeof(Data) != TYPE_DICTIONARY:
		Data = {}
	if "type" in Data:
		ClassType = Data["type"]
	
	var DATA = {}

	DefaultData = ContentManager.get_content(ClassType)
	
	
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

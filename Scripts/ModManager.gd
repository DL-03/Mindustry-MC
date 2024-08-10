extends Node



var ModBank = []
var ContentBank = []



func get_all_pathes(path: String, file_ext := "", files := []):
	path = path.simplify_path()
	var dir = DirAccess.open(path)
	#print(dir)
	if dir != null:
		dir.list_dir_begin()

		var file_name = dir.get_next()

		while file_name != "":
			if dir.current_is_dir():
				dir.get_current_dir()
				files = get_all_pathes(dir.get_current_dir()+"/"+file_name, file_ext, files)
				#print(file_name, " ", dir.get_current_dir()+"/"+file_name)
			else:
				if file_ext and file_name.get_extension() != file_ext:
					file_name = dir.get_next()
					continue

				files.append(dir.get_current_dir()+"/"+file_name)
				#print(file_name, " ", dir.get_current_dir()+"/"+file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access %s." % path)

	return files






func test_from_path(_path: String):
	_path = _path.simplify_path()
	
	if FileAccess.file_exists(_path):
		var reader := ZIPReader.new()
		var err := reader.open(_path)
		
		if err != OK:
			return
		else:
			for i in reader.get_files():
				if i.split("/")[-1] in ["mod.json","mod.hjson"]:
					return true
			
	elif DirAccess.dir_exists_absolute(_path):
		var files = get_all_pathes(_path)
		
		for i in files:
			if i.split("/")[-1] in ["mod.json","mod.hjson"]:
				return true
	
	return false

var _ModClass = preload("res://Scripts/ModClass.gd")
func open_from_path(_path: String, local = false):
	_path = _path.simplify_path()
	if test_from_path(_path):
		var t = _ModClass.new()
		t.set_path(_path)
		if not local:
			ModBank.append(t)
		return t
	else:
		return null


func close_mod(_modClass: ModClass):
	ModBank.erase(_modClass)
	
	_modClass.queue_free()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

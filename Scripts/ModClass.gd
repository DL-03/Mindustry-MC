extends Node
class_name ModClass


var Path = ""
var SourcePath = ""
var ModType = ""

var ContentBank = []
var SpriteBank = {}
var ModContentClass = ContentClass.new()




signal ContentBank_added
signal ContentBank_removed
signal ContentBank_updated

signal SpritBank_added
signal SpritBank_removed
signal SpritBank_updated


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



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




func get_sprite(key):
	if key in SpriteBank:
		if FileAccess.file_exists(SpriteBank[key]):
			var image = Image.new()
			image.load(SpriteBank[key])
			var t = ImageTexture.new()
		
			var Icon = t.create_from_image(image)
			return Icon
	return preload("res://resources/icons/error.png")









func set_path(_path: String):
	_path = _path.simplify_path()
	
	if DirAccess.dir_exists_absolute(_path):
		Path = _path
		ModType = "folder"
	elif FileAccess.file_exists(_path):
		ModType = "archive"
		SourcePath = _path
		var red = ZIPReader.new()
		var err := red.open(_path)
		#ModZipPacker.open(path)
		
		if err != OK:
			return PackedByteArray()
		else:
			red.close()
			var p = ProjectSettings.globalize_path("user://Temp/"+str(MinosUUIDGenerator.generate_new_UUID())+_path.get_file().get_basename())
			ArchiveMain.ExtracteToDirectory(SourcePath, p)
			Path = p
			
			#print(ModPath,ModPathZip,p)
	#print("fff",ModPath)
	var reader = get_all_pathes(Path)
	#dir_contents(ModPath)
	#print(reader)
	#print(reader)

	for i in reader:
		if i.split("/")[-1] in ["mod.json","mod.hjson"]:
			Path = i.left(-1*len(i.split("/")[-1])).simplify_path()
			
			ModContentClass.modClass = self
			ModContentClass.Path = i
			
			break
	
	

	var lis = get_all_pathes(Path+"/sprites/")
	for i in lis:
		SpriteBank.merge({i.get_file().substr(0, -1+i.get_file().length()-i.get_file().get_extension().length()): i}, true)
	#print(SpriteDictonary)
	
	first_scan_content()
	
	MessageAPI.info("Modification Inited")
	print("MODS")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func first_scan_content():
	ContentBank = []
	
	revursive_first_scaner_content(Path+"/content/")
	
	var sc = preload("res://Objects/CustomFileWathcer.cs")
	var customFileWathcer = sc.new()
	add_child(customFileWathcer)
	customFileWathcer.OnCreated.connect(_OnCreated)
	customFileWathcer.OnChanged.connect(_OnChanged)
	customFileWathcer.OnRenamed.connect(_OnRenamed)
	customFileWathcer.OnDeleted.connect(_OnDeleted)
	customFileWathcer.setPath(Path+"/content")


func revursive_first_scaner_content(path: String, file_ext := "", files := []):
	path = path.simplify_path()
	var dir = DirAccess.open(path)
	#print(dir)
	if dir != null:
		dir.list_dir_begin()

		var file_name = dir.get_next()

		while file_name != "":
			if dir.current_is_dir():
				dir.get_current_dir()
				revursive_first_scaner_content(dir.get_current_dir()+"/"+file_name, file_ext, files)
				#print(file_name, " ", dir.get_current_dir()+"/"+file_name)
			else:
				if file_ext and file_name.get_extension() != file_ext:
					file_name = dir.get_next()
					continue
				
				var c = ContentClass.new()
				c.modClass = self
				c.Path = dir.get_current_dir()+"/"+file_name
				ContentBank.append(c)
				add_child(c)

				#print(file_name, " ", dir.get_current_dir()+"/"+file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access %s." % path)

	return files



func _OnCreated(file):
	if file.get_extension() in ["json", "hjson"]:
		MessageAPI.debug("Обнаружен новый контент: "+file.get_file())
		
		var c = ContentClass.new()
		c.modClass = self
		c.Path = file
		ContentBank.append(c)
		add_child(c)
		#current_tab_content=current_tab_content


func _OnChanged(file):
	MessageAPI.debug("(Changed): "+str(file))
func _OnRenamed(file, file1):
	if file.get_extension() in ["json", "hjson"]:
		for i in ContentBank:
			if i.Path == file.simplify_path():
				i.Path = file1
				MessageAPI.debug("Контент файл перейменован: "+file.get_file()+" => "+file1.get_file())
func _OnDeleted(file):
	if file.get_extension() in ["json", "hjson"]:
		for i in ContentBank:
			if i.Path == file.simplify_path():
				var s = i
				ContentBank.erase(s)
				
				s.file_deleted.emit()
				MessageAPI.debug("Пропал контент: "+file.get_file())
		#current_tab_content=current_tab_content

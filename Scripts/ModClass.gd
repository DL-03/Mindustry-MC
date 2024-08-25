extends Node
class_name ModClass


var Path = ""
var SourcePath = ""
var ModType = ""

var ContentBank = []
var SpriteBank = {}
var ModContentClass = ContentClass.new()



var closing = false




signal loaded
var is_loaded = false


signal ContentBank_added
signal ContentBank_removed
signal ContentBank_updated

signal SpritBank_added
signal SpritBank_removed
signal SpritBank_updated


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func connect_loaded(function: Callable):
	if is_loaded:
		function.call()
	loaded.connect(function)



func close():
	closing = true
	
	if thread_first_scan != null:
		thread_first_scan.wait_to_finish()
	
	queue_free()


func get_all_files(path: String, file_ext := "", files := [], _max_recursion=99):
	if _max_recursion <= 0:
		return files
	else:
		var dir = DirAccess.open(path)
		#print(dir)
		if dir != null:
			dir.list_dir_begin()

			var file_name = dir.get_next()

			while file_name != "":
				if dir.current_is_dir():
					dir.get_current_dir()
					files = get_all_files(dir.get_current_dir()+"/"+file_name, file_ext, files,_max_recursion-1)
					#print(file_name, " ", dir.get_current_dir()+"/"+file_name)
				else:
					if file_ext and file_name.get_extension() != file_ext:
						file_name = dir.get_next()
						continue

					files.append(file_name)

				file_name = dir.get_next()
		else:
			print("An error occurred when trying to access %s." % path)

	return files




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
	
	print("[ModClass][set_path]: Start")
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
			

	var reader = get_all_files(Path, "", [], 1)
	
	
	
	for i in reader:
		
		if i.get_file() in ["mod.json","mod.hjson"]:
			Path = Path.path_join(i).left(len(Path.path_join(i))-len(i.get_file())).simplify_path()
			
			ModContentClass.modClass = self
			ModContentClass.Path = Path.path_join(i)
			
			print("[ModClass][set_path][ModContentClass]: Loaded")
			print("[ModClass][set_path][ModContentClass][Path]:" + Path)
			
			break
	
	

	var lis = get_all_pathes(Path.path_join("sprites"))
	for i in lis:
		SpriteBank.merge({i.get_file().substr(0, -1+i.get_file().length()-i.get_file().get_extension().length()): i}, true)
	#print(SpriteDictonary)
	
	first_scan_content()
	
	print("[ModClass][set_path]: Loaded")

func get_mod_icon():
	
	var image = Image.new()
	if FileAccess.file_exists(Path.path_join("icon.png")):
		image.load(Path.path_join("icon.png"))
	else:
		image.load("res://resources/icons/noneMod.png")
	var t = ImageTexture.new()

	var Icon = t.create_from_image(image)

	return Icon

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

var thread_first_scan

func first_scan_content():
	ContentBank = []
	
	if not DirAccess.dir_exists_absolute( Path.path_join("content") ):
		DirAccess.make_dir_recursive_absolute( Path.path_join("content") )
	
	#revursive_first_scaner_content(Path.path_join("content"))
	
	thread_first_scan = Thread.new()
	thread_first_scan.start(revursive_first_scaner_content.bind(Path.path_join("content")),Thread.PRIORITY_HIGH)
	
	
	
	var sc = preload("res://Objects/CustomFileWathcer.cs")
	var customFileWathcer = sc.new()
	add_child(customFileWathcer)
	customFileWathcer.OnCreated.connect(_OnCreated)
	customFileWathcer.OnChanged.connect(_OnChanged)
	customFileWathcer.OnRenamed.connect(_OnRenamed)
	customFileWathcer.OnDeleted.connect(_OnDeleted)
	customFileWathcer.setPath(Path.path_join("content/"))






func revursive_first_scaner_content(path: String, file_ext := "", files := [], origin=false):
	if closing:
		return
	path = path.simplify_path()
	var dir = DirAccess.open(path)
	#print(dir)
	if dir != null:
		dir.list_dir_begin()

		var file_name = dir.get_next()

		while file_name != "":
			if closing:
				return
			
			if dir.current_is_dir():
				dir.get_current_dir()
				revursive_first_scaner_content(dir.get_current_dir()+"/"+file_name, file_ext, files, true)
				#print(file_name, " ", dir.get_current_dir()+"/"+file_name)
			else:
				if file_ext and file_name.get_extension() != file_ext:
					file_name = dir.get_next()
					continue
				
				
				import_content_from_path(dir.get_current_dir().path_join(file_name))

				#print(file_name, " ", dir.get_current_dir()+"/"+file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access %s." % path)
	
	if not origin:
		is_loaded = true
		loaded.emit()
	
	return files

var _modClass = self

func import_content_from_path(path: String):
	path = path.simplify_path()
	if path.get_extension().to_lower() in ["json", "hjson"]:
		for i in ContentBank:
			if i.Path == path:
				return

		
		var c = ContentClass.new()
		c.modClass = _modClass
		c.Path = path
		ContentBank.append(c)
		add_child(c)
		
		ContentBank_added.emit(c)
		
		return c

func test_content_from_path(path: String):
	path = path.simplify_path()
	if path.to_lower() in ["json", "hjson"]:
		if FileAccess.file_exists(path):
			return true
	return false

func unload_content(contentClass: ContentClass):
	if contentClass != null:
		contentClass.close()



func _OnCreated(path: String):
	import_content_from_path(path)


func _OnChanged(file):
	pass
func _OnRenamed(file, file1):
	file = file.simplify_path()
	file1 = file1.simplify_path()
	if file.to_lower() in ["json", "hjson"]:
		for i in ContentBank:
			if i.Path == file:
				i.Path = file1
				MessageAPI.debug("Контент файл перейменован: "+file.get_file()+" => "+file1.get_file())
func _OnDeleted(file):
	file = file.simplify_path()
	if file.to_lower() in ["json", "hjson"]:
		for i in ContentBank:
			if i.Path == file:
				var s = i
				ContentBank.erase(s)
				
				s.file_deleted.emit()
				MessageAPI.debug("Пропал контент: "+file.get_file())
		#current_tab_content=current_tab_content

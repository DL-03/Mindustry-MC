extends Node
class_name ModClass

const CONTENT_SCAN_YIELD_INTERVAL := 64


var Path = ""
var SourcePath = ""
var ModType = ""
var TempDirectory := ""

var ContentBank = []
var _content_by_path: Dictionary = {}
var SpriteBank = {}
var ModContentClass = ContentClass.new()



var closing = false
var scan_in_progress = false

#var changes = []
var has_changes = false   # Если хоть что-то изменено в моде > true для ахривов


signal loaded
var is_loaded = false


signal ContentBank_added
signal ContentBank_removed
signal ContentBank_updated

signal SpriteBank_added
signal SpriteBank_removed
signal SpriteBank_updated


# Called when the node enters the scene tree for the first time.
func connect_loaded(function: Callable):
	if is_loaded:
		function.call()
		return
	loaded.connect(function)



func close():
	closing = true
	queue_free()


func _exit_tree() -> void:
	if not TempDirectory.is_empty():
		ModManager.remove_archive_temp_directory(TempDirectory)
		TempDirectory = ""


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
					files = get_all_files(dir.get_current_dir().path_join(file_name), file_ext, files,_max_recursion-1)
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
			var er = image.load(SpriteBank[key])
			if er == OK:
				return ImageTexture.new().create_from_image(image)
			else:
				image.free()
	return preload("uid://dd3tc3t6hht75")

func get_mod_icon():
	if FileAccess.file_exists(Path.path_join("icon.png")):
		var image = Image.new()
		var er = image.load(Path.path_join("icon.png"))
		if er == OK:
			return ImageTexture.new().create_from_image(image)
		else:
			image.free()
	return preload("uid://df4ipu6fwojc6")



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
		if err != OK:
			push_error("Could not open mod archive: %s" % _path)
			return

		var temp_root := ProjectSettings.globalize_path("user://Temp/ModArchives").simplify_path()
		TempDirectory = temp_root.path_join(
			"%d-%s" % [OS.get_process_id(), MinosUUIDGenerator.generate_new_UUID()]
		)
		err = DirAccess.make_dir_recursive_absolute(TempDirectory)
		if err != OK:
			red.close()
			push_error("Could not create archive working directory: %s" % TempDirectory)
			TempDirectory = ""
			return

		var extract_path := TempDirectory.path_join("extracted")
		err = DirAccess.make_dir_recursive_absolute(extract_path)
		var extracted: bool = err == OK and ArchiveMain.ExtracteToDirectory(SourcePath, extract_path)
		if not extracted:
			red.close()
			ModManager.remove_archive_temp_directory(TempDirectory)
			TempDirectory = ""
			push_error("Could not extract mod archive: %s" % _path)
			return

		Path = extract_path
		for archive_path in red.get_files():
			if archive_path.get_file() not in ["mod.json", "mod.hjson"]:
				continue

			var manifest_directory := archive_path.get_base_dir()
			var source_directory := extract_path
			if not manifest_directory.is_empty() and manifest_directory != ".":
				source_directory = extract_path.path_join(manifest_directory)

			var mod_directory := TempDirectory.path_join("mod")
			err = DirAccess.rename_absolute(source_directory, mod_directory)
			if err == OK:
				Path = mod_directory
			else:
				push_error("Could not prepare extracted mod directory: %s" % source_directory)
			break
		red.close()

	var reader = get_all_files(Path, "", [], 1)
	
	print("[reader]:" + str(reader))
		
	
	for i in reader:
		if i.get_file() in ["mod.json","mod.hjson"]:
			Path = Path.path_join(i.replace(i.get_file(), "")).simplify_path()
			
			
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



func first_scan_content():
	if scan_in_progress:
		return
	ContentBank = []
	_content_by_path.clear()
	is_loaded = false
	
	if not DirAccess.dir_exists_absolute( Path.path_join("content") ):
		DirAccess.make_dir_recursive_absolute( Path.path_join("content") )
	
	scan_in_progress = true
	call_deferred("_scan_content_directory", Path.path_join("content"))
	
	var customFileWathcer = CustomFileWatcher.new()
	add_child(customFileWathcer)
	customFileWathcer.OnCreated.connect(_OnCreated)
	customFileWathcer.OnChanged.connect(_OnChanged)
	customFileWathcer.OnRenamed.connect(_OnRenamed)
	customFileWathcer.OnDeleted.connect(_OnDeleted)
	customFileWathcer.setPath(Path)


func _scan_content_directory(root_path: String) -> void:
	var directories: Array[String] = [root_path]
	var scanned_entries := 0

	while not directories.is_empty():
		if closing:
			return

		var directory_path: String = directories.pop_back()
		var dir := DirAccess.open(directory_path)
		if dir == null:
			push_warning("Could not scan mod content directory: %s" % directory_path)
			continue

		dir.list_dir_begin()
		var file_name := dir.get_next()
		while not file_name.is_empty():
			if closing:
				dir.list_dir_end()
				return

			if dir.current_is_dir():
				if file_name != "." and file_name != "..":
					directories.append(directory_path.path_join(file_name))
			elif file_name.get_extension().to_lower() in ["json", "hjson"]:
				import_content_from_path(directory_path.path_join(file_name))

			scanned_entries += 1
			if scanned_entries % CONTENT_SCAN_YIELD_INTERVAL == 0:
				await get_tree().process_frame
				if closing:
					dir.list_dir_end()
					return

			file_name = dir.get_next()

		dir.list_dir_end()

	scan_in_progress = false
	is_loaded = true
	loaded.emit()

var _modClass = self

var modClass = self



func import_content_from_path(path: String):
	path = path.simplify_path()
	if path.get_extension().to_lower() in ["json", "hjson"]:
		if _content_by_path.has(path):
			return

		var c = ContentClass.new()
		c.modClass = _modClass
		c.Path = path
		ContentBank.append(c)
		_content_by_path[path] = c
		modClass.add_child(c)
		
		ContentBank_added.emit(c)
		
		return c


func create_content(path: String, content_type: ContentCore.ContentType, class_type="") -> ContentClass:
	path = path.simplify_path()
	if _content_by_path.has(path):
		return _content_by_path[path]

	var content_class := ContentClass.new()
	content_class.modClass = self
	var relative_path := path.trim_prefix(Path.path_join("content") + "/")
	var path_parts := relative_path.split("/")
	if path_parts.size() > 1:
		content_class.FileType = path_parts[0]
	content_class.ContentType = content_type
	content_class.create(path, content_type, class_type)
	ContentBank.append(content_class)
	_content_by_path[path] = content_class
	add_child(content_class)
	ContentBank_added.emit(content_class)
	return content_class


func test_content_from_path(path: String):
	path = path.simplify_path()
	if path.get_extension().to_lower() in ["json", "hjson"]:
		if FileAccess.file_exists(path):
			return true
	return false

func unload_content(contentClass: ContentClass):
	if contentClass != null:
		contentClass.close()


func _is_content_file(path: String) -> bool:
	var content_directory := Path.path_join("content") + "/"
	return path.simplify_path().begins_with(content_directory) \
		and path.get_extension().to_lower() in ["json", "hjson"]


func _remove_content_file(path: String) -> void:
	var content_class: ContentClass = _content_by_path.get(path)
	if content_class == null:
		return

	_content_by_path.erase(path)
	ContentBank.erase(content_class)
	content_class.file_deleted.emit()



func _OnCreated(path: String):
	path = path.simplify_path()
	if _is_content_file(path):
		import_content_from_path(path)
	elif path.simplify_path().replace(Path, "").simplify_path().split("/", false)[0] == "sprites":
		SpriteBank.merge({path.get_file().substr(0, -1+path.get_file().length()-path.get_file().get_extension().length()): path}, true)
		SpriteBank_updated.emit()
	
	print_rich("[color=green][_OnCreated][/color]: ",path.simplify_path().replace(Path, "").simplify_path())
	#import_content_from_path(path)


func _OnChanged(path: String):
	path = path.simplify_path()
	
	if path.replace(Path, "").simplify_path().split("/", false)[0] == "sprites":
		#SpriteBank.merge({path.get_file().substr(0, -1+path.get_file().length()-path.get_file().get_extension().length()): path}, true)
		#SpriteBank_updated.emit()
		pass
	
	print_rich("[color=blue][_OnChanged][/color]: ",path.simplify_path().replace(Path, "").simplify_path())
	
func _OnRenamed(path: String, new_path: String):
	path = path.simplify_path()
	new_path = new_path.simplify_path()
	
	var old_is_content := _is_content_file(path)
	var new_is_content := _is_content_file(new_path)
	if old_is_content and new_is_content:
		var content_class: ContentClass = _content_by_path.get(path)
		if content_class != null:
			_content_by_path.erase(path)
			content_class.Path = new_path
			_content_by_path[new_path] = content_class
			Notifications.debug("Контент файл перейменован: "+path.get_file()+" => "+new_path.get_file())
	elif old_is_content:
		_remove_content_file(path)
	elif new_is_content:
		import_content_from_path(new_path)

	if path.replace(Path, "").simplify_path().split("/", false)[0] == "sprites":
		SpriteBank.erase(path.get_file().substr(0, -1+path.get_file().length()-path.get_file().get_extension().length()))
		
		if new_path.replace(Path, "").simplify_path().split("/", false)[0] == "sprites":
			SpriteBank.merge({new_path.get_file().substr(0, -1+new_path.get_file().length()-new_path.get_file().get_extension().length()): new_path}, true)
		SpriteBank_updated.emit()
	
	print_rich("[color=yellow][_OnRenamed][/color]: ",path.simplify_path().replace(Path, "").simplify_path(), " => ", new_path.simplify_path().replace(Path, "").simplify_path())
	
func _OnDeleted(path: String):
	path = path.simplify_path()
	
	if _is_content_file(path):
		_remove_content_file(path)
		Notifications.debug("Пропал контент: "+path.get_file())
	elif path.replace(Path, "").simplify_path().split("/", false)[0] == "sprites":
		SpriteBank.erase(path.get_file().substr(0, -1+path.get_file().length()-path.get_file().get_extension().length()))

		SpriteBank_updated.emit()
		
	print_rich("[color=red][_OnDeleted][/color]: ",path.simplify_path().replace(Path, "").simplify_path())

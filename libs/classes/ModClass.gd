extends Node
class_name ModClass

const SCAN_FRAME_BUDGET_USEC := 4000


var Path = ""
var SourcePath = ""
var ModType = ""
var TempDirectory := ""

var ContentBank = []
var _content_by_path: Dictionary = {}
var SpriteBank = {}
var _sprite_texture_cache: Dictionary[String, Texture2D] = {}
var _mod_icon_texture: Texture2D
var _file_watcher: Node
var _sprite_scan_revision := 0
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
	if closing:
		return
	closing = true
	_release_cached_resources()
	queue_free()


func _exit_tree() -> void:
	closing = true
	_release_cached_resources()
	if is_instance_valid(ModContentClass) and ModContentClass.get_parent() == null:
		ModContentClass.free()
	ModContentClass = null


func _release_cached_resources() -> void:
	if is_instance_valid(_file_watcher):
		_file_watcher.StopWatching()
	_sprite_scan_revision += 1
	_sprite_texture_cache.clear()
	_mod_icon_texture = null
	SpriteBank.clear()
	_content_by_path.clear()
	for content_class: ContentClass in ContentBank:
		if is_instance_valid(content_class):
			content_class.release_data()
	ContentBank.clear()
	if is_instance_valid(ModContentClass):
		ModContentClass.release_data()
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
	var directories: Array[String] = [path.simplify_path()]
	while not directories.is_empty():
		var directory_path: String = directories.pop_back()
		var dir := DirAccess.open(directory_path)
		if dir == null:
			continue

		dir.list_dir_begin()
		var file_name := dir.get_next()
		while not file_name.is_empty():
			if dir.current_is_dir():
				if file_name not in [".", ".."]:
					directories.append(directory_path.path_join(file_name))
			elif file_ext.is_empty() or file_name.get_extension().to_lower() == file_ext.to_lower():
				files.append(directory_path.path_join(file_name))
			file_name = dir.get_next()
		dir.list_dir_end()
	return files


func get_sprite(key: String) -> Texture2D:
	if _sprite_texture_cache.has(key) and is_instance_valid(_sprite_texture_cache[key]):
		return _sprite_texture_cache[key]
	if SpriteBank.has(key) and FileAccess.file_exists(SpriteBank[key]):
		var image := Image.new()
		var error := image.load(SpriteBank[key])
		if error == OK:
			var texture := ImageTexture.create_from_image(image)
			_sprite_texture_cache[key] = texture
			return texture
		push_warning("Could not load sprite %s: %s" % [SpriteBank[key], error_string(error)])
	return preload("uid://dd3tc3t6hht75")


func get_mod_icon() -> Texture2D:
	if is_instance_valid(_mod_icon_texture):
		return _mod_icon_texture

	var icon_path := Path.path_join("icon.png")
	if FileAccess.file_exists(icon_path):
		var image := Image.new()
		var error := image.load(icon_path)
		if error == OK:
			_mod_icon_texture = ImageTexture.create_from_image(image)
			return _mod_icon_texture
		push_warning("Could not load mod icon %s: %s" % [icon_path, error_string(error)])
	return preload("uid://df4ipu6fwojc6")



func set_path(_path: String):
	_path = _path.simplify_path()
	SpriteBank.clear()
	_sprite_texture_cache.clear()
	_mod_icon_texture = null

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
	for i in reader:
		if i.get_file() in ["mod.json","mod.hjson"]:
			Path = Path.path_join(i.replace(i.get_file(), "")).simplify_path()
			
			
			ModContentClass.modClass = self
			ModContentClass.Path = Path.path_join(i)
			
			break

	call_deferred("_scan_sprite_directory", Path.path_join("sprites"))
	
	first_scan_content()


func _scan_sprite_directory(root_path: String) -> void:
	_sprite_scan_revision += 1
	var revision := _sprite_scan_revision
	var directories: Array[String] = [root_path]
	var frame_start_usec := Time.get_ticks_usec()

	while not directories.is_empty():
		if closing or revision != _sprite_scan_revision:
			return

		var directory_path: String = directories.pop_back()
		var dir := DirAccess.open(directory_path)
		if dir == null:
			continue

		dir.list_dir_begin()
		var file_name := dir.get_next()
		while not file_name.is_empty():
			if dir.current_is_dir():
				if file_name not in [".", ".."]:
					directories.append(directory_path.path_join(file_name))
			else:
				var sprite_path := directory_path.path_join(file_name)
				if FileAccess.file_exists(sprite_path):
					_set_sprite_path(sprite_path)

			if Time.get_ticks_usec() - frame_start_usec >= SCAN_FRAME_BUDGET_USEC:
				await get_tree().process_frame
				frame_start_usec = Time.get_ticks_usec()
				if closing or revision != _sprite_scan_revision:
					dir.list_dir_end()
					return

			file_name = dir.get_next()
		dir.list_dir_end()

	SpriteBank_updated.emit()



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
	
	if not is_instance_valid(_file_watcher):
		_file_watcher = CustomFileWatcher.new()
		add_child(_file_watcher)
		_file_watcher.OnCreated.connect(_OnCreated)
		_file_watcher.OnChanged.connect(_OnChanged)
		_file_watcher.OnRenamed.connect(_OnRenamed)
		_file_watcher.OnDeleted.connect(_OnDeleted)
	_file_watcher.setPath(Path)


func _scan_content_directory(root_path: String) -> void:
	var directories: Array[String] = [root_path]
	var frame_start_usec := Time.get_ticks_usec()

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

			if Time.get_ticks_usec() - frame_start_usec >= SCAN_FRAME_BUDGET_USEC:
				await get_tree().process_frame
				frame_start_usec = Time.get_ticks_usec()
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
	if not content_class.create(path, content_type, class_type):
		content_class.free()
		return null
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


func _is_sprite_path(path: String) -> bool:
	var relative_path := path.simplify_path().trim_prefix(Path.simplify_path().trim_suffix("/") + "/")
	return relative_path == "sprites" or relative_path.begins_with("sprites/")


func _sprite_key(path: String) -> String:
	return path.get_file().get_basename()


func _set_sprite_path(path: String) -> void:
	var key := _sprite_key(path)
	SpriteBank[key] = path.simplify_path()
	_sprite_texture_cache.erase(key)


func _invalidate_mod_icon(path: String) -> bool:
	if path.simplify_path() != Path.path_join("icon.png").simplify_path():
		return false
	_mod_icon_texture = null
	return true


func _remove_content_file(path: String) -> void:
	var content_class: ContentClass = _content_by_path.get(path)
	if content_class == null:
		return

	_content_by_path.erase(path)
	ContentBank.erase(content_class)
	content_class.file_deleted.emit()



func _OnCreated(path: String):
	if closing:
		return
	path = path.simplify_path()
	if _is_content_file(path):
		import_content_from_path(path)
	elif _is_sprite_path(path):
		_set_sprite_path(path)
		SpriteBank_updated.emit()
	elif _invalidate_mod_icon(path):
		SpriteBank_updated.emit()


func _OnChanged(path: String):
	if closing:
		return
	path = path.simplify_path()
	if _is_sprite_path(path) and FileAccess.file_exists(path):
		_set_sprite_path(path)
		SpriteBank_updated.emit()
	elif _invalidate_mod_icon(path):
		SpriteBank_updated.emit()


func _OnRenamed(path: String, new_path: String):
	if closing:
		return
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

	var sprite_bank_changed := false
	if _is_sprite_path(path):
		var old_key := _sprite_key(path)
		SpriteBank.erase(old_key)
		_sprite_texture_cache.erase(old_key)
		sprite_bank_changed = true
	if _is_sprite_path(new_path):
		_set_sprite_path(new_path)
		sprite_bank_changed = true
	var mod_icon_changed := _invalidate_mod_icon(path)
	if _invalidate_mod_icon(new_path):
		mod_icon_changed = true
	if mod_icon_changed:
		sprite_bank_changed = true
	if sprite_bank_changed:
		SpriteBank_updated.emit()


func _OnDeleted(path: String):
	if closing:
		return
	path = path.simplify_path()
	if _is_content_file(path):
		_remove_content_file(path)
		Notifications.debug("Пропал контент: "+path.get_file())
	elif _is_sprite_path(path):
		var key := _sprite_key(path)
		SpriteBank.erase(key)
		_sprite_texture_cache.erase(key)
		SpriteBank_updated.emit()
	elif _invalidate_mod_icon(path):
		SpriteBank_updated.emit()

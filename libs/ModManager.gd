extends Node


var ModBank = []
var ContentBank = []

const ARCHIVE_TEMP_ROOT := "user://Temp/ModArchives"
const LEGACY_ARCHIVE_TEMP_NAME := "^[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}.*$"


func _ready() -> void:
	call_deferred("_cleanup_abandoned_archive_directories")


func _cleanup_abandoned_archive_directories() -> void:
	var temp_root := ProjectSettings.globalize_path(ARCHIVE_TEMP_ROOT).simplify_path()
	var err := DirAccess.make_dir_recursive_absolute(temp_root)
	if err != OK:
		push_warning("Could not access archive temporary directory: %s" % temp_root)
		return

	_cleanup_legacy_archive_directories()

	for directory_name in DirAccess.get_directories_at(temp_root):
		var process_id_text := directory_name.get_slice("-", 0)
		if not process_id_text.is_valid_int():
			continue
		if ArchiveMain.IsProcessRunning(process_id_text.to_int()):
			continue
		remove_archive_temp_directory(temp_root.path_join(directory_name))


func _cleanup_legacy_archive_directories() -> void:
	var pattern := RegEx.new()
	var err := pattern.compile(LEGACY_ARCHIVE_TEMP_NAME)
	if err != OK:
		push_warning("Could not compile legacy archive directory pattern")
		return

	var temp_root := ProjectSettings.globalize_path("user://Temp").simplify_path()
	for directory_name in DirAccess.get_directories_at(temp_root):
		if pattern.search(directory_name) == null:
			continue

		var path := temp_root.path_join(directory_name)
		if not ArchiveMain.RemoveDirectory(path):
			push_warning("Could not remove legacy archive temporary directory: %s" % path)


func remove_archive_temp_directory(path: String) -> void:
	var temp_root := ProjectSettings.globalize_path(ARCHIVE_TEMP_ROOT).simplify_path()
	path = path.simplify_path()
	if path.get_base_dir() != temp_root or not DirAccess.dir_exists_absolute(path):
		return

	if not ArchiveMain.RemoveDirectory(path):
		push_warning("Could not remove archive temporary directory: %s" % path)


func _find_archive_file(reader: ZIPReader, file_names: Array[String]) -> String:
	var archive_files := reader.get_files()
	for file_name in file_names:
		for archive_path in archive_files:
			if archive_path.get_file() == file_name:
				return archive_path
	return ""


func _find_manifest_file(directory_path: String) -> String:
	var files := DirAccess.get_files_at(directory_path)
	if "mod.json" in files:
		return "mod.json"
	if "mod.hjson" in files:
		return "mod.hjson"
	return ""


func test_from_path(_path: String) -> bool:
	_path = _path.simplify_path()

	if FileAccess.file_exists(_path):
		var reader := ZIPReader.new()
		var err := reader.open(_path)
		if err != OK:
			return false

		var is_mod := not _find_archive_file(reader, ["mod.json", "mod.hjson"]).is_empty()
		reader.close()
		return is_mod

	if DirAccess.dir_exists_absolute(_path):
		return not _find_manifest_file(_path).is_empty()

	return false


func is_mod_directory(path: String) -> bool:
	path = path.simplify_path()
	return DirAccess.dir_exists_absolute(path) and not _find_manifest_file(path).is_empty()


func is_archive_candidate(path: String) -> bool:
	path = path.simplify_path()
	if not FileAccess.file_exists(path):
		return false
	if path.get_extension().to_lower() in ["zip", "jar"]:
		return true

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var signature := file.get_buffer(4)
	file.close()
	return signature == PackedByteArray([0x50, 0x4b, 0x03, 0x04])


func open_from_path(_path: String, local = false):
	_path = _path.simplify_path()
	if not test_from_path(_path):
		return null

	var mod_class = ModClass.new()
	add_child(mod_class)
	mod_class.set_path(_path)
	if not local:
		ModBank.append(mod_class)
	return mod_class


func close_mod(_modClass: ModClass):
	if _modClass == null:
		return
	ModBank.erase(_modClass)
	_modClass.close()


func _load_image_texture(image: Image, source_path: String) -> Texture2D:
	if image.is_empty():
		push_warning("Could not load mod image: %s" % source_path)
		return null
	return ImageTexture.create_from_image(image)


func _load_archive_icon(reader: ZIPReader, archive_path: String) -> Texture2D:
	var image := Image.new()
	var image_bytes := reader.read_file(archive_path)
	var extension := archive_path.get_extension().to_lower()
	var err := ERR_FILE_UNRECOGNIZED
	if extension in ["jpg", "jpeg"]:
		err = image.load_jpg_from_buffer(image_bytes)
	elif extension == "png":
		err = image.load_png_from_buffer(image_bytes)

	if err != OK:
		push_warning("Could not load mod icon from archive: %s" % archive_path)
		return null
	return _load_image_texture(image, archive_path)


func get_icon_from_path(_path: String) -> Texture2D:
	_path = _path.simplify_path()
	var icon: Texture2D

	if FileAccess.file_exists(_path):
		var reader := ZIPReader.new()
		var err := reader.open(_path)
		if err == OK:
			var icon_path := _find_archive_file(reader, ["icon.png", "icon.jpg", "icon.jpeg"])
			if not icon_path.is_empty():
				icon = _load_archive_icon(reader, icon_path)
			reader.close()
		else:
			push_warning("Could not open mod archive for icon: %s" % _path)
	elif DirAccess.dir_exists_absolute(_path):
		for icon_name in ["icon.png", "icon.jpg", "icon.jpeg"]:
			var icon_path := _path.path_join(icon_name)
			if FileAccess.file_exists(icon_path):
				var image := Image.new()
				var err := image.load(icon_path)
				if err == OK:
					icon = _load_image_texture(image, icon_path)
				else:
					push_warning("Could not load mod icon: %s" % icon_path)
				break

	if icon != null:
		return icon
	return load("res://resources/icons/noneMod.png")


func _parse_mod_data(data: String, extension: String, source_path: String) -> Variant:
	if extension == "json":
		var json := JSON.new()
		var err := json.parse(data)
		if err != OK:
			push_warning("Could not parse mod manifest %s at line %d: %s" % [
				source_path,
				json.get_error_line(),
				json.get_error_message()
			])
			return null
		return json.data
	if extension == "hjson":
		var parsed_data: Variant = HJSON.parse_string(data)
		if parsed_data == null:
			push_warning("Could not parse mod manifest: %s" % source_path)
		return parsed_data
	return null


func get_mod_preview(path: String) -> Dictionary:
	path = path.simplify_path()
	if DirAccess.dir_exists_absolute(path):
		var files := DirAccess.get_files_at(path)
		var manifest_name := "mod.json" if "mod.json" in files else "mod.hjson"
		var has_manifest := manifest_name in files
		var data: Variant = null
		if has_manifest:
			var manifest_path := path.path_join(manifest_name)
			var manifest := FileAccess.open(manifest_path, FileAccess.READ)
			if manifest == null:
				push_warning("Could not read mod manifest: %s" % manifest_path)
			else:
				data = _parse_mod_data(
					manifest.get_as_text(),
					manifest_name.get_extension().to_lower(),
					manifest_path
				)
				manifest.close()

		var icon: Texture2D
		for icon_name in ["icon.png", "icon.jpg", "icon.jpeg"]:
			if icon_name not in files:
				continue
			var icon_path := path.path_join(icon_name)
			var image := Image.new()
			var err := image.load(icon_path)
			if err == OK:
				icon = _load_image_texture(image, icon_path)
			else:
				push_warning("Could not load mod icon: %s" % icon_path)
			break
		if icon == null:
			icon = load("res://resources/icons/noneMod.png")
		return {"is_mod": has_manifest, "data": data, "icon": icon}

	if not FileAccess.file_exists(path):
		return {"is_mod": false, "data": null, "icon": load("res://resources/icons/noneMod.png")}

	var reader := ZIPReader.new()
	var err := reader.open(path)
	if err != OK:
		push_warning("Could not open mod archive: %s" % path)
		return {"is_mod": false, "data": null, "icon": load("res://resources/icons/noneMod.png")}

	var manifest_json := ""
	var manifest_hjson := ""
	var icon_png := ""
	var icon_jpg := ""
	var icon_jpeg := ""
	for archive_path in reader.get_files():
		match archive_path.get_file().to_lower():
			"mod.json":
				manifest_json = archive_path
			"mod.hjson":
				manifest_hjson = archive_path
			"icon.png":
				icon_png = archive_path
			"icon.jpg":
				icon_jpg = archive_path
			"icon.jpeg":
				icon_jpeg = archive_path

	var manifest_path := manifest_json if not manifest_json.is_empty() else manifest_hjson
	var mod_data: Variant = null
	if not manifest_path.is_empty():
		mod_data = _parse_mod_data(
			reader.read_file(manifest_path).get_string_from_utf8(),
			manifest_path.get_extension().to_lower(),
			"%s:%s" % [path, manifest_path]
		)

	var icon_path := icon_png
	if icon_path.is_empty():
		icon_path = icon_jpg if not icon_jpg.is_empty() else icon_jpeg
	var icon: Texture2D
	if not icon_path.is_empty():
		icon = _load_archive_icon(reader, icon_path)
	reader.close()
	if icon == null:
		icon = load("res://resources/icons/noneMod.png")
	return {
		"is_mod": not manifest_path.is_empty(),
		"data": mod_data,
		"icon": icon
	}


func get_mod_data_from_path(_path: String) -> Variant:
	_path = _path.simplify_path()

	if FileAccess.file_exists(_path):
		var reader := ZIPReader.new()
		var err := reader.open(_path)
		if err != OK:
			push_warning("Could not open mod archive: %s" % _path)
			return null

		var manifest_path := _find_archive_file(reader, ["mod.json", "mod.hjson"])
		var mod_data: Variant = null
		if not manifest_path.is_empty():
			mod_data = _parse_mod_data(
				reader.read_file(manifest_path).get_string_from_utf8(),
				manifest_path.get_extension().to_lower(),
				"%s:%s" % [_path, manifest_path]
			)
		reader.close()
		return mod_data

	if DirAccess.dir_exists_absolute(_path):
		var manifest_name := _find_manifest_file(_path)
		if manifest_name.is_empty():
			return null

		var manifest_path := _path.path_join(manifest_name)
		var file := FileAccess.open(manifest_path, FileAccess.READ)
		if file == null:
			push_warning("Could not read mod manifest: %s" % manifest_path)
			return null

		var mod_data: Variant = _parse_mod_data(
			file.get_as_text(),
			manifest_name.get_extension().to_lower(),
			manifest_path
		)
		file.close()
		return mod_data

	return null

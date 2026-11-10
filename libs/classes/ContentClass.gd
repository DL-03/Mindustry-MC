class_name ContentClass
extends Node

var modClass: ModClass
var has_changes := false

signal content_loaded
signal content_closed
signal data_changed
signal file_deleted

var Path := "":
	set = _set_Path
var Data: Dictionary = {}:
	set = _set_Data
var FullData: Dictionary:
	get = _get_FullData
var DefaultData: Variant
var WriteData: Dictionary = {}
var _full_data_cache: Dictionary = {}
var _full_data_valid := false
var _source_text := ""

var FileType := ""
var ContentType: ContentCore.ContentType
var ClassType := ""
var _releasing_data := false


func _ready() -> void:
	file_deleted.connect(queue_free)


func close() -> void:
	content_closed.emit()
	queue_free()


func release_data() -> void:
	_releasing_data = true
	Data = {}
	DefaultData = null
	WriteData.clear()
	_full_data_cache.clear()
	_full_data_valid = true
	modClass = null
	Path = ""
	FileType = ""
	ClassType = ""


func rename_filename(new_name: String) -> void:
	FileOperations.rename(
		Path,
		Path.get_base_dir().path_join(new_name + "." + Path.get_extension())
	)


func duplicate_file(new_name: String) -> void:
	FileOperations.Copy(
		Path,
		Path.get_base_dir().path_join(new_name + "." + Path.get_extension())
	)


func delete() -> void:
	FileOperations.Delete(Path)


func save_data(
	value: Dictionary,
	source_text_override := "",
	source_text_has_visual_changes := false
) -> bool:
	var serialized_data: String
	var source_text := source_text_override if not source_text_override.is_empty() else _source_text
	match Path.get_extension().to_lower():
		"json":
			if not source_text_override.is_empty() and not source_text_has_visual_changes:
				var parsed_text: Dictionary = HJSON.try_parse_string(source_text_override)
				if not parsed_text.get("success", false) \
				or typeof(parsed_text.get("data")) != TYPE_DICTIONARY:
					push_error("Could not save invalid JSON content: %s" % Path)
					return false
				serialized_data = JSON.stringify(parsed_text["data"], "\t")
			elif not source_text.is_empty():
				var preserve_result: Dictionary = HJSON.merge_and_stringify(
					source_text,
					JSON.stringify(value),
					false
				)
				if not preserve_result.get("success", false):
					push_error("Could not preserve JSON key order for %s: %s" % [
						Path,
						preserve_result.get("error", "Unknown error")
					])
					return false
				serialized_data = str(preserve_result["text"])
			else:
				serialized_data = JSON.stringify(value, "\t")
		"hjson":
			if not source_text_override.is_empty() \
			and not source_text_has_visual_changes:
				serialized_data = source_text_override
			elif not source_text.is_empty():
				var preserve_result: Dictionary = HJSON.merge_and_stringify(
					source_text,
					JSON.stringify(value),
					true
				)
				if not preserve_result.get("success", false):
					push_error("Could not preserve HJSON formatting for %s: %s" % [
						Path,
						preserve_result.get("error", "Unknown error")
					])
					return false
				serialized_data = str(preserve_result["text"])
			else:
				serialized_data = HJSON.stringify(value)
		_:
			push_error("Unsupported content file extension: %s" % Path.get_extension())
			return false

	var directory_path := Path.get_base_dir()
	var error := DirAccess.make_dir_recursive_absolute(directory_path)
	if error != OK and error != ERR_ALREADY_EXISTS:
		push_error("Could not create content directory %s: %s" % [
			directory_path,
			error_string(error)
		])
		return false

	var output := FileAccess.open(Path, FileAccess.WRITE)
	if output == null:
		push_error("Could not write content file %s: %s" % [
			Path,
			error_string(FileAccess.get_open_error())
		])
		return false

	output.store_string(serialized_data)
	output.flush()
	var write_error := output.get_error()
	output.close()
	if write_error != OK:
		push_error("Could not finish writing content file %s: %s" % [
			Path,
			error_string(write_error)
		])
		return false

	_source_text = serialized_data
	WriteData = {}
	Data = value
	has_changes = true
	return true


func _set_Path(path: String) -> void:
	path = path.simplify_path()
	if Path == path:
		return
	Path = path
	if not FileAccess.file_exists(path):
		return
	if not is_instance_valid(modClass):
		push_error("Cannot load content without a valid mod: %s" % path)
		return
	if path.get_extension().to_lower() not in ["json", "hjson"]:
		push_error("Unsupported content file extension: %s" % path.get_extension())
		return

	var relative_path := path.trim_prefix(modClass.Path.simplify_path().trim_suffix("/") + "/")
	if relative_path in ["mod.json", "mod.hjson"]:
		ContentType = ContentCore.ContentType.MOD
		ClassType = "mod"
	else:
		var path_parts := relative_path.split("/", false)
		if path_parts.size() >= 2 and path_parts[0] == "content":
			FileType = path_parts[1]
			var content_type: Variant = ContentCore.ContentTypePath.find_key(FileType)
			if content_type != null:
				ContentType = content_type

	var input := FileAccess.open(path, FileAccess.READ)
	if input == null:
		push_error("Could not open content file %s: %s" % [
			path,
			error_string(FileAccess.get_open_error())
		])
		return
	var file_text := input.get_as_text()
	input.close()
	_source_text = file_text
	var parsed: Variant = HJSON.parse_string(file_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Could not parse content file as an object: %s" % Path)
		Data = {}
		return
	Data = parsed
	content_loaded.emit()


func create(path: String, _type: ContentCore.ContentType, class_type: String) -> bool:
	Path = path.simplify_path()
	ContentType = _type
	ClassType = class_type
	return save_data({
		"name": Path.get_file().get_basename(),
		"type": class_type,
	})


func _set_Data(value: Variant) -> void:
	Data = value if typeof(value) == TYPE_DICTIONARY else {}
	if _releasing_data:
		DefaultData = null
		_full_data_cache.clear()
		_full_data_valid = true
		return

	if Data.has("type"):
		ClassType = str(Data["type"])

	DefaultData = ContentManager.get_content(ClassType)
	_full_data_valid = false
	_full_data_cache.clear()
	data_changed.emit()


func _get_FullData() -> Dictionary:
	if not _full_data_valid:
		if typeof(DefaultData) == TYPE_DICTIONARY:
			_full_data_cache = DefaultData.duplicate(true)
			_full_data_cache.merge(Data, true)
		else:
			_full_data_cache = Data.duplicate(true)
		_full_data_valid = true
	return _full_data_cache


func get_effective_value(key: String, fallback: Variant = null) -> Variant:
	if Data.has(key):
		return Data[key]
	if typeof(DefaultData) == TYPE_DICTIONARY:
		return DefaultData.get(key, fallback)
	return fallback


func get_only_filename(path: String) -> String:
	return path.get_file().get_basename()

extends Control

const CONTENT_KEY_SCENE = preload("uid://cnsmx158sf2fa")
const TEXTURE_PREVIEW_SCENE = preload("res://scenes/content_editor/texture_preview.tscn")
const CONTENT_SYNTAX_HIGHLIGHTER = preload("res://scenes/content_editor/content_syntax_highlighter.gd")
const FIELD_BUILD_BATCH_SIZE := 24
const COLOR_FIELDS := [
	"color",
	"flameColor",
	"mapColor",
	"outlineColor",
	"lightColor",
	"heatColor",
	"lightningColor",
	"flashColor",
]

@export var _TabContainer: TabContainer

@export var _content_type_label: Label  # ClassType here!!
@export var _content_fields: VBoxContainer
@export var _texture_flow: HFlowContainer
@export var _object_icon: Node

@onready var _text_editor: CodeEdit = $TabContainer/Text/VBoxContainer/ScrollContainer/Content
@onready var _text_error: Label = $TabContainer/Text/VBoxContainer/Error

var TabButton: Node
var ModEditor: Node
var RootNode: Node
var contentClass: ContentClass:
	set = _set_contentClass

var writeData: Dictionary = {}
var needSave := false:
	set = _set_needSave

var _checkbox_flow: HFlowContainer
var _texture_previews: Array[Control] = []
var _field_build_revision := 0
var _texture_build_revision := 0
var _last_tab_index := 0
var _text_mode_dirty := false
var _syncing_text := false
var _text_source_override := ""
var _text_source_has_visual_changes := false
var _text_error_line := -1
var _text_validation_timer: Timer
var _content_syntax_highlighter: SyntaxHighlighter


func _ready() -> void:
	_update_tab_titles()
	_TabContainer.tab_changed.connect(_on_editor_tab_changed)
	_text_editor.text_changed.connect(_on_text_editor_changed)
	_content_syntax_highlighter = CONTENT_SYNTAX_HIGHLIGHTER.new()
	_text_editor.syntax_highlighter = _content_syntax_highlighter
	_text_validation_timer = Timer.new()
	_text_validation_timer.one_shot = true
	_text_validation_timer.wait_time = 0.25
	_text_validation_timer.timeout.connect(_validate_text_content)
	add_child(_text_validation_timer)
	if not LocalizationAPI.global_language_changed.is_connected(_update_tab_titles):
		LocalizationAPI.global_language_changed.connect(_update_tab_titles)


func _update_tab_titles() -> void:
	_TabContainer.set_tab_title(0, LocalizationAPI.translate_text("|Editor|"))
	_TabContainer.set_tab_title(1, LocalizationAPI.translate_text("|Text|"))
	_TabContainer.set_tab_title(2, LocalizationAPI.translate_text("|Textures|"))


func _on_editor_tab_changed(tab_index: int) -> void:
	if _last_tab_index == 1 and tab_index != 1 and _text_mode_dirty:
		if not _apply_text_to_form():
			_TabContainer.current_tab = 1
			_last_tab_index = 1
			return

	_last_tab_index = tab_index
	if tab_index == 1 and not _text_mode_dirty:
		_refresh_text_from_form()


func _on_text_editor_changed() -> void:
	_content_syntax_highlighter.call("invalidate_cache")
	if _syncing_text:
		return
	_text_mode_dirty = _text_editor.text != _text_editor.get_meta("saved_text", "")
	_clear_text_error()
	_text_validation_timer.start()
	needSave = _text_mode_dirty or not writeData.is_empty()


func _refresh_text_from_form() -> void:
	if not is_instance_valid(contentClass):
		return

	var data: Dictionary = contentClass.Data.duplicate(true)
	for key: String in writeData:
		var value: Variant = writeData[key]
		if value == null:
			data.erase(key)
		else:
			data[key] = value

	var text := ""
	if not _text_source_override.is_empty():
		if _text_source_has_visual_changes:
			var preserve_result: Dictionary = HJSON.merge_and_stringify(
				_text_source_override,
				JSON.stringify(data),
				contentClass.Path.get_extension().to_lower() == "hjson"
			)
			if preserve_result.get("success", false):
				text = str(preserve_result["text"])
		else:
			text = _text_source_override
	if text.is_empty():
		text = JSON.stringify(data, "\t")
	_syncing_text = true
	_text_editor.text = text
	_text_editor.set_meta("saved_text", text)
	_syncing_text = false
	_text_validation_timer.stop()
	_text_mode_dirty = false
	_clear_text_error()
	needSave = not writeData.is_empty()


func _apply_text_to_form() -> bool:
	if not is_instance_valid(contentClass):
		return false

	_text_validation_timer.stop()
	var parse_result: Dictionary = HJSON.try_parse_string(_text_editor.text)
	var parsed: Variant = parse_result.get("data")
	if not parse_result.get("success", false) or typeof(parsed) != TYPE_DICTIONARY:
		_show_text_error(str(parse_result.get("error", "Expected an object.")))
		return false

	var edited_data: Dictionary = parsed
	_text_source_override = _text_editor.text
	_text_source_has_visual_changes = false
	var edited_full_data: Dictionary = edited_data.duplicate(true)
	if typeof(contentClass.DefaultData) == TYPE_DICTIONARY:
		edited_full_data = contentClass.DefaultData.duplicate(true)
		edited_full_data.merge(edited_data, true)

	writeData.clear()
	var baseline: Dictionary = contentClass.FullData
	for key: Variant in baseline:
		if not edited_full_data.has(key):
			writeData[str(key)] = null
	for key: Variant in edited_full_data:
		if not baseline.has(key) \
		or typeof(baseline[key]) != typeof(edited_full_data[key]) \
		or baseline[key] != edited_full_data[key]:
			writeData[str(key)] = edited_full_data[key]

	_text_mode_dirty = false
	_clear_text_error()
	needSave = not writeData.is_empty()
	_rebuild_content_fields()
	return true


func _validate_text_content() -> bool:
	_text_validation_timer.stop()
	var parse_result: Dictionary = HJSON.try_parse_string(_text_editor.text)
	if parse_result.get("success", false) \
	and typeof(parse_result.get("data")) == TYPE_DICTIONARY:
		_clear_text_error()
		return true

	_show_text_error(str(parse_result.get("error", "Expected an object.")))
	return false


func _show_text_error(details: String) -> void:
	_text_validation_timer.stop()
	_clear_text_error()
	_text_error.text = "%s\n%s" % [
		LocalizationAPI.translate_text("|InvalidContentText|"),
		details
	]
	_text_error.show()

	var error_regex := RegEx.new()
	error_regex.compile("At line ([0-9]+), column ([0-9]+)")
	var error_match := error_regex.search(details)
	if error_match == null:
		return

	_text_error_line = int(error_match.get_string(1)) - 1
	if _text_error_line >= 0 and _text_error_line < _text_editor.get_line_count():
		_text_editor.set_line_background_color(
			_text_error_line,
			Color(0.55, 0.08, 0.08, 0.35)
		)


func _clear_text_error() -> void:
	if _text_error_line >= 0 and _text_error_line < _text_editor.get_line_count():
		_text_editor.set_line_background_color(_text_error_line, Color.TRANSPARENT)
	_text_error_line = -1
	_text_error.text = ""
	_text_error.hide()


func prepare_text_for_save() -> bool:
	if not _text_mode_dirty:
		return true
	if not _apply_text_to_form():
		_TabContainer.current_tab = 1
		_last_tab_index = 1
		return false
	return true


func get_source_text_override() -> String:
	return _text_source_override


func has_visual_changes_after_text_edit() -> bool:
	return _text_source_has_visual_changes


func clear_source_text_override() -> void:
	_text_source_override = ""
	_text_source_has_visual_changes = false
	_refresh_text_from_form()


func _set_contentClass(value: ContentClass) -> void:
	if is_instance_valid(contentClass):
		if contentClass.data_changed.is_connected(_data_changed):
			contentClass.data_changed.disconnect(_data_changed)
		if is_instance_valid(contentClass.modClass) \
		and contentClass.modClass.SpriteBank_updated.is_connected(_SpriteBank_updated):
			contentClass.modClass.SpriteBank_updated.disconnect(_SpriteBank_updated)

	contentClass = value
	writeData.clear()
	needSave = false
	_field_build_revision += 1
	_texture_build_revision += 1

	if not is_instance_valid(contentClass):
		clear_source_text_override()
		_clear_content_fields()
		_clear_texture_previews()
		return

	if not contentClass.data_changed.is_connected(_data_changed):
		contentClass.data_changed.connect(_data_changed)
	if is_instance_valid(contentClass.modClass) \
	and not contentClass.modClass.SpriteBank_updated.is_connected(_SpriteBank_updated):
		contentClass.modClass.SpriteBank_updated.connect(_SpriteBank_updated)

	_content_type_label.text = "ClassType: " + str(contentClass.ClassType)
	_rebuild_content_fields()
	upd_needSave()
	_SpriteBank_updated()


func _data_changed() -> void:
	if not is_instance_valid(contentClass):
		return
	_content_type_label.text = "ClassType: " + str(contentClass.ClassType)
	_rebuild_content_fields()
	if not _text_mode_dirty:
		_refresh_text_from_form()
	_SpriteBank_updated()


func changed_data(key: String, value: Variant) -> void:
	if not is_instance_valid(contentClass) or typeof(contentClass.FullData) != TYPE_DICTIONARY:
		return
	if not _text_source_override.is_empty():
		_text_source_has_visual_changes = true

	var baseline: Dictionary = contentClass.FullData
	if baseline.has(key) and typeof(baseline[key]) == typeof(value) and baseline[key] == value:
		writeData.erase(key)
	else:
		writeData[key] = value

	needSave = not writeData.is_empty()


func _set_needSave(value: bool) -> void:
	needSave = value
	upd_needSave()


func upd_needSave() -> void:
	if is_instance_valid(RootNode) and is_instance_valid(RootNode.SaveButton):
		RootNode.SaveButton.disabled = not needSave
	if is_instance_valid(TabButton) and is_instance_valid(TabButton.ElementChanges):
		TabButton.ElementChanges.visible = needSave


func _clear_content_fields() -> void:
	for child: Node in _content_fields.get_children():
		_content_fields.remove_child(child)
		child.queue_free()
	_checkbox_flow = null


func _rebuild_content_fields() -> void:
	_field_build_revision += 1
	var revision := _field_build_revision
	_clear_content_fields()

	if not is_instance_valid(contentClass) or typeof(contentClass.FullData) != TYPE_DICTIONARY:
		return

	var data: Dictionary = contentClass.FullData.duplicate(true)
	for key: String in writeData:
		var value: Variant = writeData[key]
		if value == null:
			data.erase(key)
		else:
			data[key] = value
	var built_count := 0
	for key: Variant in data:
		if revision != _field_build_revision:
			return
		if str(key) != "type":
			create_input(str(key), data[key])
			built_count += 1
			if built_count % FIELD_BUILD_BATCH_SIZE == 0:
				await get_tree().process_frame


func _get_field_type(key: String, value: Variant) -> String:
	if typeof(value) == TYPE_BOOL:
		return "Boolean"
	if key == "description":
		return "MultiString"
	if key == "category":
		return "Category"
	if key in COLOR_FIELDS:
		return "Color"
	return "String"


func _create_content_input(key: String, value: Variant) -> Control:
	var input: Control = CONTENT_KEY_SCENE.instantiate()
	input.Name = key
	input.RootContentFrame = self
	input.Type = _get_field_type(key, value)

	if typeof(contentClass.DefaultData) == TYPE_DICTIONARY \
	and contentClass.DefaultData.has(key):
		input.DefaultData = contentClass.DefaultData[key]
		input.get_node("Actions").hide()

	input.Data = value
	return input


func _add_content_input(input: Control) -> void:
	if input.Type == "Boolean":
		if not is_instance_valid(_checkbox_flow):
			_checkbox_flow = HFlowContainer.new()
			_checkbox_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_checkbox_flow.add_theme_constant_override("h_separation", 20)
			_checkbox_flow.add_theme_constant_override("v_separation", 10)
			_content_fields.add_child(_checkbox_flow)
		_checkbox_flow.add_child(input)
	else:
		_checkbox_flow = null
		input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_content_fields.add_child(input)


func create_input(key: String, value: Variant) -> void:
	_add_content_input(_create_content_input(key, value))


func _clear_texture_previews() -> void:
	for preview: Control in _texture_previews:
		if is_instance_valid(preview):
			_texture_flow.remove_child(preview)
			preview.queue_free()
	_texture_previews.clear()


func _add_texture_preview(sprite_name: String, texture: Texture2D) -> void:
	var preview: Control = TEXTURE_PREVIEW_SCENE.instantiate()
	preview.get_node("TextureRect").texture = texture
	preview.get_node("Label").text = sprite_name
	_texture_flow.add_child(preview)
	_texture_previews.append(preview)


func _SpriteBank_updated() -> void:
	if not is_instance_valid(contentClass):
		return

	_texture_build_revision += 1
	var revision := _texture_build_revision
	_clear_texture_previews()
	_object_icon.contentClass = contentClass

	if not is_instance_valid(contentClass.modClass):
		return

	var base_name := get_only_filename(contentClass.Path)
	var sprite_names: Array[String] = [base_name]
	if contentClass.ClassType == "Drill":
		sprite_names.append_array([base_name + "-rotator", base_name + "-top"])
	elif contentClass.ClassType == "Conveyor":
		for rotation in range(4):
			for frame in range(4):
				sprite_names.append("%s-%d-%d" % [base_name, rotation, frame])

	for sprite_name: String in sprite_names:
		if revision != _texture_build_revision:
			return
		var texture: Texture2D
		if contentClass.ClassType == "mod":
			texture = contentClass.modClass.get_mod_icon()
		else:
			texture = contentClass.modClass.get_sprite(sprite_name)
		_add_texture_preview(sprite_name, texture)


func get_only_filename(path: String) -> String:
	return path.get_file().get_basename()


func _on_create_key_pressed() -> void:
	$/root/Main/Windows/ContentEditorKeyActions.create(self)

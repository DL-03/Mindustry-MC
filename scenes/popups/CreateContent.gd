extends Panel

@onready var ErrorString = $Panel/MarginContainer/VBoxContainer/tip
@onready var ContentTypeOption: OptionButton = $Panel/MarginContainer/VBoxContainer/ContentType
@onready var TypeOption: OptionButton = $Panel/MarginContainer/VBoxContainer/Type/OptionButton
@onready var TypeLine: LineEdit = $Panel/MarginContainer/VBoxContainer/Type/LineEdit
@onready var TypeCheck = $Panel/MarginContainer/VBoxContainer/Type/CheckCustom
@onready var CustomTypeLabel: Control = $Panel/MarginContainer/VBoxContainer/Type/MindustryLabel2
@onready var TypeContainer: Control = $Panel/MarginContainer/VBoxContainer/Type
@onready var PathLine: LineEdit = $Panel/MarginContainer/VBoxContainer/Path/LineEdit
@onready var NameString = $Panel/MarginContainer/VBoxContainer/Path/Name
@onready var NameLine: LineEdit = $Panel/MarginContainer/VBoxContainer/Name/LineEdit
@onready var ExtOption: OptionButton = $Panel/MarginContainer/VBoxContainer/Name/OptionButton
@onready var SelectFolder: FileDialog = $FileDialog
@onready var CreateButton: Button = $Panel/MarginContainer/VBoxContainer/DownPanel/Create

var modClass: ModClass


func _ready() -> void:
	_populate_content_types()
	_refresh_type_options()
	update_data()


func open(target_mod: ModClass) -> void:
	if not is_instance_valid(target_mod):
		push_error("Cannot open create-content dialog without a valid mod.")
		return

	modClass = target_mod
	ContentTypeOption.select(0)
	PathLine.clear()
	NameLine.text = "name"
	ExtOption.select(0)
	TypeCheck.Checked = false
	TypeLine.clear()
	show()
	_refresh_type_options()
	update_data()


func _populate_content_types() -> void:
	ContentTypeOption.clear()
	for content_type_name: String in ContentCore.ContentType.keys():
		var content_type: int = ContentCore.ContentType[content_type_name]
		if not ContentCore.ContentTypePath.has(content_type):
			continue
		if content_type == ContentCore.ContentType.MOD:
			continue
		ContentTypeOption.add_item(content_type_name, content_type)

	if ContentTypeOption.item_count > 0:
		ContentTypeOption.select(0)


func _get_selected_content_type() -> int:
	if ContentTypeOption.selected < 0:
		return -1
	return ContentTypeOption.get_item_id(ContentTypeOption.selected)


func _get_category_root() -> String:
	var content_type := _get_selected_content_type()
	if not ContentCore.ContentTypePath.has(content_type) or not is_instance_valid(modClass):
		return ""
	return modClass.Path.simplify_path().path_join("content").path_join(
		ContentCore.ContentTypePath[content_type]
	).simplify_path()


func _get_target_file_path() -> String:
	var category_root := _get_category_root()
	if category_root.is_empty():
		return ""
	var relative_directory := PathLine.text.strip_edges().replace("\\", "/").simplify_path()
	if relative_directory == ".":
		relative_directory = ""
	if relative_directory.begins_with("/") or relative_directory == ".." \
	or relative_directory.begins_with("../"):
		return ""

	var file_name := NameLine.text.strip_edges()
	if file_name.is_empty() or file_name in [".", ".."] \
	or file_name.contains("/") or file_name.contains("\\"):
		return ""

	var target_path := category_root
	if not relative_directory.is_empty():
		target_path = target_path.path_join(relative_directory)
	return target_path.path_join("%s.%s" % [file_name, ExtOption.text.to_lower()]).simplify_path()


func _get_available_class_types(content_type: int) -> Array:
	if content_type < 0:
		return []

	var content_type_name: String = str(ContentCore.ContentType.keys()[content_type]).to_lower()
	var content_type_lists: Dictionary = ContentManager.ContentFile.get("CreateContent", {})
	for list_name: Variant in content_type_lists:
		if str(list_name).to_lower() == content_type_name:
			var class_types: Variant = content_type_lists[list_name]
			if class_types is Array:
				return class_types
	return []


func _refresh_type_options() -> void:
	var content_type := _get_selected_content_type()
	var available_class_types := _get_available_class_types(content_type)
	var has_class_type_options := not available_class_types.is_empty()

	TypeContainer.show()
	TypeCheck.visible = has_class_type_options
	CustomTypeLabel.visible = has_class_type_options
	TypeOption.visible = has_class_type_options and not TypeCheck.Checked
	TypeLine.visible = not has_class_type_options or TypeCheck.Checked

	TypeOption.clear()
	if has_class_type_options:
		for class_type: String in available_class_types:
			TypeOption.add_item(class_type)
		if TypeOption.item_count > 0:
			TypeOption.select(0)


func update_data() -> void:
	NameString.real_text = "/%s.%s" % [NameLine.text, ExtOption.text.to_lower()]
	CreateButton.disabled = true
	ErrorString.real_text = ""

	if not is_instance_valid(modClass):
		return
	if ContentTypeOption.selected < 0:
		ErrorString.real_text = "Выберите категорию контента"
		return

	var target_path := _get_target_file_path()
	if target_path.is_empty():
		ErrorString.real_text = "Некорректное имя или путь"
		return
	if FileAccess.file_exists(target_path) or DirAccess.dir_exists_absolute(target_path):
		ErrorString.real_text = "|PathBusy|"
		return
	for content_class: ContentClass in modClass.ContentBank:
		if content_class.Path.simplify_path() == target_path:
			ErrorString.real_text = "|PathBusy|"
			return
	var available_class_types := _get_available_class_types(_get_selected_content_type())
	if _is_custom_class_type(available_class_types) and TypeLine.text.strip_edges().is_empty():
		ErrorString.real_text = "Укажите тип контента"
		return
	if not _is_custom_class_type(available_class_types) and TypeOption.selected < 0:
		ErrorString.real_text = "Выберите тип контента"
		return

	CreateButton.disabled = false


func _on_back_pressed() -> void:
	hide()


func _on_create_pressed() -> void:
	update_data()
	if CreateButton.disabled:
		return

	var content_type := _get_selected_content_type()
	var available_class_types := _get_available_class_types(content_type)
	var class_type := TypeLine.text.strip_edges() if _is_custom_class_type(available_class_types) else ""
	if class_type.is_empty():
		class_type = TypeOption.text
	if class_type.is_empty():
		ErrorString.real_text = "Для этой категории не задан тип контента"
		CreateButton.disabled = true
		return

	var target_path := _get_target_file_path()
	var directory_path := target_path.get_base_dir()
	var error := DirAccess.make_dir_recursive_absolute(directory_path)
	if error != OK and error != ERR_ALREADY_EXISTS:
		push_error("Could not create content directory %s: %s" % [
			directory_path,
			error_string(error)
		])
		ErrorString.real_text = "Не удалось создать каталог контента"
		return

	var created_content := modClass.create_content(target_path, content_type, class_type)
	if not is_instance_valid(created_content):
		ErrorString.real_text = "Не удалось создать файл контента"
		return
	hide()


func _on_option_button_item_selected(_index: int) -> void:
	_refresh_type_options()
	update_data()


func _on_EXT_option_button_item_selected(_index: int) -> void:
	update_data()


func _on_PathLine_edit_text_changed(_new_text: String) -> void:
	update_data()


func _on_NameLine_edit_text_changed(_new_text: String) -> void:
	update_data()


func _on_TypeLine_edit_text_changed(_new_text: String) -> void:
	update_data()


func _on_check_custom_state_changed(value: Variant) -> void:
	_refresh_type_options()
	update_data()


func _is_custom_class_type(available_class_types: Array) -> bool:
	return available_class_types.is_empty() or TypeCheck.Checked


func _on_1option_button_item_selected(_index: int) -> void:
	update_data()


func _on_chose_path_pressed() -> void:
	var category_root := _get_category_root()
	if category_root.is_empty():
		return
	SelectFolder.current_dir = category_root
	SelectFolder.current_path = category_root
	SelectFolder.show()


func _on_file_dialog_dir_selected(directory: String) -> void:
	var category_root := _get_category_root()
	var selected_directory := directory.simplify_path()
	if category_root.is_empty():
		return
	if selected_directory == category_root:
		PathLine.clear()
	elif selected_directory.begins_with(category_root.trim_suffix("/") + "/"):
		PathLine.text = selected_directory.trim_prefix(category_root.trim_suffix("/") + "/")
	else:
		Notifications.error("Выбранный каталог должен находиться внутри папки категории контента.")
		return
	update_data()

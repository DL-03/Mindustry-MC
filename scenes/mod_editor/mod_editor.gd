extends Control

var ButtonTab:
	set = _set_button_tab

var modClass: ModClass:
	set = _set_modClass


@export var ContentEditor: Node
@export var GlobalModCard: Node

func _set_button_tab(v):
	if ButtonTab:
		if ButtonTab.has_signal("close"):
			if ButtonTab.close.is_connected(close):
				ButtonTab.close.disconnect(close)

	ButtonTab = v
	if ButtonTab.has_signal("close"):
		if not ButtonTab.close.is_connected(close):
			ButtonTab.close.connect(close)

func close():
	ModManager.close_mod(modClass)
	ButtonTab.controller.free_tab(ButtonTab)
	


func _set_modClass(value):
	modClass = value


var ModType = ""

var _search_query := ""
var _file_tree_generation := 0
var _file_tree_filter_generation := 0
var _content_by_path: Dictionary = {}
var _context_path := ""
var _context_is_directory := false
var _context_content: ContentClass
var _file_tree_context_menu: PopupMenu
var _file_operation_dialog: ConfirmationDialog
var _file_operation_input: LineEdit

enum FileTreeAction {
	OPEN_CONTENT,
	COPY_RELATIVE_PATH,
	COPY_ABSOLUTE_PATH,
	OPEN_IN_FILE_MANAGER,
	RENAME,
	DUPLICATE,
	DELETE
}



func _ready():
	#$Panel.add_child(GlobalModCard)
	#$Panel.move_child(GlobalModCard,0)
	
	GlobalModCard.show_open_button = false
	GlobalModCard.show_type_button = true
	GlobalModCard.show_delete_button = false
	GlobalModCard.show_visible_button = true
	GlobalModCard.show_save_button = true
	
	for i in ContentCore.ContentType.values():
		FContentType.set(i, true)

	var content_tab: Button = $ModEditor/Panel/VBoxContainer/MarginContainer/Tabs/Content
	var file_manager_tab: Button = $ModEditor/Panel/VBoxContainer/MarginContainer/Tabs/FileManager
	content_tab.pressed.connect(_on_content_tab_pressed)
	file_manager_tab.pressed.connect(_on_file_manager_tab_pressed)
	var file_tree: Tree = $ModEditor/Panel/VBoxContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/Tree
	file_tree.item_activated.connect(_on_file_tree_item_activated)
	file_tree.gui_input.connect(_on_file_tree_gui_input)
	file_tree.columns = 1
	file_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	file_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	file_tree.hide()
	_setup_file_tree_context_menu()
	_set_editor_view(true)


func _setup_file_tree_context_menu() -> void:
	_file_tree_context_menu = PopupMenu.new()
	add_child(_file_tree_context_menu)
	_file_tree_context_menu.id_pressed.connect(_on_file_tree_context_action)

	_file_operation_dialog = ConfirmationDialog.new()
	_file_operation_dialog.title = "Операция с файлом"
	_file_operation_dialog.confirmed.connect(_confirm_file_operation)
	var dialog_container := VBoxContainer.new()
	_file_operation_dialog.add_child(dialog_container)
	_file_operation_input = LineEdit.new()
	_file_operation_input.custom_minimum_size = Vector2(280, 0)
	dialog_container.add_child(_file_operation_input)
	add_child(_file_operation_dialog)


func _on_file_tree_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_RIGHT or not event.pressed:
		return

	var file_tree: Tree = $ModEditor/Panel/VBoxContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/Tree
	var item := file_tree.get_item_at_position(event.position)
	if item == null:
		return

	var item_data: Variant = item.get_metadata(0)
	if typeof(item_data) != TYPE_DICTIONARY:
		return

	_context_path = str(item_data.get("path", "")).simplify_path()
	_context_is_directory = bool(item_data.get("is_dir", false))
	_context_content = _content_by_path.get(_context_path)
	if not is_instance_valid(_context_content) \
	and modClass.ModContentClass.Path.simplify_path() == _context_path:
		_context_content = modClass.ModContentClass

	file_tree.set_selected(item, 0)
	_file_tree_context_menu.clear()
	if not _context_is_directory and is_instance_valid(_context_content):
		_file_tree_context_menu.add_item("Открыть контент", FileTreeAction.OPEN_CONTENT)
	_file_tree_context_menu.add_item("Копировать относительный путь", FileTreeAction.COPY_RELATIVE_PATH)
	_file_tree_context_menu.add_item("Копировать полный путь", FileTreeAction.COPY_ABSOLUTE_PATH)
	_file_tree_context_menu.add_item("Открыть в проводнике", FileTreeAction.OPEN_IN_FILE_MANAGER)

	if _context_path != modClass.Path.simplify_path():
		_file_tree_context_menu.add_separator()
		_file_tree_context_menu.add_item("Переименовать", FileTreeAction.RENAME)
		if not _context_is_directory:
			_file_tree_context_menu.add_item("Дублировать", FileTreeAction.DUPLICATE)
		_file_tree_context_menu.add_item("Удалить", FileTreeAction.DELETE)

	_file_tree_context_menu.position = DisplayServer.mouse_get_position()
	_file_tree_context_menu.popup()
	file_tree.accept_event()


func _on_file_tree_context_action(action: int) -> void:
	if _context_path.is_empty():
		return

	match action:
		FileTreeAction.OPEN_CONTENT:
			if is_instance_valid(_context_content):
				ContentEditor.open_from_path(_context_content)
		FileTreeAction.COPY_RELATIVE_PATH:
			DisplayServer.clipboard_set(_get_context_relative_path())
			Notifications.info("|PathCopied|!")
		FileTreeAction.COPY_ABSOLUTE_PATH:
			DisplayServer.clipboard_set(_context_path)
			Notifications.info("|PathCopied|!")
		FileTreeAction.OPEN_IN_FILE_MANAGER:
			OS.shell_show_in_file_manager(_context_path)
		FileTreeAction.RENAME:
			_begin_file_rename()
		FileTreeAction.DUPLICATE:
			if is_instance_valid(_context_content):
				$/root/Main/Windows/RenameDuplicateWindow.open(_context_content, 2)
			else:
				_duplicate_file(_context_path)
		FileTreeAction.DELETE:
			if is_instance_valid(_context_content):
				$/root/Main/Windows/RenameDuplicateWindow.open(_context_content, 0)
			else:
				_begin_file_delete()


func _get_context_relative_path() -> String:
	var mod_root := modClass.Path.simplify_path().trim_suffix("/")
	if _context_path == mod_root:
		return "."
	return _context_path.trim_prefix(mod_root + "/")


func _begin_file_rename() -> void:
	if is_instance_valid(_context_content):
		$/root/Main/Windows/RenameDuplicateWindow.open(_context_content, 1)
		return

	_file_operation_dialog.title = "Переименовать"
	_file_operation_dialog.dialog_text = "Введите новое имя:"
	_file_operation_input.show()
	_file_operation_input.text = (
		_context_path.get_file().get_basename()
		if not _context_is_directory
		else _context_path.get_file()
	)
	_file_operation_dialog.popup_centered()
	_file_operation_input.grab_focus()
	_file_operation_input.select_all()


func _begin_file_delete() -> void:
	_file_operation_dialog.title = "Удалить"
	_file_operation_dialog.dialog_text = "Удалить «%s»?" % _context_path.get_file()
	_file_operation_input.hide()
	_file_operation_dialog.popup_centered()


func _confirm_file_operation() -> void:
	if _file_operation_input.visible:
		_rename_file_or_directory()
	else:
		_delete_file_or_directory()


func _rename_file_or_directory() -> void:
	var new_name := _file_operation_input.text.strip_edges()
	if new_name.is_empty() or new_name in [".", ".."] \
	or new_name.contains("/") or new_name.contains("\\"):
		push_warning("Invalid file or directory name: %s" % new_name)
		return

	var new_path := _context_path.get_base_dir().path_join(new_name)
	if not _context_is_directory:
		new_path += "." + _context_path.get_extension()
	if FileAccess.file_exists(new_path) or DirAccess.dir_exists_absolute(new_path):
		Notifications.error("|FileWithThisNameAlreadyExists|")
		return
	if not _is_path_inside_mod(_context_path) or not _is_path_inside_mod(new_path):
		push_error("Refusing to rename a path outside the mod directory.")
		return

	var error := DirAccess.rename_absolute(_context_path, new_path)
	if error != OK:
		push_error("Could not rename %s: %s" % [_context_path, error_string(error)])
		return

	if _context_is_directory:
		var old_prefix := _context_path.trim_suffix("/") + "/"
		var new_prefix := new_path.trim_suffix("/") + "/"
		for content_class: ContentClass in modClass.ContentBank.duplicate():
			var content_path := content_class.Path.simplify_path()
			if content_path.begins_with(old_prefix):
				_content_by_path.erase(content_path)
				modClass._content_by_path.erase(content_path)
				content_class.Path = new_prefix + content_path.trim_prefix(old_prefix)
				modClass._content_by_path[content_class.Path.simplify_path()] = content_class
				_register_content_class(content_class)

		for sprite_name: String in modClass.SpriteBank.keys():
			var sprite_path: String = modClass.SpriteBank[sprite_name]
			if sprite_path.begins_with(old_prefix):
				modClass.SpriteBank[sprite_name] = new_prefix + sprite_path.trim_prefix(old_prefix)
		modClass.SpriteBank_updated.emit()

	_refresh_file_tree()


func _delete_file_or_directory() -> void:
	if not _is_path_inside_mod(_context_path):
		push_error("Refusing to delete a path outside the mod directory.")
		return

	var error := _remove_path_recursive(_context_path)
	if error != OK:
		push_error("Could not delete %s: %s" % [_context_path, error_string(error)])
		return

	if _context_is_directory:
		var content_prefix := _context_path.trim_suffix("/") + "/"
		for content_class: ContentClass in modClass.ContentBank.duplicate():
			if content_class.Path.simplify_path().begins_with(content_prefix):
				modClass._remove_content_file(content_class.Path)

	_refresh_file_tree()


func _remove_path_recursive(path: String) -> Error:
	if DirAccess.dir_exists_absolute(path):
		for directory_name: String in DirAccess.get_directories_at(path):
			var error := _remove_path_recursive(path.path_join(directory_name))
			if error != OK:
				return error
		for file_name: String in DirAccess.get_files_at(path):
			var error := DirAccess.remove_absolute(path.path_join(file_name))
			if error != OK:
				return error
	return DirAccess.remove_absolute(path)


func _is_path_inside_mod(path: String) -> bool:
	var mod_root := modClass.Path.simplify_path().trim_suffix("/")
	var normalized_path := path.simplify_path()
	return normalized_path != mod_root and normalized_path.begins_with(mod_root + "/")


func _duplicate_file(path: String) -> void:
	var base_name := path.get_file().get_basename() + "_copy"
	var extension := path.get_extension()
	var duplicate_path := path.get_base_dir().path_join(base_name)
	if not extension.is_empty():
		duplicate_path += "." + extension
	var suffix := 2
	while FileAccess.file_exists(duplicate_path) or DirAccess.dir_exists_absolute(duplicate_path):
		duplicate_path = path.get_base_dir().path_join("%s_%d" % [base_name, suffix])
		if not extension.is_empty():
			duplicate_path += "." + extension
		suffix += 1

	var error := DirAccess.copy_absolute(path, duplicate_path)
	if error != OK:
		push_error("Could not duplicate %s: %s" % [path, error_string(error)])
		return
	_refresh_file_tree()


@export var LoadingWindow: Node

func setPath(path):
	if ModManager.test_from_path(path):
		modClass = ModManager.open_from_path(path)
		
		
		ButtonTab.modClass = modClass
		
		LoadingWindow.show()
		$LoadingWindow/Panel/MarginContainer/VBoxContainer/ProgressBar.indeterminate = true
		
		modClass.connect_loaded(_on_mod_loaded)
		modClass.ContentBank_added.connect(
			func(_contentClass: ContentClass):
				_register_content_class(_contentClass)
				_update_content_card_visibility(_contentClass)
				_update_loading_progress()
				if $Window.visible:
					_refresh_content_bank_window()
				if modClass.is_loaded and _is_file_manager_visible():
					_refresh_file_tree()
		)
			
		
		print(modClass.ModContentClass.FullData)

		GlobalModCard.mouse_default_cursor_shape = CURSOR_POINTING_HAND
		
		GlobalModCard.ModEditor = self
		GlobalModCard.contentClass = modClass.ModContentClass
		
		ContentEditor.open_from_path(modClass.ModContentClass)

		Notifications.info("|ModificationOpened|")
		

func _on_mod_loaded() -> void:
	var progress_bar: ProgressBar = $LoadingWindow/Panel/MarginContainer/VBoxContainer/ProgressBar
	progress_bar.indeterminate = false
	progress_bar.max_value = 1
	progress_bar.value = 1
	LoadingWindow.hide()

	_refresh_content_bank_window()
	_content_by_path.clear()
	for content_class: ContentClass in modClass.ContentBank:
		_register_content_class(content_class)
	refresh_content_list()
	if _is_file_manager_visible():
		_refresh_file_tree()


func _register_content_class(content_class: ContentClass) -> void:
	var content_path := content_class.Path.simplify_path()
	_content_by_path[content_path] = content_class
	var delete_callback := _on_content_file_deleted.bind(content_path)
	if not content_class.file_deleted.is_connected(delete_callback):
		content_class.file_deleted.connect(delete_callback)


func _on_content_file_deleted(content_path: String) -> void:
	_content_by_path.erase(content_path)
	if _is_file_manager_visible():
		_refresh_file_tree()


func _update_loading_progress() -> void:
	if not LoadingWindow.visible or modClass == null:
		return

	var content_count: int = modClass.ContentBank.size()
	var label: Node = $LoadingWindow/Panel/MarginContainer/VBoxContainer/Label2
	var mod_name: String = str(modClass.ModContentClass.FullData.get("name", "None"))
	var last_path := ""
	if content_count > 0:
		last_path = str(modClass.ContentBank[-1].Path).substr(modClass.Path.length())

	label.real_text = "|Loading|: %s\n|Content|[%d]: %s" % [
		mod_name,
		content_count,
		last_path
	]


var CONTENT_CARD = preload("uid://dxllrpipx487b")

# =================
# FILTERS
# =================

var FContentType: Dictionary[ContentCore.ContentType, bool] = {}
var _content_list_refresh_revision := 0
var _content_list_refresh_running := false
const CONTENT_LIST_REFRESH_BATCH_SIZE := 24
const FILE_TREE_FOLDER_GLYPH := ""
const FILE_TREE_IMAGE_GLYPH := ""
const FILE_TREE_MUSIC_GLYPH := ""
const FILE_TREE_VIDEO_GLYPH := ""
const FILE_TREE_CODE_GLYPH := ""
const FILE_TREE_TEXT_GLYPH := ""
const FILE_TREE_UNKNOWN_GLYPH := ""
var _file_tree_icon_cache: Dictionary[String, Texture2D] = {}

# =================

func filters_changed(tooltip: Node):
	for k in FContentType.keys():
		FContentType[k] = tooltip.FContentType.get(k, false)
	refresh_content_list()
	_apply_file_tree_filters()

func _on_popup_mind_tooltip_tooltip_will_show(tooltip: Node) -> void:
	tooltip.clear_connections()
	tooltip.ctype_import(FContentType)
	tooltip.changed.connect(filters_changed.bind(tooltip))

func _content_add(_content_class):
	if _content_class == null or typeof(_content_class.Data) != TYPE_DICTIONARY:
		return null

	var card: Node = ListLoadedContentCards.get(_content_class)
	if is_instance_valid(card):
		return card

	card = CONTENT_CARD.instantiate()
	card.ModEditor = self
	card.ContentEditor = ContentEditor
	card.contentClass = _content_class
	ListContentElements.call_deferred("add_child", card)
	ListLoadedContentCards[_content_class] = card
	return card

@export var ListContentElements: Node
var ListLoadedContentCards = {}


func refresh_content_list():
	if modClass == null:
		return

	_content_list_refresh_revision += 1
	if not _content_list_refresh_running:
		_refresh_content_list_incrementally()


func _refresh_content_list_incrementally() -> void:
	_content_list_refresh_running = true

	while true:
		var refresh_revision := _content_list_refresh_revision
		var content_bank: Array = modClass.ContentBank.duplicate()
		var processed_count := 0

		for content_class: ContentClass in content_bank:
			if refresh_revision != _content_list_refresh_revision:
				break

			_update_content_card_visibility(content_class)
			processed_count += 1

			if processed_count >= CONTENT_LIST_REFRESH_BATCH_SIZE:
				processed_count = 0
				await get_tree().process_frame

		if refresh_revision == _content_list_refresh_revision:
			break

	_content_list_refresh_running = false


func _update_content_card_visibility(content_class: ContentClass) -> void:
	var card: Node = ListLoadedContentCards.get(content_class)
	if not is_instance_valid(card):
		if ListLoadedContentCards.has(content_class):
			ListLoadedContentCards.erase(content_class)
		card = null

	var should_show: bool = (
		content_class.ContentType in ContentCore.ContentType.values()
		and FContentType.get(content_class.ContentType, false)
		and content_class.File != null
		and content_class.Data != null
		and typeof(content_class.Data) == TYPE_DICTIONARY
		and _matches_content_search(content_class)
	)

	if should_show:
		if card == null:
			card = _content_add(content_class)
		if card != null:
			card.show()
	elif card != null:
		card.hide()


func _matches_content_search(content_class: ContentClass) -> bool:
	if _search_query.is_empty():
		return true

	var data_name := str(content_class.Data.get("name", ""))
	var file_name := content_class.Path.get_file().get_basename()
	var relative_path := content_class.Path.simplify_path().trim_prefix(
		modClass.Path.simplify_path().trim_suffix("/") + "/"
	)
	var query := _search_query.to_lower()
	return (
		data_name.to_lower().contains(query)
		or file_name.to_lower().contains(query)
		or relative_path.to_lower().contains(query)
	)


func _set_editor_view(show_content: bool) -> void:
	var content_tab: Button = $ModEditor/Panel/VBoxContainer/MarginContainer/Tabs/Content
	var file_manager_tab: Button = $ModEditor/Panel/VBoxContainer/MarginContainer/Tabs/FileManager
	content_tab.disabled = show_content
	file_manager_tab.disabled = not show_content
	var content_list: ScrollContainer = $ModEditor/Panel/VBoxContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/ScrollContainer
	var file_tree: Tree = $ModEditor/Panel/VBoxContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/Tree
	content_list.visible = show_content
	file_tree.visible = not show_content


func _is_file_manager_visible() -> bool:
	return $ModEditor/Panel/VBoxContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/Tree.visible


func _on_content_tab_pressed() -> void:
	_set_editor_view(true)


func _on_file_manager_tab_pressed() -> void:
	_set_editor_view(false)
	_refresh_file_tree()


func _refresh_file_tree() -> void:
	if modClass == null or modClass.Path.is_empty():
		return

	_file_tree_generation += 1
	_populate_file_tree(_file_tree_generation)


func _populate_file_tree(generation: int) -> void:
	var file_tree: Tree = $ModEditor/Panel/VBoxContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/Tree
	file_tree.clear()

	var mod_root := modClass.Path.simplify_path()
	if not DirAccess.dir_exists_absolute(mod_root):
		push_warning("Could not open mod directory for file tree: %s" % mod_root)
		return

	var root_label := mod_root.get_file()
	if typeof(modClass.ModContentClass.Data) == TYPE_DICTIONARY:
		root_label = str(modClass.ModContentClass.Data.get("name", root_label))
	var root_item := file_tree.create_item()
	_set_file_tree_glyph(root_item, FILE_TREE_FOLDER_GLYPH, root_label)
	root_item.set_metadata(0, {"path": mod_root, "relative_path": "", "is_dir": true})
	root_item.set_tooltip_text(0, ".")
	root_item.set_selectable(0, false)
	root_item.set_collapsed(false)

	var directories: Array[Dictionary] = [
		{"path": mod_root, "item": root_item, "relative_path": ""}
	]
	var visited := 0

	while not directories.is_empty():
		if generation != _file_tree_generation:
			return

		var current: Dictionary = directories.pop_back()
		var current_path: String = current["path"]
		var current_item: TreeItem = current["item"]
		var parent_relative_path: String = current["relative_path"]
		var directory_names := DirAccess.get_directories_at(current_path)
		var file_names := DirAccess.get_files_at(current_path)
		directory_names.sort()
		file_names.sort()

		for directory_name: String in directory_names:
			var directory_path := current_path.path_join(directory_name)
			var relative_path := directory_name if parent_relative_path.is_empty() else parent_relative_path.path_join(directory_name)
			var directory_item := file_tree.create_item(current_item)
			_set_file_tree_glyph(directory_item, FILE_TREE_FOLDER_GLYPH, directory_name)
			directory_item.set_metadata(0, {
				"path": directory_path,
				"relative_path": relative_path,
				"is_dir": true
			})
			directory_item.set_tooltip_text(0, relative_path)
			directory_item.set_collapsed(true)
			directories.append({
				"path": directory_path,
				"item": directory_item,
				"relative_path": relative_path
			})
			visited += 1
			if visited % CONTENT_LIST_REFRESH_BATCH_SIZE == 0:
				await get_tree().process_frame
				if generation != _file_tree_generation:
					return

		for file_name: String in file_names:
			var file_path := current_path.path_join(file_name)
			var relative_path := file_name if parent_relative_path.is_empty() else parent_relative_path.path_join(file_name)
			var file_item := file_tree.create_item(current_item)
			var content_class: ContentClass = _content_by_path.get(file_path.simplify_path())
			_set_file_tree_file_icon(file_item, file_path, content_class, file_name)
			file_item.set_metadata(0, {
				"path": file_path,
				"relative_path": relative_path,
				"is_dir": false
			})
			file_item.set_tooltip_text(0, relative_path)
			visited += 1
			if visited % CONTENT_LIST_REFRESH_BATCH_SIZE == 0:
				await get_tree().process_frame
				if generation != _file_tree_generation:
					return

	_apply_file_tree_filters()


func _apply_file_tree_filters() -> void:
	if not _is_file_manager_visible():
		return

	_file_tree_filter_generation += 1
	_update_file_tree_filter_visibility(_file_tree_filter_generation)


func _update_file_tree_filter_visibility(generation: int) -> void:
	var file_tree: Tree = $ModEditor/Panel/VBoxContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/Tree
	var root_item := file_tree.get_root()
	if root_item == null:
		return

	var items: Array[TreeItem] = []
	var pending: Array[TreeItem] = [root_item]
	while not pending.is_empty():
		var item: TreeItem = pending.pop_back()
		items.append(item)
		var child := item.get_first_child()
		while child != null:
			pending.append(child)
			child = child.get_next()

	var processed := 0
	for index in range(items.size() - 1, -1, -1):
		if generation != _file_tree_filter_generation:
			return

		var item := items[index]
		var metadata: Variant = item.get_metadata(0)
		if typeof(metadata) != TYPE_DICTIONARY:
			item.visible = false
			continue

		var item_path := str(metadata.get("path", ""))
		if metadata.get("is_dir", false):
			var has_children := item.get_first_child() != null
			var has_visible_child := false
			var child := item.get_first_child()
			while child != null:
				if child.visible:
					has_visible_child = true
					break
				child = child.get_next()

			item.visible = item == root_item \
				or (not _search_query.is_empty() \
					and _matches_file_tree_search(item_path, item.get_text(0))) \
				or has_visible_child \
				or (_search_query.is_empty() and not has_children)
		else:
			item.visible = _file_tree_item_matches_filters(item_path, item.get_text(0))

		processed += 1
		if processed >= CONTENT_LIST_REFRESH_BATCH_SIZE:
			processed = 0
			await get_tree().process_frame


func _file_tree_item_matches_filters(item_path: String, displayed_name: String) -> bool:
	var content_class: ContentClass = _content_by_path.get(item_path.simplify_path())
	if is_instance_valid(content_class):
		if content_class.ContentType in ContentCore.ContentType.values() \
		and not FContentType.get(content_class.ContentType, false):
			return false

		if typeof(content_class.Data) == TYPE_DICTIONARY \
		and not _search_query.is_empty() \
		and str(content_class.Data.get("name", "")).to_lower().contains(_search_query.to_lower()):
			return true

	return _matches_file_tree_search(item_path, displayed_name)


func _matches_file_tree_search(item_path: String, displayed_name: String) -> bool:
	if _search_query.is_empty():
		return true

	var relative_path := item_path.simplify_path().trim_prefix(
		modClass.Path.simplify_path().trim_suffix("/") + "/"
	)
	var query := _search_query.to_lower()
	return displayed_name.to_lower().contains(query) or relative_path.to_lower().contains(query)


func _set_file_tree_file_icon(
	item: TreeItem,
	file_path: String,
	content_class: ContentClass,
	file_name: String
) -> void:
	var normalized_file_name := file_name.to_lower()
	if normalized_file_name in ["mod.json", "mod.hjson"]:
		item.set_text(0, file_name)
		item.set_icon(0, ModManager.get_icon_from_path(modClass.Path))
		item.set_icon_max_width(0, 20)
		return

	var extension := file_path.get_extension().to_lower()
	if extension in ["png", "jpg", "jpeg", "webp", "bmp", "gif", "tga", "svg"]:
		var image_icon := _get_file_tree_image_icon(file_path)
		if image_icon != null:
			item.set_text(0, file_name)
			item.set_icon(0, image_icon)
			item.set_icon_max_width(0, 20)
		else:
			_set_file_tree_glyph(item, FILE_TREE_IMAGE_GLYPH, file_name)
		return

	if extension in ["mp3", "ogg", "wav", "flac", "aac", "m4a", "mid", "midi", "opus", "wma"]:
		_set_file_tree_glyph(item, FILE_TREE_MUSIC_GLYPH, file_name)
		return

	if extension in ["mp4", "mkv", "webm", "avi", "mov", "wmv", "m4v", "mpg", "mpeg", "3gp"]:
		_set_file_tree_glyph(item, FILE_TREE_VIDEO_GLYPH, file_name)
		return

	if is_instance_valid(content_class) and content_class != modClass.ModContentClass:
		var sprite_name := file_path.get_file().get_basename()
		if content_class.modClass != null and content_class.modClass.SpriteBank.has(sprite_name):
			var sprite_path: String = content_class.modClass.SpriteBank[sprite_name]
			var content_icon := _get_file_tree_sprite_icon(sprite_path)
			if content_icon != null:
				item.set_text(0, file_name)
				item.set_icon(0, content_icon)
				item.set_icon_max_width(0, 20)
				return

	var code_extensions := [
		"gd", "cs", "tscn", "tres", "gdshader", "shader", "py", "js", "ts",
		"jsx", "tsx", "java", "kt", "kts", "c", "h", "cc", "cpp", "hpp",
		"go", "rs", "rb", "php", "lua", "sql", "sh", "bash", "bat", "cmd",
		"ps1", "html", "css", "scss"
	]
	if extension in code_extensions:
		_set_file_tree_glyph(item, FILE_TREE_CODE_GLYPH, file_name)
		return

	var text_extensions := [
		"txt", "md", "json", "hjson", "cfg", "ini", "xml", "yaml", "yml",
		"csv", "log", "properties", "toml"
	]
	var glyph := FILE_TREE_TEXT_GLYPH if extension in text_extensions else FILE_TREE_UNKNOWN_GLYPH
	_set_file_tree_glyph(item, glyph, file_name)


func _set_file_tree_glyph(item: TreeItem, glyph: String, label: String) -> void:
	item.set_text(0, glyph + " " + label)


func _get_file_tree_sprite_icon(sprite_path: String) -> Texture2D:
	if _file_tree_icon_cache.has(sprite_path):
		return _file_tree_icon_cache[sprite_path]

	var image := Image.new()
	var error := image.load(sprite_path)
	if error != OK:
		push_warning("Could not load content icon: %s" % sprite_path)
		return null

	var texture := ImageTexture.create_from_image(image)
	_file_tree_icon_cache[sprite_path] = texture
	return texture


func _get_file_tree_image_icon(file_path: String) -> Texture2D:
	if _file_tree_icon_cache.has(file_path):
		return _file_tree_icon_cache[file_path]

	var image := Image.new()
	var error: Error
	if file_path.get_extension().to_lower() == "svg":
		var svg_source := FileAccess.get_file_as_string(file_path)
		error = image.load_svg_from_string(svg_source)
	else:
		error = image.load(file_path)

	if error != OK:
		push_warning("Could not load image preview for file tree: %s" % file_path)
		return null

	var longest_side := maxf(float(image.get_width()), float(image.get_height()))
	if longest_side > 32.0:
		var resize_scale := 32.0 / longest_side
		image.resize(
			maxi(1, roundi(image.get_width() * resize_scale)),
			maxi(1, roundi(image.get_height() * resize_scale)),
			Image.INTERPOLATE_LANCZOS
		)

	var texture := ImageTexture.create_from_image(image)
	_file_tree_icon_cache[file_path] = texture
	return texture


func _on_file_tree_item_activated() -> void:
	var selected_item: TreeItem = $ModEditor/Panel/VBoxContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/Tree.get_selected()
	if selected_item == null:
		return

	var item_metadata: Variant = selected_item.get_metadata(0)
	if typeof(item_metadata) != TYPE_DICTIONARY or item_metadata.get("is_dir", true):
		return

	var file_path: String = str(item_metadata.get("path", "")).simplify_path()
	var content_class: ContentClass
	if modClass.ModContentClass.Path.simplify_path() == file_path:
		content_class = modClass.ModContentClass
	else:
		content_class = _content_by_path.get(file_path)
	if not is_instance_valid(content_class):
		for candidate: ContentClass in modClass.ContentBank:
			if candidate.Path.simplify_path() == file_path:
				content_class = candidate
				_register_content_class(candidate)
				break
	if is_instance_valid(content_class):
		ContentEditor.open_from_path(content_class)


var SpritesDirAccess: DirAccess


func _on_window_close_requested():
	$Window.hide()


func _on_create_content_pressed():
	$/root/Main/Windows/CreateContent.open(modClass)


func _on_reload_content_pressed():
	refresh_content_list()


func _on_content_bank_pressed():
	_refresh_content_bank_window()
	$Window.show()


func _refresh_content_bank_window() -> void:
	var content_data: PackedStringArray = []
	for content_class: ContentClass in modClass.ContentBank:
		content_data.append(str(content_class.Data))
	$Window/RichTextLabel.text = "\n".join(content_data)


func _on_cancel_loading_pressed():
	$LoadingWindow/Panel/MarginContainer/VBoxContainer/HBoxContainer/Cancel.disabled = true
	close()



func _on_search_pressed() -> void:
	$ModEditor/Panel/VBoxContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/Filters/SearchLine.grab_focus()

func _on_search_line_text_changed(new_text: String) -> void:
	_search_query = new_text.strip_edges()
	refresh_content_list()
	_apply_file_tree_filters()

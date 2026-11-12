@tool
class_name TabWorkspace
extends Control

signal tab_selected(group_id: StringName, tab_id: StringName)
signal tab_moved(tab_id: StringName, source_group: StringName, target_group: StringName)
signal tab_closed(group_id: StringName, tab_id: StringName)
signal group_added(group_id: StringName)
signal group_moved(group_id: StringName, target_index: int)
signal drop_target_changed(group_id: StringName, tab_index: int, in_tab_strip: bool)

class TabButton:
	extends Button

	var workspace: TabWorkspace
	var group_id: StringName
	var tab_id: StringName
	var drag_preview_text: String
	var drop_marker: ColorRect

	func show_drop_marker(at_end: bool) -> void:
		if not is_instance_valid(drop_marker):
			drop_marker = ColorRect.new()
			drop_marker.color = Color(1.0, 0.82, 0.4)
			drop_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
			drop_marker.z_index = 5
			add_child(drop_marker)
		drop_marker.set_anchors_and_offsets_preset(
			Control.PRESET_RIGHT_WIDE if at_end else Control.PRESET_LEFT_WIDE
		)
		drop_marker.offset_left = -2
		drop_marker.offset_right = 2
		drop_marker.offset_top = 2
		drop_marker.offset_bottom = -2

	func hide_drop_marker() -> void:
		if is_instance_valid(drop_marker):
			drop_marker.queue_free()
		drop_marker = null

	func _get_drag_data(_position: Vector2) -> Variant:
		var preview := PanelContainer.new()
		var preview_label := Label.new()
		preview_label.text = drag_preview_text
		preview.add_child(preview_label)
		preview.custom_minimum_size = Vector2(130, 34)
		workspace.set_drag_preview(preview)
		return {"source": "tab_workspace", "tab_id": str(tab_id)}


class GroupHeader:
	extends Button

	var workspace: TabWorkspace
	var group_id: StringName

	func _get_drag_data(_position: Vector2) -> Variant:
		var preview := PanelContainer.new()
		var preview_label := Label.new()
		preview_label.text = text
		preview.add_child(preview_label)
		preview.custom_minimum_size = Vector2(130, 32)
		workspace.set_drag_preview(preview)
		return {"source": "tab_workspace_group", "group_id": str(group_id)}


class TabStrip:
	extends BoxContainer

	var workspace: TabWorkspace
	var group_id: StringName

	func _can_drop_data(position: Vector2, data: Variant) -> bool:
		if workspace == null or not workspace._is_tab_drag_data(data):
			return false
		workspace._show_drop_target(
			group_id,
			workspace._tab_index_at_position(self, position),
			true
		)
		return true

	func _drop_data(position: Vector2, data: Variant) -> void:
		var target_index := workspace._tab_index_at_position(self, position)
		workspace.move_tab(
			StringName(data["tab_id"]),
			group_id,
			target_index
		)
		workspace._clear_drop_target()

	func _draw() -> void:
		if (
			workspace == null
			or not workspace._is_drop_target(group_id, true)
			or get_child_count() > 0
		):
			return
		var target_index: int = workspace._drop_target_index
		var marker_position := 0.0
		if get_child_count() > 0:
			if target_index >= get_child_count():
				var last_child := get_child(get_child_count() - 1) as Control
				marker_position = (
					last_child.position.y + last_child.size.y
					if vertical
					else last_child.position.x + last_child.size.x
				)
			else:
				var target_child := get_child(target_index) as Control
				marker_position = target_child.position.y if vertical else target_child.position.x
		var marker_color := Color(1.0, 0.82, 0.4)
		if vertical:
			draw_rect(Rect2(Vector2(0, marker_position - 2), Vector2(size.x, 4)), marker_color)
		else:
			draw_rect(Rect2(Vector2(marker_position - 2, 0), Vector2(4, size.y)), marker_color)


class GroupPanel:
	extends PanelContainer

	var workspace: TabWorkspace
	var group_id: StringName

	func _can_drop_data(_position: Vector2, data: Variant) -> bool:
		if workspace == null:
			return false
		if workspace._is_group_drag_data(data):
			var source_id := StringName(data["group_id"])
			if source_id == group_id:
				return false
			workspace._show_group_drop_target(group_id)
			return true
		if not workspace._is_tab_drag_data(data):
			return false
		workspace._show_drop_target(group_id, -1, false)
		return true

	func _drop_data(position: Vector2, data: Variant) -> void:
		if workspace._is_group_drag_data(data):
			var group: Dictionary = workspace._groups[group_id]
			var target_index := workspace._group_order.find(group_id)
			var coordinate: float = position.x if not workspace.split_vertical else position.y
			var panel: Control = group["panel"]
			var extent: float = panel.size.x if not workspace.split_vertical else panel.size.y
			if coordinate > extent * 0.5:
				target_index += 1
			var source_index: int = workspace._group_order.find(StringName(data["group_id"]))
			if target_index > source_index:
				target_index -= 1
			workspace.move_group(StringName(data["group_id"]), target_index)
			workspace._clear_group_drop_target()
			return
		workspace.move_tab(StringName(data["tab_id"]), group_id)
		workspace._clear_drop_target()

	func _draw() -> void:
		if workspace == null:
			return
		if workspace._is_drop_target(group_id, false):
			draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.82, 0.4), false, 3.0)
		elif workspace._group_drop_target == group_id:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.55, 0.8, 1.0), false, 3.0)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_DRAG_END and workspace != null:
			workspace._clear_drop_target()
			workspace._clear_group_drop_target()


@export_group("Group Layout")
@export var split_vertical := false:
	set(value):
		split_vertical = value
		_apply_split_layout()

@export_group("Tab Pages")
@export var pages: Array[TabWorkspacePage] = []:
	set(value):
		_disconnect_page_resources()
		pages = value
		_connect_page_resources()
		if is_node_ready():
			_rebuild_authored_pages()

@export_group("Tab Appearance")
@export var tabs_vertical := false:
	set(value):
		tabs_vertical = value
		for group_id: StringName in _group_order:
			_update_group_layout(group_id)
			_render_group(group_id)

@export var compact_tabs := false:
	set(value):
		compact_tabs = value
		for group_id: StringName in _group_order:
			_update_group_layout(group_id)
			_render_group(group_id)

@export_group("Panel Styling")
@export var tab_panel_stylebox: StyleBox:
	set(value):
		tab_panel_stylebox = value
		_apply_panel_styles()

@export var content_panel_stylebox: StyleBox:
	set(value):
		content_panel_stylebox = value
		_apply_panel_styles()

var _groups: Dictionary = {}
var _tabs: Dictionary = {}
var _group_order: Array[StringName] = []
var _root_box: VBoxContainer
var _groups_container: BoxContainer
var _rebuilding_pages := false
var _drop_target_group: StringName = &""
var _drop_target_index := -1
var _drop_target_in_strip := false
var _group_drop_target: StringName = &""


func _ready() -> void:
	_build_shell()
	_connect_page_resources()
	_rebuild_authored_pages()


func _connect_page_resources() -> void:
	for page: TabWorkspacePage in pages:
		if is_instance_valid(page) and not page.changed.is_connected(_on_page_resource_changed):
			page.changed.connect(_on_page_resource_changed)


func _disconnect_page_resources() -> void:
	for page: TabWorkspacePage in pages:
		if is_instance_valid(page) and page.changed.is_connected(_on_page_resource_changed):
			page.changed.disconnect(_on_page_resource_changed)


func _on_page_resource_changed() -> void:
	if Engine.is_editor_hint() and is_node_ready():
		_rebuild_authored_pages()


func _rebuild_authored_pages() -> void:
	if _rebuilding_pages or not is_instance_valid(_groups_container):
		return
	_rebuilding_pages = true
	for group: Dictionary in _groups.values():
		if is_instance_valid(group["panel"]):
			group["panel"].queue_free()
	_groups.clear()
	_tabs.clear()
	_group_order.clear()

	var selected_tabs: Dictionary = {}
	for index in pages.size():
		var page := pages[index]
		if not is_instance_valid(page):
			continue
		var group_id: StringName = page.group_id
		if group_id.is_empty():
			group_id = &"main"
		if not _groups.has(group_id):
			var group_title := page.group_title if not page.group_title.is_empty() else str(group_id)
			add_group(group_title, group_id)

		var tab_id := page.tab_id
		if tab_id.is_empty():
			tab_id = StringName("page_%d" % (index + 1))
		var content: Control
		if is_instance_valid(page.content_scene):
			content = page.content_scene.instantiate() as Control
			if not is_instance_valid(content):
				push_error("TabWorkspace: page content scene root must be a Control.")
				continue
			content.name = String(tab_id)
		if not add_tab(
			group_id,
			tab_id,
			page.title,
			content,
			page.icon,
			page.closable,
			page.tab_scene
		):
			if is_instance_valid(content):
				content.queue_free()
			continue
		if page.selected_on_start and not selected_tabs.has(group_id):
			selected_tabs[group_id] = tab_id

	for group_id: StringName in _group_order:
		var group: Dictionary = _groups[group_id]
		var selected_id: StringName = selected_tabs.get(
			group_id,
			group["tabs"][0] if not group["tabs"].is_empty() else &""
		)
		if not selected_id.is_empty():
			select_tab(group_id, selected_id)
	if _groups.is_empty():
		add_group("Основная", &"main")
	_rebuilding_pages = false


func add_group(title: String, group_id: StringName = &"") -> StringName:
	if group_id.is_empty():
		group_id = StringName("group_%d" % (_groups.size() + 1))
	if _groups.has(group_id):
		push_warning("TabWorkspace: group already exists: %s" % group_id)
		return &""

	var panel := GroupPanel.new()
	panel.workspace = self
	panel.group_id = group_id
	panel.custom_minimum_size = Vector2(220, 180)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var group_box := VBoxContainer.new()
	group_box.add_theme_constant_override("separation", 5)
	margin.add_child(group_box)

	var header := HBoxContainer.new()
	group_box.add_child(header)

	var group_header := GroupHeader.new()
	group_header.workspace = self
	group_header.group_id = group_id
	group_header.text = title
	group_header.flat = true
	group_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group_header.tooltip_text = "Перетащите заголовок, чтобы переставить панель"
	header.add_child(group_header)

	var count_label := Label.new()
	count_label.modulate = Color(0.7, 0.72, 0.67)
	header.add_child(count_label)

	var body := BoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	group_box.add_child(body)

	var tab_panel := PanelContainer.new()
	tab_panel.set_meta("workspace_group_id", group_id)
	tab_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(tab_panel)

	var tab_scroll := ScrollContainer.new()
	tab_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_panel.add_child(tab_scroll)

	var strip := TabStrip.new()
	strip.workspace = self
	strip.group_id = group_id
	strip.add_theme_constant_override("separation", 3)
	tab_scroll.add_child(strip)

	var content_panel := PanelContainer.new()
	content_panel.set_meta("workspace_group_id", group_id)
	content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(content_panel)

	var content_box := VBoxContainer.new()
	content_panel.add_child(content_box)

	var empty_label := Label.new()
	empty_label.text = "У этой вкладки нет связанного содержимого."
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_box.add_child(empty_label)

	var drop_hint := Label.new()
	drop_hint.text = "Отпустите, чтобы встроить вкладку в эту панель"
	drop_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drop_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	drop_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	drop_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drop_hint.size_flags_vertical = Control.SIZE_EXPAND_FILL
	drop_hint.add_theme_color_override("font_color", Color(1.0, 0.82, 0.4))
	drop_hint.hide()
	group_box.add_child(drop_hint)

	_groups[group_id] = {
		"title": title,
		"panel": panel,
		"header": group_header,
		"header_count": count_label,
		"body": body,
		"tab_panel": tab_panel,
		"tab_scroll": tab_scroll,
		"tab_strip": strip,
		"content_panel": content_panel,
		"content_box": content_box,
		"empty_label": empty_label,
		"drop_hint": drop_hint,
		"tabs": [],
		"selected": &"",
	}
	_group_order.append(group_id)
	if is_instance_valid(_groups_container):
		_groups_container.add_child(panel)
		_update_group_layout(group_id)
		_apply_panel_styles(group_id)
		_render_group(group_id)
	group_added.emit(group_id)
	return group_id


func remove_group(group_id: StringName) -> bool:
	if not _groups.has(group_id) or _groups.size() <= 1:
		return false
	if not _groups[group_id]["tabs"].is_empty():
		return false

	var group: Dictionary = _groups[group_id]
	if is_instance_valid(group["panel"]):
		group["panel"].queue_free()
	_groups.erase(group_id)
	_group_order.erase(group_id)
	return true


func move_group(group_id: StringName, target_index: int) -> bool:
	if not _groups.has(group_id) or not is_instance_valid(_groups_container):
		return false
	var source_index := _group_order.find(group_id)
	if source_index < 0:
		return false
	target_index = clampi(target_index, 0, _group_order.size() - 1)
	if target_index == source_index:
		return false

	_group_order.remove_at(source_index)
	_group_order.insert(target_index, group_id)
	_groups_container.move_child(_groups[group_id]["panel"], target_index)
	group_moved.emit(group_id, target_index)
	return true


func get_tab_panel(group_id: StringName) -> Control:
	if not _groups.has(group_id):
		return null
	return _groups[group_id]["tab_panel"]


func get_content_panel(group_id: StringName) -> Control:
	if not _groups.has(group_id):
		return null
	return _groups[group_id]["content_panel"]


func get_bound_group_id(panel: Control) -> StringName:
	if not is_instance_valid(panel) or not panel.has_meta("workspace_group_id"):
		return &""
	return StringName(panel.get_meta("workspace_group_id"))


func add_tab(
	group_id: StringName,
	tab_id: StringName,
	title: String,
	content: Control = null,
	icon: String = "",
	closable: bool = true,
	tab_scene: PackedScene = null
) -> bool:
	if not _groups.has(group_id):
		push_warning("TabWorkspace: unknown group: %s" % group_id)
		return false
	if tab_id.is_empty() or _tabs.has(tab_id):
		push_warning("TabWorkspace: tab id is empty or already exists: %s" % tab_id)
		return false
	if is_instance_valid(content):
		for existing_tab: Dictionary in _tabs.values():
			if existing_tab["content"] == content:
				push_warning("TabWorkspace: a content control can belong to only one tab")
				return false

	var group: Dictionary = _groups[group_id]
	group["tabs"].append(tab_id)
	group["selected"] = tab_id
	_tabs[tab_id] = {
		"title": title,
		"icon": icon,
		"group_id": group_id,
		"content": content,
		"closable": closable,
		"modified": false,
		"tab_scene": tab_scene,
		"tab_visual": null,
	}
	if is_instance_valid(content):
		var content_box: VBoxContainer = group["content_box"]
		_attach_content(content, content_box)
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_render_group(group_id)
	tab_selected.emit(group_id, tab_id)
	return true


func select_tab(group_id: StringName, tab_id: StringName) -> bool:
	if not _groups.has(group_id) or not _tabs.has(tab_id):
		return false
	if _tabs[tab_id]["group_id"] != group_id:
		return false

	_groups[group_id]["selected"] = tab_id
	_render_group(group_id)
	tab_selected.emit(group_id, tab_id)
	return true


func move_tab(
	tab_id: StringName,
	target_group_id: StringName,
	target_index: int = -1
) -> bool:
	if not _tabs.has(tab_id) or not _groups.has(target_group_id):
		return false

	var tab: Dictionary = _tabs[tab_id]
	var source_group_id: StringName = tab["group_id"]
	var source_group: Dictionary = _groups[source_group_id]
	var target_group: Dictionary = _groups[target_group_id]
	var source_index: int = source_group["tabs"].find(tab_id)
	if source_index < 0:
		return false

	source_group["tabs"].remove_at(source_index)
	if source_group_id == target_group_id and target_index > source_index:
		target_index -= 1
	target_index = (
		target_group["tabs"].size()
		if target_index < 0
		else clampi(target_index, 0, target_group["tabs"].size())
	)
	target_group["tabs"].insert(target_index, tab_id)
	tab["group_id"] = target_group_id

	if source_group["selected"] == tab_id:
		source_group["selected"] = (
			source_group["tabs"][mini(source_index, source_group["tabs"].size() - 1)]
			if not source_group["tabs"].is_empty()
			else &""
		)
	target_group["selected"] = tab_id

	var content: Control = tab["content"]
	if is_instance_valid(content):
		var target_content_box: VBoxContainer = target_group["content_box"]
		_attach_content(content, target_content_box)

	_render_group(source_group_id)
	if target_group_id != source_group_id:
		_render_group(target_group_id)
	tab_moved.emit(tab_id, source_group_id, target_group_id)
	return true


func close_tab(tab_id: StringName) -> bool:
	if not _tabs.has(tab_id):
		return false
	var tab: Dictionary = _tabs[tab_id]
	if not tab["closable"]:
		return false

	var group_id: StringName = tab["group_id"]
	var group: Dictionary = _groups[group_id]
	var tab_index: int = group["tabs"].find(tab_id)
	group["tabs"].erase(tab_id)
	if group["selected"] == tab_id:
		group["selected"] = (
			group["tabs"][mini(tab_index, group["tabs"].size() - 1)]
			if not group["tabs"].is_empty()
			else &""
		)

	var content: Control = tab["content"]
	if is_instance_valid(content):
		content.queue_free()
	_tabs.erase(tab_id)
	_render_group(group_id)
	tab_closed.emit(group_id, tab_id)
	return true


func set_tab_modified(tab_id: StringName, modified: bool) -> bool:
	if not _tabs.has(tab_id):
		return false
	_tabs[tab_id]["modified"] = modified
	_render_group(_tabs[tab_id]["group_id"])
	return true


func set_split_vertical(value: bool) -> void:
	split_vertical = value


func set_tabs_vertical(value: bool) -> void:
	tabs_vertical = value


func set_compact_tabs(value: bool) -> void:
	compact_tabs = value


func get_group_ids() -> Array[StringName]:
	return _group_order.duplicate()


func get_tab_ids(group_id: StringName) -> Array[StringName]:
	if not _groups.has(group_id):
		return []
	var result: Array[StringName] = []
	for tab_id: StringName in _groups[group_id]["tabs"]:
		result.append(tab_id)
	return result


func get_tab_group(tab_id: StringName) -> StringName:
	if not _tabs.has(tab_id):
		return &""
	return _tabs[tab_id]["group_id"]


func get_selected_tab_id(group_id: StringName) -> StringName:
	if not _groups.has(group_id):
		return &""
	return _groups[group_id]["selected"]


func get_tab_content(tab_id: StringName) -> Control:
	if not _tabs.has(tab_id):
		return null
	return _tabs[tab_id]["content"]


func is_tab_modified(tab_id: StringName) -> bool:
	return _tabs.has(tab_id) and _tabs[tab_id]["modified"]


func get_tab_visual(tab_id: StringName) -> Control:
	if not _tabs.has(tab_id):
		return null
	return _tabs[tab_id]["tab_visual"]


func serialize_layout() -> Dictionary:
	var serialized_groups: Array[Dictionary] = []
	for group_id: StringName in _group_order:
		var group: Dictionary = _groups[group_id]
		var serialized_tabs: Array[String] = []
		for tab_id: StringName in group["tabs"]:
			serialized_tabs.append(str(tab_id))
		serialized_groups.append({
			"id": str(group_id),
			"title": group["title"],
			"tabs": serialized_tabs,
			"selected": str(group["selected"]),
		})
	return {
		"version": 1,
		"split_vertical": split_vertical,
		"tabs_vertical": tabs_vertical,
		"compact_tabs": compact_tabs,
		"groups": serialized_groups,
	}


func _build_shell() -> void:
	var background := PanelContainer.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	background.add_child(margin)

	_root_box = VBoxContainer.new()
	_root_box.add_theme_constant_override("separation", 6)
	margin.add_child(_root_box)

	_groups_container = BoxContainer.new()
	_groups_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_groups_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root_box.add_child(_groups_container)
	_apply_split_layout()


func _apply_split_layout() -> void:
	if is_instance_valid(_groups_container):
		_groups_container.vertical = split_vertical


func _update_group_layout(group_id: StringName) -> void:
	if not _groups.has(group_id):
		return
	var group: Dictionary = _groups[group_id]
	var body: BoxContainer = group["body"]
	var tab_panel: PanelContainer = group["tab_panel"]
	var scroll: ScrollContainer = group["tab_scroll"]
	var strip: TabStrip = group["tab_strip"]

	body.vertical = not tabs_vertical
	strip.vertical = tabs_vertical
	tab_panel.size_flags_horizontal = (
		Control.SIZE_SHRINK_BEGIN if tabs_vertical else Control.SIZE_EXPAND_FILL
	)
	tab_panel.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL if tabs_vertical else Control.SIZE_SHRINK_BEGIN
	)
	if tabs_vertical:
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.custom_minimum_size = Vector2(150 if not compact_tabs else 62, 0)
	else:
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.custom_minimum_size = Vector2(0, 40 if not compact_tabs else 30)


func _render_group(group_id: StringName) -> void:
	if not _groups.has(group_id):
		return
	var group: Dictionary = _groups[group_id]
	var strip: TabStrip = group["tab_strip"]
	var content_box: VBoxContainer = group["content_box"]
	var empty_label: Label = group["empty_label"]

	for child: Node in strip.get_children():
		strip.remove_child(child)
		child.queue_free()
	for tab_id: StringName in group["tabs"]:
		_tabs[tab_id]["tab_visual"] = null
	for child: Node in content_box.get_children():
		if child != empty_label:
			child.hide()

	var tab_ids: Array = group["tabs"]
	group["header_count"].text = "%d" % tab_ids.size()
	for tab_id: StringName in tab_ids:
		var tab: Dictionary = _tabs[tab_id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		strip.add_child(row)

		var tab_button := TabButton.new()
		tab_button.workspace = self
		tab_button.group_id = group_id
		tab_button.tab_id = tab_id
		tab_button.theme_type_variation = "VTab" if tabs_vertical else "HTab"
		tab_button.drag_preview_text = _tab_button_text(tab, tab_id)
		tab_button.tooltip_text = str(tab["title"])
		tab_button.toggle_mode = true
		tab_button.button_pressed = group["selected"] == tab_id
		tab_button.disabled = false
		tab_button.custom_minimum_size = (
			Vector2(52, 34) if compact_tabs else Vector2(90, 34)
		)
		tab_button.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL if tabs_vertical else Control.SIZE_SHRINK_BEGIN
		)
		tab_button.pressed.connect(select_tab.bind(group_id, tab_id))
		var tab_scene: PackedScene = tab.get("tab_scene")
		if is_instance_valid(tab_scene):
			var tab_visual := tab_scene.instantiate() as Control
			if not is_instance_valid(tab_visual):
				push_error("TabWorkspace: tab scene root must be a Control.")
				tab_button.text = _tab_button_text(tab, tab_id)
			else:
				_configure_tab_visual(tab_visual, tab, group["selected"] == tab_id)
				tab_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				tab_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_set_tab_visual_mouse_filter(tab_visual)
				tab_button.flat = true
				tab_button.text = ""
				tab_button.add_child(tab_visual)
				tab["tab_visual"] = tab_visual
		else:
			tab_button.text = _tab_button_text(tab, tab_id)
		row.add_child(tab_button)

		if tab["closable"] and not compact_tabs:
			var close_button := Button.new()
			close_button.text = "×"
			close_button.tooltip_text = "Закрыть вкладку"
			close_button.theme_type_variation = "ButtonUnborderTiny"
			close_button.custom_minimum_size = Vector2(26, 30)
			close_button.pressed.connect(close_tab.bind(tab_id))
			row.add_child(close_button)

	var selected_id: StringName = group["selected"]
	var selected_content: Control = (
		_tabs[selected_id]["content"]
		if _tabs.has(selected_id)
		else null
	)
	empty_label.visible = not is_instance_valid(selected_content)
	if is_instance_valid(selected_content):
		_attach_content(selected_content, content_box)
		selected_content.show()
		selected_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		selected_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	group["drop_hint"].visible = _is_drop_target(group_id, false)
	group["panel"].queue_redraw()
	strip.queue_redraw()


func _attach_content(content: Control, content_box: VBoxContainer) -> void:
	if content.get_parent() == content_box:
		return
	if content.get_parent() == null:
		content_box.add_child(content)
	else:
		content.reparent(content_box)


func _tab_button_text(tab: Dictionary, tab_id: StringName) -> String:
	if compact_tabs:
		return str(tab["icon"]) if not str(tab["icon"]).is_empty() else str(tab_id)
	if str(tab["icon"]).is_empty():
		return str(tab["title"])
	var modified_marker := " •" if tab["modified"] else ""
	return "%s  %s%s" % [tab["icon"], tab["title"], modified_marker]


func _is_tab_drag_data(data: Variant) -> bool:
	return (
		typeof(data) == TYPE_DICTIONARY
		and data.get("source") == "tab_workspace"
		and _tabs.has(StringName(data.get("tab_id", "")))
	)


func _is_group_drag_data(data: Variant) -> bool:
	return (
		typeof(data) == TYPE_DICTIONARY
		and data.get("source") == "tab_workspace_group"
		and _groups.has(StringName(data.get("group_id", "")))
	)


func _show_group_drop_target(group_id: StringName) -> void:
	_group_drop_target = group_id
	for candidate_id: StringName in _group_order:
		_groups[candidate_id]["panel"].queue_redraw()


func _clear_group_drop_target() -> void:
	_group_drop_target = &""
	for group_id: StringName in _group_order:
		_groups[group_id]["panel"].queue_redraw()


func _apply_panel_styles(group_id: StringName = &"") -> void:
	var group_ids: Array[StringName] = []
	if group_id.is_empty():
		group_ids = _group_order.duplicate()
	else:
		group_ids.append(group_id)
	for current_id: StringName in group_ids:
		if not _groups.has(current_id):
			continue
		var group: Dictionary = _groups[current_id]
		_apply_panel_style(group["tab_panel"], tab_panel_stylebox)
		_apply_panel_style(group["content_panel"], content_panel_stylebox)


func _apply_panel_style(panel: PanelContainer, stylebox: StyleBox) -> void:
	if not is_instance_valid(panel):
		return
	if is_instance_valid(stylebox):
		panel.add_theme_stylebox_override("panel", stylebox)
	else:
		panel.remove_theme_stylebox_override("panel")


func _configure_tab_visual(
	visual: Control,
	tab: Dictionary,
	selected: bool
) -> void:
	var properties := {
		"tab_title": str(tab["title"]),
		"tab_icon": str(tab["icon"]),
		"tab_selected": selected,
		"tab_modified": bool(tab["modified"]),
		"compact_mode": compact_tabs,
	}
	var available_properties: Dictionary = {}
	for property: Dictionary in visual.get_property_list():
		available_properties[property["name"]] = true
	for property_name: String in properties:
		if available_properties.has(property_name):
			visual.set(property_name, properties[property_name])


func _set_tab_visual_mouse_filter(node: Node) -> void:
	for child: Node in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_tab_visual_mouse_filter(child)


func _show_drop_target(
	group_id: StringName,
	tab_index: int,
	in_tab_strip: bool
) -> void:
	_drop_target_group = group_id
	_drop_target_index = tab_index
	_drop_target_in_strip = in_tab_strip
	for candidate_id: StringName in _group_order:
		var group: Dictionary = _groups[candidate_id]
		group["drop_hint"].visible = candidate_id == group_id and not in_tab_strip
		for row: Node in group["tab_strip"].get_children():
			if row.get_child_count() > 0 and row.get_child(0) is TabButton:
				(row.get_child(0) as TabButton).hide_drop_marker()
		if candidate_id == group_id and in_tab_strip:
			var strip: TabStrip = group["tab_strip"]
			if strip.get_child_count() > 0:
				var marker_index := clampi(tab_index, 0, strip.get_child_count() - 1)
				var at_end := tab_index >= strip.get_child_count()
				var row := strip.get_child(marker_index)
				if row.get_child_count() > 0 and row.get_child(0) is TabButton:
					(row.get_child(0) as TabButton).show_drop_marker(at_end)
		group["panel"].queue_redraw()
		group["tab_strip"].queue_redraw()
	drop_target_changed.emit(group_id, tab_index, in_tab_strip)


func _clear_drop_target() -> void:
	if _drop_target_group.is_empty():
		return
	_drop_target_group = &""
	_drop_target_index = -1
	_drop_target_in_strip = false
	for group: Dictionary in _groups.values():
		group["drop_hint"].hide()
		for row: Node in group["tab_strip"].get_children():
			if row.get_child_count() > 0 and row.get_child(0) is TabButton:
				(row.get_child(0) as TabButton).hide_drop_marker()
		group["panel"].queue_redraw()
		group["tab_strip"].queue_redraw()
	drop_target_changed.emit(&"", -1, false)


func _is_drop_target(group_id: StringName, in_tab_strip: bool) -> bool:
	return _drop_target_group == group_id and _drop_target_in_strip == in_tab_strip


func _tab_index_at_position(strip: TabStrip, position: Vector2) -> int:
	var horizontal_position := position.x if not strip.vertical else position.y
	for index in strip.get_child_count():
		var child := strip.get_child(index) as Control
		var midpoint := (
			child.position.x + child.size.x / 2.0
			if not strip.vertical
			else child.position.y + child.size.y / 2.0
		)
		if horizontal_position < midpoint:
			return index
	return strip.get_child_count()

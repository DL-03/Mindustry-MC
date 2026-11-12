@tool
extends Button
class_name MindIButton

@export_group("Content")
@export var left_icon: MindLabel:
	set(value):
		_disconnect_label(left_icon)
		left_icon = value
		_connect_label(left_icon)
		_sync_content()

@export var label: MindLabel:
	set(value):
		_disconnect_label(label)
		label = value
		_connect_label(label)
		_sync_content()

@export var right_icon: MindLabel:
	set(value):
		_disconnect_label(right_icon)
		right_icon = value
		_connect_label(right_icon)
		_sync_content()

@export_multiline var real_text: String = "[emb]MindIButton":
	set(value):
		real_text = value
		_real_text_assignment_count += 1
		_real_text_was_set = is_instance_valid(label) or _real_text_assignment_count > 1
		_sync_content()

@export var real_text_icon_left: String = "[emb offset=3]0":
	set(value):
		real_text_icon_left = value
		_real_text_icon_left_assignment_count += 1
		_real_text_icon_left_was_set = is_instance_valid(left_icon) \
			or _real_text_icon_left_assignment_count > 1
		_sync_content()

@export var real_text_icon_right: String = "[emb offset=3]0":
	set(value):
		real_text_icon_right = value
		_real_text_icon_right_assignment_count += 1
		_real_text_icon_right_was_set = is_instance_valid(right_icon) \
			or _real_text_icon_right_assignment_count > 1
		_sync_content()

@export var show_left_icon := true:
	set(value):
		show_left_icon = value
		_sync_content()

@export var show_right_icon := true:
	set(value):
		show_right_icon = value
		_sync_content()

@export_multiline var real_tooltip_text: String = "":
	set(value):
		real_tooltip_text = value
		_update_tooltip()

@export_group("Layout")
@export_range(0, 64, 1, "or_greater") var content_separation: int = 5:
	set(value):
		content_separation = maxi(value, 0)
		override_internal_layout = true
		_sync_layout()

@export var content_margins: Vector4i = Vector4i(15, 15, 15, 15):
	set(value):
		content_margins = value
		override_internal_layout = true
		_sync_layout()

@export_enum("Left", "Center", "Right") var h_aligment: int = 1:
	set(value):
		h_aligment = clampi(value, 0, 2)
		override_internal_layout = true
		_sync_layout()

@export var override_internal_layout := false:
	set(value):
		override_internal_layout = value
		_sync_layout()

@export_group("Appearance")
@export_range(1, 128, 1, "or_greater") var font_size: int = 16:
	set(value):
		font_size = maxi(value, 1)
		_sync_appearance()

@export_range(1, 128, 1, "or_greater") var icon_size: int = 26:
	set(value):
		icon_size = maxi(value, 1)
		_sync_appearance()

@export_group("Colors")
@export var font_color: Color = Color.WHITE:
	set(value):
		font_color = value
		_sync_appearance()

@export var icon_color: Color = Color.WHITE:
	set(value):
		icon_color = value
		_sync_appearance()

@export var font_color_disabled: Color = Color.from_string("#454545", Color.DIM_GRAY):
	set(value):
		font_color_disabled = value
		_sync_appearance()

@export var icon_color_disabled: Color = Color.from_string("#454545", Color.DIM_GRAY):
	set(value):
		icon_color_disabled = value
		_sync_appearance()

var _regex := RegEx.new()
var _last_disabled_state := false
var _left_icon_scene_visibility := true
var _right_icon_scene_visibility := true
var _icon_visibility_captured := false
var _real_text_was_set := false
var _real_text_icon_left_was_set := false
var _real_text_icon_right_was_set := false
var _real_text_assignment_count := 0
var _real_text_icon_left_assignment_count := 0
var _real_text_icon_right_assignment_count := 0

const INTERNAL_LAYOUT: PackedScene = preload("res://widgets/mind_i_button_content.tscn")
const TOOLTIP_SCENE: PackedScene = preload("res://widgets/mind_tooltip.tscn")


func _init() -> void:
	_real_text_was_set = false
	_real_text_icon_left_was_set = false
	_real_text_icon_right_was_set = false
	_real_text_assignment_count = 0
	_real_text_icon_left_assignment_count = 0
	_real_text_icon_right_assignment_count = 0


func _enter_tree() -> void:
	_ensure_internal_layout()
	_resolve_internal_nodes()
	_set_internal_mouse_filter()
	_hide_native_button_text()


func _ready() -> void:
	_regex.compile("\\[.*?\\]")
	_resolve_internal_nodes()
	_set_internal_mouse_filter()
	_hide_native_button_text()
	_connect_label(left_icon)
	_connect_label(label)
	_connect_label(right_icon)
	_capture_icon_visibility()
	_sync_content()
	_sync_layout()
	_sync_appearance()
	_update_tooltip()
	_last_disabled_state = disabled
	set_process(true)


func _ensure_internal_layout() -> void:
	if not is_instance_valid(get_node_or_null("MarginContainer")):
		var layout := INTERNAL_LAYOUT.instantiate()
		add_child(layout)
		if Engine.is_editor_hint():
			_lock_internal_layout(layout)
	if not is_instance_valid(get_node_or_null("_MindTooltip")):
		var tooltip := TOOLTIP_SCENE.instantiate()
		tooltip.name = "_MindTooltip"
		add_child(tooltip)
		if Engine.is_editor_hint():
			_lock_internal_layout(tooltip)


func _lock_internal_layout(node: Node) -> void:
	node.set_meta("_edit_lock_", true)
	for child: Node in node.get_children():
		_lock_internal_layout(child)


func _resolve_internal_nodes() -> void:
	if not is_instance_valid(left_icon):
		left_icon = get_node_or_null("MarginContainer/HBoxContainer/LeftIcon") as MindLabel
	if not is_instance_valid(label):
		label = get_node_or_null("MarginContainer/HBoxContainer/Label") as MindLabel
	if not is_instance_valid(right_icon):
		right_icon = get_node_or_null("MarginContainer/HBoxContainer/RightIcon") as MindLabel


func _set_internal_mouse_filter() -> void:
	var internal_layout := get_node_or_null("MarginContainer")
	if is_instance_valid(internal_layout):
		_set_mouse_filter_recursive(internal_layout)


func _set_mouse_filter_recursive(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		_set_mouse_filter_recursive(child)


func _process(_delta: float) -> void:
	if _last_disabled_state == disabled:
		return
	_last_disabled_state = disabled
	_sync_appearance()


func _sync_content() -> void:
	_capture_icon_visibility()
	if is_instance_valid(left_icon):
		if _real_text_icon_left_was_set:
			left_icon.real_text = real_text_icon_left
		left_icon.visible = show_left_icon and (
			_left_icon_scene_visibility or not real_text_icon_left.is_empty()
		)
	if is_instance_valid(label) and _real_text_was_set:
		label.real_text = real_text
	if is_instance_valid(right_icon):
		if _real_text_icon_right_was_set:
			right_icon.real_text = real_text_icon_right
		right_icon.visible = show_right_icon and (
			_right_icon_scene_visibility or not real_text_icon_right.is_empty()
		)

	_refresh_native_text()


func _capture_icon_visibility() -> void:
	if _icon_visibility_captured:
		return
	if not is_instance_valid(left_icon) or not is_instance_valid(right_icon):
		return
	_left_icon_scene_visibility = left_icon.visible
	_right_icon_scene_visibility = right_icon.visible
	_icon_visibility_captured = true


func _refresh_native_text() -> void:
	if not is_instance_valid(label) or not _regex.is_valid():
		return

	var displayed_parts := PackedStringArray()
	if is_instance_valid(left_icon) and left_icon.visible and not left_icon.text.is_empty():
		displayed_parts.append(left_icon.text)
	if label.visible and not label.text.is_empty():
		displayed_parts.append(label.text)
	if is_instance_valid(right_icon) and right_icon.visible and not right_icon.text.is_empty():
		displayed_parts.append(right_icon.text)
	text = _regex.sub(" ".join(displayed_parts).strip_edges(), "", true)


func _connect_label(target: MindLabel) -> void:
	if is_instance_valid(target) \
	and not target.display_text_changed.is_connected(_on_child_text_changed):
		target.display_text_changed.connect(_on_child_text_changed)


func _disconnect_label(target: MindLabel) -> void:
	if is_instance_valid(target) \
	and target.display_text_changed.is_connected(_on_child_text_changed):
		target.display_text_changed.disconnect(_on_child_text_changed)


func _on_child_text_changed(_value: String) -> void:
	_refresh_native_text()


func _sync_layout() -> void:
	if not override_internal_layout:
		return
	var row := get_node_or_null("MarginContainer/HBoxContainer") as HBoxContainer
	if is_instance_valid(row):
		row.add_theme_constant_override("separation", content_separation)
	var margin := get_node_or_null("MarginContainer") as MarginContainer
	if is_instance_valid(margin):
		margin.add_theme_constant_override("margin_left", content_margins.x)
		margin.add_theme_constant_override("margin_top", content_margins.y)
		margin.add_theme_constant_override("margin_right", content_margins.z)
		margin.add_theme_constant_override("margin_bottom", content_margins.w)
	if is_instance_valid(label):
		label.horizontal_alignment = [
			HORIZONTAL_ALIGNMENT_LEFT,
			HORIZONTAL_ALIGNMENT_CENTER,
			HORIZONTAL_ALIGNMENT_RIGHT,
		][h_aligment]


func _sync_appearance() -> void:
	var resolved_font_color := font_color_disabled if disabled else font_color
	var resolved_icon_color := icon_color_disabled if disabled else icon_color
	if is_instance_valid(label):
		label.font_color = resolved_font_color
		label.add_theme_font_size_override("font_size", font_size)
	for icon_label: MindLabel in [left_icon, right_icon]:
		if is_instance_valid(icon_label):
			icon_label.font_color = resolved_icon_color
			icon_label.add_theme_font_size_override("font_size", icon_size)


func upd() -> void:
	_sync_content()


func _on_icon_text_left_ready() -> void:
	_sync_content()


func _on_icon_text_right_ready() -> void:
	_sync_content()


func _on_text_ready() -> void:
	_sync_content()
	_sync_appearance()


func _on_mind_tooltip_ready() -> void:
	_update_tooltip()


func _hide_native_button_text() -> void:
	var transparent := Color(1, 1, 1, 0)
	for color_name: StringName in [
		&"font_color",
		&"font_focus_color",
		&"font_pressed_color",
		&"font_hover_color",
		&"font_hover_pressed_color",
		&"font_disabled_color",
		&"font_outline_color",
	]:
		add_theme_color_override(color_name, transparent)


func tl_upd() -> void:
	_update_tooltip()


func _update_tooltip() -> void:
	var tooltip_node := get_node_or_null("_MindTooltip")
	if not is_instance_valid(tooltip_node):
		return
	tooltip_node.tooltip_text = (
		"[emb]" + real_tooltip_text
		if not real_tooltip_text.is_empty()
		else ""
	)

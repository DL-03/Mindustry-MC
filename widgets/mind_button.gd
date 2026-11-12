@tool
extends Button
class_name MindButton

@export_group("Content")
@export var label: MindLabel:
	set(value):
		if is_instance_valid(label) and label.display_text_changed.is_connected(_on_label_text_changed):
			label.display_text_changed.disconnect(_on_label_text_changed)
		label = value
		_connect_label()
		_sync_content()

@export_multiline var real_text: String = "[emb]MindButton":
	set(value):
		real_text = value
		_real_text_assignment_count += 1
		_real_text_was_set = is_instance_valid(label) or _real_text_assignment_count > 1
		_sync_content()

@export_group("Layout")
@export_enum("Left", "Center", "Right") var label_alignment: int = 1:
	set(value):
		label_alignment = clampi(value, 0, 2)
		override_internal_layout = true
		_sync_layout()

@export var content_margins: Vector4i = Vector4i(15, 15, 15, 15):
	set(value):
		content_margins = value
		override_internal_layout = true
		_sync_layout()

@export_group("Appearance")
@export var font_color: Color = Color.WHITE:
	set(value):
		font_color = value
		_sync_appearance()

@export var font_color_disabled: Color = Color.from_string("#454545", Color.DIM_GRAY):
	set(value):
		font_color_disabled = value
		_sync_appearance()

@export_range(1, 128, 1, "or_greater") var font_size: int = 16:
	set(value):
		font_size = maxi(value, 1)
		_sync_appearance()

@export_group("Internal Layout")
@export var override_internal_layout := false:
	set(value):
		override_internal_layout = value
		_sync_layout()

var _markup_regex := RegEx.new()
var _last_disabled_state := false
var _real_text_was_set := false
var _real_text_assignment_count := 0

const INTERNAL_LAYOUT: PackedScene = preload("res://widgets/mind_button_content.tscn")


func _init() -> void:
	_real_text_was_set = false
	_real_text_assignment_count = 0


func _enter_tree() -> void:
	_ensure_internal_layout()
	_resolve_internal_nodes()
	_set_internal_mouse_filter()
	_hide_native_button_text()


func _ready() -> void:
	_markup_regex.compile("\\[.*?\\]")
	_resolve_internal_nodes()
	_set_internal_mouse_filter()
	_hide_native_button_text()
	_connect_label()
	_sync_content()
	_sync_layout()
	_sync_appearance()
	_last_disabled_state = disabled
	set_process(true)


func _ensure_internal_layout() -> void:
	if is_instance_valid(get_node_or_null("MarginContainer")):
		return
	var layout := INTERNAL_LAYOUT.instantiate()
	add_child(layout)
	if Engine.is_editor_hint():
		_lock_internal_layout(layout)


func _lock_internal_layout(node: Node) -> void:
	node.set_meta("_edit_lock_", true)
	for child: Node in node.get_children():
		_lock_internal_layout(child)


func _resolve_internal_nodes() -> void:
	if not is_instance_valid(label):
		label = get_node_or_null("MarginContainer/Label") as MindLabel


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
	if is_instance_valid(label) and _real_text_was_set:
		label.real_text = real_text
	_refresh_native_text()


func _connect_label() -> void:
	if is_instance_valid(label) \
	and not label.display_text_changed.is_connected(_on_label_text_changed):
		label.display_text_changed.connect(_on_label_text_changed)


func _on_label_text_changed(_value: String) -> void:
	_refresh_native_text()


func _refresh_native_text() -> void:
	if not is_instance_valid(label) or not _markup_regex.is_valid():
		return
	text = _markup_regex.sub(label.text, "", true)


func _sync_appearance() -> void:
	if not is_instance_valid(label):
		return
	label.font_color = font_color_disabled if disabled else font_color
	label.add_theme_font_size_override("font_size", font_size)


func _sync_layout() -> void:
	if not override_internal_layout or not is_instance_valid(label):
		return
	label.horizontal_alignment = [
		HORIZONTAL_ALIGNMENT_LEFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		HORIZONTAL_ALIGNMENT_RIGHT,
	][label_alignment]
	var margin := label.get_parent() as MarginContainer
	if is_instance_valid(margin):
		margin.add_theme_constant_override("margin_left", content_margins.x)
		margin.add_theme_constant_override("margin_top", content_margins.y)
		margin.add_theme_constant_override("margin_right", content_margins.z)
		margin.add_theme_constant_override("margin_bottom", content_margins.w)


func _on_text_ready() -> void:
	_sync_content()
	_sync_layout()
	_sync_appearance()


func _on_mouse_entered() -> void:
	_refresh_native_text()


func _on_mouse_exited() -> void:
	_refresh_native_text()


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

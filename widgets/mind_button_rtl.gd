@tool
extends Button
class_name MindButtonRTL

@export_group("Content")
@export var label: MindRTL:
	set(value):
		if is_instance_valid(label) and label.display_text_changed.is_connected(_on_label_text_changed):
			label.display_text_changed.disconnect(_on_label_text_changed)
		label = value
		_connect_label()
		upd()

@export_multiline var real_text: String = "[emb]MindButtonRTL":
	set(value):
		real_text = value
		_real_text_assignment_count += 1
		_real_text_was_set = is_instance_valid(label) or _real_text_assignment_count > 1
		_sync_label_content()

@export_group("Layout")
@export_enum("Left", "Center", "Right") var label_alignment: int = 1:
	set(value):
		label_alignment = clampi(value, 0, 2)
		override_internal_layout = true
		_sync_layout()

@export_range(0, 64, 1, "or_greater") var horizontal_margin: int = 15:
	set(value):
		horizontal_margin = maxi(value, 0)
		override_internal_layout = true
		_sync_layout()

@export_range(0, 64, 1, "or_greater") var vertical_margin: int = 15:
	set(value):
		vertical_margin = maxi(value, 0)
		override_internal_layout = true
		_sync_layout()

@export_range(1, 128, 1, "or_greater") var label_font_size: int = 16:
	set(value):
		label_font_size = maxi(value, 1)
		override_internal_layout = true
		_sync_layout()

@export var override_internal_layout := false:
	set(value):
		override_internal_layout = value
		_sync_layout()

var regex = RegEx.new()
var _real_text_was_set := false
var _real_text_assignment_count := 0

const INTERNAL_LAYOUT: PackedScene = preload("res://widgets/mind_button_rtl_content.tscn")


func _init() -> void:
	_real_text_was_set = false
	_real_text_assignment_count = 0


func _enter_tree() -> void:
	_ensure_internal_layout()
	_resolve_internal_nodes()
	_set_internal_mouse_filter()
	_hide_native_button_text()


func _ready() -> void:
	regex.compile("\\[.*?\\]")
	_resolve_internal_nodes()
	_set_internal_mouse_filter()
	_hide_native_button_text()
	_connect_label()
	_sync_label_content()
	_sync_layout()
	upd()


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
		label = get_node_or_null("MarginContainer/Label") as MindRTL


func _set_internal_mouse_filter() -> void:
	var internal_layout := get_node_or_null("MarginContainer")
	if is_instance_valid(internal_layout):
		_set_mouse_filter_recursive(internal_layout)


func _set_mouse_filter_recursive(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		_set_mouse_filter_recursive(child)


func _connect_label() -> void:
	if is_instance_valid(label) \
	and not label.display_text_changed.is_connected(_on_label_text_changed):
		label.display_text_changed.connect(_on_label_text_changed)

func _on_label_text_changed(_value: String) -> void:
	upd()

func upd() -> void:
	if is_instance_valid(label):
		if not regex.is_valid():
			regex.compile("\\[.*?\\]")
		text = regex.sub(label.text, "", true)

func _sync_label_content() -> void:
	if is_instance_valid(label) and _real_text_was_set:
		label.real_text = real_text

func _sync_layout() -> void:
	if not override_internal_layout or not is_instance_valid(label):
		return
	label.horizontal_alignment = [
		HORIZONTAL_ALIGNMENT_LEFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		HORIZONTAL_ALIGNMENT_RIGHT,
	][label_alignment]
	label.add_theme_font_size_override("normal_font_size", label_font_size)
	var margin := label.get_parent() as MarginContainer
	if is_instance_valid(margin):
		margin.add_theme_constant_override("margin_left", horizontal_margin)
		margin.add_theme_constant_override("margin_right", horizontal_margin)
		margin.add_theme_constant_override("margin_top", vertical_margin)
		margin.add_theme_constant_override("margin_bottom", vertical_margin)

func _on_label_finished() -> void:
	upd()


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

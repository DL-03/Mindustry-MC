@tool
extends Button
class_name MindCheckBox

@export_group("State")
@export var Checked: bool = false:
	set(value):
		Checked = value
		_sync_checkmark()

@export_group("Appearance")
@export var indicator_size: Vector2 = Vector2(40, 40):
	set(value):
		indicator_size = value.max(Vector2.ONE)
		custom_minimum_size = indicator_size

@export var checkmark_color: Color = Color.from_string("#454545", Color.DIM_GRAY):
	set(value):
		checkmark_color = value
		_sync_checkmark_color()

signal state_changed


func _ready() -> void:
	custom_minimum_size = indicator_size
	var mark_panel := get_node_or_null("MarginContainer/Panel/MarginContainer2/Panel") as Panel
	if is_instance_valid(mark_panel):
		var current_style := mark_panel.get_theme_stylebox("panel")
		if is_instance_valid(current_style):
			mark_panel.add_theme_stylebox_override("panel", current_style.duplicate())
	_sync_checkmark()
	_sync_checkmark_color()


func _on_pressed() -> void:
	Checked = not Checked
	state_changed.emit(Checked)


func _on_mouse_entered() -> void:
	if not button_pressed:
		_set_mark_color("hover")
	else:
		_set_mark_color("pressed")


func _on_mouse_exited() -> void:
	_set_mark_color("normal")


func _on_button_down() -> void:
	_set_mark_color("pressed")


func _on_button_up() -> void:
	_set_mark_color("hover" if is_hovered() else "normal")


func _sync_checkmark() -> void:
	var checkmark := get_node_or_null("MarginContainer/Panel/MarginContainer2") as Control
	if is_instance_valid(checkmark):
		checkmark.visible = Checked


func _sync_checkmark_color() -> void:
	var mark_panel := get_node_or_null("MarginContainer/Panel/MarginContainer2/Panel") as Panel
	if not is_instance_valid(mark_panel):
		return
	var current_style := mark_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if not is_instance_valid(current_style):
		return
	var replacement := current_style.duplicate() as StyleBoxFlat
	replacement.bg_color = checkmark_color
	mark_panel.add_theme_stylebox_override("panel", replacement)


func _set_mark_color(style_name: StringName) -> void:
	var mark_panel := get_node_or_null("MarginContainer/Panel/MarginContainer2/Panel") as Panel
	if not is_instance_valid(mark_panel):
		return
	var style := mark_panel.get_theme_stylebox("panel") as StyleBoxFlat
	var button_style := get_theme_stylebox(style_name) as StyleBoxFlat
	if is_instance_valid(style) and is_instance_valid(button_style):
		var replacement := style.duplicate() as StyleBoxFlat
		replacement.bg_color = button_style.bg_color
		mark_panel.add_theme_stylebox_override("panel", replacement)

@tool
extends HBoxContainer
class_name MindColorEdit

signal data_changed(color: Color)

@export_group("Color")
@export var Data: Color = Color.PURPLE:
	set(value):
		Data = value
		_sync_controls()

@export_group("Controls")
@export var Line_Edit: LineEdit:
	set(value):
		Line_Edit = value
		_sync_controls()

@export var ColorButton: ColorPickerButton:
	set(value):
		ColorButton = value
		_sync_controls()

@export_group("Appearance")
@export var allow_alpha := true:
	set(value):
		allow_alpha = value
		_sync_controls()

@export var field_placeholder := "#RRGGBBAA":
	set(value):
		field_placeholder = value
		_sync_controls()

@export_range(0, 64, 1, "or_greater") var control_separation := 5:
	set(value):
		control_separation = maxi(value, 0)
		add_theme_constant_override("separation", control_separation)

@export_range(24, 128, 1, "or_greater") var picker_button_size := 40:
	set(value):
		picker_button_size = maxi(value, 24)
		_sync_controls()

var _current_data := Color.PURPLE


func _ready() -> void:
	_current_data = Data
	add_theme_constant_override("separation", control_separation)
	_sync_controls()


func _sync_controls() -> void:
	_current_data = Data
	if is_instance_valid(Line_Edit):
		Line_Edit.text = "#" + Data.to_html(true)
	if is_instance_valid(ColorButton):
		ColorButton.color = Data
		ColorButton.edit_alpha = allow_alpha
		ColorButton.custom_minimum_size = Vector2(picker_button_size, picker_button_size)
	if is_instance_valid(Line_Edit):
		Line_Edit.placeholder_text = field_placeholder


func _on_line_edit_text_changed(new_text: String) -> void:
	var normalized_text := new_text.strip_edges()
	if not normalized_text.begins_with("#"):
		normalized_text = "#" + normalized_text
	if not Color.html_is_valid(normalized_text):
		return

	_current_data = Color.from_string(normalized_text, Data)
	if is_instance_valid(ColorButton):
		ColorButton.color = _current_data
	data_changed.emit(_current_data)


func _on_color_picker_button_color_changed(color: Color) -> void:
	_current_data = color
	if is_instance_valid(Line_Edit):
		Line_Edit.text = "#" + color.to_html(true)
	data_changed.emit(_current_data)

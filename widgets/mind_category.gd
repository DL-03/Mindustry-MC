@tool
extends HBoxContainer
class_name MindCategory

signal data_changed(value: String)

@export_group("Selection")
@export var Data: String = "":
	set(value):
		Data = value.to_lower()
		_sync_selection()

@export_group("Category Options")
@export var category_icons: Dictionary = {}:
	set(value):
		category_icons = value
		_sync_option_labels()

@export var category_labels: Dictionary = {}:
	set(value):
		category_labels = value
		_sync_option_labels()

var _hovered_category := ""


func _ready() -> void:
	var options := get_node_or_null("HFlowContainer")
	if not is_instance_valid(options):
		return
	for option: Node in options.get_children():
		if not option is Button:
			continue
		var option_button := option as Button
		if not option_button.pressed.is_connected(_on_option_pressed.bind(option_button)):
			option_button.pressed.connect(_on_option_pressed.bind(option_button))
		if not option_button.mouse_entered.is_connected(_on_option_mouse_entered.bind(option_button)):
			option_button.mouse_entered.connect(_on_option_mouse_entered.bind(option_button))
		if not option_button.mouse_exited.is_connected(_on_option_mouse_exited.bind(option_button)):
			option_button.mouse_exited.connect(_on_option_mouse_exited.bind(option_button))
	_sync_option_labels()
	_sync_selection()


func _on_option_pressed(option: Button) -> void:
	Data = option.name
	data_changed.emit(Data)


func _on_option_mouse_entered(option: Button) -> void:
	_hovered_category = option.name
	_sync_hover_preview()


func _on_option_mouse_exited(_option: Button) -> void:
	_hovered_category = ""
	_sync_hover_preview()


func _sync_selection() -> void:
	if not is_node_ready():
		return
	var options := get_node_or_null("HFlowContainer")
	if not is_instance_valid(options):
		return
	var selected_option := options.get_node_or_null(Data) as Button
	for option: Node in options.get_children():
		if option is BaseButton:
			(option as BaseButton).disabled = option == selected_option
	if is_instance_valid(selected_option):
		_set_preview(selected_option, true)
	elif not Data.is_empty():
		Data = ""
		_set_empty_preview()
	else:
		_set_empty_preview()


func _sync_hover_preview() -> void:
	if not is_node_ready():
		return
	var options := get_node_or_null("HFlowContainer")
	if not is_instance_valid(options):
		return
	var hovered_option := options.get_node_or_null(_hovered_category) as Button
	if is_instance_valid(hovered_option):
		_set_preview(hovered_option, hovered_option.disabled)
	else:
		_sync_selection()


func _set_preview(option: Button, selected: bool) -> void:
	var icon := get_node_or_null("Panel/HBoxContainer/Icon") as MindLabel
	var text_label := get_node_or_null("Panel/HBoxContainer/Text") as MindLabel
	if is_instance_valid(icon) and option is MindIButton:
		icon.real_text = (option as MindIButton).real_text_icon_left
	if is_instance_valid(text_label):
		text_label.real_text = str(category_labels.get(option.name, option.name))
	_set_border_color("UI.GREEN" if selected else "UI.GRAY")


func _sync_option_labels() -> void:
	if not is_node_ready():
		return
	var options := get_node_or_null("HFlowContainer")
	if not is_instance_valid(options):
		return
	for option: Node in options.get_children():
		if not option is MindIButton:
			continue
		var category_button := option as MindIButton
		if category_icons.has(option.name):
			category_button.real_text_icon_left = str(category_icons[option.name])


func _set_empty_preview() -> void:
	var icon := get_node_or_null("Panel/HBoxContainer/Icon") as MindLabel
	var text_label := get_node_or_null("Panel/HBoxContainer/Text") as MindLabel
	if is_instance_valid(icon):
		icon.real_text = "-"
	if is_instance_valid(text_label):
		text_label.real_text = "None"
	_set_border_color("UI.RED")


func _set_border_color(color_key: String) -> void:
	var icon := get_node_or_null("Panel/HBoxContainer/Icon") as Control
	if not is_instance_valid(icon):
		return
	var style := icon.get_theme_stylebox("normal") as StyleBoxFlat
	if not is_instance_valid(style):
		return
	var unique_style := style.duplicate() as StyleBoxFlat
	unique_style.border_color = COLORS.get_color(color_key)
	icon.add_theme_stylebox_override("normal", unique_style)

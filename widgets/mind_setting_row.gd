@tool
class_name MindSettingRow
extends PanelContainer

@export_group("Text")
@export var title_text := "":
	set(value):
		title_text = value
		_sync_text()

@export_multiline var description_text := "":
	set(value):
		description_text = value
		_sync_text()

@export_group("Control")
@export var control_scene: PackedScene:
	set(value):
		control_scene = value
		_rebuild_control()

@export_range(0, 600, 1, "or_greater") var control_min_width := 180:
	set(value):
		control_min_width = maxi(value, 0)
		_sync_control_size()

@export var title_label: MindLabel:
	set(value):
		title_label = value
		_sync_text()

@export var description_label: MindLabel:
	set(value):
		description_label = value
		_sync_text()

@export var control_slot: Control:
	set(value):
		control_slot = value
		_rebuild_control()

var setting_control: Control


func _ready() -> void:
	_sync_text()
	_rebuild_control()


func _sync_text() -> void:
	if is_instance_valid(title_label):
		title_label.real_text = title_text
	if is_instance_valid(description_label):
		description_label.real_text = description_text
		description_label.visible = not description_text.is_empty()


func _rebuild_control() -> void:
	if not is_node_ready() or not is_instance_valid(control_slot):
		return
	if is_instance_valid(setting_control):
		control_slot.remove_child(setting_control)
		setting_control.queue_free()
	setting_control = null
	if not is_instance_valid(control_scene):
		return
	setting_control = control_scene.instantiate() as Control
	if not is_instance_valid(setting_control):
		push_error("MindSettingRow: control scene root must be a Control.")
		return
	control_slot.add_child(setting_control)
	_sync_control_size()


func _sync_control_size() -> void:
	if is_instance_valid(control_slot):
		control_slot.custom_minimum_size.x = control_min_width
	if is_instance_valid(setting_control):
		setting_control.size_flags_horizontal = Control.SIZE_SHRINK_END

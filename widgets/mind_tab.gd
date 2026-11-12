@tool
extends Button
class_name MindTab

enum TabDirection {
	TOP,
	LEFT,
	BOTTOM,
	RIGHT
}

@export_group("Internal Nodes")
@export var label: MindLabel
@export var marginContainer: MarginContainer

@export_group("Tab")
@export var direction: TabDirection = TabDirection.TOP:
	set = _set_direction

func _ready() -> void:
	_apply_direction()

func _on_h_box_container_resized() -> void:
	_update_minimum_size()

func _set_direction(value: TabDirection) -> void:
	direction = value
	_apply_direction()

func _apply_direction() -> void:
	if not is_instance_valid(marginContainer):
		return
	match direction:
		TabDirection.TOP:
			theme_type_variation = "VTab"
			marginContainer.add_theme_constant_override("margin_top", 5)
			marginContainer.add_theme_constant_override("margin_left", 5)
			marginContainer.add_theme_constant_override("margin_bottom", 0)
			marginContainer.add_theme_constant_override("margin_right", 5)
		TabDirection.LEFT:
			theme_type_variation = "HTab"
			marginContainer.add_theme_constant_override("margin_top", 5)
			marginContainer.add_theme_constant_override("margin_left", 5)
			marginContainer.add_theme_constant_override("margin_bottom", 5)
			marginContainer.add_theme_constant_override("margin_right", 0)
		TabDirection.BOTTOM:
			theme_type_variation = "VTabR"
			marginContainer.add_theme_constant_override("margin_top", 0)
			marginContainer.add_theme_constant_override("margin_left", 5)
			marginContainer.add_theme_constant_override("margin_bottom", 5)
			marginContainer.add_theme_constant_override("margin_right", 5)
		TabDirection.RIGHT:
			theme_type_variation = "HTabR"
			marginContainer.add_theme_constant_override("margin_top", 5)
			marginContainer.add_theme_constant_override("margin_left", 0)
			marginContainer.add_theme_constant_override("margin_bottom", 5)
			marginContainer.add_theme_constant_override("margin_right", 5)
	_update_minimum_size()

func _update_minimum_size() -> void:
	if is_instance_valid(marginContainer):
		custom_minimum_size = marginContainer.get_combined_minimum_size()

@tool
extends Button

enum TabDirection {
	TOP,
	LEFT,
	BOTTOM,
	RIGHT
}

@export var label: MindLabel
@export var marginContainer: MarginContainer

@export var direction: TabDirection = TabDirection.TOP:
	set = _set_direction

func _ready() -> void:
	custom_minimum_size = marginContainer.get_minimum_size()

func _on_h_box_container_resized() -> void:
	custom_minimum_size = marginContainer.get_minimum_size()

func _set_direction(v):
	direction = v
	
	match direction:
		0:
			theme_type_variation = "VTab"
			
			marginContainer.add_theme_constant_override("margin_top", 5)
			marginContainer.add_theme_constant_override("margin_left", 5)
			marginContainer.add_theme_constant_override("margin_bottom", 0)
			marginContainer.add_theme_constant_override("margin_right", 5)
		1:
			theme_type_variation = "HTab"
			
			marginContainer.add_theme_constant_override("margin_top", 5)
			marginContainer.add_theme_constant_override("margin_left", 5)
			marginContainer.add_theme_constant_override("margin_bottom", 5)
			marginContainer.add_theme_constant_override("margin_right", 0)
		2:
			theme_type_variation = "VTabR"
			
			marginContainer.add_theme_constant_override("margin_top", 0)
			marginContainer.add_theme_constant_override("margin_left", 5)
			marginContainer.add_theme_constant_override("margin_bottom", 5)
			marginContainer.add_theme_constant_override("margin_right", 5)
		3:
			theme_type_variation = "HTabR"
			
			marginContainer.add_theme_constant_override("margin_top", 5)
			marginContainer.add_theme_constant_override("margin_left", 0)
			marginContainer.add_theme_constant_override("margin_bottom", 5)
			marginContainer.add_theme_constant_override("margin_right", 5)
	
	custom_minimum_size = marginContainer.get_minimum_size()

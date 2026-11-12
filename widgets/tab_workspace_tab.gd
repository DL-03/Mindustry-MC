@tool
class_name TabWorkspaceTab
extends PanelContainer

@export var tab_title := "":
	set(value):
		tab_title = value
		_update_visuals()

@export var tab_icon := "":
	set(value):
		tab_icon = value
		_update_visuals()

@export var tab_selected := false:
	set(value):
		tab_selected = value
		_update_visuals()

@export var tab_modified := false:
	set(value):
		tab_modified = value
		_update_visuals()

@export var compact_mode := false:
	set(value):
		compact_mode = value
		_update_visuals()


func _ready() -> void:
	_update_visuals()


func _update_visuals() -> void:
	var icon_label := get_node_or_null("Content/Icon") as Label
	var title_label := get_node_or_null("Content/Title") as Label
	var modified_label := get_node_or_null("Content/Modified") as Label
	if is_instance_valid(icon_label):
		icon_label.text = tab_icon
		icon_label.visible = not tab_icon.is_empty()
	if is_instance_valid(title_label):
		title_label.text = tab_title
		title_label.visible = not compact_mode
	if is_instance_valid(modified_label):
		modified_label.visible = tab_modified

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#594a2f") if tab_selected else Color("#242424")
	style.border_color = Color("#ffd37f")
	style.border_width_bottom = 3 if tab_selected else 0
	style.content_margin_left = 10
	style.content_margin_top = 5
	style.content_margin_right = 10
	style.content_margin_bottom = 5
	add_theme_stylebox_override("panel", style)

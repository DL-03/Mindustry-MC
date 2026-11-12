@tool
extends Button
class_name MindUTab

signal close
signal selected

@export_group("Tab")
@export_multiline var tab_title: String = "":
	set(value):
		tab_title = value
		_sync_title()

@export var has_changes: bool = true:
	set(value):
		has_changes = value
		_sync_changes()

@export_group("Appearance")
@export var tab_icon: Texture2D:
	set(value):
		tab_icon = value
		_sync_icon()


func _ready() -> void:
	_sync_title()
	_sync_changes()
	_sync_icon()
	_update_minimum_size()


func _on_pressed() -> void:
	selected.emit()


func _on_close_pressed() -> void:
	close.emit()


func _on_margin_container_resized() -> void:
	_update_minimum_size()


func _on_h_box_container_resized() -> void:
	_update_minimum_size()


func _sync_title() -> void:
	var title_label := get_node_or_null("MarginContainer/HBoxContainer/Label") as MindRTL
	if is_instance_valid(title_label) and not tab_title.is_empty():
		title_label.real_text = "[emb]" + tab_title


func _sync_changes() -> void:
	var change_indicator := get_node_or_null("MarginContainer/HBoxContainer/Changes")
	if is_instance_valid(change_indicator):
		change_indicator.visible = has_changes


func _sync_icon() -> void:
	if not is_instance_valid(tab_icon):
		return
	var icon := get_node_or_null("MarginContainer/HBoxContainer/Icon") as TextureRect
	if is_instance_valid(icon):
		icon.texture = tab_icon


func _update_minimum_size() -> void:
	var margin := get_node_or_null("MarginContainer") as Control
	if not is_instance_valid(margin):
		return
	var minimum := margin.get_combined_minimum_size()
	custom_minimum_size = Vector2(maxf(minimum.x, 175), maxf(minimum.y, 35))

@tool
class_name TabWorkspacePage
extends Resource

@export_group("Tab")
@export var tab_id: StringName = &"":
	set(value):
		tab_id = value
		emit_changed()

@export var title: String = "Новая вкладка":
	set(value):
		title = value
		emit_changed()

@export var group_id: StringName = &"main":
	set(value):
		group_id = value
		emit_changed()

@export var group_title: String = "Основная":
	set(value):
		group_title = value
		emit_changed()

@export var icon: String = "":
	set(value):
		icon = value
		emit_changed()

@export var closable: bool = true:
	set(value):
		closable = value
		emit_changed()

@export var selected_on_start: bool = false:
	set(value):
		selected_on_start = value
		emit_changed()

@export var tab_scene: PackedScene:
	set(value):
		tab_scene = value
		emit_changed()

@export_group("Content")
@export var content_scene: PackedScene:
	set(value):
		content_scene = value
		emit_changed()

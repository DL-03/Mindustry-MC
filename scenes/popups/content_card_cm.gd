extends PanelContainer

@export var crp_tooltip: MindTooltip
@export var cap_tooltip: MindTooltip

signal delete
signal rename
signal _duplicate

signal copy_relative_path
signal copy_absolute_path
signal open_in_explorer

var signals = [delete,rename,_duplicate,copy_relative_path,copy_absolute_path,open_in_explorer]

func clear_connections():
	for s in signals:
		for i in s.get_connections():
			s.disconnect(i.callable)


func _on_delete_pressed() -> void:
	delete.emit()

func _on_rename_pressed() -> void:
	rename.emit()

func _on_duplicate_pressed() -> void:
	_duplicate.emit()


func _on_copy_relative_path_pressed() -> void:
	copy_relative_path.emit()

func _on_copy_absolute_path_pressed() -> void:
	copy_absolute_path.emit()

func _on_open_in_explorer_pressed() -> void:
	open_in_explorer.emit()


func tip(data):
	$AnimationPlayer.play("show")

func untip():
	$AnimationPlayer.play("hide")

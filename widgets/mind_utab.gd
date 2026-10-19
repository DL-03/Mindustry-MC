@tool
extends Button

func _process(delta):
	$MarginContainer.size.x = 0
	custom_minimum_size.x = $MarginContainer.size.x
	size.x = 0

signal close

func _on_close_pressed() -> void:
	close.emit()

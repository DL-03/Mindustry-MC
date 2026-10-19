@tool
extends Button
class_name MindButton

@onready var label = $MarginContainer/Label

var regex = RegEx.new()

func _ready() -> void:
	regex.compile("\\[.*?\\]")
	upd()

func upd():
	if label:
		text = regex.sub(label.text, "", true)

func _on_label_finished() -> void:
	upd()

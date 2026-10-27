@tool
extends Button
class_name MindButtonRTL

@export var label: MindRTL

var regex = RegEx.new()

func _ready() -> void:
	regex.compile("\\[.*?\\]")
	upd()

func upd():
	if label:
		if not regex.is_valid():
			regex.compile("\\[.*?\\]")
		text = regex.sub(label.text, "", true)

func _on_label_finished() -> void:
	upd()

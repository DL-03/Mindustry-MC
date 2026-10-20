@tool
extends Button
class_name MindIButton

@onready var left_icon = $MarginContainer/HBoxContainer/LeftIcon
@onready var label = $MarginContainer/HBoxContainer/MindRTL
@onready var right_icon = $MarginContainer/HBoxContainer/RightIcon

var regex = RegEx.new()

func _ready() -> void:
	regex.compile("\\[.*?\\]")
	upd()

func upd():
	if label:
		text = regex.sub(left_icon.text+" "+label.text+" "+right_icon.text, "", true)

func _on_label_finished() -> void:
	upd()

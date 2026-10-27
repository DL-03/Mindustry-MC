@tool
extends Button
class_name MindIButtonRTL

@export var left_icon: MindRTL
@export var label: MindRTL
@export var right_icon: MindRTL

var regex = RegEx.new()

func _ready() -> void:
	regex.compile("\\[.*?\\]")
	upd()

func upd():
	if label:
		if not regex.is_valid():
			regex.compile("\\[.*?\\]")
		var _text = ""
		
		if left_icon.visible:
			_text += left_icon.text
		if label.visible:
			if left_icon.visible:
				_text += " "
			_text += label.text
		if right_icon.visible:
			if label.visible:
				_text += " "
			_text += right_icon.text
		
		text = regex.sub(_text, "", true)

func _on_label_finished() -> void:
	upd()

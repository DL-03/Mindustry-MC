@tool
extends Control
class_name MindTooltipDefault

@export_group("Content")
@export var label: MindRTL

func tip(data: Dictionary):
	if label:
		var placeholders: Dictionary = {}
		if data.get("placeholders") is Dictionary:
			placeholders = data["placeholders"]
		label.set_tooltip_content(data.get("text", label.real_text), placeholders)
		$AnimationPlayer.play("show")
	else:
		push_error("Ссылка на ноду label равна null! Проверьте путь в mind_tooltip.gd")

func utip(data: Dictionary):
	if label:
		var placeholders: Dictionary = {}
		if data.get("placeholders") is Dictionary:
			placeholders = data["placeholders"]
		label.set_tooltip_content(data.get("text", label.real_text), placeholders)
	
	else:
		push_error("Ссылка на ноду label равна null! Проверьте путь в mind_tooltip.gd")

func untip():
	if label: 
		$AnimationPlayer.play("hide")
	else:
		push_error("Ссылка на ноду label равна null! Проверьте путь в mind_tooltip.gd")

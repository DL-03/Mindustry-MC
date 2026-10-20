extends Node

@export var CLASS_ModEditor = preload("res://Objects/ForEditor/ModEditor.tscn")


func OpenFromPath(TabButton, Path, Type = null) -> void :
	var t = CLASS_ModEditor.instantiate()
	$/root/Main/V1.add_child(t)
	TabButton.ContentFrame = t
	t.ButtonTab = TabButton
	t.setPath(Path)

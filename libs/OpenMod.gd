extends Node

@export var CLASS_ModEditor = preload("res://scenes/mod_editor/mod_editor.tscn")


func OpenFromPath(TabButton, Path, Type = null) -> void :
	var t = CLASS_ModEditor.instantiate()
	$/root/Main/V1.add_child(t)
	TabButton.ContentFrame = t
	t.ButtonTab = TabButton
	t.setPath(Path)

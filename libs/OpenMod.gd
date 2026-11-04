extends Node

@export var CLASS_ModEditor = preload("res://scenes/mod_editor/mod_editor.tscn")

@onready var _main = $/root/Main

func OpenFromPath(Path, Type = null) -> void :
	var tcontent = CLASS_ModEditor.instantiate()
	var tab = _main.create_tab()
	
	_main.tabsDict.set(tab,tcontent)

	tcontent.ButtonTab = tab
	tcontent.setPath(Path)
	
	_main.ContentPanel.add_child(tcontent)
	_main.set_tab(tab)

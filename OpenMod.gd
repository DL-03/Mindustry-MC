extends Node

@export var CLASS_ModEditor = preload("res://Objects/ForEditor/ModEditor.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func OpenFromPath(TabButton, Path, Type=null) -> void:
	var t = CLASS_ModEditor.instantiate()
	TabButton.text = "MindustryMod"
	$/root/Main/V1.add_child(t)
	TabButton.ContentFrame = t
	t.ButtonTab = TabButton
	t.setPath(Path)

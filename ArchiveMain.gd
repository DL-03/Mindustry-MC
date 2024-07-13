extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func ExtracteToDirectory(ZipPath,extractPath):
	var my_csharp_script = preload("res://ArchiveMain.cs").new()
	my_csharp_script.ExtracteToDirectory(ZipPath,extractPath)

extends Node

var cs = preload("res://libs/FileOperations.cs")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func Copy(a,b):
	var FileOperationsCS = cs.new()
	FileOperationsCS.Copy(a,b)
	FileOperationsCS.free()
func rename(a,b):
	var FileOperationsCS = cs.new()
	FileOperationsCS.rename(a,b)
	FileOperationsCS.free()

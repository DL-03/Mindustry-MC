extends Node

var csharp_script = preload("res://libs/FileOperations.cs").new()

func Copy(a,b):
	csharp_script.Copy(a,b)
func rename(a,b):
	csharp_script.rename(a,b)

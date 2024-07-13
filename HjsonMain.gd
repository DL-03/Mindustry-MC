extends Node

func parse_string(text):
	var my_csharp_script = preload("res://HjsonMain.cs").new()
	var s = my_csharp_script.parse_string(text)
	if s != null:
		return JSON.parse_string(my_csharp_script.parse_string(text))
	

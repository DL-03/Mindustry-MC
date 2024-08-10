extends Node


var my_csharp_script = preload("res://libs/HjsonMain.cs").new()


func parse_string(text):
	var s = my_csharp_script.parse_string(text)
	if s != null:
		return JSON.parse_string(my_csharp_script.parse_string(text))
func stringify(data):
	var s = my_csharp_script.stringify(str(data))
	return s

extends Node


var csharp_script = preload("res://libs/HjsonMain.cs").new()


func parse_string(text):
	var s = csharp_script.parse_string(text)
	if s != null:
		return JSON.parse_string(csharp_script.parse_string(text))
func stringify(data):
	var s = csharp_script.stringify(str(data))
	return s

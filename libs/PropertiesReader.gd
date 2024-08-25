@tool
extends Node


func parse(text: String):
	var result = {}
	
	if text != null:
		text = str(text)
		
		
		for i in text.split("\n"):
			if i.begins_with("#"):
				#continue
				pass
			elif len(i.split("=", false, 1)) > 1:
				var key = i.split("=", false, 1)[0].strip_edges()
				var value = i.split("=", false, 1)[1].strip_edges().replace("\\n", "\n")
				
				
				result.merge({key: value}, true)
				

	return result


func _ready():
	print(parse("auch = emn\n#nonono\n  second    =   123"))

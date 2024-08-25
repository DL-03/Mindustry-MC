extends Node

var ContentFile = preload("res://resources/ContentType.json").data
var ClassType = ContentFile["ClassType"]


func reverseDict(_dict):
	var __list = _dict.keys()
	__list.reverse()


	var _dict2 = {}
	#if _dict != null:
	for i in __list:
		_dict2.merge({i: _dict[i]})
	return _dict2



func get_content(_type=null):
	
	if _type != null:
		#if _type in ClassType:
		var _podType = null
		for i in ClassType.keys():
			if i.to_lower() == _type.to_lower():
				_podType = i
		if _podType != null:
			var classDefault = reverseDict(ClassType[_podType])
			var _mod = classDefault.duplicate()
			var _mod1 = {}
			var _tt = true
			if "extend" in _mod:
				_mod1 = reverseDict(ClassType[_mod["extend"]])
				_mod.merge(_mod1)

			while _tt:
				if "extend" in _mod1:
					if _mod1["extend"] in ClassType:
						#print(_mod1["extend"])
						_mod1 = reverseDict(ClassType[_mod1["extend"]])
						_mod.merge(_mod1)
					
				else:
					_tt = false

			if "extend" in _mod:
				_mod.erase("extend")

			return reverseDict(_mod)
		else:
			return reverseDict({})
	return null

# Called when the node enters the scene tree for the first time.
func _ready():
	#print("WOS:",get_content("material"))
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

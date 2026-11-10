extends Node

var ContentFile = preload("res://resources/ContentType.json").data
var ClassType = ContentFile["ClassType"]
var _content_cache: Dictionary = {}


func reverseDict(_dict):
	var __list = _dict.keys()
	__list.reverse()


	var _dict2 = {}
	#if _dict != null:
	for i in __list:
		_dict2.merge({i: _dict[i]})
	return _dict2



func get_content(_type=null):
	if _type == null:
		return null

	var cache_key := str(_type).to_lower()
	if _content_cache.has(cache_key):
		return _content_cache[cache_key].duplicate()

	var pod_type: Variant
	for key: Variant in ClassType:
		if str(key).to_lower() == cache_key:
			pod_type = key
			break

	var result: Dictionary
	if pod_type == null:
		result = reverseDict({})
	else:
		var class_default: Dictionary = reverseDict(ClassType[pod_type])
		var merged: Dictionary = class_default.duplicate()
		var inherited: Dictionary = {}
		if merged.has("extend"):
			inherited = reverseDict(ClassType[merged["extend"]])
			merged.merge(inherited)

		while inherited.has("extend"):
			var parent_type: Variant = inherited["extend"]
			if not ClassType.has(parent_type):
				break
			inherited = reverseDict(ClassType[parent_type])
			merged.merge(inherited)

		merged.erase("extend")
		result = reverseDict(merged)

	_content_cache[cache_key] = result
	return result.duplicate()

# Called when the node enters the scene tree for the first time.
func _ready():
	#print("WOS:",get_content("material"))
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

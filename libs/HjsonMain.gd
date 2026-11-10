extends Node


var csharp_script = preload("res://libs/HjsonMain.cs").new()


func parse_string(text):
	var json_text: Variant = csharp_script.parse_string(text)
	if json_text != null:
		return JSON.parse_string(json_text)


func try_parse_string(text: String) -> Dictionary:
	var result: Dictionary = csharp_script.try_parse_string(text)
	if not result.get("success", false):
		return result

	var parsed: Variant = JSON.parse_string(str(result.get("json", "")))
	if parsed == null:
		return {"success": false, "error": "Could not decode parser output."}
	return {"success": true, "data": parsed}


func merge_and_stringify(
	original_text: String,
	updated_json: String,
	preserve_whitespace_and_comments: bool
) -> Dictionary:
	return csharp_script.merge_and_stringify(
		original_text,
		updated_json,
		preserve_whitespace_and_comments
	)


func stringify(data):
	var s = csharp_script.stringify(str(data))
	return s

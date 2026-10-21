@tool
extends Node


func parse(text: String) -> Dictionary:
	var result: Dictionary = {}
	for line in _get_logical_lines(text):
		var entry := _parse_entry(line)
		if not entry.is_empty():
			result[entry[0]] = entry[1]
	return result


func _get_logical_lines(text: String) -> PackedStringArray:
	var logical_lines := PackedStringArray()
	var pending := ""
	var continuing := false

	for physical_line in text.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
		var line: String = physical_line
		if continuing:
			var first_non_whitespace := 0
			while first_non_whitespace < line.length() \
					and _is_whitespace(line.substr(first_non_whitespace, 1)):
				first_non_whitespace += 1
			line = line.substr(first_non_whitespace)

		var slash_count := 0
		for index in range(line.length() - 1, -1, -1):
			if line.substr(index, 1) != "\\":
				break
			slash_count += 1

		if slash_count % 2 == 1:
			pending += line.substr(0, line.length() - 1)
			continuing = true
		else:
			logical_lines.append(pending + line)
			pending = ""
			continuing = false

	if continuing:
		logical_lines.append(pending)
	return logical_lines


func _parse_entry(line: String) -> Array:
	var start := 0
	while start < line.length() and _is_whitespace(line.substr(start, 1)):
		start += 1
	if start >= line.length():
		return []

	var first_character := line.substr(start, 1)
	if first_character == "#" or first_character == "!":
		return []

	var separator := -1
	var escaped := false
	for index in range(start, line.length()):
		var character := line.substr(index, 1)
		if escaped:
			escaped = false
		elif character == "\\":
			escaped = true
		elif character == "=" or character == ":" or _is_whitespace(character):
			separator = index
			break

	var key: String
	var value_start: int
	if separator == -1:
		key = line.substr(start)
		value_start = line.length()
	else:
		key = line.substr(start, separator - start)
		value_start = separator
		if _is_whitespace(line.substr(separator, 1)):
			while value_start < line.length() and _is_whitespace(line.substr(value_start, 1)):
				value_start += 1
			if value_start < line.length() and line.substr(value_start, 1) in ["=", ":"]:
				value_start += 1
		else:
			value_start += 1
		while value_start < line.length() and _is_whitespace(line.substr(value_start, 1)):
			value_start += 1

	if key.is_empty():
		return []

	var value := line.substr(value_start).strip_edges()
	if value.length() >= 2 and value.begins_with("\"") and value.ends_with("\""):
		value = value.substr(1, value.length() - 2)
	return [ _decode_escapes(key), _decode_escapes(value) ]


func _decode_escapes(value: String) -> String:
	var decoded := ""
	var index := 0
	while index < value.length():
		var character := value.substr(index, 1)
		index += 1
		if character != "\\" or index >= value.length():
			decoded += character
			continue

		var escaped_character := value.substr(index, 1)
		index += 1
		match escaped_character:
			"t":
				decoded += "\t"
			"n":
				decoded += "\n"
			"r":
				decoded += "\r"
			"f":
				decoded += "\f"
			"u":
				if index + 4 <= value.length():
					var code_unit_text := value.substr(index, 4)
					if _is_hex_string(code_unit_text):
						var code_unit := code_unit_text.hex_to_int()
						index += 4
						if code_unit >= 0xD800 and code_unit <= 0xDBFF \
								and value.substr(index, 2) == "\\u" \
								and index + 6 <= value.length():
							var low_surrogate_text := value.substr(index + 2, 4)
							if _is_hex_string(low_surrogate_text):
								var low_surrogate := low_surrogate_text.hex_to_int()
								if low_surrogate >= 0xDC00 and low_surrogate <= 0xDFFF:
									code_unit = 0x10000 + ((code_unit - 0xD800) << 10) + (low_surrogate - 0xDC00)
									index += 6
						decoded += char(code_unit)
					else:
						decoded += "\\u"
				else:
					decoded += "\\u"
			_:
				decoded += escaped_character
	return decoded


func _is_whitespace(character: String) -> bool:
	return character == " " or character == "\t" or character == "\f"


func _is_hex_string(value: String) -> bool:
	if value.length() != 4:
		return false
	for index in range(value.length()):
		if value.substr(index, 1).to_lower() not in "0123456789abcdef":
			return false
	return true

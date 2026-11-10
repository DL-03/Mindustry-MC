extends SyntaxHighlighter

const KEY_COLOR := Color("#80cbc4")
const STRING_COLOR := Color("#a5d6a7")
const NUMBER_COLOR := Color("#ffcc80")
const LITERAL_COLOR := Color("#ce93d8")
const COMMENT_COLOR := Color("#90a4ae")
const SYMBOL_COLOR := Color("#b0bec5")

var _line_start_states: Array[Dictionary] = []


func invalidate_cache() -> void:
	_line_start_states.clear()


func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var code_edit := get_text_edit()
	if not is_instance_valid(code_edit) or line < 0 or line >= code_edit.get_line_count():
		return {}

	if _line_start_states.is_empty():
		_line_start_states.append(_initial_state())
	var default_color := code_edit.get_theme_color("font_color")
	while _line_start_states.size() <= line:
		var previous_line := _line_start_states.size() - 1
		var next_state := _scan_line(
			code_edit.get_line(previous_line),
			_line_start_states[previous_line],
			null,
			default_color
		)
		_line_start_states.append(next_state)

	var result: Dictionary = {}
	_scan_line(code_edit.get_line(line), _line_start_states[line], result, default_color)
	return result


func _initial_state() -> Dictionary:
	return {
		"block_comment": false,
		"multiline_string": false,
		"quote": "",
	}


func _scan_line(
	text: String,
	initial_state: Dictionary,
	colors: Variant,
	default_color: Color
) -> Dictionary:
	var state := initial_state.duplicate()
	var index := 0

	while index < text.length():
		if state["block_comment"]:
			var comment_end := text.find("*/", index)
			if comment_end < 0:
				_add_color(colors, index, text.length(), COMMENT_COLOR, default_color)
				return state
			_add_color(colors, index, comment_end + 2, COMMENT_COLOR, default_color)
			index = comment_end + 2
			state["block_comment"] = false
			continue

		if state["multiline_string"]:
			var string_end := text.find("'''", index)
			if string_end < 0:
				_add_color(colors, index, text.length(), STRING_COLOR, default_color)
				return state
			_add_color(colors, index, string_end + 3, STRING_COLOR, default_color)
			index = string_end + 3
			state["multiline_string"] = false
			continue

		if not str(state["quote"]).is_empty():
			var continued_quote := str(state["quote"])
			var continued_end := _find_quote_end(text, index, continued_quote)
			if continued_end < 0:
				_add_color(colors, index, text.length(), STRING_COLOR, default_color)
				return state
			_add_color(colors, index, continued_end + 1, STRING_COLOR, default_color)
			index = continued_end + 1
			state["quote"] = ""
			continue

		var character := text[index]
		if character in [" ", "\t", "\r"]:
			index += 1
			continue

		if character == "#" or text.substr(index, 2) == "//":
			_add_color(colors, index, text.length(), COMMENT_COLOR, default_color)
			break

		if text.substr(index, 2) == "/*":
			var block_end := text.find("*/", index + 2)
			if block_end < 0:
				_add_color(colors, index, text.length(), COMMENT_COLOR, default_color)
				state["block_comment"] = true
				return state
			_add_color(colors, index, block_end + 2, COMMENT_COLOR, default_color)
			index = block_end + 2
			continue

		if text.substr(index, 3) == "'''":
			var multiline_end := text.find("'''", index + 3)
			if multiline_end < 0:
				_add_color(colors, index, text.length(), STRING_COLOR, default_color)
				state["multiline_string"] = true
				return state
			_add_color(colors, index, multiline_end + 3, STRING_COLOR, default_color)
			index = multiline_end + 3
			continue

		if character in ["\"", "'"]:
			var quote_end := _find_quote_end(text, index + 1, character)
			var token_end := quote_end + 1 if quote_end >= 0 else text.length()
			var following := _skip_whitespace(text, token_end)
			var token_color := KEY_COLOR if following < text.length() \
				and text[following] == ":" else STRING_COLOR
			_add_color(colors, index, token_end, token_color, default_color)
			if quote_end < 0:
				state["quote"] = character
				return state
			index = token_end
			continue

		if character in ["{", "}", "[", "]", ":", ","]:
			_add_color(colors, index, index + 1, SYMBOL_COLOR, default_color)
			index += 1
			continue

		var token_end := index
		while token_end < text.length() \
		and text[token_end] not in [" ", "\t", "\r", "{", "}", "[", "]", ",", ":", "#"]:
			if text.substr(token_end, 2) in ["//", "/*"]:
				break
			token_end += 1
		if token_end == index:
			index += 1
			continue

		var token := text.substr(index, token_end - index)
		var after_token := _skip_whitespace(text, token_end)
		if after_token < text.length() and text[after_token] == ":":
			_add_color(colors, index, token_end, KEY_COLOR, default_color)
		elif token in ["true", "false", "null"]:
			_add_color(colors, index, token_end, LITERAL_COLOR, default_color)
		elif token.is_valid_float():
			_add_color(colors, index, token_end, NUMBER_COLOR, default_color)
		else:
			_add_color(colors, index, token_end, STRING_COLOR, default_color)
		index = token_end

	return state


func _find_quote_end(text: String, start: int, quote: String) -> int:
	var index := start
	while index < text.length():
		if text[index] == "\\":
			index += 2
			continue
		if text[index] == quote:
			return index
		index += 1
	return -1


func _skip_whitespace(text: String, start: int) -> int:
	var index := start
	while index < text.length() and text[index] in [" ", "\t", "\r"]:
		index += 1
	return index


func _add_color(
	colors: Variant,
	start: int,
	end: int,
	color: Color,
	default_color: Color
) -> void:
	if colors == null or start >= end:
		return
	colors[start] = color
	colors[end] = default_color

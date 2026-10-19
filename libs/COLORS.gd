@tool
extends Node

const COLOR_PATTERN := r"\[([^\]]+)\]\|([^|]*)\||\|([^|]*)\|\[([^\]]+)\]|\[([^\]]*)\]"

var _color_pattern: RegEx

var data = {
	"ARC": {
		"CLEAR": "#00000000",
		"BLACK": "#000000",
		"WHITE": "#ffffff",
		"LIGHT_GRAY": "#bfbfbf",
		"GRAY": "#7f7f7f",
		"DARK_GRAY": "#3f3f3f",
		"LIGHT_GREY": "#bfbfbf",
		"GREY": "#7f7f7f",
		"DARK_GREY": "#3f3f3f",
		"BLUE": "#4169e1",
		"NAVY": "#00007f",
		"ROYAL": "#4169e1",
		"SLATE": "#4169e1",
		"SKY": "#87ceeb",
		"CYAN": "#00ffff",
		"TEAL": "#007f7f",
		"GREEN": "#38d667",
		"ACID": "#7fff00",
		"LIME": "#32cd32",
		"FOREST": "#228b22",
		"OLIVE": "#6b8e23",
		"YELLOW": "#ffff00",
		"GOLD": "#ffd700",
		"GOLDENROD": "#daa520",
		"ORANGE": "#ffa500",
		"BROWN": "#8b4513",
		"TAN": "#d2b48c",
		"BRICK": "#b22222",
		"RED": "#e55454",
		"SCARLET": "#ff341c",
		"CRIMSON": "#dc143c",
		"CORAL": "#ff7f50",
		"SALMON": "#fa8072",
		"PINK": "#ff69b4",
		"MAGENTA": "#ff00ff",
		"PURPLE": "#a020f0",
		"VIOLET": "#ee82ee",
		"MAROON": "#b03060",
	}, "UI": {
		"YELLOW": "#ffd37f",
		"RED": "#e55454",
		"GREEN": "#54d67d",
		"GRAY": "#454545",
	}}

func get_color(a: String):
	var a_list = a.split(".")
	if len(a_list) > 0:
		if len(a_list) > 1:
			if a_list[0].to_upper() in data:
				if a_list[1].to_upper() in data[a_list[0].to_upper()]:
					return Color.from_string(data[a_list[0].to_upper()][a_list[1].to_upper()], Color.PURPLE)
		else:
			if a_list[0].to_upper() in data["ARC"]:
				return Color.from_string(data["ARC"][a_list[0].to_upper()], Color.PURPLE)
	return Color.PURPLE



func colorita(text: String) -> String:
	if not is_instance_valid(_color_pattern):
		_color_pattern = RegEx.new()
		var error := _color_pattern.compile(COLOR_PATTERN)
		if error != OK:
			push_error("COLORS.colorita: failed to compile the color pattern")
			return text

	var matches := _color_pattern.search_all(text)
	for match_index in range(matches.size() - 1, -1, -1):
		var color_match: RegExMatch = matches[match_index]
		var color_name := color_match.get_string(1)
		var content := color_match.get_string(2)
		var replacement := ""
		if color_name.is_empty() and content.is_empty():
			content = color_match.get_string(3)
			color_name = color_match.get_string(4)
		if color_name.is_empty() and content.is_empty():
			color_name = color_match.get_string(5)

		var color_html := _get_color_html(color_name)
		if color_html.is_empty():
			continue

		if not content.is_empty() or color_match.get_string(1) != "" or color_match.get_string(4) != "":
			replacement = "[color=#%s]%s[/color]" % [color_html, content]
		else:
			replacement = "[color=#%s]" % color_html
		text = text.substr(0, color_match.get_start()) + replacement + text.substr(color_match.get_end())

	return text


func _get_color_html(color_name: String) -> String:
	if color_name.is_empty():
		return "ffffff"

	if color_name.begins_with("#"):
		var hex := color_name.substr(1)
		if hex.length() not in [3, 6]:
			return ""
		for character in hex:
			if not character in "0123456789abcdefABCDEF":
				return ""
		return Color.from_string(color_name, Color.TRANSPARENT).to_html(false)

	var color_parts := color_name.split(".")
	var palette := "ARC"
	var color_key := color_parts[0]
	if color_parts.size() == 2:
		palette = color_parts[0].to_upper()
		color_key = color_parts[1]
	elif color_parts.size() != 1:
		return ""

	palette = palette.to_upper()
	color_key = color_key.to_upper()
	if not data.has(palette) or not data[palette].has(color_key):
		return ""

	return Color.from_string(data[palette][color_key], Color.PURPLE).to_html(false)

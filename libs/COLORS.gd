@tool
extends Node

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
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


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



func colorita(text: String):
	if text == null:
		return ""
	
	var level = 0
	var text1 = ""
	var type = "Main"
	var _color = ""

	var result = ""
	var mode = 0
	var translator = {"level": 0, "text": "", "class": "", "parametr": ""}
	var colorita = {"level": 0, "text": "", "class": "", "parametr": ""}
	var r = 0
	#print("".rsplit())
	#print(text.split("\r\n",false))
	
	for s in [text]:
		var ii = -1
		for i in s:
			ii += 1
			if mode == 0:
				if "|1" == i: # - HERE TRANSLATOR BLOCKATOR
					if r == 0:
						#print(s[ii+1])
						if s[ii+1] == "|":
							r = 1
						else:
							mode = 1
							translator["level"] = 0
					else:
						r = 0
						result += "||"

				elif "[" == i:
					_color = ""
					mode = 2
				else:
					result += i
			if mode == 1:
				if "|" == i:

					if translator["level"] == 0:
						translator["level"] = 1
						#translator["class"] = "Main"
						translator["parametr"] = ""
					else:
						if translator["parametr"] in LocalizationAPI.LanguageDict["LanguageDict"]:
								result += LocalizationAPI.LanguageDict["LanguageDict"][translator["parametr"]][LocalizationAPI.language_list[LocalizationAPI.current_language]]
								translator["level"] = 0
						if translator["level"] != 0:
							result += translator["parametr"]
							translator["level"] = 0

						#translator["class"] = "Main"
						translator["parametr"] = ""
						mode = 0

				elif translator["level"] == 1:
					if translator["parametr"] == "" and i == " ":
						result += "| "
						translator["level"] = 0
					elif ".1" == i:
						translator["level"] = 2
						translator["class"] = translator["parametr"]
						translator["parametr"] = ""
					else:
						translator["parametr"] += i
				elif translator["level"] == 2:
					translator["parametr"] += i
			elif mode == 2:
				if i != "[" and i != "]":
					_color += i
				if i == "[":
					result += '[color='
				if i == "]":
					var _t = get_color(_color)
					#print(_color.to_upper().substr(0, len(_color)-3))
					if _t == Color.PURPLE:
						result += _color
					else:
						result += _t.to_html()
					result += ']'
					mode = 0
		result += "<br>"

	return result.substr(0, len(result)-4)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

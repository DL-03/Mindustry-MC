@tool
extends RichTextLabel
class_name MindustryTextLabel





@export_multiline var real_text = "":
	set = _set_real_text
@export_enum("Left","Center","Right") var text_aligment = 0:
	set = _set_text_aligment

func _set_real_text(value):
	real_text = value
	_text_update()
func _set_text_aligment(value):
	text_aligment = value
	_text_update()

func _text_update():
	bbcode_enabled = true
	
	
	
	var _text = ""

	match text_aligment:
		1:
			_text += "[center]"
		2:
			_text += "[right]"
	
	
	_text += textFormater(real_text)
	#_text += "LONG TEXT LONG TEXT"
	#print(_text)
	text = _text


# Called when the node enters the scene tree for the first time.
func _ready():
	_text_update()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	



func textFormater(text):
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
				if "|" == i:
					if r == 0:
						print(s[ii+1])
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
						translator["class"] = "Main"
						translator["parametr"] = ""
					else:
						#if translator["class"] in self.LanguageDictFile["LanguageDict"]:
						#	if translator["parametr"] in self.LanguageDictFile["LanguageDict"][translator["class"]]:
						#		if self.saveDataFile["Settings"]["Language"] in \
						#				self.LanguageDictFile["LanguageDict"][translator["class"]][
						#					translator["parametr"]]:
						#			result += \
						#			self.LanguageDictFile["LanguageDict"][translator["class"]][translator["parametr"]][
						#				self.saveDataFile["Settings"]["Language"]]
						#			translator["level"] = 0
						#if translator["level"] != 0:
						#	result += translator["parametr"]
						#	translator["level"] = 0

						translator["class"] = "Main"
						translator["parametr"] = ""
						mode = 0

				elif translator["level"] == 1:
					if translator["parametr"] == "" and i == " ":
						result += "| "
						translator["level"] = 0
					elif "." == i:
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
					#print(_color.to_upper().substr(0, len(_color)-3))
					if _color.to_upper().substr(0, 3) == "UI.":
						
						if _color.to_upper().substr(3) in Colors.Colors["UI"]:
							result += Colors.Colors["UI"][_color.to_upper().substr(3)]
						else:
							result += _color
					elif _color.to_upper() in Colors.Colors["MINDUSTRY"]:
						result += Colors.Colors["MINDUSTRY"][_color.to_upper()]
					else:
						result += _color
					result += ']'
					mode = 0
		result += "<br>"

	return result.substr(0, len(result)-4)

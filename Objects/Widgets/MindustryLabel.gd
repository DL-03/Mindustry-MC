@tool
extends Label
class_name MindustryLabel


@export_multiline var real_text = "":
	set = _set_real_text
@export_multiline var real_tooltip_text = "":
	set = _set_real_tooltip_text
		

func _set_real_tooltip_text(value):
	real_tooltip_text = value
	
	if value == "":
		mouse_filter = MOUSE_FILTER_IGNORE
	else:
		mouse_filter = MOUSE_FILTER_PASS


func _set_real_text(value):
	real_text = value
	if translate_text(value) == null:
		text = value
	else:
		text = translate_text(value)



@export var font_color = Color.WHITE:
	set = _set_font_color

func _set_font_color(value):
	if value != null:
		font_color = value
		
		var sfc = font_color
		sfc.v = 0.24
		
		add_theme_color_override("font_color", font_color)
		add_theme_color_override("font_shadow_color", sfc)




# Called when the node enters the scene tree for the first time.
func _ready():
	LocalizationAPI.change_current_language.connect(func(): real_text = real_text)
	
	real_tooltip_text = real_tooltip_text
	real_text = real_text
	font_color = font_color


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func translate_text(text):
	var text_list = text.split("|")
	
	var result = ""
	
	for i in text_list:
		if i in LocalizationAPI.LanguageDict["LanguageDict"]:
			if LocalizationAPI.language_list[LocalizationAPI.current_language] in LocalizationAPI.LanguageDict["LanguageDict"][i]:
				result += translate_text(LocalizationAPI.LanguageDict["LanguageDict"][i][LocalizationAPI.language_list[LocalizationAPI.current_language]])
			else:
				result += i
		else:
			result += i
	return result


func _on_mouse_entered():
	print("eees")
	if real_tooltip_text != "":
		$/root/Main/MindustryToolTip.tip(real_tooltip_text,get_viewport().get_mouse_position())


func _on_mouse_exited():
	if real_tooltip_text != "":
		$/root/Main/MindustryToolTip.untip()

@tool
extends RichTextLabel
class_name MindustryTextLabel




@export_multiline var real_text = "":
	set = _set_real_text
@export_enum("Left","Center","Right") var text_aligment = 0:
	set = _set_text_aligment
@export_enum("Up","Center","Bottom") var text_vertical_aligment = 0:
	set = _text_vertical_aligment

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
	_text_update()
func _set_text_aligment(value):
	text_aligment = value
	_text_update()
func _text_vertical_aligment(value):
	text_vertical_aligment = value
	material.set_shader_parameter("text_vertical_aligment", text_vertical_aligment)
	_text_update()
	
	



func _text_update():
	bbcode_enabled = true
	
	
	
	var _text = ""

	match text_aligment:
		1:
			_text += "[center]"
		2:
			_text += "[right]"
	
	
	_text += COLORS.colorita(LocalizationAPI.translate_text(real_text))
	#_text += "LONG TEXT LONG TEXT"
	#print(_text)
	text = str(_text)
	text_size = get_theme_default_font().get_string_size(text,HORIZONTAL_ALIGNMENT_CENTER,-1,get_theme_default_font_size())*Vector2(1,len(text.split('\n')))




func _ready():
	LocalizationAPI.global_language_changed.connect(_text_update)
	
	material.set_shader_parameter("object_size", size)
	material = material.duplicate()
	_text_update()
var text_size = get_theme_default_font().get_string_size(text,HORIZONTAL_ALIGNMENT_CENTER,-1,get_theme_default_font_size()):
	set = _set_text_size

func _set_text_size(value):
	text_size = value
	
	material.set_shader_parameter("text_size", text_size)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_resized():
	material.set_shader_parameter("object_size", size)


func _on_mouse_entered():
	if real_tooltip_text != "":
		$/root/Main/MindustryToolTip.tip(real_tooltip_text,get_viewport().get_mouse_position())


func _on_mouse_exited():
	if real_tooltip_text != "":
		$/root/Main/MindustryToolTip.untip()

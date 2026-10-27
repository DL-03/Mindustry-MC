@tool
extends Button
class_name MindButton

@export var label: MindLabel

@export var font_color = Color.WHITE:
	set = _set_font_color

@export var font_color_disabled = Color.from_string("#454545", Color.DIM_GRAY):
	set = _set_font_color_disabled


@export_multiline var real_text = "":
	set = _set_real_text
@export var font_size = 16:
	set = _set_font_size


func _set_font_color(value):
	if value != null:
		font_color = value
		
		if label != null:
			label.font_color = font_color

func _set_font_color_disabled(value):
	if value != null:
		font_color_disabled = value

func _set_font_size(value):
	if value != null:
		font_size = value
		
		if label != null:
			label.add_theme_font_size_override("font_size", value)

func _set_real_text(value):
	real_text = value
	
	if label:
		label.real_text = real_text

var disabled_d = 0

func _process(delta):
	if disabled:
		if disabled_d == 0:
			label.font_color = font_color_disabled
			disabled_d = 1
	else:
		if disabled_d == 1:
			label.font_color = font_color
			disabled_d = 0


func _on_text_ready():
	real_text = real_text
	
	font_size = font_size

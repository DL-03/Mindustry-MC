@tool
extends Button
class_name MindustryButton



@export var Text_Element: Node
@export var Icon_Text_Element: Node


@export var font_color = Color.WHITE
@export var real_text_icon = "":
	set = _real_text_icon

@export_multiline var real_text = "":
	set = _set_real_text
@export_enum("Left", "Center", "Right") var h_aligment = 1:
	set = _set_h_aligment
@export var font_size = 16:
	set = _set_font_size
@export var icon_size = 26:
	set = _set_icon_size

@export_multiline var real_tooltip_text = ""

func _set_font_size(value):
	if value != null:
		font_size = value
		
		if Text_Element != null:
			Text_Element.add_theme_font_size_override("font_size", value)
func _set_icon_size(value):
	if value != null:
		icon_size = value
		
		if Icon_Text_Element != null:
			Icon_Text_Element.add_theme_font_size_override("font_size", value)
func _set_h_aligment(value):
	h_aligment = value
	print(h_aligment)
	if h_aligment == 0:
		#Text_Element.size_flags_horizontal = SIZE_SHRINK_BEGIN | SIZE_EXPAND
		Text_Element.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	elif h_aligment == 1:
		#Text_Element.size_flags_horizontal = SIZE_SHRINK_CENTER | SIZE_EXPAND
		Text_Element.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elif h_aligment == 2:
		#Text_Element.size_flags_horizontal = SIZE_SHRINK_END | SIZE_EXPAND
		Text_Element.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
func _set_real_text(value):
	real_text = value
	
	Text_Element.real_text = real_text

	Text_Element.visible = (real_text != "")
func _real_text_icon(value):
	real_text_icon = value
	
	Icon_Text_Element.real_text = real_text_icon
	
	Icon_Text_Element.visible = (real_text_icon != "")
# Called when the node enters the scene tree for the first time.




func _ready():
	
	real_text_icon = real_text_icon
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if disabled:
		Text_Element.font_color = Color.from_string("#454545", Color.DIM_GRAY)
		Icon_Text_Element.font_color = Color.from_string("#454545", Color.DIM_GRAY)
	else:
		Text_Element.font_color = font_color
		Icon_Text_Element.font_color = font_color




func _on_mouse_entered():
	print("eees")
	if real_tooltip_text != "":
		$/root/Main/MindustryToolTip.tip(real_tooltip_text,get_viewport().get_mouse_position())


func _on_mouse_exited():
	if real_tooltip_text != "":
		$/root/Main/MindustryToolTip.untip()


func _on_text_ready():
	real_text = real_text
	
	font_size = font_size
	h_aligment = h_aligment

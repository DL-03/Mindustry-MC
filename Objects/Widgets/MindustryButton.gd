@tool
extends Button
class_name MindustryButton



@export var Text_Element: Node
@export var Icon_Text_Left_Element: Node
@export var Icon_Text_Right_Element: Node


@export var font_color = Color.WHITE:
	set = _set_font_color
@export var icon_color = Color.WHITE:
	set = _set_icon_color

@export var font_color_disabled = Color.from_string("#454545", Color.DIM_GRAY):
	set = _set_font_color_disabled
@export var icon_color_disabled = Color.from_string("#454545", Color.DIM_GRAY):
	set = _set_icon_color_disabled

@export var real_text_icon_left = "":
	set = _real_text_icon_left
@export var real_text_icon_right = "":
	set = _real_text_icon_right

@export_multiline var real_text = "":
	set = _set_real_text
@export_enum("Left", "Center", "Right") var h_aligment = 1:
	set = _set_h_aligment
@export var font_size = 16:
	set = _set_font_size
@export var icon_size = 26:
	set = _set_icon_size

@export_multiline var real_tooltip_text = ""

func _set_icon_color(value):
	if value != null:
		icon_color = value
		
		if Icon_Text_Left_Element != null:
			Icon_Text_Left_Element.font_color = icon_color
		if Icon_Text_Right_Element != null:
			Icon_Text_Right_Element.font_color = icon_color
func _set_font_color(value):
	if value != null:
		font_color = value
		
		if Text_Element != null:
			Text_Element.font_color = font_color
			
func _set_icon_color_disabled(value):
	if value != null:
		icon_color_disabled = value
		

func _set_font_color_disabled(value):
	if value != null:
		font_color_disabled = value





func _set_font_size(value):
	if value != null:
		font_size = value
		
		if Text_Element != null:
			Text_Element.add_theme_font_size_override("font_size", value)
func _set_icon_size(value):
	if value != null:
		icon_size = value
		
		if Icon_Text_Left_Element != null:
			Icon_Text_Left_Element.add_theme_font_size_override("font_size", value)
		if Icon_Text_Right_Element != null:
			Icon_Text_Right_Element.add_theme_font_size_override("font_size", value)

func _set_h_aligment(value):
	h_aligment = value
	#print(h_aligment)
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
	
func _real_text_icon_left(value):
	real_text_icon_left = str(value)
	
	if Icon_Text_Left_Element != null:
		Icon_Text_Left_Element.real_text = real_text_icon_left
		
		Icon_Text_Left_Element.visible = (real_text_icon_left != "")
func _real_text_icon_right(value):
	real_text_icon_right = str(value)
	
	if Icon_Text_Right_Element != null:
		Icon_Text_Right_Element.real_text = real_text_icon_right
		
		Icon_Text_Right_Element.visible = (real_text_icon_right != "")





func _ready():
	
	pass
	
func _full_ready():
	pass


var disabled_d = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if disabled:
		if disabled_d == 0:
			Text_Element.font_color = font_color_disabled
			Icon_Text_Left_Element.font_color = icon_color_disabled
			Icon_Text_Right_Element.font_color = icon_color_disabled
			disabled_d = 1
	else:
		if disabled_d == 1:
			Text_Element.font_color = font_color
			Icon_Text_Left_Element.font_color = icon_color
			Icon_Text_Right_Element.font_color = icon_color
			disabled_d = 0




func _on_mouse_entered():
	#print("eees")
	if real_tooltip_text != "":
		$/root/Main/MindustryToolTip.tip(real_tooltip_text,get_viewport().get_mouse_position())


func _on_mouse_exited():
	if real_tooltip_text != "":
		$/root/Main/MindustryToolTip.untip()


func _on_text_ready():
	real_text = real_text
	
	font_size = font_size
	h_aligment = h_aligment


func _on_icon_text_left_ready():
	real_text_icon_left = real_text_icon_left



func _on_icon_text_right_ready():
	real_text_icon_right = real_text_icon_right

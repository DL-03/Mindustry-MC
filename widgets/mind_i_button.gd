@tool
extends Button
class_name MindIButton

@export var left_icon: MindLabel
@export var label: MindLabel
@export var right_icon: MindLabel

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
		
		if left_icon != null:
			left_icon.font_color = icon_color
		if right_icon != null:
			right_icon.font_color = icon_color
func _set_font_color(value):
	if value != null:
		font_color = value
		
		if label != null:
			label.font_color = font_color
			
func _set_icon_color_disabled(value):
	if value != null:
		icon_color_disabled = value
		

func _set_font_color_disabled(value):
	if value != null:
		font_color_disabled = value


func _set_font_size(value):
	if value != null:
		font_size = value
		
		if label != null:
			label.add_theme_font_size_override("font_size", value)
func _set_icon_size(value):
	if value != null:
		icon_size = value
		
		if left_icon != null:
			left_icon.add_theme_font_size_override("font_size", value)
		if right_icon != null:
			right_icon.add_theme_font_size_override("font_size", value)

func _set_h_aligment(value):
	h_aligment = value
	if h_aligment == 0:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	elif h_aligment == 1:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elif h_aligment == 2:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _set_real_text(value):
	real_text = value
	
	if label:
		label.real_text = real_text

	
func _real_text_icon_left(value):
	real_text_icon_left = str(value)
	
	if left_icon != null:
		left_icon.real_text = real_text_icon_left
		
		left_icon.visible = (real_text_icon_left != "")
func _real_text_icon_right(value):
	real_text_icon_right = str(value)
	
	if right_icon != null:
		right_icon.real_text = real_text_icon_right
		
		right_icon.visible = (real_text_icon_right != "")


var disabled_d = 0

func _ready() -> void:
	label.real_text = real_text
	
	font_size = font_size
	h_aligment = h_aligment

func _process(delta):
	if disabled:
		if disabled_d == 0:
			label.font_color = font_color_disabled
			left_icon.font_color = icon_color_disabled
			right_icon.font_color = icon_color_disabled
			disabled_d = 1
	else:
		if disabled_d == 1:
			label.font_color = font_color
			left_icon.font_color = icon_color
			right_icon.font_color = icon_color
			disabled_d = 0


func _on_icon_text_left_ready():
	real_text_icon_left = real_text_icon_left

func _on_icon_text_right_ready():
	real_text_icon_right = real_text_icon_right



func _on_mind_tooltip_ready() -> void:
	tl_upd()

func tl_upd():
	var _MindTooltip = get_node_or_null("_MindTooltip")
	if not _MindTooltip:
		return
	if real_tooltip_text:
		_MindTooltip.tooltip_text = "[emb]"+real_tooltip_text
	else:
		_MindTooltip.tooltip_text = ""

@tool
extends Label
class_name MindustryLabel


@export_multiline var real_text = "":
	set = _set_real_text
@export_multiline var real_tooltip_text = "":
	set = _set_real_tooltip_text
		

func _set_real_tooltip_text(value):
	real_tooltip_text = value
	tl_upd()

func _set_real_text(value):
	real_text = value

	text = LocalizationAPI.translate_text(value)


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
	LocalizationAPI.global_language_changed.connect(func(): real_text = real_text)
	
	real_text = real_text
	font_color = font_color



func _on_mind_tooltip_ready() -> void:
	tl_upd()

func tl_upd():
	var _MindTooltip = get_node_or_null("MindTooltip")
	if not _MindTooltip:
		return
	if real_tooltip_text:
		_MindTooltip.tooltip_text = "[emb]"+real_tooltip_text
	else:
		_MindTooltip.tooltip_text = ""

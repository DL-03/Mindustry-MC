@tool
extends Label
class_name MindLabel

signal display_text_changed(value: String)

@export_group("Text")
@export_multiline var real_text: String = "":
	set = _set_real_text

@export var placeholders: Dictionary = {}:
	set = _set_placeholders

@export_group("Appearance")
@export var font_color: Color = Color.WHITE:
	set = _set_font_color

const EMBOSS_TAG_REGEX := r"\[(/?)emb(?:\s+([^\]]*))?\]"
const EMBOSS_ATTRIBUTES_REGEX := r"(\w+)\s*=\s*([^\s\]]+)"
const PLACEHOLDER_REGEX := r"\{([^{}]+)\}"
const COLOR_TAG_REGEX := r"^\[color=(#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8}))\]"

var _emboss_tag_regex := RegEx.new()
var _emboss_attributes_regex := RegEx.new()
var _placeholder_regex := RegEx.new()
var _color_tag_regex := RegEx.new()

func _init() -> void:
	_emboss_tag_regex.compile(EMBOSS_TAG_REGEX)
	_emboss_attributes_regex.compile(EMBOSS_ATTRIBUTES_REGEX)
	_placeholder_regex.compile(PLACEHOLDER_REGEX)
	_color_tag_regex.compile(COLOR_TAG_REGEX)

func _ready() -> void:
	if LocalizationAPI and LocalizationAPI.has_signal("global_language_changed"):
		var update_callback := Callable(self, "_update_styled_text")
		if not LocalizationAPI.global_language_changed.is_connected(update_callback):
			LocalizationAPI.global_language_changed.connect(update_callback)
	_update_styled_text()

func _set_real_text(value: String) -> void:
	real_text = value
	_update_styled_text()

func _set_placeholders(value: Dictionary) -> void:
	placeholders = value
	_update_styled_text()

func _set_font_color(value: Color) -> void:
	font_color = value
	_update_styled_text()

func _update_styled_text() -> void:
	var display_text := _replace_placeholders(real_text)
	
	if LocalizationAPI:
		display_text = LocalizationAPI.translate_text(display_text)

	var has_emboss := false
	var emboss_offset := 2
	var custom_emboss_color: Variant = null
	for tag_match in _emboss_tag_regex.search_all(display_text):
		if tag_match.get_string(1) == "":
			has_emboss = true
			for attribute_match in _emboss_attributes_regex.search_all(tag_match.get_string(2)):
				match attribute_match.get_string(1):
					"offset":
						var offset_text := attribute_match.get_string(2)
						if offset_text.is_valid_float():
							emboss_offset = roundi(offset_text.to_float())
					"color":
						custom_emboss_color = Color.from_string(
							attribute_match.get_string(2),
							Color.BLACK
						)
			break
	display_text = _emboss_tag_regex.sub(display_text, "", true)

	var resolved_text_color := font_color
	if COLORS:
		display_text = COLORS.colorita(display_text)
	var color_match := _color_tag_regex.search(display_text)
	if color_match:
		resolved_text_color = Color.from_string(color_match.get_string(1), font_color)
		display_text = display_text.substr(color_match.get_end())
	display_text = display_text.replace("[/color]", "")

	var changed := text != display_text
	text = display_text
	add_theme_color_override("font_color", resolved_text_color)
	add_theme_constant_override("shadow_offset_x", 0)
	add_theme_constant_override("shadow_offset_y", emboss_offset if has_emboss else 0)
	if has_emboss:
		var shadow_color: Color = custom_emboss_color \
			if custom_emboss_color is Color \
			else resolved_text_color.darkened(0.7)
		add_theme_color_override("font_shadow_color", shadow_color)
	else:
		add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	if changed:
		display_text_changed.emit(text)

func _replace_placeholders(source: String) -> String:
	if placeholders.is_empty():
		return source

	var matches := _placeholder_regex.search_all(source)
	if matches.is_empty():
		return source

	var result := ""
	var previous_end := 0
	for placeholder_match in matches:
		result += source.substr(previous_end, placeholder_match.get_start() - previous_end)
		var key := placeholder_match.get_string(1)
		if placeholders.has(key) and placeholders[key] != null:
			result += str(placeholders[key])
		else:
			result += placeholder_match.get_string(0)
		previous_end = placeholder_match.get_end()
	result += source.substr(previous_end)
	return result

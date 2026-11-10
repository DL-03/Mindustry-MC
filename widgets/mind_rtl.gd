@tool
extends RichTextLabel
class_name MindRTL


@export_multiline var real_text: String = "":
	set = _set_real_text

@export var placeholders: Dictionary = {}:
	set = _set_placeholders

@export var emb_label: Control

const EMBOSS_TAG_REGEX := r"\[(/?)emb(?:\s+([^\]]*))?\]"
const EMBOSS_ATTRIBUTES_REGEX := r"(\w+)\s*=\s*([^\s\]]+)"
const PLACEHOLDER_REGEX := r"\{([^{}]+)\}"
const EMBOSS_SHADER: Shader = preload("res://widgets/mind_rtl_emboss.gdshader")

const MIRRORED_PROPERTIES: Array[StringName] = [
	&"autowrap_mode",
	&"bbcode_enabled",
	&"clip_contents",
	&"custom_minimum_size",
	&"fit_content",
	&"horizontal_alignment",
	&"language",
	&"scroll_active",
	&"scroll_following",
	&"size_flags_horizontal",
	&"size_flags_vertical",
	&"tab_size",
	&"text_direction",
	&"theme",
	&"theme_type_variation",
	&"vertical_alignment",
]

var _shadow_labels: Array[RichTextLabel] = []
var _emboss_clips: Array[Control] = []
var _plain_text_regex := RegEx.new()
var _emboss_regex := RegEx.new()
var _attributes_regex := RegEx.new()
var _placeholder_regex := RegEx.new()
var _last_visible_text := ""
var _last_segments: Array[Dictionary] = []
var _last_alignment := Vector2i(-1, -1)
var _has_rendered_text := false
var _batch_content_update := false
var _emboss_rebuild_pending := false

func _init() -> void:
	_plain_text_regex.compile(r"\[[^\]]*\]")
	_emboss_regex.compile(EMBOSS_TAG_REGEX)
	_attributes_regex.compile(EMBOSS_ATTRIBUTES_REGEX)
	_placeholder_regex.compile(PLACEHOLDER_REGEX)

func _ready() -> void:
	if LocalizationAPI and LocalizationAPI.has_signal("global_language_changed"):
		var update_callback = Callable(self, "_text_update")
		if not LocalizationAPI.global_language_changed.is_connected(update_callback):
			LocalizationAPI.global_language_changed.connect(update_callback)
	_sync_properties()
	_text_update()

func _set_real_text(value: String) -> void:
	real_text = value
	if not _batch_content_update:
		_text_update()

func _set_placeholders(value: Dictionary) -> void:
	placeholders = value
	if not _batch_content_update:
		_text_update()

func set_tooltip_content(value: String, new_placeholders: Dictionary) -> void:
	if real_text == value and placeholders == new_placeholders:
		return
	_batch_content_update = true
	real_text = value
	placeholders = new_placeholders
	_batch_content_update = false
	_text_update()

func _text_update() -> void:
	bbcode_enabled = true
	var display_text := _replace_placeholders(real_text)
	if LocalizationAPI:
		display_text = LocalizationAPI.translate_text(display_text)
	if COLORS:
		display_text = COLORS.colorita(display_text)

	var segments: Array[Dictionary] = []
	var visible_parts: PackedStringArray = []
	var plain_index := 0
	var previous_end := 0
	var active_segments: Array[Dictionary] = []

	for tag_match in _emboss_regex.search_all(display_text):
		var preceding_text := display_text.substr(
			previous_end,
			tag_match.get_start() - previous_end
		)
		visible_parts.append(preceding_text)
		plain_index += _plain_text_regex.sub(preceding_text, "", true).length()

		if tag_match.get_string(1) == "/":
			if not active_segments.is_empty():
				var closed_segment: Dictionary = active_segments.pop_back()
				closed_segment["end"] = plain_index
				if closed_segment["end"] > closed_segment["start"]:
					segments.append(closed_segment)
		else:
			var new_segment := {
				"start": plain_index,
				"offset": 2.0,
				"color": null,
			}
			var attributes_text: String = tag_match.get_string(2)
			for attribute_match in _attributes_regex.search_all(attributes_text):
				match attribute_match.get_string(1):
					"offset":
						var offset_text: String = attribute_match.get_string(2)
						if offset_text.is_valid_float():
							new_segment["offset"] = offset_text.to_float()
					"color":
						var color_text: String = attribute_match.get_string(2)
						new_segment["color"] = Color.from_string(color_text, Color.BLACK)
			active_segments.append(new_segment)

		previous_end = tag_match.get_end()

	var trailing_text := display_text.substr(previous_end)
	visible_parts.append(trailing_text)
	plain_index += _plain_text_regex.sub(trailing_text, "", true).length()
	while not active_segments.is_empty():
		var active_segment: Dictionary = active_segments.pop_back()
		active_segment["end"] = plain_index
		if active_segment["end"] > active_segment["start"]:
			segments.append(active_segment)

	var visible_text := "".join(visible_parts)
	segments.sort_custom(_sort_emboss_segments)
	if _has_rendered_text and visible_text == _last_visible_text and segments == _last_segments:
		return

	_has_rendered_text = true
	_last_visible_text = visible_text
	_last_segments = segments
	_last_alignment = Vector2i(horizontal_alignment, vertical_alignment)
	set_process(not segments.is_empty() and is_instance_valid(emb_label))
	text = visible_text
	_schedule_emboss_rebuild()

func _replace_placeholders(source: String) -> String:
	if placeholders == null or placeholders.is_empty():
		return source
	if _placeholder_regex == null:
		_placeholder_regex = RegEx.new()
		var compile_error := _placeholder_regex.compile(PLACEHOLDER_REGEX)
		if compile_error != OK:
			push_error("MindRTL: failed to compile placeholder pattern.")
			return source

	var matches := _placeholder_regex.search_all(source)
	if matches.is_empty():
		return source

	var result := ""
	var previous_end := 0
	for placeholder_match in matches:
		result += source.substr(
			previous_end,
			placeholder_match.get_start() - previous_end
		)
		var placeholder_key := placeholder_match.get_string(1)
		if placeholders.has(placeholder_key) and placeholders[placeholder_key] != null:
			result += str(placeholders[placeholder_key])
		else:
			result += placeholder_match.get_string(0)
		previous_end = placeholder_match.get_end()
	result += source.substr(previous_end)
	return result

func _sort_emboss_segments(a: Dictionary, b: Dictionary) -> bool:
	if a["start"] == b["start"]:
		return a["end"] > b["end"]
	return a["start"] < b["start"]

func _sync_properties() -> void:
	if not is_instance_valid(emb_label):
		return
	for shadow_label in _shadow_labels:
		_sync_shadow_label(shadow_label)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_POST_ENTER_TREE, NOTIFICATION_THEME_CHANGED]:
		_sync_properties()
		if is_node_ready():
			_schedule_emboss_rebuild()
	elif what == NOTIFICATION_RESIZED and is_node_ready():
		_schedule_emboss_rebuild()

func _process(_delta: float) -> void:
	var alignment := Vector2i(horizontal_alignment, vertical_alignment)
	if alignment == _last_alignment:
		return
	_last_alignment = alignment
	_schedule_emboss_rebuild()

func _schedule_emboss_rebuild() -> void:
	if not is_instance_valid(emb_label) or _emboss_rebuild_pending:
		return
	_emboss_rebuild_pending = true
	call_deferred("_run_scheduled_emboss_rebuild")

func _run_scheduled_emboss_rebuild() -> void:
	_emboss_rebuild_pending = false
	_rebuild_emboss_layers(_last_visible_text, _last_segments)

func _rebuild_emboss_layers(visible_text: String, segments: Array[Dictionary]) -> void:
	if not is_instance_valid(emb_label):
		return

	var parsed_text := get_parsed_text()
	var character_count := get_total_character_count()
	if segments.is_empty():
		for clip in _emboss_clips:
			clip.visible = false
		return
	if character_count == 0:
		for clip in _emboss_clips:
			clip.visible = false
		return

	var layer_index := 0
	for segment in segments:
		var start_index: int = clampi(segment["start"], 0, character_count)
		var end_index: int = clampi(segment["end"], start_index, character_count)
		for line_index in range(get_line_count()):
			var line_range := get_line_range(line_index)
			var run_start := maxi(start_index, line_range.x)
			var run_end := mini(end_index, line_range.y)
			if run_end <= run_start:
				continue
			_create_emboss_layer(
				visible_text,
				parsed_text,
				run_start,
				run_end,
				line_index,
				segment,
				layer_index
			)
			layer_index += 1
	for unused_index in range(layer_index, _emboss_clips.size()):
		_emboss_clips[unused_index].visible = false

func _create_emboss_layer(
	visible_text: String,
	parsed_text: String,
	start_index: int,
	end_index: int,
	line_index: int,
	segment: Dictionary,
	layer_index: int
) -> void:
	if line_index < 0 or end_index <= start_index:
		return

	var line_range := get_line_range(line_index)
	var line_start: int = line_range.x
	var prefix_end: int = clampi(start_index, line_start, line_range.y)
	var text_end: int = clampi(end_index, prefix_end, line_range.y)
	var prefix := parsed_text.substr(line_start, prefix_end - line_start)
	var run_text := parsed_text.substr(prefix_end, text_end - prefix_end)
	var font := get_theme_font("normal_font")
	var font_size := get_theme_font_size("normal_font_size")
	if font == null:
		font = get_theme_default_font()
	if font == null:
		return
	if font_size <= 0:
		font_size = 16
	var prefix_width := font.get_string_size(prefix, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var full_width := font.get_string_size(
		prefix + run_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size
	).x
	var line_width := get_line_width(line_index)
	var style := get_theme_stylebox("normal")
	var content_left := style.get_content_margin(SIDE_LEFT) if style else 0.0
	var content_top := style.get_content_margin(SIDE_TOP) if style else 0.0
	var content_bottom := style.get_content_margin(SIDE_BOTTOM) if style else 0.0
	var available_width := size.x
	var available_height := size.y
	if style:
		available_width -= style.get_content_margin(SIDE_LEFT) + style.get_content_margin(SIDE_RIGHT)
		available_height -= content_top + content_bottom
	var horizontal_offset := 0.0
	match horizontal_alignment:
		HORIZONTAL_ALIGNMENT_CENTER:
			horizontal_offset = maxf((available_width - line_width) / 2.0, 0.0)
		HORIZONTAL_ALIGNMENT_RIGHT:
			horizontal_offset = maxf(available_width - line_width, 0.0)
	var vertical_offset := 0.0
	var content_height := get_content_height()
	match vertical_alignment:
		VERTICAL_ALIGNMENT_CENTER:
			vertical_offset = maxf((available_height - content_height) / 2.0, 0.0)
		VERTICAL_ALIGNMENT_BOTTOM:
			vertical_offset = maxf(available_height - content_height, 0.0)

	var horizontal_padding := 0.5
	var vertical_padding := 2.0
	var run_rect := Rect2(
		content_left + horizontal_offset + prefix_width - horizontal_padding,
		content_top + vertical_offset + get_line_offset(line_index) + minf(0.0, float(segment["offset"])) - vertical_padding,
		maxf(full_width - prefix_width + horizontal_padding * 2.0, horizontal_padding * 2.0),
		get_line_height(line_index) + absf(float(segment["offset"])) + vertical_padding * 2.0
	)
	var clip: Control
	var shadow: RichTextLabel
	if layer_index < _emboss_clips.size():
		clip = _emboss_clips[layer_index]
		shadow = _shadow_labels[layer_index]
	else:
		clip = Control.new()
		clip.clip_contents = true
		clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		emb_label.add_child(clip)

		shadow = RichTextLabel.new()
		shadow.bbcode_enabled = true
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow.fit_content = fit_content
		shadow.autowrap_mode = autowrap_mode
		shadow.theme = theme
		shadow.theme_type_variation = theme_type_variation
		shadow.material = ShaderMaterial.new()
		(shadow.material as ShaderMaterial).shader = EMBOSS_SHADER
		clip.add_child(shadow)
		_emboss_clips.append(clip)
		_shadow_labels.append(shadow)
		_sync_shadow_label(shadow)

	clip.visible = true
	clip.position = run_rect.position
	clip.size = run_rect.size
	shadow.position = -run_rect.position + Vector2(-1.0, float(segment["offset"]))
	if shadow.size != size:
		shadow.size = size
	if shadow.text != visible_text:
		shadow.text = visible_text
	var emboss_color: Variant = segment["color"]
	(shadow.material as ShaderMaterial).set_shader_parameter(
		"use_custom_color",
		emboss_color != null
	)
	if emboss_color != null:
		(shadow.material as ShaderMaterial).set_shader_parameter("emboss_color", emboss_color)

func _sync_shadow_label(shadow_label: RichTextLabel) -> void:
	for property_name in MIRRORED_PROPERTIES:
		shadow_label.set(property_name, get(property_name))
	for property_info in get_property_list():
		var property_name: StringName = property_info.name
		if str(property_name).begins_with("theme_override_") \
		and property_name != &"theme_override_styles/normal":
			shadow_label.set(property_name, get(property_name))
	var empty_style := StyleBoxEmpty.new()
	var parent_style := get_theme_stylebox("normal")
	if parent_style:
		for side in range(4):
			empty_style.set_content_margin(side, parent_style.get_content_margin(side))
	shadow_label.add_theme_stylebox_override("normal", empty_style)

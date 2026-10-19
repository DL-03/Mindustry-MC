@tool
class_name MindTooltip
extends Node

enum TooltipScope {
	GLOBAL, # Использует общий синглтон-менеджер (экономит ноды)
	LOCAL   # Создает свой собственный инстанс (для вложенных тултипов и изоляции)
}

enum SourceType {
	PACKED_SCENE,
	EXISTING_NODE
}

enum PositionMode {
	FIXED_OFFSET_FROM_MOUSE,
	FOLLOW_MOUSE_REALTIME,
	FIXED_SCREEN_POSITION,
	RELATIVE_TO_PARENT,
	CUSTOM
}

enum Anchor {
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT,
	CENTER,
	CUSTOM
}

enum OverflowBehavior {
	CLAMP_TO_EDGE,
	FLIP_AROUND_MOUSE
}

@export_group("Tooltip Architecture")
@export var tooltip_scope: TooltipScope = TooltipScope.GLOBAL

@export_group("Tooltip Content")
@export var source_type: SourceType = SourceType.PACKED_SCENE:
	set(value):
		source_type = value
		_on_editor_preview_changed()
@export var tooltip_scene: PackedScene = preload("res://widgets/tooltips/mind_tooltip_default.tscn"):
	set(value):
		tooltip_scene = value
		_on_editor_preview_changed()
@export var tooltip_node_path: NodePath:
	set(value):
		tooltip_node_path = value
		_on_editor_preview_changed()
@export_multiline var tooltip_text: String = "":
	set(value):
		tooltip_text = value
		_on_content_changed()
@export var custom_data: Dictionary = {}:
	set(value):
		custom_data = value
		_on_content_changed()

@export_group("Editor Preview")
@export var preview_in_editor: bool = false:
	set(value):
		preview_in_editor = value
		_on_editor_preview_changed()

@export_group("Positioning & Behavior")
@export var position_mode: PositionMode = PositionMode.FIXED_OFFSET_FROM_MOUSE:
	set(value):
		position_mode = value
		_on_position_settings_changed()
@export var anchor: Anchor = Anchor.BOTTOM_RIGHT:
	set(value):
		anchor = value
		_on_position_settings_changed()
@export var anchor_offset: Vector2 = Vector2(5, 5):
	set(value):
		anchor_offset = value
		_on_position_settings_changed()
@export var overflow_behavior: OverflowBehavior = OverflowBehavior.CLAMP_TO_EDGE:
	set(value):
		overflow_behavior = value
		_on_position_settings_changed()
@export var fixed_position: Vector2 = Vector2.ZERO:
	set(value):
		fixed_position = value
		_on_position_settings_changed()
@export var mouse_offset: Vector2 = Vector2(5, 5):
	set(value):
		mouse_offset = value
		_on_position_settings_changed()
@export var show_delay: float = 0.0
@export var hide_on_mouse_exit: bool = true
@export var clamp_to_screen: bool = true:
	set(value):
		clamp_to_screen = value
		_on_position_settings_changed()
@export var screen_padding: Vector2 = Vector2(5, 5):
	set(value):
		screen_padding = value
		_on_position_settings_changed()

var _parent_control: Control
var _tooltip_instance: Control = null # Используется только для LOCAL режима
var _editor_preview_instance: Control = null
var _editor_preview_generation: int = 0
var _editor_preview_update_pending: bool = false
var _editor_preview_position_pending: bool = false
var _last_editor_parent_rect: Rect2 = Rect2()
var _last_editor_preview_size: Vector2 = Vector2.ZERO
var _is_hovered: bool = false
var _hover_generation: int = 0
var _hide_generation: int = 0
var _position_generation: int = 0
var _last_tooltip_size: Vector2 = Vector2.ZERO
var _last_parent_rect: Rect2 = Rect2()

static var _shared_canvas_layer: CanvasLayer = null

func _ready() -> void:
	_parent_control = get_parent() as Control
	if not _parent_control:
		if not Engine.is_editor_hint():
			push_warning("MindTooltip: Parent node is not a Control!")
		return
	if Engine.is_editor_hint():
		set_process(preview_in_editor)
		if preview_in_editor:
			_queue_editor_preview_update()
		return
	
	_parent_control.mouse_entered.connect(_on_mouse_entered)
	_parent_control.mouse_exited.connect(_on_mouse_exited)
	if tooltip_scope == TooltipScope.LOCAL:
		_ensure_canvas_layer()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		if preview_in_editor and is_instance_valid(_editor_preview_instance) and is_instance_valid(_parent_control):
			var parent_rect = _parent_control.get_global_rect()
			if not _editor_preview_position_pending and (parent_rect != _last_editor_parent_rect or _editor_preview_instance.size != _last_editor_preview_size):
				_editor_preview_position_pending = true
				call_deferred("_position_editor_preview", _editor_preview_instance, _editor_preview_generation)
		return

	if not _is_hovered or tooltip_scope == TooltipScope.GLOBAL:
		return
	
	# Локальная логика отслеживания размеров для LOCAL режима
	if _tooltip_instance and _tooltip_instance.visible:
		if position_mode == PositionMode.RELATIVE_TO_PARENT and is_instance_valid(_parent_control):
			var parent_rect = _parent_control.get_global_rect()
			if parent_rect != _last_parent_rect:
				_update_tooltip_position()
		var current_size = _tooltip_instance.size
		if current_size != _last_tooltip_size:
			_last_tooltip_size = current_size
			_update_tooltip_position()
		
		if position_mode == PositionMode.FOLLOW_MOUSE_REALTIME:
			_update_tooltip_position()

func _on_mouse_entered() -> void:
	_is_hovered = true
	_hover_generation += 1
	_hide_generation += 1
	var generation = _hover_generation
	
	if show_delay > 0:
		await get_tree().create_timer(show_delay).timeout
		if not _is_hovered or generation != _hover_generation:
			return
			
	_show_tooltip()

func _on_mouse_exited() -> void:
	_is_hovered = false
	_hover_generation += 1
		
	if hide_on_mouse_exit:
		_hide_generation += 1
		call_deferred("_hide_if_pointer_left", _hide_generation)

func _on_tooltip_mouse_entered() -> void:
	_hide_generation += 1

func _on_tooltip_mouse_exited() -> void:
	if hide_on_mouse_exit:
		_hide_generation += 1
		call_deferred("_hide_if_pointer_left", _hide_generation)

func _hide_if_pointer_left(generation: int) -> void:
	await get_tree().process_frame
	if generation != _hide_generation or _is_hovered or not hide_on_mouse_exit:
		return
	var hovered_control = get_viewport().gui_get_hovered_control()
	if _is_control_or_descendant(_parent_control, hovered_control) or _is_control_or_descendant(_tooltip_instance, hovered_control):
		return
	_hide_tooltip()

func _is_control_or_descendant(control: Control, hovered_control: Control) -> bool:
	return is_instance_valid(control) and is_instance_valid(hovered_control) and (control == hovered_control or control.is_ancestor_of(hovered_control))

func _ensure_canvas_layer() -> void:
	if not _shared_canvas_layer or not is_instance_valid(_shared_canvas_layer):
		_shared_canvas_layer = CanvasLayer.new()
		_shared_canvas_layer.layer = 128
		var root = Engine.get_main_loop().root
		root.call_deferred("add_child", _shared_canvas_layer)

func _on_editor_preview_changed() -> void:
	if Engine.is_editor_hint() and is_inside_tree():
		set_process(preview_in_editor)
		_queue_editor_preview_update()

func _queue_editor_preview_update() -> void:
	if _editor_preview_update_pending:
		return
	_editor_preview_update_pending = true
	call_deferred("_update_editor_preview")

func _update_editor_preview() -> void:
	_editor_preview_update_pending = false
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	_editor_preview_generation += 1
	_editor_preview_position_pending = false
	var generation = _editor_preview_generation
	if is_instance_valid(_editor_preview_instance):
		_editor_preview_instance.hide()
		_editor_preview_instance.queue_free()
	_editor_preview_instance = null
	_parent_control = get_parent() as Control
	if is_instance_valid(_parent_control):
		for child in _parent_control.get_children():
			if child is Control and child.has_meta("mind_tooltip_editor_preview"):
				child.hide()
				child.queue_free()
	if not preview_in_editor:
		return

	if not is_instance_valid(_parent_control):
		return

	var preview: Control
	if source_type == SourceType.PACKED_SCENE and tooltip_scene:
		preview = tooltip_scene.instantiate() as Control
	elif source_type == SourceType.EXISTING_NODE and not tooltip_node_path.is_empty():
		var source = get_node_or_null(tooltip_node_path) as Control
		if is_instance_valid(source):
			preview = source.duplicate() as Control
	if not is_instance_valid(preview):
		return

	preview.top_level = true
	preview.owner = null
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.set_meta("mind_tooltip_editor_preview", true)
	_editor_preview_instance = preview
	call_deferred("_attach_editor_preview", preview, generation)

func _attach_editor_preview(preview: Control, generation: int) -> void:
	if generation != _editor_preview_generation or preview != _editor_preview_instance or not is_instance_valid(preview) or not is_instance_valid(_parent_control):
		return
	_parent_control.add_child(preview)
	var data = _get_effective_data()
	if preview.has_method("tip"):
		preview.call("tip", data)
	elif preview.has_method("_setup_tooltip"):
		preview.call("_setup_tooltip", data)
		preview.show()
	else:
		preview.show()

	var animation_player = preview.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation_player and animation_player.has_animation("show"):
		animation_player.play("show")
		animation_player.seek(animation_player.get_animation("show").length, true)
		animation_player.pause()
	preview.show()
	call_deferred("_position_editor_preview", preview, generation)

func _position_editor_preview(preview: Control, generation: int) -> void:
	await get_tree().process_frame
	if generation != _editor_preview_generation or preview != _editor_preview_instance or not is_instance_valid(preview):
		if generation == _editor_preview_generation:
			_editor_preview_position_pending = false
		return
	preview.reset_size()
	preview.pivot_offset_ratio = _get_pivot_ratio_for_anchor(anchor)
	preview.global_position = _calculate_position(preview, true)
	_last_editor_parent_rect = _parent_control.get_global_rect()
	_last_editor_preview_size = preview.size
	_editor_preview_position_pending = false

func _get_or_create_tooltip() -> Control:
	if _tooltip_instance and is_instance_valid(_tooltip_instance):
		return _tooltip_instance
		
	if source_type == SourceType.PACKED_SCENE and tooltip_scene:
		_tooltip_instance = tooltip_scene.instantiate() as Control
	elif source_type == SourceType.EXISTING_NODE and not tooltip_node_path.is_empty():
		var node = get_node_or_null(tooltip_node_path)
		if node is Control:
			_tooltip_instance = node
			if _tooltip_instance.get_parent():
				_tooltip_instance.get_parent().remove_child(_tooltip_instance)
				
	if _tooltip_instance:
		_shared_canvas_layer.add_child(_tooltip_instance)
		_tooltip_instance.hide()
		_tooltip_instance.mouse_entered.connect(_on_tooltip_mouse_entered)
		_tooltip_instance.mouse_exited.connect(_on_tooltip_mouse_exited)
			
	return _tooltip_instance

func _get_effective_data() -> Dictionary:
	var data = custom_data.duplicate()
	if not tooltip_text.is_empty():
		data["text"] = tooltip_text
	data["anchor"] = anchor
	return data

func _get_pivot_ratio_for_anchor(p_anchor: Anchor) -> Vector2:
	match p_anchor:
		Anchor.TOP: return Vector2(0.5, 1.0)
		Anchor.BOTTOM: return Vector2(0.5, 0.0)
		Anchor.LEFT: return Vector2(1.0, 0.5)
		Anchor.RIGHT: return Vector2(0.0, 0.5)
		Anchor.TOP_LEFT: return Vector2(1.0, 1.0)
		Anchor.TOP_RIGHT: return Vector2(0.0, 1.0)
		Anchor.BOTTOM_LEFT: return Vector2(1.0, 0.0)
		Anchor.BOTTOM_RIGHT: return Vector2(0.0, 0.0)
		Anchor.CENTER: return Vector2(0.5, 0.5)
		_: return Vector2.ZERO

func _show_tooltip() -> void:
	var effective_data = _get_effective_data()
	
	if tooltip_scope == TooltipScope.GLOBAL:
		MindTooltipManager.show_global_tooltip(_parent_control, tooltip_scene, effective_data, anchor, anchor_offset, position_mode, fixed_position, mouse_offset, clamp_to_screen, screen_padding, overflow_behavior, hide_on_mouse_exit)
	else:
		var tip_node = _get_or_create_tooltip()
		if not tip_node:
			return
		tip_node.pivot_offset_ratio = _get_pivot_ratio_for_anchor(anchor)
		
		if tip_node.has_method("tip"):
			tip_node.call("tip", effective_data)
		elif tip_node.has_method("_setup_tooltip"):
			tip_node.call("_setup_tooltip", effective_data)
			tip_node.show()
		else:
			tip_node.show()
		tip_node.reset_size()
		tip_node.pivot_offset_ratio = _get_pivot_ratio_for_anchor(anchor)
		_last_tooltip_size = tip_node.size
		_position_generation += 1
		call_deferred("_position_local_tooltip_after_layout", tip_node, _position_generation)

func _position_local_tooltip_after_layout(tip_node: Control, generation: int) -> void:
	await get_tree().process_frame
	if generation != _position_generation or not is_instance_valid(tip_node) or tip_node != _tooltip_instance or not tip_node.visible:
		return
	tip_node.reset_size()
	tip_node.pivot_offset_ratio = _get_pivot_ratio_for_anchor(anchor)
	_last_tooltip_size = tip_node.size
	_update_tooltip_position()

func _hide_tooltip() -> void:
	if tooltip_scope == TooltipScope.GLOBAL:
		MindTooltipManager.hide_global_tooltip(_parent_control)
	else:
		_position_generation += 1
		if _tooltip_instance and is_instance_valid(_tooltip_instance):
			if _tooltip_instance.has_method("untip"):
				_tooltip_instance.call("untip")
			else:
				_tooltip_instance.hide()

func _calculate_position(tip_node: Control, editor_preview: bool = false) -> Vector2:
	var viewport = get_viewport()
	var tip_size = tip_node.size
	var target_rect = Rect2()
	var current_mode = position_mode
	var current_anchor = anchor
	if editor_preview and current_mode in [PositionMode.FIXED_OFFSET_FROM_MOUSE, PositionMode.FOLLOW_MOUSE_REALTIME]:
		current_mode = PositionMode.RELATIVE_TO_PARENT
	
	match current_mode:
		PositionMode.FIXED_OFFSET_FROM_MOUSE, PositionMode.FOLLOW_MOUSE_REALTIME:
			var mouse_pos = viewport.get_mouse_position()
			target_rect = Rect2(mouse_pos + mouse_offset, Vector2.ZERO)
		PositionMode.FIXED_SCREEN_POSITION:
			target_rect = Rect2(fixed_position, Vector2.ZERO)
		PositionMode.RELATIVE_TO_PARENT:
			if _parent_control and is_instance_valid(_parent_control):
				target_rect = _parent_control.get_global_rect()
		PositionMode.CUSTOM:
			return tip_node.global_position
			
	var final_pos = Vector2.ZERO
	var offset = anchor_offset if current_mode == PositionMode.RELATIVE_TO_PARENT else Vector2.ZERO
	if current_anchor == Anchor.CUSTOM:
		final_pos = target_rect.position + offset
	else:
		var tooltip_pivot = _get_pivot_ratio_for_anchor(current_anchor)
		var target_anchor = Vector2.ONE - tooltip_pivot
		final_pos = target_rect.position + target_rect.size * target_anchor - tip_size * tooltip_pivot
		final_pos += offset * _get_offset_sign(current_anchor)
			
	if clamp_to_screen and current_mode != PositionMode.CUSTOM and not Engine.is_editor_hint():
		var screen_size = viewport.get_visible_rect().size
		if overflow_behavior == OverflowBehavior.FLIP_AROUND_MOUSE and (position_mode == PositionMode.FIXED_OFFSET_FROM_MOUSE or position_mode == PositionMode.FOLLOW_MOUSE_REALTIME):
			var mouse_pos = viewport.get_mouse_position()
			if final_pos.x + tip_size.x > screen_size.x - screen_padding.x:
				final_pos.x = mouse_pos.x - tip_size.x - mouse_offset.x
			if final_pos.y + tip_size.y > screen_size.y - screen_padding.y:
				final_pos.y = mouse_pos.y - tip_size.y - mouse_offset.y
				
		final_pos.x = clamp(final_pos.x, screen_padding.x, max(screen_padding.x, screen_size.x - tip_size.x - screen_padding.x))
		final_pos.y = clamp(final_pos.y, screen_padding.y, max(screen_padding.y, screen_size.y - tip_size.y - screen_padding.y))
		
	return final_pos

func _get_offset_sign(p_anchor: Anchor) -> Vector2:
	match p_anchor:
		Anchor.TOP: return Vector2(1.0, -1.0)
		Anchor.BOTTOM: return Vector2(1.0, 1.0)
		Anchor.LEFT: return Vector2(-1.0, 1.0)
		Anchor.RIGHT: return Vector2(1.0, 1.0)
		Anchor.TOP_LEFT: return Vector2(-1.0, -1.0)
		Anchor.TOP_RIGHT: return Vector2(1.0, -1.0)
		Anchor.BOTTOM_LEFT: return Vector2(-1.0, 1.0)
		_: return Vector2(1.0, 1.0)

func _update_tooltip_position() -> void:
	if not _tooltip_instance or position_mode == PositionMode.CUSTOM:
		return
	_tooltip_instance.global_position = _calculate_position(_tooltip_instance) + _tooltip_instance.size * _tooltip_instance.pivot_offset_ratio
	if position_mode == PositionMode.RELATIVE_TO_PARENT and is_instance_valid(_parent_control):
		_last_parent_rect = _parent_control.get_global_rect()

func _on_content_changed() -> void:
	if Engine.is_editor_hint():
		if preview_in_editor:
			_queue_editor_preview_update()
		return
	if _is_hovered:
		var effective_data = _get_effective_data()
		if tooltip_scope == TooltipScope.GLOBAL:
			MindTooltipManager.update_global_tooltip(_parent_control, effective_data)
		else:
			if _tooltip_instance and _tooltip_instance.visible:
				if _tooltip_instance.has_method("utip"):
					_tooltip_instance.call("utip", effective_data)
				elif _tooltip_instance.has_method("tip"):
					_tooltip_instance.call("tip", effective_data)
				_last_tooltip_size = _tooltip_instance.size
				_update_tooltip_position()

func _on_position_settings_changed() -> void:
	if Engine.is_editor_hint():
		if preview_in_editor:
			_queue_editor_preview_update()
		return
	if _is_hovered:
		if tooltip_scope == TooltipScope.GLOBAL:
			MindTooltipManager.show_global_tooltip(_parent_control, tooltip_scene, _get_effective_data(), anchor, anchor_offset, position_mode, fixed_position, mouse_offset, clamp_to_screen, screen_padding, overflow_behavior, hide_on_mouse_exit)
		else:
			if _tooltip_instance and _tooltip_instance.visible:
				_tooltip_instance.pivot_offset_ratio = _get_pivot_ratio_for_anchor(anchor)
				var effective_data = _get_effective_data()
				if _tooltip_instance.has_method("utip"):
					_tooltip_instance.call("utip", effective_data)
				elif _tooltip_instance.has_method("tip"):
					_tooltip_instance.call("tip", effective_data)
				_update_tooltip_position()

func update_custom_data(new_data: Dictionary) -> void:
	custom_data = new_data

func update_tooltip_text(new_text: String) -> void:
	tooltip_text = new_text

func _exit_tree() -> void:
	_position_generation += 1
	_editor_preview_generation += 1
	if source_type == SourceType.PACKED_SCENE and _tooltip_instance and is_instance_valid(_tooltip_instance):
		_tooltip_instance.queue_free()
	if is_instance_valid(_editor_preview_instance):
		_editor_preview_instance.hide()
		_editor_preview_instance.queue_free()
	_editor_preview_instance = null

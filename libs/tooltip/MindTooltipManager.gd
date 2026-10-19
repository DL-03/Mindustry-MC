extends Node

var _shared_canvas_layer: CanvasLayer
# Словарь кеша: PackedScene -> Экземпляр тултипа
var _instances: Dictionary = {} 

var _current_active_instance: Control = null
var _current_target: Control = null
var _current_parent: Control = null
var _current_anchor: int = 0
var _current_offset: Vector2 = Vector2.ZERO
var _current_position_mode: int = 0
var _current_fixed_position: Vector2 = Vector2.ZERO
var _current_mouse_offset: Vector2 = Vector2.ZERO
var _current_clamp_to_screen: bool = true
var _current_hide_on_mouse_exit: bool = true
var _current_screen_padding: Vector2 = Vector2.ZERO
var _current_overflow_behavior: int = 0
var _last_size: Vector2 = Vector2.ZERO
var _last_parent_rect: Rect2 = Rect2()
var _show_generation: int = 0
var _hide_generation: int = 0

func _ready() -> void:
	_shared_canvas_layer = CanvasLayer.new()
	_shared_canvas_layer.layer = 128
	get_tree().root.call_deferred("add_child", _shared_canvas_layer)

func _process(_delta: float) -> void:
	if not is_instance_valid(_current_target) and not is_instance_valid(_current_parent) and is_instance_valid(_current_active_instance):
		_clear_active_tooltip()
		return
	if not _current_active_instance or not is_instance_valid(_current_active_instance) or not _current_active_instance.visible:
		return
		
	# Динамически отслеживаем изменение размера (например, при переносе текста на новую строку)
	var current_size = _current_active_instance.size
	if current_size != _last_size:
		_last_size = current_size
		_update_position()
		
	if _current_position_mode == 1: # FOLLOW_MOUSE_REALTIME
		_update_position()
	elif _current_position_mode == 3 and is_instance_valid(_current_parent):
		var parent_rect = _current_parent.get_global_rect()
		if parent_rect != _last_parent_rect:
			_update_position()

func _clear_active_tooltip() -> void:
	_show_generation += 1
	_hide_generation += 1
	var instance = _current_active_instance
	_current_active_instance = null
	_current_target = null
	_current_parent = null
	if is_instance_valid(instance):
		_hide_instance(instance, true)

func show_global_tooltip(parent: Control, scene: PackedScene, data: Dictionary, anchor: int, offset: Vector2, mode: int, fixed_position: Vector2 = Vector2.ZERO, mouse_offset: Vector2 = Vector2.ZERO, clamp_to_screen: bool = true, screen_padding: Vector2 = Vector2.ZERO, overflow_behavior: int = 0, hide_on_mouse_exit: bool = true) -> void:
	if not data:
		return
	if not "text" in data:
		return
	if data.text == "":
		return
	
	if not scene or not is_instance_valid(parent):
		return
	var previous_instance = _current_active_instance
	# Получаем или создаем инстанс конкретно для ЭТОЙ сцены тултипа
	var instance = _get_or_create_instance(scene)
	if not instance:
		return
	_hide_generation += 1
	if is_instance_valid(previous_instance) and previous_instance != instance:
		_hide_instance(previous_instance, true)

	_current_target = parent
	_current_parent = parent
	_current_anchor = anchor
	_current_offset = offset
	_current_position_mode = mode
	_current_fixed_position = fixed_position
	_current_mouse_offset = mouse_offset
	_current_clamp_to_screen = clamp_to_screen
	_current_hide_on_mouse_exit = hide_on_mouse_exit
	_current_screen_padding = screen_padding
	_current_overflow_behavior = overflow_behavior
	_current_active_instance = instance
	
	# Делаем видимым, чтобы движок смог рассчитать минимальный размер текста
	instance.show()
	# Передаем данные в метод tip() префаба
	if instance.has_method("tip"):
		instance.call("tip", data)
	elif instance.has_method("_setup_tooltip"):
		instance.call("_setup_tooltip", data)
	instance.reset_size()
	instance.pivot_offset_ratio = _get_pivot_ratio(anchor)
	_last_size = instance.size
	_show_generation += 1
	_update_position()
	call_deferred("_position_after_layout", instance, _show_generation)

func _position_after_layout(instance: Control, generation: int) -> void:
	await get_tree().process_frame
	if generation != _show_generation or instance != _current_active_instance or not is_instance_valid(instance):
		return
	instance.reset_size()
	instance.pivot_offset_ratio = _get_pivot_ratio(_current_anchor)
	_last_size = instance.size
	_update_position()

func hide_global_tooltip(parent: Variant = null) -> void:
	if parent != null:
		if not is_instance_valid(parent) or parent != _current_target:
			return
	_hide_generation += 1
	call_deferred("_hide_global_tooltip_if_pointer_left", parent, _hide_generation)

func _hide_global_tooltip_if_pointer_left(parent: Variant, generation: int) -> void:
	await get_tree().process_frame
	if generation != _hide_generation:
		return
	if parent != null and (not is_instance_valid(parent) or _current_target != parent):
		return
	var hovered_control = get_viewport().gui_get_hovered_control()
	if _is_control_or_descendant(_current_parent, hovered_control) or _is_control_or_descendant(_current_active_instance, hovered_control):
		return
	_show_generation += 1
	_current_target = null
	_current_parent = null
	var instance = _current_active_instance
	_current_active_instance = null
	if is_instance_valid(instance):
		_hide_instance(instance)

func _hide_instance(instance: Control, immediate: bool = false) -> void:
	if instance.has_method("untip"):
		instance.call("untip")
	else:
		instance.hide()
	if immediate:
		instance.hide()

func _is_control_or_descendant(control: Variant, hovered_control: Variant) -> bool:
	return is_instance_valid(control) and is_instance_valid(hovered_control) and (control == hovered_control or control.is_ancestor_of(hovered_control))

func _on_tooltip_mouse_entered(instance: Control) -> void:
	if instance == _current_active_instance:
		_hide_generation += 1

func _on_tooltip_mouse_exited(instance: Control) -> void:
	if _current_hide_on_mouse_exit and instance == _current_active_instance:
		if is_instance_valid(_current_target):
			hide_global_tooltip(_current_target)

func update_global_tooltip(parent: Control, data: Dictionary) -> void:
	if _current_target == parent and _current_active_instance and is_instance_valid(_current_active_instance):
		if _current_active_instance.has_method("utip"):
			_current_active_instance.call("utip", data)
		elif _current_active_instance.has_method("tip"):
			_current_active_instance.call("tip", data)
		_current_active_instance.reset_size()
		_last_size = _current_active_instance.size
		_update_position()

func _get_or_create_instance(scene: PackedScene) -> Control:
	if _instances.has(scene) and is_instance_valid(_instances[scene]):
		return _instances[scene]
		
	var new_instance = scene.instantiate() as Control
	if not new_instance:
		push_warning("MindTooltipManager: Tooltip scene root must be a Control.")
		return null
	_shared_canvas_layer.add_child(new_instance)
	new_instance.hide()
	new_instance.mouse_entered.connect(_on_tooltip_mouse_entered.bind(new_instance))
	new_instance.mouse_exited.connect(_on_tooltip_mouse_exited.bind(new_instance))
	_instances[scene] = new_instance
	return new_instance

func _get_pivot_ratio(anchor: int) -> Vector2:
	match anchor:
		0: return Vector2(0.5, 1.0)
		1: return Vector2(0.5, 0.0)
		2: return Vector2(1.0, 0.5)
		3: return Vector2(0.0, 0.5)
		4: return Vector2(1.0, 1.0)
		5: return Vector2(0.0, 1.0)
		6: return Vector2(1.0, 0.0)
		7: return Vector2(0.0, 0.0)
		8: return Vector2(0.5, 0.5)
		_: return Vector2.ZERO

func _update_position() -> void:
	if not _current_active_instance or not is_instance_valid(_current_active_instance):
		return
	if _current_position_mode == 4: # CUSTOM
		return
	if _current_position_mode == 3 and (not _current_parent or not is_instance_valid(_current_parent)):
		return

	var viewport = get_viewport()
	var tip_size = _current_active_instance.size
	var target_rect = Rect2()
	match _current_position_mode:
		0, 1: # FIXED_OFFSET_FROM_MOUSE, FOLLOW_MOUSE_REALTIME
			target_rect = Rect2(viewport.get_mouse_position() + _current_mouse_offset, Vector2.ZERO)
		2: # FIXED_SCREEN_POSITION
			target_rect = Rect2(_current_fixed_position, Vector2.ZERO)
		3: # RELATIVE_TO_PARENT
			target_rect = _current_parent.get_global_rect()

	var offset = _current_offset if _current_position_mode == 3 else Vector2.ZERO
	var final_pos = Vector2.ZERO
	var tooltip_pivot = _get_pivot_ratio(_current_anchor)
	if _current_anchor == 9: # CUSTOM
		final_pos = target_rect.position + offset
	else:
		var target_anchor = Vector2.ONE - tooltip_pivot
		final_pos = target_rect.position + target_rect.size * target_anchor - tip_size * tooltip_pivot
		final_pos += offset * _get_offset_sign(_current_anchor)

	if _current_clamp_to_screen:
		var screen_size = viewport.get_visible_rect().size
		if _current_overflow_behavior == 1 and _current_position_mode < 2:
			var mouse_pos = viewport.get_mouse_position()
			if final_pos.x + tip_size.x > screen_size.x - _current_screen_padding.x:
				final_pos.x = mouse_pos.x - tip_size.x - _current_mouse_offset.x
			if final_pos.y + tip_size.y > screen_size.y - _current_screen_padding.y:
				final_pos.y = mouse_pos.y - tip_size.y - _current_mouse_offset.y
		final_pos.x = clamp(final_pos.x, _current_screen_padding.x, max(_current_screen_padding.x, screen_size.x - tip_size.x - _current_screen_padding.x))
		final_pos.y = clamp(final_pos.y, _current_screen_padding.y, max(_current_screen_padding.y, screen_size.y - tip_size.y - _current_screen_padding.y))

	_current_active_instance.global_position = final_pos + tip_size * tooltip_pivot
	if _current_position_mode == 3 and is_instance_valid(_current_parent):
		_last_parent_rect = _current_parent.get_global_rect()

func _get_offset_sign(anchor: int) -> Vector2:
	match anchor:
		0: return Vector2(1.0, -1.0)
		1: return Vector2(1.0, 1.0)
		2: return Vector2(-1.0, 1.0)
		3: return Vector2(1.0, 1.0)
		4: return Vector2(-1.0, -1.0)
		5: return Vector2(1.0, -1.0)
		6: return Vector2(-1.0, 1.0)
		_: return Vector2(1.0, 1.0)

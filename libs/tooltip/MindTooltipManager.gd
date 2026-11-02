extends Node

var _shared_canvas_layer: CanvasLayer
var _instances: Dictionary = {}
var _active_tooltips: Dictionary = {}
var _show_generation: int = 0

func _ready() -> void:
	_shared_canvas_layer = CanvasLayer.new()
	_shared_canvas_layer.layer = 128
	get_tree().root.call_deferred("add_child", _shared_canvas_layer)

func _process(_delta: float) -> void:
	for scene in _active_tooltips.keys():
		var state: Dictionary = _active_tooltips[scene]
		var parent: Variant = state.get("parent")
		var instance: Variant = state.get("instance")
		if not is_instance_valid(instance):
			_active_tooltips.erase(scene)
			_instances.erase(scene)
			continue
		if not is_instance_valid(parent):
			_active_tooltips.erase(scene)
			_hide_instance(instance as Control, true)
			continue
		if not instance.visible:
			continue

		if instance.size != state.last_size or (state.position_mode == 3 and parent.get_global_rect() != state.last_parent_rect):
			_update_position(state)
		elif state.position_mode == 1:
			_update_position(state)

func show_global_tooltip(parent: Control, scene: PackedScene, data: Dictionary, anchor: int, offset: Vector2, mode: int, fixed_position: Vector2 = Vector2.ZERO, mouse_offset: Vector2 = Vector2.ZERO, clamp_to_screen: bool = true, screen_padding: Vector2 = Vector2.ZERO, overflow_behavior: int = 0, hide_on_mouse_exit: bool = true, hide_delay: float = 0.0, before_show: Callable = Callable(), allow_empty_text: bool = false) -> Control:
	if not allow_empty_text and (not data.has("text") or data["text"] == ""):
		return null
	if not scene or not is_instance_valid(parent):
		return null

	var instance := _get_or_create_instance(scene)
	if not is_instance_valid(instance):
		return null
	var previous_state: Dictionary = _active_tooltips.get(scene, {})
	var previous_parent: Variant = previous_state.get("parent")
	var is_new_tooltip: bool = previous_parent != parent or not instance.visible
	var state := {
		"parent": parent,
		"instance": instance,
		"anchor": anchor,
		"offset": offset,
		"position_mode": mode,
		"fixed_position": fixed_position,
		"mouse_offset": mouse_offset,
		"clamp_to_screen": clamp_to_screen,
		"hide_on_mouse_exit": hide_on_mouse_exit,
		"hide_delay": hide_delay,
		"screen_padding": screen_padding,
		"overflow_behavior": overflow_behavior,
		"last_size": instance.size,
		"last_parent_rect": parent.get_global_rect(),
		"show_generation": _show_generation + 1,
		"hide_generation": int(previous_state.get("hide_generation", 0)) + 1
	}
	_show_generation += 1
	_active_tooltips[scene] = state
	var parent_exit_callable := Callable(self, "_on_parent_tree_exiting").bind(scene, parent, instance)
	if not parent.tree_exiting.is_connected(parent_exit_callable):
		parent.tree_exiting.connect(parent_exit_callable)

	if is_new_tooltip and before_show.is_valid():
		before_show.call(instance)

	instance.show()
	if instance.has_method("tip"):
		instance.call("tip", data)
	elif instance.has_method("_setup_tooltip"):
		instance.call("_setup_tooltip", data)
	instance.reset_size()
	instance.pivot_offset_ratio = _get_pivot_ratio(anchor)
	state.last_size = instance.size
	if is_new_tooltip:
		_bring_to_front(instance)
	_update_position(state)
	call_deferred("_position_after_layout", scene, instance, state.show_generation)
	return instance

func _on_parent_tree_exiting(scene: PackedScene, parent: Control, instance: Control) -> void:
	if not _active_tooltips.has(scene):
		return
	var state: Dictionary = _active_tooltips[scene]
	if state.get("parent") != parent or state.get("instance") != instance:
		return
	_active_tooltips.erase(scene)
	if is_instance_valid(instance):
		_hide_instance(instance, true)

func _position_after_layout(scene: PackedScene, instance: Control, generation: int) -> void:
	await get_tree().process_frame
	if not _active_tooltips.has(scene):
		return
	var state: Dictionary = _active_tooltips[scene]
	if generation != state.show_generation or instance != state.instance or not is_instance_valid(instance):
		return
	instance.reset_size()
	instance.pivot_offset_ratio = _get_pivot_ratio(state.anchor)
	state.last_size = instance.size
	_update_position(state)

func hide_global_tooltip(parent: Variant = null, delay: float = -1.0, force: bool = false) -> void:
	for scene in _active_tooltips.keys():
		var state: Dictionary = _active_tooltips[scene]
		if parent == null or state.parent == parent:
			_schedule_hide(scene, delay, force)

func _schedule_hide(scene: PackedScene, delay: float, force: bool) -> void:
	if not _active_tooltips.has(scene):
		return
	var state: Dictionary = _active_tooltips[scene]
	state.hide_generation += 1
	var hide_delay: float = state.hide_delay if delay < 0 else delay
	call_deferred("_hide_tooltip_if_pointer_left", scene, state.instance, state.hide_generation, hide_delay, force)

func _hide_tooltip_if_pointer_left(scene: PackedScene, instance: Control, generation: int, delay: float, force: bool) -> void:
	await get_tree().process_frame
	if not _active_tooltips.has(scene):
		return
	var state: Dictionary = _active_tooltips[scene]
	if state.instance != instance or generation != state.hide_generation:
		return
	if delay > 0:
		await get_tree().create_timer(delay).timeout
		if not _active_tooltips.has(scene):
			return
		state = _active_tooltips[scene]
		if state.instance != instance or generation != state.hide_generation:
			return
	if not force:
		var hovered_control = get_viewport().gui_get_hovered_control()
		if _is_control_or_descendant(state.parent, hovered_control) or _is_control_or_descendant(instance, hovered_control):
			return
	if is_instance_valid(instance):
		_hide_instance(instance)

func is_global_tooltip_visible(parent: Control) -> bool:
	for state in _active_tooltips.values():
		if state.parent == parent and is_instance_valid(state.instance) and state.instance.visible:
			return true
	return false

func is_global_tooltip_at_position(parent: Control, position: Vector2) -> bool:
	for state in _active_tooltips.values():
		if state.parent == parent and is_instance_valid(state.instance) and state.instance.visible and state.instance.get_global_rect().has_point(position):
			return true
	return false

func _hide_instance(instance: Control, immediate: bool = false) -> void:
	if instance.has_method("untip"):
		instance.call("untip")
	else:
		instance.hide()
	if immediate:
		instance.hide()

func _is_control_or_descendant(control: Variant, hovered_control: Variant) -> bool:
	return is_instance_valid(control) and is_instance_valid(hovered_control) and (control == hovered_control or control.is_ancestor_of(hovered_control))

func _get_state_for_instance(instance: Control) -> Dictionary:
	for state in _active_tooltips.values():
		if state.instance == instance:
			return state
	return {}

func _on_tooltip_mouse_entered(instance: Control) -> void:
	var state := _get_state_for_instance(instance)
	if not state.is_empty():
		state.hide_generation += 1

func _on_tooltip_mouse_exited(instance: Control) -> void:
	var state := _get_state_for_instance(instance)
	if not state.is_empty() and state.hide_on_mouse_exit and is_instance_valid(state.parent):
		hide_global_tooltip(state.parent, state.hide_delay)

func update_global_tooltip(parent: Control, data: Dictionary) -> void:
	for state in _active_tooltips.values():
		if state.parent != parent or not is_instance_valid(state.instance) or not state.instance.visible:
			continue
		var instance: Control = state.instance
		if instance.has_method("utip"):
			instance.call("utip", data)
		elif instance.has_method("tip"):
			instance.call("tip", data)
		instance.reset_size()
		state.last_size = instance.size
		_update_position(state)
		return

func _get_or_create_instance(scene: PackedScene) -> Control:
	if _instances.has(scene) and is_instance_valid(_instances[scene]):
		return _instances[scene]

	var new_instance := scene.instantiate() as Control
	if not is_instance_valid(new_instance):
		push_warning("MindTooltipManager: Tooltip scene root must be a Control.")
		return null
	_shared_canvas_layer.add_child(new_instance)
	new_instance.hide()
	new_instance.mouse_entered.connect(_on_tooltip_mouse_entered.bind(new_instance))
	new_instance.mouse_exited.connect(_on_tooltip_mouse_exited.bind(new_instance))
	_instances[scene] = new_instance
	return new_instance

func _bring_to_front(instance: Control) -> void:
	var highest_z_index := instance.z_index
	for sibling in _shared_canvas_layer.get_children():
		if sibling is Control and sibling != instance:
			highest_z_index = maxi(highest_z_index, sibling.z_index)
	instance.z_index = highest_z_index
	instance.move_to_front()

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

func _update_position(state: Dictionary) -> void:
	var instance: Variant = state.get("instance")
	var parent: Variant = state.get("parent")
	if not is_instance_valid(instance) or not is_instance_valid(parent):
		return
	var position_mode: int = state.position_mode
	if position_mode == 4:
		return

	var viewport = get_viewport()
	var tip_size = instance.size
	var target_rect = Rect2()
	match position_mode:
		0, 1:
			target_rect = Rect2(viewport.get_mouse_position() + state.mouse_offset, Vector2.ZERO)
		2:
			target_rect = Rect2(state.fixed_position, Vector2.ZERO)
		3:
			target_rect = parent.get_global_rect()

	var offset: Vector2 = state.offset if position_mode == 3 else Vector2.ZERO
	var tooltip_pivot = _get_pivot_ratio(state.anchor)
	var final_pos = Vector2.ZERO
	if state.anchor == 9:
		final_pos = target_rect.position + offset
	else:
		var target_anchor = Vector2.ONE - tooltip_pivot
		final_pos = target_rect.position + target_rect.size * target_anchor - tip_size * tooltip_pivot
		final_pos += offset * _get_offset_sign(state.anchor)

	if state.clamp_to_screen:
		var screen_size = viewport.get_visible_rect().size
		if state.overflow_behavior == 1 and position_mode < 2:
			var mouse_pos = viewport.get_mouse_position()
			if final_pos.x + tip_size.x > screen_size.x - state.screen_padding.x:
				final_pos.x = mouse_pos.x - tip_size.x - state.mouse_offset.x
			if final_pos.y + tip_size.y > screen_size.y - state.screen_padding.y:
				final_pos.y = mouse_pos.y - tip_size.y - state.mouse_offset.y
		var padding: Vector2 = state.screen_padding
		final_pos.x = clamp(final_pos.x, padding.x, max(padding.x, screen_size.x - tip_size.x - padding.x))
		final_pos.y = clamp(final_pos.y, padding.y, max(padding.y, screen_size.y - tip_size.y - padding.y))

	instance.global_position = final_pos + tip_size * tooltip_pivot
	state.last_size = instance.size
	if position_mode == 3:
		state.last_parent_rect = parent.get_global_rect()

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

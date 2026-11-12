@tool
extends HBoxContainer
class_name MindNotification

@export_group("Nodes")
@export var animationPlayer: AnimationPlayer
@export var label: MindRTL
@export var closeElement: Button
@export var timer: Timer

@export_group("Content")
@export_multiline var text: String = "":
	set = _set_text

var _close_pressed := 0

func _set_text(value: String) -> void:
	text = value
	if is_instance_valid(label):
		label.real_text = text

func _ready() -> void:
	if is_instance_valid(label):
		label.real_text = text
	if not Engine.is_editor_hint() and is_instance_valid(animationPlayer):
		animationPlayer.play("show")

func _on_mind_button_pressed() -> void:
	if _close_pressed > 0:
		queue_free()
	elif is_instance_valid(animationPlayer):
		animationPlayer.play("hide")
	_close_pressed += 1

func _on_timer_timeout() -> void:
	if is_instance_valid(animationPlayer):
		animationPlayer.play("hide")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "hide":
		queue_free()
	elif anim_name == "show" and is_instance_valid(label):
		label.scroll_active = true

func _on_animation_player_animation_started(anim_name: StringName) -> void:
	if anim_name == "hide":
		if is_instance_valid(timer):
			timer.stop()
		if is_instance_valid(label):
			label.scroll_active = false

extends HBoxContainer

@export var animationPlayer: AnimationPlayer
@export var label: MindRTL
@export var closeElement: Button
@export var timer: Timer
@export var text = "":
	set = _set_text

var _close_pressed = 0

func _set_text(v):
	text = v
	label.real_text = text

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.real_text = text
	animationPlayer.play("show")

func _on_mind_button_pressed() -> void:
	if _close_pressed > 0:
		queue_free()
	else:
		animationPlayer.play("hide")
	_close_pressed += 1

func _on_timer_timeout() -> void:
	animationPlayer.play("hide")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "hide":
		queue_free()
	if anim_name == "show":
		label.scroll_active = true


func _on_animation_player_animation_started(anim_name: StringName) -> void:
	if anim_name == "hide":
		timer.stop()
		label.scroll_active = false

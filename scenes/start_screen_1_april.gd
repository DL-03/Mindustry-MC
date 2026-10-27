extends Control

var p = preload("res://resources/icons/OIP (2).jpg")

# Called when the node enters the scene tree for the first time.
func _ready():
	$TextureRect.texture = p
	$TextureRect/AnimationPlayer.play("new_animation")
	
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#$VideoStreamPlayer.size = size
	$TextureRect.position = size/2


func _on_animation_player_animation_finished(anim_name):
	$VideoStreamPlayer.paused = false


func _on_video_stream_player_finished():
	$VideoStreamPlayer2.paused = false


func _on_video_stream_player_2_finished():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

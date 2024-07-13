extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	get_window().size = Vector2(512,512)
	get_window().borderless = true	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

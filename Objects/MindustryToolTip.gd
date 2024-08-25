extends Control






func tip(text = "", pos = Vector2.ZERO):
	
	
	$MindustryToolTip.real_text = text
	$MindustryToolTip.size = Vector2.ZERO
	
	$MindustryToolTip.position.x = min(0,$/root/Main.size.x-($MindustryToolTip.size.x+pos.x))
	$MindustryToolTip.position.y = min(0,$/root/Main.size.y-($MindustryToolTip.size.y+pos.y))
	
	
	
	position = pos
	$AnimationPlayer.play("show")
	
	
func untip():
	$AnimationPlayer.play("hide")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

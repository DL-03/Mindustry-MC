extends Panel


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_close_pressed():
	hide()


func _on_button_2_pressed():
	show()


func _on_github_pressed():
	OS.shell_open("https://github.com/DL-03/")


func _on_discord_pressed():
	OS.shell_open("https://discord.gg/MCdqTUQAFH")

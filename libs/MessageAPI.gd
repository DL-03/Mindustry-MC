extends Node


@onready var MessagePanel = $/root/Main/MessagePanel





func info(text):
	MessagePanel.SummonMessage(text,0)
func debug(text):
	MessagePanel.SummonMessage(text,1)
func error(text):
	MessagePanel.SummonMessage(text,2)

func SummonMessage(text="",_type=0):
	MessagePanel.SummonMessage(text,_type)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

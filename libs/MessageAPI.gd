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
	
var timer = Timer.new()



func on_updated_settings():
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings" in SaveDataAPI.data:
			if "saveMessageFrequency" in SaveDataAPI.data["Settings"]:
				timer.wait_time = SaveDataAPI.data["Settings"]["saveMessageFrequency"]
				timer.stop()
				timer.start()
	

# Called when the node enters the scene tree for the first time.
func _ready():
	SaveDataAPI.data_changed.connect(func():
		on_updated_settings()
	)
	on_updated_settings()
	
	
	
	
	timer.wait_time = 60
	timer.timeout.connect(func():
		#RequestLanguages.request("https://github.com/DL-03/Mindustry-MC-Upgrade-Files/tree/main/Languages")
		info("|Message.dont_forget_to_save|")
		#timer.start()
		
		)
	timer.autostart = true
	
	add_child(timer)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

extends Node


signal data_loaded


var defaultData = {
	"Settings": {
		"Language": 0,
		"AutoOpenModeMindustry": false,
		"contentFileMomentalWarningYes": false,
		"saveMessageFrequency": 60
	}
}
var data = {}


func save_data():
	var s = FileAccess.open("user://saveData.json", FileAccess.WRITE)
	s.store_string(str(data))
	s.close()

func load_data():
	if not FileAccess.file_exists("user://saveData.json"):
		var s = FileAccess.open("user://saveData.json", FileAccess.WRITE)
		s.store_string(str(defaultData))
		data = defaultData
		s.close()
	else:
		var s = FileAccess.open("user://saveData.json", FileAccess.READ)
		data = defaultData
		data.merge(JSON.parse_string(s.get_as_text()), true)
		s.close()
	data_loaded.emit()


# Called when the node enters the scene tree for the first time.
func _ready():
	load_data()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

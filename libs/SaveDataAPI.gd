@tool
extends Node


signal data_loaded
signal data_changed

var defaultData = {
	"Settings.Language": "en",
	"Settings.AutoOpenSettings": true,
	"Settings.TimeForDelete": 5,
	"Settings.MomentalDelete": false,
	"Settings.SaveMessageFrequency": 60,
	"Settings.HorizontalTabsInMainWindow": false,
	"Settings.Debug": false
}
var data = {}


func save_data():
	var s = FileAccess.open("user://saveData.json", FileAccess.WRITE)
	s.store_string(JSON.stringify(data))
	s.close()
	data_changed.emit()

func load_data():
	if not FileAccess.file_exists("user://saveData.json"):
		var s = FileAccess.open("user://saveData.json", FileAccess.WRITE)
		s.store_string(JSON.stringify(data))
		data = defaultData.duplicate(true)
		s.close()
	else:
		var s = FileAccess.open("user://saveData.json", FileAccess.READ)
		data = JSON.parse_string(s.get_as_text())
		data.merge(defaultData)
		s.close()
	data_loaded.emit()
	data_changed.emit()


# Called when the node enters the scene tree for the first time.
func _ready():
	load_data()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

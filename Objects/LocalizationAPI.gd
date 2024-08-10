@tool
extends Node



var LanguageDict = preload("res://resources/LanguageDict.json").data



signal change_current_language

#11
var language_list = [
	"en",
	"ru"
]

var current_language = 0:
	set = set_current_language

func set_current_language(value):
	current_language = value
	
	change_current_language.emit()
	SaveDataAPI.data["Settings"]["Language"] = value
	SaveDataAPI.save_data()
	







# Called when the node enters the scene tree for the first time.
func _ready():
	SaveDataAPI.data_loaded.connect(func():
		current_language = SaveDataAPI.data["Settings"]["Language"]
		)
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

extends Panel

@export var tabsDict: Dictionary[Node, Node] = {}

@export var DebugButton: Button

func on_loaded_settings():
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings.AutoOpenSettings" in SaveDataAPI.data:
			visible = SaveDataAPI.data["Settings.AutoOpenSettings"]

func _ready() -> void:
	SaveDataAPI.data_loaded.connect(on_loaded_settings)
	on_loaded_settings()
	
	for _tab in tabsDict.keys():
		_tab.pressed.connect(set_tab.bind(_tab))
		
		_tab.disabled = false
		if _tab in tabsDict:
			tabsDict[_tab].hide()
	
	set_tab(tabsDict.keys()[0])

var current_tab = null
func set_tab(_tab: Node) -> void:
	if current_tab:
		tabsDict[current_tab].hide()
		current_tab.disabled = false
	
	current_tab = _tab
	
	tabsDict[_tab].show()
	_tab.disabled = true

func _on_close_pressed():
	hide()

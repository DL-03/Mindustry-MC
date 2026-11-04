extends VBoxContainer

var DebugTab: Button

@export var PerSaveMessageParam: Node
@export var AutoOpenSettings: Node
@export var TimeForDelete: Node
@export var MomentalDelete: Node
@export var HorizontalTabs: Node
@export var DEBUG: Node


func _ready() -> void:
	SaveDataAPI.data_loaded.connect(on_loaded_settings)
	on_loaded_settings()

func on_loaded_settings():
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings.SaveMessageFrequency" in SaveDataAPI.data:
			PerSaveMessageParam.value = SaveDataAPI.data["Settings.SaveMessageFrequency"]
		if "Settings.AutoOpenSettings" in SaveDataAPI.data:
			AutoOpenSettings.Checked = SaveDataAPI.data["Settings.AutoOpenSettings"]
			visible = SaveDataAPI.data["Settings.AutoOpenSettings"]
		if "Settings.MomentalDelete" in SaveDataAPI.data:
			MomentalDelete.Checked = SaveDataAPI.data["Settings.MomentalDelete"]
		if "Settings.TimeForDelete" in SaveDataAPI.data:
			TimeForDelete.value = SaveDataAPI.data["Settings.TimeForDelete"]
		if "Settings.HorizontalTabsInMainWindow" in SaveDataAPI.data:
			HorizontalTabs.Checked = SaveDataAPI.data["Settings.HorizontalTabsInMainWindow"]
		if "Settings.Debug" in SaveDataAPI.data:
			DEBUG.Checked = SaveDataAPI.data["Settings.Debug"]
			DebugTab.visible = SaveDataAPI.data["Settings.Debug"]
		

func _on_save_message_frequenc_spin_box_value_changed(value):
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings.SaveMessageFrequency" in SaveDataAPI.data:
			SaveDataAPI.data["Settings.SaveMessageFrequency"] = value
			SaveDataAPI.save_data()

func _on_auto_open_settings_state_changed(value):
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings.AutoOpenSettings" in SaveDataAPI.data:
			SaveDataAPI.data["Settings.AutoOpenSettings"] = value
			SaveDataAPI.save_data()

func _on_momental_delete_state_changed(value):
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings.MomentalDelete" in SaveDataAPI.data:
			SaveDataAPI.data["Settings.MomentalDelete"] = value
			SaveDataAPI.save_data()

func _on_momental_delete_spin_box_value_changed(value):
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings.TimeForDelete" in SaveDataAPI.data:
			SaveDataAPI.data["Settings.TimeForDelete"] = value
			SaveDataAPI.save_data()

func _on_debug_check_box_state_changed(value):
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings.Debug" in SaveDataAPI.data:
			SaveDataAPI.data["Settings.Debug"] = value
			DebugTab.visible = value
			SaveDataAPI.save_data()


func _on_mind_check_box_state_changed(value) -> void:
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings.HorizontalTabsInMainWindow" in SaveDataAPI.data:
			SaveDataAPI.data["Settings.HorizontalTabsInMainWindow"] = value
			SaveDataAPI.save_data()

extends Panel





@export_category("-Settings-")
@export_category("Information")

@export var Information_Description: MindRTL


@export_category("Main")

@export var LangList: OptionButton
@export var AutoOpenSettings: Node
@export var TimeForDelete: Node
@export var MomentalDelete: Node
@export var DEBUG: Node

@export_category("Language")

@export var DescText: Node


@onready var Tabs = $MarginContainer/VBoxContainer/TabPanel/DecorTabs/Decor2/Tabs
@onready var Panels = $MarginContainer/VBoxContainer/TabPanel/Panels






func on_loaded_settings():
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings.SaveMessageFrequency" in SaveDataAPI.data:
			$MarginContainer/VBoxContainer/TabPanel/Panels/Main/VBoxContainer/perSaveMessageParam/SpinBox.value = SaveDataAPI.data["Settings.SaveMessageFrequency"]
		#print("::: ",SaveDataAPI.data["Settings"]["AutoOpenSettings"])
		if "Settings.AutoOpenSettings" in SaveDataAPI.data:
			AutoOpenSettings.Checked = SaveDataAPI.data["Settings.AutoOpenSettings"]
			visible = SaveDataAPI.data["Settings.AutoOpenSettings"]
		if "Settings.MomentalDelete" in SaveDataAPI.data:
			MomentalDelete.Checked = SaveDataAPI.data["Settings.MomentalDelete"]
		if "Settings.TimeForDelete" in SaveDataAPI.data:
			TimeForDelete.value = SaveDataAPI.data["Settings.TimeForDelete"]
		if "Settings.Debug" in SaveDataAPI.data:
			DEBUG.Checked = SaveDataAPI.data["Settings.Debug"]
			
			$MarginContainer/VBoxContainer/TabPanel/DecorTabs/Decor2/Tabs/Debug.visible = SaveDataAPI.data["Settings.Debug"]

@onready var LangContent = $MarginContainer/VBoxContainer/TabPanel/Panels/Language/HBoxContainer/VBoxContainer/Panel/MarginContainer/ScrollContainer/MarginContainer/VBoxContainer/Content
@onready var LangContentElement = $MarginContainer/VBoxContainer/TabPanel/Panels/Language/HBoxContainer/VBoxContainer/Panel/MarginContainer/ScrollContainer/MarginContainer/VBoxContainer/Element
	

func LangContent_select(index):
	if index != -1:
		if index < len(LocalizationAPI.LanguageBank.keys()):
			LocalizationAPI.set_global_language(LocalizationAPI.LanguageBank.keys()[index])
		
		for i in LangContent.get_children():
			i.disabled = false
		if index < LangContent.get_child_count():
			LangContent.get_child(index).disabled = true


func on_updated_lbu():
	LangContentElement.hide()
	
	for i in LangContent.get_children():
		i.queue_free()
	#LangList.clear()
	
	var index = 0
	for i in LocalizationAPI.LanguageBank.keys():
		var s = LangContentElement.duplicate()
		LangContent.add_child(s)
		s.disabled = false
		s.show()
		
		if LocalizationAPI.has_text("displayName", i):
			#LangList.add_item(LocalizationAPI.translate_text("|displayName| - |version|", i))
			s.real_text_icon_left = i
			s.real_text = LocalizationAPI.translate_text("|displayName|", i)
			s.real_text_icon_right = LocalizationAPI.translate_text("|version|", i)
		else:
			s.real_text_icon_left = i
			s.real_text = i
			s.real_text_icon_right = LocalizationAPI.translate_text("|version|", i)
			#LangList.add_item(i+LocalizationAPI.translate_text(" - |version|", i))
			
		s.pressed.connect(func(): 
			LangContent_select(index)
			
	
			if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
				if "Settings.Language" in SaveDataAPI.data:
					SaveDataAPI.data["Settings.Language"] = LocalizationAPI.LanguageBank.keys()[index]
					SaveDataAPI.save_data()
			)
		s.mouse_entered.connect(func():
			DescSelect(i)
			
			var pt = DescText.get_parent().get_parent().get_theme_stylebox("panel").duplicate()
			pt.border_color = COLORS.get_color("UI.YELLOW")
			DescText.get_parent().get_parent().add_theme_stylebox_override("panel", pt)
			)
		s.mouse_exited.connect(func():
			DescSelect(LocalizationAPI.global_language)
			
			var pt = DescText.get_parent().get_parent().get_theme_stylebox("panel").duplicate()
			pt.border_color = COLORS.get_color("UI.GRAY")
			DescText.get_parent().get_parent().add_theme_stylebox_override("panel", pt)
			)
		index += 1
	
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings.Language" in SaveDataAPI.data:
			#LangList.select(LocalizationAPI.LanguageBank.keys().find(SaveDataAPI.data["Settings.Language"]))
			#LangContent
			LangContent_select(LocalizationAPI.LanguageBank.keys().find(SaveDataAPI.data["Settings.Language"]))
			#LangList.select(LocalizationAPI.LanguageBank.keys().find(SaveDataAPI.data["Settings.Language"]))


func DescSelect(lang):
	DescText.real_text = LocalizationAPI.translate_text(
'''|SettingsWindow.Language.DescriptionPanel.Name.text|: |displayName|
|SettingsWindow.Language.DescriptionPanel.File.text|: '''+lang+'''.properties
|SettingsWindow.Language.DescriptionPanel.Version.text|: |version|
|SettingsWindow.Language.DescriptionPanel.MajorVersion.text|: 1

|description|'''
, lang)


func on_global_lc():
	DescSelect(LocalizationAPI.global_language)
	
	var pt = DescText.get_parent().get_parent().get_theme_stylebox("panel").duplicate()
	pt.border_color = COLORS.get_color("UI.GRAY")
	DescText.get_parent().get_parent().add_theme_stylebox_override("panel", pt)
	
	$MarginContainer/VBoxContainer/TabPanel/Panels/Information/VBoxContainer/HBoxContainer/LineEdit.placeholder_text = LocalizationAPI.translate_text("|SettingsWindow.Information.Secret.text|")
# Called when the node enters the scene tree for the first time.
func _ready():
	Information_Description.placeholders["version"] = ProjectSettings.get_setting("application/config/version")
	Information_Description.placeholders["engine"] = "Godot Engine " + Engine.get_version_info().string + " [mono]"
	
	#LocalizationAPI.change_current_language.connect(func():
	#	LangList.select(LocalizationAPI.current_language)
	#)
	'''SaveDataAPI.data_loaded.connect(func():
		if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
			if "Settings" in SaveDataAPI.data:
				if "Language" in SaveDataAPI.data["Settings"]:
					LangList.text = SaveDataAPI.data["Settings"]["Language"]
		)
	
				LangList.text = SaveDataAPI.data["Settings"]["Language"]'''
	LocalizationAPI.language_bank_updated.connect(func():
		on_updated_lbu()
	)
	on_updated_lbu()
	
	SaveDataAPI.data_loaded.connect(func():
		on_loaded_settings()
	)
	on_loaded_settings()
	
	LocalizationAPI.global_language_changed.connect(func():
		on_global_lc()
	)
	on_global_lc()
# Called every frame. 'delta' is the elapsed time since the previous frame.


var Tabs_Panels_is_ready = false

func _process(delta):
	if Tabs_Panels_is_ready == false:
		if Tabs != null:
			if Panels != null:
				Tabs_Panels_is_ready = true
				
				for i in Tabs.get_children():
					i.pressed.connect(func():
						for j in Tabs.get_children():
							j.disabled = i==j
						
						for j in Panels.get_children():
							j.visible = i.name==j.name
						
						)


func _on_close_pressed():
	hide()



func _on_github_pressed():
	OS.shell_open("https://github.com/DL-03/")

func _on_discord_pressed():
	OS.shell_open("https://discord.gg/MCdqTUQAFH")



func password():
	var password = $MarginContainer/VBoxContainer/TabPanel/Panels/Information/VBoxContainer/HBoxContainer/LineEdit.text.to_lower()
	
	if password == "0.21" or password == "v0.21":
		MessageAPI.info("|Secret.0.21|")


	elif password == "mywidgets":
		MessageAPI.info("Godot version MMC not have MyWidgets")
	else:
		if password == "1234":
			MessageAPI.info("|Secret.1234|")


		elif password == "dl" or password == "dl03":
			MessageAPI.info("|Secret.DL|")
		elif password == "vladislav117" or password == "117":
			MessageAPI.info("|Secret.Vladislav117|")
		elif password == "exmii" or password == "exmiii":
			MessageAPI.info("|Secret.Exmii|")
		elif password == "ivandog11" or password == "ivandog11" or password == "псина сутулая":
			MessageAPI.info("|Secret.IvanDog11|")
		elif password == "neu" or password == "neu512":
			MessageAPI.info("|Secret.Neu|")
		elif password == "axy" or password == "axylua":
			MessageAPI.info("|Secret.axylua|")
		
		elif password == "jojo":
			MessageAPI.info("|Secret.jojo|")

		elif password == "_ignatusik_" or password == "ignatusik" or password == "игнатусик":
			MessageAPI.info("|Secret._ignatusik_|")

		elif password == "пароль" or password == "password":
			MessageAPI.info("|Secret.Password|")
		elif password == "код" or password == "code":
			MessageAPI.info("|Secret.Code|")
		elif password == "ximalider":
			MessageAPI.info("|Secret.Ximalider|")
		elif password == "travel":
			MessageAPI.info("|Secret.Travel|")
		elif password == "секрет" or password == "secret":
			MessageAPI.info("|Secret.Secret|")
		else:
			MessageAPI.info("|Secret.!else!|")


func _on_enter_pressed():
	password()


	

func _on_line_edit_text_submitted(new_text):
	password()


func _on_lang_option_button_item_selected(index):
	LocalizationAPI.set_global_language(LocalizationAPI.LanguageBank.keys()[index])
	
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings.Language" in SaveDataAPI.data:
			SaveDataAPI.data["Settings.Language"] = LocalizationAPI.LanguageBank.keys()[index]
			SaveDataAPI.save_data()


func _on_github_mouse_entered():
	$MarginContainer/VBoxContainer/TabPanel/Panels/Information/VBoxContainer/Author/MindRTL/Github.label.real_text = "[emb]|FollowTheLink|"


func _on_github_mouse_exited():
	$MarginContainer/VBoxContainer/TabPanel/Panels/Information/VBoxContainer/Author/MindRTL/Github.label.real_text = ""












var DebugBank = []


func ModBank_updated():
	var mb = $MarginContainer/VBoxContainer/TabPanel/Panels/Debug/UpPanel/ModBank/VBoxContainer
		
	for i in mb.get_children():
		i.free()
	
	
	
	
	
	
	
	for c in ModManager.ModBank:
		var _Button = Button.new()
		_Button.text = c.Path.get_file()
		_Button.pressed.connect(func():
			var cb = $MarginContainer/VBoxContainer/TabPanel/Panels/Debug/UpPanel/ContentBank/VBoxContainer
			
			for i in cb.get_children():
				i.free()
			
			
			var ___Button = Button.new()
			___Button.text = c.ModContentClass.Path.get_file()
			
			cb.add_child(___Button)
			
			
			
			for i in c.ContentBank:
				var __Button = Button.new()
				__Button.text = i.Path.get_file()
				
				cb.add_child(__Button)
			
			)
		mb.add_child(_Button)

		#DebugBank.append({"ModClass": _ModClass, "Button": _Button})


func _on_db_open_pressed():
	ModBank_updated()


func _on_db_close_pressed():
	pass # Replace with function body.


func _on_save_message_frequenc_spin_box_value_changed(value):
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings.SaveMessageFrequency" in SaveDataAPI.data:
			SaveDataAPI.data["Settings.SaveMessageFrequency"] = value
			SaveDataAPI.save_data()


func _on_spin_box_changed():
	var value = $MarginContainer/VBoxContainer/TabPanel/Panels/Main/VBoxContainer/perSaveMessageParam/SpinBox.value
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings.SaveMessageFrequency" in SaveDataAPI.data:
			SaveDataAPI.data["Settings.SaveMessageFrequency"] = value
			SaveDataAPI.save_data()


func _on_lang_reload_pressed():
	LocalizationAPI.refresh_lang()


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


func _on_time_for_delete_spin_box_changed():
	var value = TimeForDelete.value
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings.TimeForDelete" in SaveDataAPI.data:
			SaveDataAPI.data["Settings.TimeForDelete"] = value
			SaveDataAPI.save_data()


func _on_momental_delete_spin_box_value_changed(value):
	
	
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings.TimeForDelete" in SaveDataAPI.data:
			SaveDataAPI.data["Settings.TimeForDelete"] = value
			SaveDataAPI.save_data()


func _on_itch_io_pressed():
	OS.shell_open("https://dl03.itch.io/")
	


func _on_myndustry_check_box_state_changed(value):
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings.Debug" in SaveDataAPI.data:
			SaveDataAPI.data["Settings.Debug"] = value
			$MarginContainer/VBoxContainer/TabPanel/DecorTabs/Decor2/Tabs/Debug.visible = value
			SaveDataAPI.save_data()
	


func _on_open_folder_mmc_pressed():
	if OS.get_name() == "Windows":
		OS.execute("explorer.exe", PackedStringArray([ProjectSettings.globalize_path("user://").replace("/", "\\")]))

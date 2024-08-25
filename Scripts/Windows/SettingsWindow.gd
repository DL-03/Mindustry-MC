extends Panel

@export var EngineVersion_Value: Node


@export var LangList: OptionButton



func on_loaded_settings():
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings" in SaveDataAPI.data:
			if "saveMessageFrequency" in SaveDataAPI.data["Settings"]:
					$MarginContainer/VBoxContainer/perSaveMessageParam/SpinBox.value = SaveDataAPI.data["Settings"]["saveMessageFrequency"]


func on_updated_lbu():
	LangList.clear()
		
	for i in LocalizationAPI.LanguageBank.keys():
		if LocalizationAPI.has_text("displayName", i):
			LangList.add_item(LocalizationAPI.translate_text("|displayName| - |version|", i))
		else:
			LangList.add_item(i+LocalizationAPI.translate_text(" - |version|", i))
	
	
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings" in SaveDataAPI.data:
			if "Language" in SaveDataAPI.data["Settings"]:
				LangList.select(LocalizationAPI.LanguageBank.keys().find(SaveDataAPI.data["Settings"]["Language"]))

# Called when the node enters the scene tree for the first time.
func _ready():
	EngineVersion_Value.text = "Godot Engine " + Engine.get_version_info().string + " [mono]"
	
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
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_close_pressed():
	hide()



func _on_github_pressed():
	OS.shell_open("https://github.com/DL-03/")


func _on_discord_pressed():
	OS.shell_open("https://discord.gg/MCdqTUQAFH")



func password():
	var password = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/LineEdit.text.to_lower()
	
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
		if "Settings" in SaveDataAPI.data:
			if "Language" in SaveDataAPI.data["Settings"]:
				SaveDataAPI.data["Settings"]["Language"] = LocalizationAPI.LanguageBank.keys()[index]
				SaveDataAPI.save_data()


func _on_github_mouse_entered():
	$MarginContainer/VBoxContainer/VBoxContainer/Author/MindustryTextLabel/Github.real_text = "|FollowTheLink|"


func _on_github_mouse_exited():
	$MarginContainer/VBoxContainer/VBoxContainer/Author/MindustryTextLabel/Github.real_text = ""












var DebugBank = []


func ModBank_updated():
	var mb = $MarginContainer/VBoxContainer/DebugBank/UpPanel/ModBank/VBoxContainer
		
	for i in mb.get_children():
		i.free()
	
	
	
	
	
	
	
	for c in ModManager.ModBank:
		var _Button = Button.new()
		_Button.text = c.Path.get_file()
		_Button.pressed.connect(func():
			var cb = $MarginContainer/VBoxContainer/DebugBank/UpPanel/ContentBank/VBoxContainer
			
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
		if "Settings" in SaveDataAPI.data:
			if "saveMessageFrequency" in SaveDataAPI.data["Settings"]:
				SaveDataAPI.data["Settings"]["saveMessageFrequency"] = max(1, value)
				SaveDataAPI.save_data()


func _on_spin_box_changed():
	var value = $MarginContainer/VBoxContainer/perSaveMessageParam/SpinBox.value
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings" in SaveDataAPI.data:
			if "saveMessageFrequency" in SaveDataAPI.data["Settings"]:
				SaveDataAPI.data["Settings"]["saveMessageFrequency"] = max(1, value)
				SaveDataAPI.save_data()


func _on_lang_reload_pressed():
	LocalizationAPI.refresh_lang()

extends Panel

@export var EngineVersion_Value: Node


@export var LangList: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	EngineVersion_Value.text = "Godot Engine " + Engine.get_version_info().string + " [mono]"
	
	LangList.select(SaveDataAPI.data["Settings"]["Language"])

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


func _on_option_button_item_selected(index):
	LocalizationAPI.current_language = index


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

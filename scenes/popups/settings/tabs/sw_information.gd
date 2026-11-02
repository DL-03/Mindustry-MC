extends VBoxContainer

@export var Description: MindRTL
@export var SecretLine: LineEdit
@export var GithubLink: Button


func _ready() -> void:
	Description.placeholders = {"version" = ProjectSettings.get_setting("application/config/version"), "engine" = "Godot Engine " + Engine.get_version_info().string + " [mono]"}
	
	LocalizationAPI.global_language_changed.connect(on_global_lc)
	on_global_lc()


func on_global_lc():
	SecretLine.placeholder_text = LocalizationAPI.translate_text("|Secret|")


func _on_visibility_changed() -> void:
	if visible:
		pass



func _on_github_pressed():
	OS.shell_open("https://github.com/DL-03")

func _on_itch_io_pressed():
	OS.shell_open("https://dl03.itch.io")

func _on_discord_pressed():
	OS.shell_open("https://discord.gg/MCdqTUQAFH")



func _on_github_mouse_entered():
	GithubLink.label.real_text = "[emb]|FollowTheLink|"

func _on_github_mouse_exited():
	GithubLink.label.real_text = ""




func _on_line_edit_text_submitted(new_text: String) -> void:
	secret_check()

func _on_enter_pressed() -> void:
	secret_check()

func secret_check():
	var password = SecretLine.text.to_lower()
	
	if password == "0.21" or password == "v0.21":
		Notifications.info("|Secret.0.21|")
	elif password == "1234":
		Notifications.info("|Secret.1234|")
	elif password == "dl" or password == "dl03":
		Notifications.info("|Secret.DL|")
	elif password == "vladislav117" or password == "117":
		Notifications.info("|Secret.Vladislav117|")
	elif password == "exmii" or password == "exmiii":
		Notifications.info("|Secret.Exmii|")
	elif password == "ivandog11" or password == "ivandog11" or password == "псина сутулая":
		Notifications.info("|Secret.IvanDog11|")
	elif password == "neu" or password == "neu512":
		Notifications.info("|Secret.Neu|")
	elif password == "axy" or password == "axylua":
		Notifications.info("|Secret.axylua|")

	elif password == "_ignatusik_" or password == "ignatusik" or password == "игнатусик":
		Notifications.info("|Secret._ignatusik_|")

	elif password == "пароль" or password == "password":
		Notifications.info("|Secret.Password|")
	elif password == "код" or password == "code":
		Notifications.info("|Secret.Code|")
	elif password == "ximalider":
		Notifications.info("|Secret.Ximalider|")
	elif password == "travel":
		Notifications.info("|Secret.Travel|")
	elif password == "секрет" or password == "secret":
		Notifications.info("|Secret.Secret|")
	elif password == "jojo" or password == "жожа" or password == "jotaro":
		Notifications.info("|Secret.jojo|")
	elif password == "ss14" or password == "ss13":
		Notifications.info("|Secret.ss14|")
	elif password == "nexus":
		Notifications.info("|Secret.nexus|")
	elif password == "linux" or password == "линукс":
		Notifications.info("|Secret.linux|")
	elif password == "arch" or password == "arch linux" or password == "archlinux":
		Notifications.info("|Secret.arch|")
	elif password == "android":
		Notifications.info("|Secret.android|")
	elif password == "ios":
		Notifications.info("|Secret.ios|")
	elif password == "windows":
		Notifications.info("|Secret.windows|")
	elif password == "mac":
		Notifications.info("|Secret.mac|")
	elif password == "nuke" or password == "оперы" or password == "ops" or password == "delta" or password == "дельта":
		Notifications.info("|Secret.nuke|")
	elif password == "max" or password == "макс" or password == "стинт" or password == "stint":
		Notifications.info("|Secret.max|")
	elif password == "mindsl":
		Notifications.info("|Secret.mindsl|")
	elif password == "jsab":
		Notifications.info("|Secret.jsab|")
	else:
		Notifications.info("|Secret.!else!|")

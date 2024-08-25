extends Control



	
func pop(path):

	if OS.get_name() == "Windows":
		OS.execute("explorer.exe", PackedStringArray([path]))

# Called when the node enters the scene tree for the first time.
func _ready():
	#var richlab = $VBoxContainer/VBoxContainer/ScrollContainer/VBoxContainer/Panel/RichTextLabel
	var path = ""
	match OS.get_name():
		"Windows":
			path = ProjectSettings.globalize_path(OS.get_environment("APPDATA")+"\\Mindustry\\mods\\")
		"Android":
			pass
		"Linux":
			pass
	print("[ModManager][_ready][MindsutyModsPath]: "+path)
	print("[ModManager][_ready][MMC_DataPath]: "+path)
	if OS.get_name() != "Windows":
		$VBoxContainer/DownPanel/OpenFolder.visible = false
	
	$VBoxContainer/DownPanel/OpenFolder.pressed.connect(pop.bind(path))
	
	var panel = $VBoxContainer/VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer
	
	#$VBoxContainer/Mod_Explorer.current_path = path
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_create_modification_pressed():
	$/root/Main/Windows/CreateMod.open()

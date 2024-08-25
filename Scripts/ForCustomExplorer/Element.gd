extends Button







var RootNode: Node
enum TypeElement {
	FOLDER,
	MOD,
	FILE
}

var Type = null
var Path = ""




enum TableType {
	HUGE_ICONS,
	BIG_ICONS,
	DEFAULT_ICONS,
	SMALL_ICONS,
	LIST,
	TABLE,
	TILE,
	CONTENT
}
var table_type = TableType.TILE

func table_update():
	if TableType.LIST==table_type or TableType.TABLE==table_type:
		custom_minimum_size.y = 50
		if TypeElement.MOD == Type:
			$MarginContainer/HBoxContainer/InfoPanel/Author.hide()
			$MarginContainer/HBoxContainer/InfoPanel/Version.hide()
		$MarginContainer/HBoxContainer/InfoPanel/PathBox.hide()
	elif TableType.TILE==table_type or TableType.CONTENT==table_type:
		custom_minimum_size.y = 130
		if TypeElement.MOD == Type:
			$MarginContainer/HBoxContainer/InfoPanel/Author.show()
			$MarginContainer/HBoxContainer/InfoPanel/Version.show()
		$MarginContainer/HBoxContainer/InfoPanel/PathBox.show()
	$MarginContainer/HBoxContainer.vertical = (table_type in [TableType.HUGE_ICONS,TableType.BIG_ICONS,TableType.DEFAULT_ICONS,TableType.SMALL_ICONS])
	if (table_type in [TableType.HUGE_ICONS,TableType.BIG_ICONS,TableType.DEFAULT_ICONS,TableType.SMALL_ICONS]):
		#if TypeElement.MOD == Type:
		$MarginContainer/HBoxContainer/InfoPanel/Author.hide()
		$MarginContainer/HBoxContainer/InfoPanel/Version.hide()
		$MarginContainer/HBoxContainer/InfoPanel/PathBox.show()
		
		if table_type == TableType.SMALL_ICONS:
			$MarginContainer/HBoxContainer/InfoPanel/PathBox.hide()
		else:
			$MarginContainer/HBoxContainer/InfoPanel/PathBox.show()
		
		
		match table_type:
			0: custom_minimum_size = Vector2(240,360)
			1: custom_minimum_size = Vector2(200,315)
			2: custom_minimum_size = Vector2(160,280)
			3: custom_minimum_size = Vector2(130,220)
			4: custom_minimum_size = Vector2(350,50)
			5: custom_minimum_size = Vector2(350,50)
			6: custom_minimum_size = Vector2(350,130)
			7: custom_minimum_size = Vector2(350,130)
		$MarginContainer/HBoxContainer/InfoPanel/DisplayName.text_aligment = 1
		$MarginContainer/HBoxContainer/InfoPanel/Name.horizontal_alignment = 1
	else:
		custom_minimum_size.x = 400
		
		$MarginContainer/HBoxContainer/InfoPanel/DisplayName.text_aligment = 0
		$MarginContainer/HBoxContainer/InfoPanel/Name.horizontal_alignment = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



func set_path(path: String):
	Path = path.simplify_path()
	
	if ModManager.test_from_path(Path):
		Type = TypeElement.MOD
	else:
		if FileAccess.file_exists(Path):
			Type = TypeElement.FILE
		else:
			if DirAccess.dir_exists_absolute(Path):
				Type = TypeElement.FOLDER
			else:
				return
	update_data()


func update_data():
	if TypeElement.FOLDER == Type:
		$MarginContainer/HBoxContainer/Panel.hide()
		$MarginContainer/HBoxContainer/InfoPanel/Name.real_text = Path.get_file()
		$MarginContainer/HBoxContainer/InfoPanel/PathBox/Path.real_text = Path
		$MarginContainer/HBoxContainer/InfoPanel/PathBox/Path.real_tooltip_text = "[UI.YELLOW]|CustomExplorer.Element.CopyPath.text|![WHITE]\n"+Path
		
		$MarginContainer/HBoxContainer/InfoPanel/Author.hide()
		$MarginContainer/HBoxContainer/InfoPanel/Version.hide()
		$MarginContainer/HBoxContainer/InfoPanel/DisplayName.hide()
	elif TypeElement.FILE == Type:
		$MarginContainer/HBoxContainer/Panel.hide()
		$MarginContainer/HBoxContainer/TextIcon.real_text = ""
		$MarginContainer/HBoxContainer/InfoPanel/Name.real_text = Path.get_file()
		$MarginContainer/HBoxContainer/InfoPanel/PathBox/Path.real_text = Path
		$MarginContainer/HBoxContainer/InfoPanel/PathBox/Path.real_tooltip_text = "[UI.YELLOW]|CustomExplorer.Element.CopyPath.text|![WHITE]\n"+Path
		
		$MarginContainer/HBoxContainer/InfoPanel/Author.hide()
		$MarginContainer/HBoxContainer/InfoPanel/Version.hide()
		$MarginContainer/HBoxContainer/InfoPanel/DisplayName.hide()
	elif TypeElement.MOD == Type:
		var data = ModManager.get_mod_data_from_path(Path)
		
		$MarginContainer/HBoxContainer/TextIcon.hide()
		$MarginContainer/HBoxContainer/InfoPanel/PathBox/Path.real_text = Path
		$MarginContainer/HBoxContainer/InfoPanel/PathBox/Path.real_tooltip_text = "[UI.YELLOW]|CustomExplorer.Element.CopyPath.text|![WHITE]\n"+Path
		
		$MarginContainer/HBoxContainer/Panel/MarginContainer/ImageIcon.texture = ModManager.get_icon_from_path(Path)
		
		
		if data != null:
			if "name" in data:
				$MarginContainer/HBoxContainer/InfoPanel/Name.real_text = data["name"]
			else:
				$MarginContainer/HBoxContainer/InfoPanel/Name.real_text = "None"
			if "author" in data:
				$MarginContainer/HBoxContainer/InfoPanel/Author.real_text = data["author"]
			else:
				$MarginContainer/HBoxContainer/InfoPanel/Author.real_text = "[UI.RED]None"
			if "version" in data:
				$MarginContainer/HBoxContainer/InfoPanel/Version.real_text = data["version"]
			else:
				$MarginContainer/HBoxContainer/InfoPanel/Version.real_text = "None"
			
			if "displayName" in data:
				$MarginContainer/HBoxContainer/InfoPanel/DisplayName.real_text = data["displayName"]
			else:
				$MarginContainer/HBoxContainer/InfoPanel/DisplayName.real_text = "[UI.RED]None"
			
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_pressed():
	if TypeElement.FOLDER == Type:
		RootNode.set_path(Path)
	elif TypeElement.MOD == Type:
		var AllTabButtons = $/root/Main/V1/UpPanel/TabsPanel/MarginContainer/ScrollContainer/MarginContainer/HBoxContainer/Tabs
		for i in AllTabButtons.get_children():
			if i.disabled:
				if i.ContentFrame == null:
					OpenMod.OpenFromPath(i, Path)
					break
		$/root/Main/V1/ModManager.visible = false

func _on_resized():
	if (table_type in [TableType.HUGE_ICONS,TableType.BIG_ICONS,TableType.DEFAULT_ICONS,TableType.SMALL_ICONS]):
		$MarginContainer/HBoxContainer/Panel.custom_minimum_size.x = size.x-10
		$MarginContainer/HBoxContainer/Panel.custom_minimum_size.y = size.x-10
		
		$MarginContainer/HBoxContainer/TextIcon.custom_minimum_size.x = size.x-10
		$MarginContainer/HBoxContainer/TextIcon.custom_minimum_size.y = size.x-10
	else:
		$MarginContainer/HBoxContainer/Panel.custom_minimum_size.x = size.y-10
		$MarginContainer/HBoxContainer/Panel.custom_minimum_size.y = size.y-10
		
		$MarginContainer/HBoxContainer/TextIcon.custom_minimum_size.x = size.y-10
		$MarginContainer/HBoxContainer/TextIcon.custom_minimum_size.y = size.y-10
	


func _on_path_pressed():
	DisplayServer.clipboard_set(Path)
	MessageAPI.info("|CustomExplorer.Message.PathCopied|!")


func _on_open_folder_pressed():
	if OS.get_name() == "Windows":
		OS.execute("explorer.exe", PackedStringArray([ Path.simplify_path().replace("/", "\\")]))

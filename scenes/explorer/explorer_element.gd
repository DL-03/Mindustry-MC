extends Button

var RootNode: Node
enum TypeElement {
	FOLDER,
	MOD,
	FILE
}

var Type = null
var Path = ""
var _mod_preview: Dictionary = {}

@export var richLabel: MindRTL
@export var filePathElement: Node

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
			pass
			#$MarginContainer/HBoxContainer/InfoPanel/Author.hide()
			#$MarginContainer/HBoxContainer/InfoPanel/Version.hide()
		filePathElement.hide()
	elif TableType.TILE==table_type or TableType.CONTENT==table_type:
		custom_minimum_size.y = 130
		if TypeElement.MOD == Type:
			pass
			#$MarginContainer/HBoxContainer/InfoPanel/Author.show()
			#$MarginContainer/HBoxContainer/InfoPanel/Version.show()
		filePathElement.show()
	$MarginContainer/HBoxContainer.vertical = (table_type in [TableType.HUGE_ICONS,TableType.BIG_ICONS,TableType.DEFAULT_ICONS,TableType.SMALL_ICONS])
	if (table_type in [TableType.HUGE_ICONS,TableType.BIG_ICONS,TableType.DEFAULT_ICONS,TableType.SMALL_ICONS]):
		filePathElement.show()
		
		if table_type == TableType.SMALL_ICONS:
			filePathElement.hide()
		else:
			filePathElement.show()
		
		
		match table_type:
			0: custom_minimum_size = Vector2(240,360)
			1: custom_minimum_size = Vector2(200,315)
			2: custom_minimum_size = Vector2(160,280)
			3: custom_minimum_size = Vector2(130,220)
			4: custom_minimum_size = Vector2(350,50)
			5: custom_minimum_size = Vector2(350,50)
			6: custom_minimum_size = Vector2(350,130)
			7: custom_minimum_size = Vector2(350,130)

		richLabel.horizontal_alignment = 1
	else:
		custom_minimum_size.x = 400
		richLabel.horizontal_alignment = 0

func set_path(path: String):
	Path = path.simplify_path()
	_mod_preview.clear()
	
	if DirAccess.dir_exists_absolute(Path):
		if ModManager.is_mod_directory(Path):
			Type = TypeElement.MOD
		else:
			Type = TypeElement.FOLDER
	elif FileAccess.file_exists(Path):
		if ModManager.is_archive_candidate(Path):
			_mod_preview = ModManager.get_mod_preview(Path)
		if _mod_preview.get("is_mod", false):
			Type = TypeElement.MOD
		else:
			Type = TypeElement.FILE
	else:
		return
	update_data()


func update_data():
	if Type in [TypeElement.FOLDER,TypeElement.FILE]:
		$MarginContainer/HBoxContainer/Panel.hide()
		
		richLabel.real_text = "[emb][UI.YELLOW]"+Path.get_file()
		filePathElement.path = Path
	
		if TypeElement.FILE == Type:
			$MarginContainer/HBoxContainer/TextIcon.real_text = "[emb offset=4]  "
	
	elif TypeElement.MOD == Type:
		if _mod_preview.is_empty():
			_mod_preview = ModManager.get_mod_preview(Path)
		var data: Variant = _mod_preview.get("data")
		filePathElement.path = Path
		
		$MarginContainer/HBoxContainer/TextIcon.hide()
		$MarginContainer/HBoxContainer/Panel/MarginContainer/ImageIcon.texture = _mod_preview.get("icon")
		
		var _displayName = "[UI.RED]None"
		var _name = "[UI.RED]None"
		var _author = "[UI.RED]None"
		var _version = "[UI.RED]None"
		
		if typeof(data) == TYPE_DICTIONARY:
			if "displayName" in data:
				_displayName = "[UI.YELLOW]"+data["displayName"]
			if "name" in data:
				_name = "[UI.YELLOW]"+data["name"]
			if "author" in data:
				_author = "[]"+data["author"]
			if "version" in data:
				_version = "[]"+data["version"]
	
		richLabel.real_text = "[emb]"+_displayName+"\n"+_name+"\n"+_author+"\n"+_version

func _on_pressed():
	if TypeElement.FOLDER == Type:
		RootNode.set_path(Path)
	elif TypeElement.MOD == Type:
		OpenMod.OpenFromPath(Path)


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

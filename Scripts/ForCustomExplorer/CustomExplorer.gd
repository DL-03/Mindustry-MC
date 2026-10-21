extends Control



var current_path = ""
var _refresh_generation := 0
const REFRESH_BATCH_SIZE := 16





@onready var PathLine = $Panels/UpPanel/LineEdit




@export_enum("Default", "Open Mod") var Mode = 0


@export var filter_mod = false
@export var filter_folder = false
@export var filter_image = false

@export var filter_other = false

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




func set_path(path: String):
	if typeof(path) == TYPE_STRING:
		path = path.simplify_path()
		
		if DirAccess.dir_exists_absolute(path):
			current_path = path
			
			PathLine.text = current_path+"/"
			refresh()

func addElement(_path):
	var element = preload("res://Objects/ForCustomExplorer/Element.tscn").instantiate()
	element.RootNode = self
	element.table_type = table_type
	element.set_path(_path)
	element.table_update()
	var container: Node = $Panels/ScrollContainer/MarginContainer/Flow
	if not container.visible:
		container = $Panels/ScrollContainer/MarginContainer/Box
	container.add_child(element)

func refresh():
	_refresh_generation += 1
	var generation := _refresh_generation
	var flow: Node = $Panels/ScrollContainer/MarginContainer/Flow
	var box: Node = $Panels/ScrollContainer/MarginContainer/Box
	for container in [flow, box]:
		for child in container.get_children():
			child.queue_free()

	if not DirAccess.dir_exists_absolute(current_path):
		PathLine.add_theme_color_override("font_color", COLORS.get_color("UI.RED"))
		return

	PathLine.add_theme_color_override("font_color", COLORS.get_color("UI.GREEN"))
	var directories := DirAccess.get_directories_at(current_path)
	var files := DirAccess.get_files_at(current_path)
	directories.sort()
	files.sort()
	var entries: Array[String] = []
	for directory_name in directories:
		entries.append(current_path.path_join(directory_name))
	for file_name in files:
		entries.append(current_path.path_join(file_name))
	_populate_directory.call_deferred(generation, entries)


func _populate_directory(generation: int, entries: Array[String]) -> void:
	for index in entries.size():
		if generation != _refresh_generation:
			return
		addElement(entries[index])
		if (index + 1) % REFRESH_BATCH_SIZE == 0:
			await get_tree().process_frame

var HOME_PATH = ""


func l_glc_changed():
	$Panels/UpPanel/OptionButton.set_item_text(0, LocalizationAPI.translate_text("|HugeIcons|"))
	$Panels/UpPanel/OptionButton.set_item_text(1, LocalizationAPI.translate_text("|BigIcons|"))
	$Panels/UpPanel/OptionButton.set_item_text(2, LocalizationAPI.translate_text("|DefaultIcons|"))
	$Panels/UpPanel/OptionButton.set_item_text(3, LocalizationAPI.translate_text("|SmallIcons|"))
	
	$Panels/UpPanel/OptionButton.set_item_text(4, LocalizationAPI.translate_text("|List|"))
	$Panels/UpPanel/OptionButton.set_item_text(5, LocalizationAPI.translate_text("|Table|"))
	
	$Panels/UpPanel/OptionButton.set_item_text(6, LocalizationAPI.translate_text("|Tile|"))
	$Panels/UpPanel/OptionButton.set_item_text(7, LocalizationAPI.translate_text("|Content1|"))

func _ready():
	match OS.get_name():
		"Windows":
			HOME_PATH = OS.get_environment("APPDATA") + "/Mindustry/mods/"
		"macOS":
			print("macOS not support!")
			HOME_PATH = "/"
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			HOME_PATH = OS.get_environment("HOME") + "/.local/share/Mindustry/mods/"
		"Android":
			HOME_PATH = "/Android/data/io.anuke.mindustry/files/mods/"
		"iOS":
			print("iOS not support!")
			HOME_PATH = "/"
		"Web":
			print("Web not support!")

	$Panels/UpPanel/OptionButton.add_item("Huge Icons")
	$Panels/UpPanel/OptionButton.add_item("Big Icons")
	$Panels/UpPanel/OptionButton.add_item("Default Icons")
	$Panels/UpPanel/OptionButton.add_item("Small Icons")
	
	$Panels/UpPanel/OptionButton.add_item("List")
	$Panels/UpPanel/OptionButton.add_item("Table")
	
	$Panels/UpPanel/OptionButton.add_item("Tile")
	$Panels/UpPanel/OptionButton.add_item("Content")
	
	$Panels/UpPanel/OptionButton.select(6)
	table_update()
	
	LocalizationAPI.global_language_changed.connect(l_glc_changed)
	l_glc_changed()
	set_path(HOME_PATH)


func table_update():
	if table_type in [TableType.HUGE_ICONS,TableType.BIG_ICONS,TableType.DEFAULT_ICONS,TableType.SMALL_ICONS,TableType.LIST,TableType.TILE]:
		$Panels/ScrollContainer/MarginContainer/Flow.vertical = (table_type in [TableType.HUGE_ICONS,TableType.BIG_ICONS,TableType.DEFAULT_ICONS,TableType.SMALL_ICONS])
		
		for i in $Panels/ScrollContainer/MarginContainer/Box.get_children():
			$Panels/ScrollContainer/MarginContainer/Box.remove_child(i)
			$Panels/ScrollContainer/MarginContainer/Flow.add_child(i)
		$Panels/ScrollContainer/MarginContainer/Box.hide()
		$Panels/ScrollContainer/MarginContainer/Flow.show()
	else:
		for i in $Panels/ScrollContainer/MarginContainer/Flow.get_children():
			$Panels/ScrollContainer/MarginContainer/Flow.remove_child(i)
			$Panels/ScrollContainer/MarginContainer/Box.add_child(i)
		$Panels/ScrollContainer/MarginContainer/Flow.hide()
		$Panels/ScrollContainer/MarginContainer/Box.show()
			
	for i in $Panels/ScrollContainer/MarginContainer/Box.get_children():
		i.table_type = table_type
		i.table_update()
	for i in $Panels/ScrollContainer/MarginContainer/Flow.get_children():
		i.table_type = table_type
		i.table_update()
	
	$Panels/UpPanel/OptionButton.select(table_type)

func _on_refresh_pressed():
	refresh()

func submited(new_text: String):
	if new_text == "" or new_text == " ":
		new_text = "/"
		if OS.get_name() == "Windows":
			new_text = "C:/"

		PathLine.text = new_text
	
	if new_text.get_extension().to_lower() == "open_mod":
		var _path = new_text.left(len(new_text)-len(new_text.get_extension())-1)
		print("[CustomExplorer][submited][OpenMod][Path]: ",_path)
		new_text = current_path

		var AllTabButtons = $/root/Main/V1/HBoxContainer/Panel/MarginContainer/ScrollContainer/MarginContainer2/HBoxContainer
		for i in AllTabButtons.get_children():
			if i.disabled:
				if i.ContentFrame == null:
					OpenMod.OpenFromPath(i, _path)
					break
		$/root/Main/V1/ModManager.visible = false

	current_path = new_text.simplify_path()
	
	if DirAccess.dir_exists_absolute(current_path):
		if len(current_path) > 0:
			if current_path[-1] != "/":
				PathLine.text = current_path+"/"

	refresh()

func _on_line_edit_text_submitted(new_text: String):
	submited(new_text)

func _on_line_edit_text_changed(new_text):
	var color: Color;
	
	if new_text.get_extension().to_lower() == "open_mod":
		var _path = new_text.left(len(new_text)-len(new_text.get_extension())-1)
		if DirAccess.dir_exists_absolute(_path):
			color = COLORS.get_color("UI.YELLOW")
		else:
			color = COLORS.get_color("UI.RED")
		
		if color:
			PathLine.add_theme_color_override("font_color", color)
		return
	
	if DirAccess.dir_exists_absolute(new_text):
		color = COLORS.get_color("UI.GREEN")
	else:
		color = COLORS.get_color("UI.RED")
	
	if color:
		PathLine.add_theme_color_override("font_color", color)


func _on_home_pressed():
	set_path(HOME_PATH)


func _on_up_folder_pressed():
	set_path(current_path.get_base_dir())


func _on_search_pressed():
	submited(PathLine.text)


func _on_option_button_item_selected(index):
	table_type = index
	table_update()

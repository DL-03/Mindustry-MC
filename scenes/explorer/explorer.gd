extends Control



var current_path = ""
var _refresh_generation := 0
const REFRESH_BATCH_SIZE := 16

@export_enum("Default", "Open Mod") var Mode = 0

@export var filter_mod = false
@export var filter_folder = false
@export var filter_image = false

@export var filter_other = false


@export_category("Prefabs")
var p_element = preload("uid://ctvf6s35ig4fm")
@export_category("Nodes")
@export var n_path_line: LineEdit
@export var n_flow_container: FlowContainer
@export var n_box_container: BoxContainer
var n_current_container: Container

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


# Чистит контейнеры box/flow
func clear_containers():
	for c in n_box_container.get_children():
		c.queue_free()
	for c in n_flow_container.get_children():
		c.queue_free()


func set_path(path: String):
	if typeof(path) == TYPE_STRING:
		path = path.simplify_path()
		
		if DirAccess.dir_exists_absolute(path):
			current_path = path
			
			n_path_line.text = current_path+"/"
			refresh()

func addElement(_path):
	var element = p_element.instantiate()
	element.RootNode = self
	element.table_type = table_type
	element.set_path(_path)
	element.table_update()

	n_current_container.add_child(element)

func refresh():
	_refresh_generation += 1
	var generation := _refresh_generation

	clear_containers()

	if not DirAccess.dir_exists_absolute(current_path):
		n_path_line.add_theme_color_override("font_color", COLORS.get_color("UI.RED"))
		return

	n_path_line.add_theme_color_override("font_color", COLORS.get_color("UI.GREEN"))
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
	var filts = ["HugeIcons","BigIcons","DefaultIcons","SmallIcons","List","Table","Tile","Content1"]
	for i in len(filts):
		$Panels/UpPanel/OptionButton.set_item_text(i, LocalizationAPI.translate_text(filts[i]))

func _ready():
	match OS.get_name():
		"Windows":
			HOME_PATH = OS.get_environment("APPDATA") + "/Mindustry/mods/"
		"macOS":
			HOME_PATH = OS.get_environment("HOME") + "/Library/Application Support/Mindustry/mods/"
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			HOME_PATH = OS.get_environment("HOME") + "/.local/share/Mindustry/mods/"
		"Android":
			HOME_PATH = "/storage/emulated/0/Android/data/io.anuke.mindustry/files/mods/"
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

# Обновляет елементы в зависимости от типа отображения
func table_update():
	var _prev_container
	
	if table_type in [TableType.HUGE_ICONS,TableType.BIG_ICONS,TableType.DEFAULT_ICONS,TableType.SMALL_ICONS,TableType.LIST,TableType.TILE]:
		n_flow_container.vertical = (table_type in [TableType.HUGE_ICONS,TableType.BIG_ICONS,TableType.DEFAULT_ICONS,TableType.SMALL_ICONS])
		
		_prev_container = n_box_container
		n_current_container = n_flow_container
	else:
		_prev_container = n_flow_container
		n_current_container = n_box_container
	
	for i in _prev_container.get_children():
		_prev_container.remove_child(i)
		n_current_container.add_child(i)

	_prev_container.hide()
	n_current_container.show()

	for i in n_current_container.get_children():
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

		n_path_line.text = new_text
	
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
				n_path_line.text = current_path+"/"

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
			n_path_line.add_theme_color_override("font_color", color)
		return
	
	if DirAccess.dir_exists_absolute(new_text):
		color = COLORS.get_color("UI.GREEN")
	else:
		color = COLORS.get_color("UI.RED")
	
	if color:
		n_path_line.add_theme_color_override("font_color", color)


func _on_home_pressed():
	set_path(HOME_PATH)


func _on_up_folder_pressed():
	set_path(current_path.get_base_dir())


func _on_search_pressed():
	submited(n_path_line.text)


func _on_option_button_item_selected(index):
	table_type = index
	table_update()

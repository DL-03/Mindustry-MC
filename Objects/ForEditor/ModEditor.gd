extends HSplitContainer

var ButtonTab = null

var ModContentClass = ContentClass.new()

var modClass: ModClass:
	set = _set_modClass

var ContentDirWathcer = DirectoryWatcher.new()



@export var ContentEditor: Node



func Close():
	ModManager.close_mod(modClass)
	queue_free()





func _set_modClass(value):
	modClass = value



var ModType = ""

#@export var GlobalModCard = preload("res://Objects/ModCard.tscn").instantiate()
var GlobalModCard = null
# Called when the node enters the scene tree for the first time.


func _ModContentClass_changed():
	pass
func _ready():
	ModContentClass.data_changed.connect(_ModContentClass_changed)
	
	
	await update_content_bank_window()
	
	GlobalModCard = $Panel/ModCard
	
	#$Panel.add_child(GlobalModCard)
	#$Panel.move_child(GlobalModCard,0)
	
	GlobalModCard.show_open_button = false
	GlobalModCard.show_type_button = true
	GlobalModCard.show_delete_button = false
	GlobalModCard.show_visible_button = true
	GlobalModCard.show_save_button = true
	
	
	ContentTabButtons = [
		$Panel/Panel/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/blocks,
		$Panel/Panel/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/items,
		$Panel/Panel/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/liquids,
		
		$Panel/Panel/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/status,
		$Panel/Panel/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/units,
		$Panel/Panel/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/weathers,
		$Panel/Panel/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/sectors
	]
	
	for i in ContentTabButtons:
		i.RootManager = self
	
	
	



func update_content_bank_window():
	if $Window.visible:
		$Window/RichTextLabel.text = ""
		for i in modClass.ContentBank:
			$Window/RichTextLabel.text += str(i.Data)+'\n'
	await get_tree().create_timer(5.0).timeout.connect(update_content_bank_window)
		

func dir_contents(path):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				pass
				#print("Found directory: " + file_name)
			else:
				pass
				#print("Found file: " + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

func get_all_pathes(path: String, file_ext := "", files := []):
	path = path.simplify_path()
	var dir = DirAccess.open(path)
	#print(dir)
	if dir != null:
		dir.list_dir_begin()

		var file_name = dir.get_next()

		while file_name != "":
			if dir.current_is_dir():
				dir.get_current_dir()
				files = get_all_pathes(dir.get_current_dir()+"/"+file_name, file_ext, files)
				#print(file_name, " ", dir.get_current_dir()+"/"+file_name)
			else:
				if file_ext and file_name.get_extension() != file_ext:
					file_name = dir.get_next()
					continue

				files.append(dir.get_current_dir()+"/"+file_name)
				#print(file_name, " ", dir.get_current_dir()+"/"+file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access %s." % path)

	return files





func setPath(path):
	
	if ModManager.test_from_path(path):
		modClass = ModManager.open_from_path(path)
		
		ButtonTab.text = modClass.ModContentClass.FullData["name"]
		
		#print(FileAccess.file_exists(ModPath.path_join("icon.png")))
		if FileAccess.file_exists(modClass.Path.path_join("icon.png")):
			var image = Image.new()
			image.load(modClass.Path.path_join("icon.png"))
			var t = ImageTexture.new()
			
			var Icon = t.create_from_image(image)
			GlobalModCard.get_node("MarginContainer/HBoxContainer/MarginContainer/TextureRect").texture = Icon
			ButtonTab.icon = Icon
		
		GlobalModCard.mouse_default_cursor_shape = CURSOR_POINTING_HAND
		
		#return
		
		GlobalModCard.ModEditor = self
		GlobalModCard.contentClass = modClass.ModContentClass
		
		#ContentEditor.open_from_path(ModContentClass)

		#first_scan_content()
		
		MessageAPI.info("Modification Opened")
		

	
	
	






func pressed_button_content():
	for i in ContentTabButtons:
		i.disabled = false

var ContentTabButtons = []


@onready var CONTENT_CARD = preload("res://Objects/ContentCard.tscn")
#@onready var CONTENT_CARD = preload("res://test.tscn")


func _content_add(_content_class):
	if _content_class != null:
		if typeof(_content_class.Data) == TYPE_DICTIONARY:
		
			var _s = CONTENT_CARD.instantiate()
			#print(Data)
			#_s.modClass = self.modClass
			_s.ModEditor = self
			_s.ContentEditor = ContentEditor
			
			_s.contentClass = _content_class
			#_s.Data = _data
			#_s.Path = _path
			
			
			
			$Panel/Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer.add_child(_s)
			
			_s.show()



func _set_current_tab_content(value):
	
	#if value != current_tab_content:
	if value != null:
		for i in $Panel/Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer.get_children():
			i.free()
		
		
		for i in modClass.ContentBank:
			if i.FileType == value:
				if i.File != null:
					if i.Data != null:
						await _content_add(i)
		
		
		

	current_tab_content = value
	
var current_tab_content = null:
	set = _set_current_tab_content



var SpritesDirAccess: DirAccess


func _on_window_close_requested():
	$Window.hide()


func _on_create_content_pressed():
	$/root/Main/CreateContent.open(modClass)


func _on_reload_content_pressed():
	current_tab_content = current_tab_content


func _on_content_bank_pressed():
	$Window.show()

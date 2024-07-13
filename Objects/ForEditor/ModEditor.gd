extends HSplitContainer

var ButtonTab = null

var ArchiveMain = preload("res://ArchiveMain.gd").new()
var HjsonMain = preload("res://HjsonMain.gd").new()



var SpriteDictonary = {}
var ContentBank = []

var ContentDirWathcer = DirectoryWatcher.new()

func get_sprite(key):
	if key in SpriteDictonary:
		if FileAccess.file_exists(SpriteDictonary[key]):
			var image = Image.new()
			image.load(SpriteDictonary[key])
			var t = ImageTexture.new()
		
			var Icon = t.create_from_image(image)
			return Icon
	return preload("res://resources/icons/error.png")

@export var ContentEditor: Node



func Close():
	ModZipReader.close()
	queue_free()



var ModContentClass = ContentClass.new()



var ModPath = ""
var ModPathZip = ""
var ModZipReader = ZIPReader.new()


#@export var GlobalModCard = preload("res://Objects/ModCard.tscn").instantiate()
var GlobalModCard = null
# Called when the node enters the scene tree for the first time.
func _ready():
	await update_content_bank_window()
	
	GlobalModCard = $Panel/ModCard
	
	#$Panel.add_child(GlobalModCard)
	#$Panel.move_child(GlobalModCard,0)
	
	GlobalModCard.show_open_button = false
	GlobalModCard.show_type_button = false
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
		for i in ContentBank:
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
	if DirAccess.dir_exists_absolute(path):
		ModPath = path
				
	elif FileAccess.file_exists(path):
		var ModPathZip = path
		var err = ModZipReader.open(path)
		#ModZipPacker.open(path)
		
		if err != OK:
			return PackedByteArray()
		else:
			
			
			var p = ProjectSettings.globalize_path("user://Temp/"+path.get_file().get_basename())
			ArchiveMain.ExtracteToDirectory(ModPathZip, p)
			ModPath = p
			#print(ModPath,ModPathZip,p)
	#print("fff",ModPath)
	var reader = get_all_pathes(ModPath)
	#dir_contents(ModPath)
	#print(reader)
	#print(reader)
	ModContentClass.ModEditor = self
	for i in reader:
		#print(i)
		
		if i.get_file() == "mod.json":
			ModPath = i.left(-8)
			ModContentClass.Path = i
			break
		elif i.get_file() == "mod.hjson":
			ModPath = i.left(-9)
			ModContentClass.Path = i
			break
		else:
			pass
	
	
	#print(DirAccess.dir_exists_absolute(ModPath),ModPath)
	#print("----------------------")
	#var DirAccessPath = DirAccess.open(Path)
	#ContentMod.setPath()
	#print(ContentMod)
	
	var _f = ModContentClass.Data
	#print(_f, " ", ContentMod.getPath())
	if _f != null:
		if "displayName" in _f:
			GlobalModCard.get_node("MarginContainer/HBoxContainer/VBoxContainer/displayName").real_text = _f.displayName
		if "name" in _f:
			GlobalModCard.get_node("MarginContainer/HBoxContainer/VBoxContainer/name").text = _f.name
			ButtonTab.text = _f.name
		if "author" in _f:
			GlobalModCard.get_node("MarginContainer/HBoxContainer/VBoxContainer/author").real_text = str(_f.author)
		if "version" in _f:
			GlobalModCard.get_node("MarginContainer/HBoxContainer/VBoxContainer/version").real_text = str(_f.version)
		GlobalModCard.get_node("MarginContainer/HBoxContainer/VBoxContainer/Path").text = str(ModPath)
	#print(FileAccess.file_exists(ModPath.path_join("icon.png")))
	if FileAccess.file_exists(ModPath.path_join("icon.png")):
		var image = Image.new()
		image.load(ModPath.path_join("icon.png"))
		var t = ImageTexture.new()
		
		var Icon = t.create_from_image(image)
		GlobalModCard.get_node("MarginContainer/HBoxContainer/MarginContainer/TextureRect").texture = Icon
		ButtonTab.icon = Icon
	
	GlobalModCard.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	GlobalModCard.ModEditor = self
	GlobalModCard.contentClass = ModContentClass
	ContentEditor.open_from_path(ModContentClass)
	#openFromPath(ContentMod.getPath())
	SpritesDirAccess = DirAccess.open(ModPath.simplify_path()+"/sprites/")
	#print(ModPath.simplify_path()+"/sprites/")
	var lis = get_all_pathes(ModPath.simplify_path()+"/sprites/")
	for i in lis:
		SpriteDictonary.merge({i.get_file().substr(0, -1+i.get_file().length()-i.get_file().get_extension().length()): i}, true)
	#print(SpriteDictonary)
	
	first_scan_content()
		


func revursive_first_scaner_content(path: String, file_ext := "", files := []):
	path = path.simplify_path()
	var dir = DirAccess.open(path)
	#print(dir)
	if dir != null:
		dir.list_dir_begin()

		var file_name = dir.get_next()

		while file_name != "":
			if dir.current_is_dir():
				dir.get_current_dir()
				revursive_first_scaner_content(dir.get_current_dir()+"/"+file_name, file_ext, files)
				#print(file_name, " ", dir.get_current_dir()+"/"+file_name)
			else:
				if file_ext and file_name.get_extension() != file_ext:
					file_name = dir.get_next()
					continue
				
				var c = preload("res://Objects/ContentClass.gd").new()
				c.ModEditor = self
				c.Path = dir.get_current_dir()+"/"+file_name
				ContentBank.append(c)

				#print(file_name, " ", dir.get_current_dir()+"/"+file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access %s." % path)

	return files


func first_scan_content():
	ContentBank = []
	revursive_first_scaner_content(ModPath.simplify_path()+"/content/")
	ContentDirWathcer.add_scan_directory(ModPath.simplify_path()+"/content/")
	ContentDirWathcer.files_created.connect(func(files):
		print("[CreatedFiles]:", files)
	)
	ContentDirWathcer.files_deleted.connect(func(files):
		print("[DeletedFiles]:", files)
	)
	ContentDirWathcer.files_modified.connect(func(files):
		print("[ModifiedFiles]:", files)
	)
	ContentDirWathcer.scan_delay = 0.5
	ContentDirWathcer.scan_step = 20
	
	add_child(ContentDirWathcer)
	


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
			_s.ModEditor = self
			_s.ContentEditor = ContentEditor
			
			_s.contentClass = _content_class
			#_s.Data = _data
			#_s.Path = _path
			
			
			
			$Panel/Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer.add_child(_s)
			
			_s.show()



func _set_current_tab_content(value):
	
	if value != current_tab_content:
		for i in $Panel/Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer.get_children():
			i.free()
		
		
		for i in ContentBank:
			if i.FileType == value:
				if i.File != null:
					if i.Data != null:
						await _content_add(i)
		
		
		''' LEGACY '''
		#var list_files = get_all_pathes(ModPath.simplify_path()+"/content/"+value)
		var list_files = []
		for i in list_files:
			
			var Data = null
			
			if i.substr(i.length()-5) == ".json":
				if FileAccess.file_exists(i):
					var file = FileAccess.open(i, FileAccess.READ)
					Data = JSON.parse_string(file.get_as_text())
					file.close()
				
			elif i.substr(i.length()-6) == ".hjson":
				if FileAccess.file_exists(i):
					#print(FileAccess.open(i, FileAccess.READ))
					var file = FileAccess.open(i, FileAccess.READ)
					Data = HjsonMain.parse_string(file.get_as_text())
					file.close()
			
			#await _content_add(Data, i)
			Data = null
			#print(i.substr(i.length()-6), i)

	current_tab_content = value
	
var current_tab_content = null:
	set = _set_current_tab_content



var SpritesDirAccess: DirAccess


func _on_window_close_requested():
	$Window.hide()


func _on_create_content_pressed():
	$Window.show()

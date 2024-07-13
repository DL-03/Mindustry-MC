extends Control

var ButtonTab = null

var ArchiveMain = preload("res://ArchiveMain.gd").new()
var HjsonMain = preload("res://HjsonMain.gd").new()





var ModType = ""
var ModPath = ""
var ModPathZip = ""
var ModZipReader = ZIPReader.new()

var ModFilePath = ""


# Called when the node enters the scene tree for the first time.
func _ready():
	#$/root/Main/V1/DownPanel.visible = false
	
	var _ModCard = preload("res://Objects/ModCard.tscn").instantiate()
	
	$DownPanel/LeftPanel/V1.add_child(_ModCard)
	$DownPanel/LeftPanel/V1.move_child(_ModCard, 0)
	
	_ModCard.show_open_button = false
	_ModCard.show_delete_button = false
	_ModCard.show_type_button = false
	_ModCard.show_visible_button = true
	_ModCard.show_save_button = true

	pass
	
	



# Called every frame. 'delta' is the elapsed time since the previous frame.

class ContentFile:
	var ZipPath = ""
	var Path = "" #is/path/for/file
	#var Data = {} #{"name": "Hello"}
	#var Text = "" #{"name": "Hello"}
	var FileType = "" #.json #.hjson
	var _FileAccess = null
	var _ZIPReader = null
	var _ZIPPacker = null
	func _init():
		pass
	func setPath(path):
		print("[][[][][][]]", path)
		print(FileAccess.file_exists(path))
		if FileAccess.file_exists(path):
			_FileAccess = FileAccess.open(path, FileAccess.READ)
			Path = _FileAccess.get_path_absolute()
			print(Path)

	func getData():
		if Path.get_extension() == "json":
			return JSON.parse_string(_FileAccess.get_as_text())
		elif Path.get_extension() == "hjson":
			return preload("res://HjsonMain.gd").new().parse_string(_FileAccess.get_as_text())

	func getFileExtension():
		return Path.get_extension()
			
	func getPath():
		return Path


var ContentMod = ContentFile.new()



func _process(delta):
	pass
	
func dir_contents(path):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			else:
				print("Found file: " + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

func get_all_pathes(path: String, file_ext := "", files := []):
	var dir = DirAccess.open(path)
	print(dir)
	if dir != null:
		dir.list_dir_begin()

		var file_name = dir.get_next()

		while file_name != "":
			if dir.current_is_dir():
				dir.get_current_dir()
				files = get_all_pathes(dir.get_current_dir()+"/"+file_name, file_ext, files)
				print(file_name, " ", dir.get_current_dir()+"/"+file_name)
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

func get_all_files(path: String, file_ext := "", files := []):
	var dir = DirAccess.open(path)
	print(dir)
	if dir != null:
		dir.list_dir_begin()

		var file_name = dir.get_next()

		while file_name != "":
			if dir.current_is_dir():
				dir.get_current_dir()
				files = get_all_files(dir.get_current_dir()+"/"+file_name, file_ext, files)
				print(file_name, " ", dir.get_current_dir()+"/"+file_name)
			else:
				if file_ext and file_name.get_extension() != file_ext:
					file_name = dir.get_next()
					continue

				files.append(file_name)

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
		print("ZIPP")
		
		if err != OK:
			return PackedByteArray()
		else:
			
			
			var p = ProjectSettings.globalize_path("user://Temp/"+path.get_file().get_basename())
			ArchiveMain.ExtracteToDirectory(ModPathZip, p)
			ModPath = p
			print(ModPath,ModPathZip,p)
	print("fff",ModPath)
	var reader = get_all_pathes(ModPath)
	#dir_contents(ModPath)
	#print(reader)
	#print(reader)
	print("wow/so.json".get_file())
	print("pop")
	print()
	for i in reader:
		#print(i)
		
		if i.get_file() == "mod.json":
			ModPath = i.left(-8)
			print(i)
			ContentMod.setPath(i)
			break
		elif i.get_file() == "mod.hjson":
			ModPath = i.left(-9)
			print(i.left(-9))
			print(i)
			print(ModPath)
			ContentMod.setPath(i)
			break
		else:
			pass
	
	
	print(DirAccess.dir_exists_absolute(ModPath),ModPath)
	print("----------------------")
	#var DirAccessPath = DirAccess.open(Path)
	#ContentMod.setPath()
	print(ContentMod)
	var _f = ContentMod.getData()
	print(_f, " ", ContentMod.getPath())
	if _f != null:
		if "name" in _f:
			#$DownPanel/LeftPanel/V1/ModCard/MarginContainer/HBoxContainer/VBoxContainer/name.text = _f.name
			ButtonTab.text = _f.name
		if "author" in _f:
			pass
			#$DownPanel/LeftPanel/V1/ModCard/MarginContainer/HBoxContainer/VBoxContainer/author.text = str(_f.author)
		if "version" in _f:
			pass
			#$DownPanel/LeftPanel/V1/ModCard/MarginContainer/HBoxContainer/VBoxContainer/version.text = str(_f.version)
	print(FileAccess.file_exists(ModPath.path_join("icon.png")))
	if FileAccess.file_exists(ModPath.path_join("icon.png")):
		var image = Image.new()
		image.load(ModPath.path_join("icon.png"))
		var t = ImageTexture.new()
		
		var Icon = t.create_from_image(image)
		#$DownPanel/LeftPanel/V1/ModCard/MarginContainer/HBoxContainer/MarginContainer/TextureRect.texture = Icon
		ButtonTab.icon = Icon
	
	#openFromPath(ContentMod.getPath())
	
'	
func openFromPath(path):
	var v = $DownPanel/Panel2/VBoxContainer/Panel/HBoxContainer/MarginContainer/ScrollContainer/MarginContainer2/HBoxContainer
	
	var r = ContentFile.new()
	r.setPath(path)
	
	
	var Data = r.getData()
	
	
	
	if Data != null:
		var frameContent = preload("res://content_frame_rect.tscn").instantiate()
		
		var tabb = preload("res://TabContent_Button.tscn")
		var s = tabb.instantiate()
		#s.get_node("Panel/H1/P2").visible = false
		#s.custom_minimum_size.y = 100
		frameContent.setPath(path)
		frameContent.TabButton = s
		
		s.ContentFrame = frameContent
		
		s.text = str(Data["name"])
		
		#st.get_node("Path").text = PathZip
		#if Icon != null:
		#	s.icon = Icon
		
		$DownPanel/Panel2/VBoxContainer/Panel2/MarginContainer.add_child(frameContent)
		v.add_child(s)
		frameContent.visible = true
'

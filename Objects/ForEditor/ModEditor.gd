extends Control

var ButtonTab = null


var modClass: ModClass:
	set = _set_modClass

var ContentDirWathcer = DirectoryWatcher.new()



@export var ContentEditor: Node



func Close():
	ModManager.close_mod(modClass)
	queue_free()
	#if ButtonTab != null:
	#	ButtonTab.queue_free()





func _set_modClass(value):
	modClass = value



var ModType = ""

#@export var GlobalModCard = preload("res://Objects/ModCard.tscn").instantiate()
var GlobalModCard = null
# Called when the node enters the scene tree for the first time.







func _ModContentClass_changed():
	pass
func _ready():
	#ModContentClass.data_changed.connect(_ModContentClass_changed)
	
	
	await update_content_bank_window()
	
	GlobalModCard = $ModEditor/Panel/ModCard
	
	#$Panel.add_child(GlobalModCard)
	#$Panel.move_child(GlobalModCard,0)
	
	GlobalModCard.show_open_button = false
	GlobalModCard.show_type_button = true
	GlobalModCard.show_delete_button = false
	GlobalModCard.show_visible_button = true
	GlobalModCard.show_save_button = true
	
	
	ContentTabButtons = [
		$ModEditor/Panel/Panel/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/all,
	
		$ModEditor/Panel/Panel/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/blocks,
		$ModEditor/Panel/Panel/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/items,
		$ModEditor/Panel/Panel/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/liquids,
		
		$ModEditor/Panel/Panel/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/status,
		$ModEditor/Panel/Panel/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/units,
		$ModEditor/Panel/Panel/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/weathers,
		$ModEditor/Panel/Panel/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/sectors
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



@onready var LoadingWindow = $LoadingWindow

func setPath(path):
	
	if ModManager.test_from_path(path):
		modClass = ModManager.open_from_path(path)
		
		
		ButtonTab.modClass = modClass
		
		
		__max_contentData = len(get_all_pathes(modClass.Path.path_join("content")))
		
		modClass.connect_loaded(func():
			LoadingWindow.call_deferred("hide")
			)
		modClass.ContentBank_added.connect(
			func(_contentClass: ContentClass):
				_content_add(_contentClass)
		)
			
		
		print(modClass.ModContentClass.FullData)

		GlobalModCard.mouse_default_cursor_shape = CURSOR_POINTING_HAND
		
		#return
		
		GlobalModCard.ModEditor = self
		GlobalModCard.contentClass = modClass.ModContentClass
		
		ContentEditor.open_from_path(modClass.ModContentClass)

		#first_scan_content()
		
		MessageAPI.info("|Message.modification_has_been_opened|")
		

	
	
	






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
			
			
			ListContentElements.call_deferred("add_child", _s)
			#ListContentElements.add_child(_s)
			
			_s.show()


@onready var ListContentElements = $ModEditor/Panel/Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer

func refresh_content_list():
	
		#i.free()
	
	for i in modClass.ContentBank:
		if current_tab_content == "all":
			if i.File != null:
				if i.Data != null:
					_content_add(i)
		elif i.FileType == current_tab_content:
			if i.File != null:
				if i.Data != null:
					_content_add(i)
	return
					


func _set_current_tab_content(value):
	
	current_tab_content = value
	if value != null:
		for i in ListContentElements.get_children():
			i.queue_free()
		
		
		#refresh_content_list()
		#var thread = Thread.new()
		#thread.start(refresh_content_list,Thread.PRIORITY_NORMAL)
		refresh_content_list()
		
		

	
	
var current_tab_content = null:
	set = _set_current_tab_content



var SpritesDirAccess: DirAccess


func _on_window_close_requested():
	$Window.hide()


func _on_create_content_pressed():
	$/root/Main/Windows/CreateContent.open(modClass)


func _on_reload_content_pressed():
	current_tab_content = current_tab_content


func _on_content_bank_pressed():
	$Window.show()




var __max_contentData = 0

func _process(delta):
	if LoadingWindow.visible:
		if modClass != null:
			if modClass.ModContentClass != null:
				#$LoadingWindow/Panel/MarginContainer/VBoxContainer/Label2.text = str(ModContentClass)
				if modClass.ModContentClass.FullData != null:
					$LoadingWindow/Panel/MarginContainer/VBoxContainer/Label2.real_text = "|ModEditor.LoadingWindow.Label.text|: " + str(modClass.ModContentClass.FullData["name"]) + "\n|ModEditor.LoadingWindow.Content.text|["+str(len(modClass.ContentBank))+"/"+str(__max_contentData)+"]: "+ str(modClass.ContentBank[-1].Path).substr(len(modClass.Path))
					
					$LoadingWindow/Panel/MarginContainer/VBoxContainer/ProgressBar.max_value = __max_contentData
					$LoadingWindow/Panel/MarginContainer/VBoxContainer/ProgressBar.value = len(modClass.ContentBank)


func _on_cancel_loading_pressed():
	$LoadingWindow/Panel/MarginContainer/VBoxContainer/HBoxContainer/Cancel.disabled = true
	Close()

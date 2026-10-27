extends Control

var ButtonTab = null


var modClass: ModClass:
	set = _set_modClass


@export var ContentEditor: Node



func Close():
	ModManager.close_mod(modClass)
	queue_free()
	#if ButtonTab != null:
	#	ButtonTab.queue_free()





func _set_modClass(value):
	modClass = value



var ModType = ""

#@export var GlobalModCard = preload("res://prefabs/ModCard.tscn").instantiate()
var GlobalModCard = null
# Called when the node enters the scene tree for the first time.







func _ready():
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
	
	
	
@onready var LoadingWindow = $LoadingWindow

func setPath(path):
	
	if ModManager.test_from_path(path):
		modClass = ModManager.open_from_path(path)
		
		
		ButtonTab.modClass = modClass
		
		$LoadingWindow.show()
		$LoadingWindow/Panel/MarginContainer/VBoxContainer/ProgressBar.indeterminate = true
		
		modClass.connect_loaded(_on_mod_loaded)
		modClass.ContentBank_added.connect(
			func(_contentClass: ContentClass):
				_content_add(_contentClass)
				_update_loading_progress()
				if $Window.visible:
					_refresh_content_bank_window()
		)
			
		
		print(modClass.ModContentClass.FullData)

		GlobalModCard.mouse_default_cursor_shape = CURSOR_POINTING_HAND
		
		#return
		
		GlobalModCard.ModEditor = self
		GlobalModCard.contentClass = modClass.ModContentClass
		
		ContentEditor.open_from_path(modClass.ModContentClass)

		#first_scan_content()
		
		Notifications.info("|ModificationOpened|")
		

func _on_mod_loaded() -> void:
	var progress_bar: ProgressBar = $LoadingWindow/Panel/MarginContainer/VBoxContainer/ProgressBar
	progress_bar.indeterminate = false
	progress_bar.max_value = 1
	progress_bar.value = 1
	LoadingWindow.hide()


func _update_loading_progress() -> void:
	if not LoadingWindow.visible or modClass == null:
		return

	var content_count: int = modClass.ContentBank.size()
	var label: Node = $LoadingWindow/Panel/MarginContainer/VBoxContainer/Label2
	var mod_name: String = str(modClass.ModContentClass.FullData.get("name", "None"))
	var last_path := ""
	if content_count > 0:
		last_path = str(modClass.ContentBank[-1].Path).substr(modClass.Path.length())

	label.real_text = "|Loading|: %s\n|Content|[%d]: %s" % [
		mod_name,
		content_count,
		last_path
	]






func pressed_button_content():
	for i in ContentTabButtons:
		i.disabled = false

var ContentTabButtons = []


@onready var CONTENT_CARD = preload("uid://dxllrpipx487b")




func _content_add(_content_class):
	if _content_class != null \
	and (current_tab_content == null or current_tab_content == "all" or _content_class.FileType == current_tab_content) \
	and typeof(_content_class.Data) == TYPE_DICTIONARY:
		
		var _s = CONTENT_CARD.instantiate()
		_s.ModEditor = self
		_s.ContentEditor = ContentEditor
		_s.contentClass = _content_class
		ListContentElements.call_deferred("add_child", _s)
		_s.show()


@onready var ListContentElements = $ModEditor/Panel/Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer

func refresh_content_list():
	
		#i.free()
	
	for i in modClass.ContentBank:
		if current_tab_content == null or current_tab_content == "all":
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
	_refresh_content_bank_window()
	$Window.show()


func _refresh_content_bank_window() -> void:
	var content_data: PackedStringArray = []
	for content_class: ContentClass in modClass.ContentBank:
		content_data.append(str(content_class.Data))
	$Window/RichTextLabel.text = "\n".join(content_data)


func _on_cancel_loading_pressed():
	$LoadingWindow/Panel/MarginContainer/VBoxContainer/HBoxContainer/Cancel.disabled = true
	Close()

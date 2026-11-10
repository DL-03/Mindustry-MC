class_name ModCard
extends Button


@export var mindRTL: MindRTL
@export var filePathElement: Node

var CLASS_NAME = "ModCard"

var Path = ""

var ModEditor: Node
var contentClass: ContentClass:
	set = _set_contentClass

var mod_explorer


func _contentClass_updated():
	if typeof(contentClass.FullData) == TYPE_DICTIONARY:
		var _displayName = "[UI.RED]None"
		var _name = "[UI.RED]None"
		var _author = "[UI.RED]None"
		var _version = "[UI.RED]None"
		
		if contentClass.FullData != null:
			if "displayName" in contentClass.FullData:
				_displayName = "[UI.YELLOW]"+contentClass.FullData["displayName"]
			if "name" in contentClass.FullData:
				_name = "[UI.YELLOW]"+contentClass.FullData["name"]
			if "author" in contentClass.FullData:
				_author = "[]"+contentClass.FullData["author"]
			if "version" in contentClass.FullData:
				_version = "[]"+str(contentClass.FullData["version"])
	
		mindRTL.real_text = "[emb]"+_displayName+"\n"+_name+"\n"+_author+"\n"+_version

	filePathElement.path = ModEditor.modClass.Path

	if ModEditor.modClass.ModType.to_lower() == "folder":
		$MarginContainer/HBoxContainer/VFlowContainer/Type.real_text = ""
		if $MarginContainer/HBoxContainer/VFlowContainer/Type/MindTooltip:
			$MarginContainer/HBoxContainer/VFlowContainer/Type/MindTooltip.tooltip_text = "[UI.YELLOW]|Folder|"
	else:
		$MarginContainer/HBoxContainer/VFlowContainer/Type.real_text = ""
		if $MarginContainer/HBoxContainer/VFlowContainer/Type/MindTooltip:
			$MarginContainer/HBoxContainer/VFlowContainer/Type/MindTooltip.tooltip_text = "[UI.YELLOW]|Archive|"
		
	show_save_button = ModEditor.modClass.ModType.to_lower() == "archive"
	
	$MarginContainer/HBoxContainer/MarginContainer/TextureRect.texture = ModEditor.modClass.get_mod_icon()

func _set_contentClass(value):
	if value == null:
		return
	
	contentClass = value
	
	contentClass.data_changed.connect(_contentClass_updated)
	
	
	_contentClass_updated()
	
	
	

var TempSize = 0
var Visible = true
# Called when the node enters the scene tree for the first time.
func _ready():
	_set_TypeButton(0)




var show_visible_button = false:
	set = _set_show_visible_button
func _set_show_visible_button(value):
	show_visible_button = value
	$MarginContainer/HBoxContainer/VFlowContainer/Visible.visible = value
var show_open_button = false:
	set = _set_show_open_button
func _set_show_open_button(value):
	show_open_button = value
	$MarginContainer/HBoxContainer/VFlowContainer/Open.visible = value
var show_type_button = false:
	set = _set_show_type_button
func _set_show_type_button(value):
	show_type_button = value
	$MarginContainer/HBoxContainer/VFlowContainer/Type.visible = value
var show_delete_button = false:
	set = _set_show_delete_button
func _set_show_delete_button(value):
	show_delete_button = value
	$MarginContainer/HBoxContainer/VFlowContainer/Delete.visible = value
var show_save_button = false:
	set = _set_show_save_button
func _set_show_save_button(value):
	show_save_button = value
	$MarginContainer/HBoxContainer/VFlowContainer/Save.visible = value
	


var TypeButton = 0:
	set(value): _set_TypeButton(value)
func _set_TypeButton(value):
	if value == 0:
		$MarginContainer/HBoxContainer.vertical = false
		set_anchors_preset(Control.PRESET_HCENTER_WIDE)
		
		$MarginContainer/HBoxContainer/VFlowContainer.vertical = true
		
		$MarginContainer/HBoxContainer/MarginContainer/TextureRect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		#$MarginContainer/HBoxContainer/MarginContainer/TextureRect.size_flags_horizontal = Control.SizeFlags.SIZE_SHRINK_BEGIN
		#$MarginContainer/HBoxContainer/MarginContainer/TextureRect.size_flags_vertical = Control.SizeFlags.SIZE_EXPAND_FILL
		mindRTL.horizontal_alignment = 0
	else:
		$MarginContainer/HBoxContainer.vertical = true
		
		$MarginContainer/HBoxContainer/VFlowContainer.vertical = false
		
		$MarginContainer/HBoxContainer/MarginContainer/TextureRect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL 
		#$MarginContainer/HBoxContainer/MarginContainer/TextureRect.size_flags_horizontal = Control.SizeFlags.SIZE_EXPAND_FILL
		#$MarginContainer/HBoxContainer/MarginContainer/TextureRect.size_flags_vertical = Control.SizeFlags.SIZE_SHRINK_BEGIN
		
		mindRTL.horizontal_alignment = 1

func open_press():
	var AllTabButtons = $/root/Main/V1/HBoxContainer/Panel/MarginContainer/ScrollContainer/MarginContainer2/HBoxContainer
	for i in AllTabButtons.get_children():
		if i.disabled:
			if i.ContentFrame == null:
				OpenMod.OpenFromPath(i, Path)
				break
	$/root/Main/V1/ModManager.visible = false


@onready var ControlPanel = $MarginContainer/HBoxContainer/VFlowContainer

func toggle_visible():
	Visible = not Visible
	
	
	filePathElement.visible = Visible

	
	if Visible:
		custom_minimum_size.y = 130

		ControlPanel.get_node("Visible").real_text_icon_left = ""
	else:
		custom_minimum_size.y = 50

		ControlPanel.get_node("Visible").real_text_icon_left = ""


func _on_visible_pressed() -> void:
	toggle_visible()


func _on_open_pressed() -> void:
	open_press()


func _on_resized():
	pass # Replace with function body.


func _on_pressed():
	if ModEditor != null:
		ModEditor.ContentEditor.open_from_path(contentClass)

func _on_save_pressed():
	if ModEditor.modClass.ModType.to_lower() == "archive":
		ArchiveMain.Pack(ModEditor.modClass.Path, ModEditor.modClass.SourcePath)
		Notifications.info("Moddification Saved!")


func _on_delete_pressed():
	$/root/Main/DeleteMod.open(Path)

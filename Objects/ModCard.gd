class_name ModCard
extends Button


var CLASS_NAME = "ModCard"


var ModEditor: Node
var contentClass: ContentClass

var TempSize = 0
var Visible = true
# Called when the node enters the scene tree for the first time.
func _ready():
	_set_TypeButton(0)

var Path = ""


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
		$MarginContainer/HBoxContainer/VBoxContainer/displayName.text_aligment = 0
		$MarginContainer/HBoxContainer/VBoxContainer/name.horizontal_alignment = 0
		$MarginContainer/HBoxContainer/VBoxContainer/author.text_aligment = 0
		$MarginContainer/HBoxContainer/VBoxContainer/version.text_aligment = 0
	else:
		$MarginContainer/HBoxContainer.vertical = true
		
		$MarginContainer/HBoxContainer/VFlowContainer.vertical = false
		
		$MarginContainer/HBoxContainer/MarginContainer/TextureRect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL 
		#$MarginContainer/HBoxContainer/MarginContainer/TextureRect.size_flags_horizontal = Control.SizeFlags.SIZE_EXPAND_FILL
		#$MarginContainer/HBoxContainer/MarginContainer/TextureRect.size_flags_vertical = Control.SizeFlags.SIZE_SHRINK_BEGIN
		
		$MarginContainer/HBoxContainer/VBoxContainer/displayName.text_aligment = 1
		$MarginContainer/HBoxContainer/VBoxContainer/name.horizontal_alignment = 1
		$MarginContainer/HBoxContainer/VBoxContainer/author.text_aligment = 1
		$MarginContainer/HBoxContainer/VBoxContainer/version.text_aligment = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func setData():
	pass


func open_press():
	var AllTabButtons = $/root/Main/V1/HBoxContainer/Panel/MarginContainer/ScrollContainer/MarginContainer2/HBoxContainer
	for i in AllTabButtons.get_children():
		if i.disabled:
			if i.ContentFrame == null:
				OpenMod.OpenFromPath(i, Path)
				break
	$/root/Main/V1/ModManager.visible = false



@onready var InfoPanel = $MarginContainer/HBoxContainer/VBoxContainer
@onready var ControlPanel = $MarginContainer/HBoxContainer/VFlowContainer

func toggle_visible():
	Visible = not Visible
	
	
	InfoPanel.get_node("author").visible = Visible
	InfoPanel.get_node("version").visible = Visible
	InfoPanel.get_node("Path").visible = Visible

	
	if Visible:
		custom_minimum_size.y = 130

		ControlPanel.get_node("Visible").text = ""
	else:
		custom_minimum_size.y = 50

		ControlPanel.get_node("Visible").text = ""


func _on_visible_pressed() -> void:
	toggle_visible()


func _on_open_pressed() -> void:
	open_press()


func _on_resized():
	pass # Replace with function body.


func _on_pressed():
	if ModEditor != null:
		ModEditor.ContentEditor.open_from_path(contentClass)

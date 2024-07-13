extends Control


var Name = "":
	set = _set_Name
var Type = "Text":
	set = _set_Type
var Data = null:
	set = _set_Data
var DefaultData = null


var VALUE_EDIT = null




func _update():
	if VALUE_EDIT != null:
		VALUE_EDIT.queue_free()
		VALUE_EDIT = null

	
	if Data != null:
		if Type == "String":
			VALUE_EDIT = LineEdit.new()
			VALUE_EDIT.text = str(Data)
			
			VALUE_EDIT.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			VALUE_EDIT.size_flags_vertical = Control.SIZE_EXPAND_FILL
		elif Type == "MultiString":
			VALUE_EDIT = TextEdit.new()
			VALUE_EDIT.text = str(Data)
			
			VALUE_EDIT.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			VALUE_EDIT.custom_minimum_size.y = 175
		elif Type == "Boolean":
			VALUE_EDIT = preload("res://Objects/Widgets/MyndustryCheckBox.tscn").instantiate()
			VALUE_EDIT.Checked = bool(Data)
		elif Type == "Color":
			VALUE_EDIT = preload("res://Objects/Widgets/MyColorEdit.tscn").instantiate()
			VALUE_EDIT.Data = Color.from_string(str(Data), Color.PURPLE)
	else:
		VALUE_EDIT = LineEdit.new()
		VALUE_EDIT.text = ""
		
		VALUE_EDIT.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		VALUE_EDIT.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if VALUE_EDIT != null:
		add_child(VALUE_EDIT)
func _set_Name(value):
	Name = value
	
	$NameLabel.text = Name+":"



func _set_Type(value):
	Type = value
	
	_update()
	
func _set_Data(value):
	Data = value
	
	_update()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

var MouseFocus = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if MouseFocus:
		get_node("/root/Main/TooltipContentKeys").position = get_viewport().get_mouse_position() + Vector2(5, 5)


func _on_name_label_mouse_entered():
	MouseFocus = true
	get_node("/root/Main/TooltipContentKeys").show()
	
	get_node("/root/Main/TooltipContentKeys/MarginContainer/VBoxContainer/HBoxContainer/Name").text = Name
	get_node("/root/Main/TooltipContentKeys/MarginContainer/VBoxContainer/HBoxContainer/DisplayName").text = Name
	
	get_node("/root/Main/TooltipContentKeys/MarginContainer/VBoxContainer/HBoxContainer2/ValueDefault").remove_theme_color_override("font_color")
	
	get_node("/root/Main/TooltipContentKeys/MarginContainer/VBoxContainer/HBoxContainer2/sW").visible = (typeof(DefaultData) == TYPE_STRING)
	get_node("/root/Main/TooltipContentKeys/MarginContainer/VBoxContainer/HBoxContainer2/eW").visible = (typeof(DefaultData) == TYPE_STRING)
	
	var _name_type = get_node("/root/Main/TooltipContentKeys/MarginContainer/VBoxContainer/HBoxContainer2/NameType")
	if Type == "Color":
		_name_type.text = "Color"
		_name_type.add_theme_color_override("font_color", Color.GOLD)
	elif typeof(DefaultData) == TYPE_STRING:
		_name_type.text = "String"
		_name_type.add_theme_color_override("font_color", Color.WEB_GRAY)
		get_node("/root/Main/TooltipContentKeys/MarginContainer/VBoxContainer/HBoxContainer2/ValueDefault")
		
	elif typeof(DefaultData) == TYPE_BOOL:
		_name_type.text = "Boolean"
		_name_type.add_theme_color_override("font_color", Color.DODGER_BLUE)
		if DefaultData:
			get_node("/root/Main/TooltipContentKeys/MarginContainer/VBoxContainer/HBoxContainer2/ValueDefault").add_theme_color_override("font_color", Color.SEA_GREEN)
		else:
			get_node("/root/Main/TooltipContentKeys/MarginContainer/VBoxContainer/HBoxContainer2/ValueDefault").add_theme_color_override("font_color", Color.INDIAN_RED)
			
	elif typeof(DefaultData) == TYPE_ARRAY:
		_name_type.text = "Array"
		_name_type.add_theme_color_override("font_color", Color.GREEN_YELLOW)
	elif typeof(DefaultData) == TYPE_DICTIONARY:
		_name_type.text = "Dictionary"
		_name_type.add_theme_color_override("font_color", Color.YELLOW)
	elif typeof(DefaultData) == TYPE_INT:
		_name_type.text = "Integer"
		_name_type.add_theme_color_override("font_color", Color.BLUE_VIOLET)
	elif typeof(DefaultData) == TYPE_FLOAT:
		_name_type.text = "Float"
		_name_type.add_theme_color_override("font_color", Color.WEB_PURPLE)
	elif typeof(DefaultData) == TYPE_NIL:
		_name_type.text = "Null"
		_name_type.add_theme_color_override("font_color", Color.RED)
	else:
		_name_type.text = "?"
		_name_type.add_theme_color_override("font_color", Color.FIREBRICK)
		
	get_node("/root/Main/TooltipContentKeys/MarginContainer/VBoxContainer/HBoxContainer2/ValueDefault").text = str(DefaultData)
func _on_name_label_mouse_exited():
	MouseFocus = false
	get_node("/root/Main/TooltipContentKeys").hide()

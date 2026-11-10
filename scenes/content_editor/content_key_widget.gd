extends Control


var RootContentFrame: Node
@export var mindTooltip: MindTooltip


var Name = "":
	set = _set_Name
var Type = "Text":
	set = _set_Type
var Data = null:
	set = _set_Data
var DefaultData = null


var VALUE_EDIT = null

func delete_data():
	RootContentFrame.changed_data(Name, null)
	queue_free()

func LineEdit_text_changed(value):
	if typeof(DefaultData) == TYPE_DICTIONARY:
		RootContentFrame.changed_data(Name, JSON.parse_string(value))
	elif typeof(DefaultData) == TYPE_FLOAT:
		if value[len(value)-1] in ["f", "F"]:
			RootContentFrame.changed_data(Name, float(value.substr(0, len(value)-1)))
		else:
			RootContentFrame.changed_data(Name, float(value))
		
		
		
	elif typeof(DefaultData) == TYPE_INT:
		RootContentFrame.changed_data(Name, int(value))
	elif typeof(DefaultData) == TYPE_ARRAY:
		RootContentFrame.changed_data(Name, JSON.parse_string(value))
	else:
		RootContentFrame.changed_data(Name, value)

func TextEdit_text_changed():
	RootContentFrame.changed_data(Name, VALUE_EDIT.text)
	
func CheckBox_state_changed(value):
	RootContentFrame.changed_data(Name, value)

func ColorEdit_data_changed(value):
	RootContentFrame.changed_data(Name, "#"+value.to_html(true))

func Category_data_changed(value):
	RootContentFrame.changed_data(Name, value.to_lower())

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
			
			VALUE_EDIT.text_changed.connect(LineEdit_text_changed)
		elif Type == "MultiString":
			VALUE_EDIT = TextEdit.new()
			VALUE_EDIT.text = str(Data)
			
			VALUE_EDIT.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			VALUE_EDIT.custom_minimum_size.y = 175
			
			VALUE_EDIT.text_changed.connect(TextEdit_text_changed)
		elif Type == "Boolean":
			VALUE_EDIT = preload("res://widgets/mind_check_box.tscn").instantiate()
			VALUE_EDIT.Checked = bool(Data)
			
			VALUE_EDIT.state_changed.connect(CheckBox_state_changed)
		elif Type == "Color":
			VALUE_EDIT = preload("res://widgets/mind_color_edit.tscn").instantiate()
			VALUE_EDIT.Data = Color.from_string(str(Data), Color.PURPLE)
			
			VALUE_EDIT.data_changed.connect(ColorEdit_data_changed)
		elif Type == "Category":
			VALUE_EDIT = preload("res://widgets/mind_category.tscn").instantiate()
			VALUE_EDIT.Data = str(Data)
			
			VALUE_EDIT.data_changed.connect(Category_data_changed)
	else:
		VALUE_EDIT = LineEdit.new()
		VALUE_EDIT.text = ""
		
		VALUE_EDIT.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		VALUE_EDIT.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		VALUE_EDIT.text_changed.connect(LineEdit_text_changed)
	if VALUE_EDIT != null:
		add_child(VALUE_EDIT)
	
	

	
func upd_tooltip():
	var __parametr = ""
	var __value = ""
	var __type = ""
	var __description = ""
	
	if LocalizationAPI.has_text("ClassType."+Name):
		__parametr = Name+" ( |ClassType."+Name+"| [])"
	else:
		__parametr = Name
	
	var _type = Type
	var _color = Color.WHITE
	
	var _color_default = Color.WHITE
	
	if Type == "Color":
		_type = "Color"
		_color = Color.GOLD
	elif Type == "Category":
		_type = "Category"
		_color = Color.DEEP_PINK
	elif typeof(DefaultData) == TYPE_STRING:
		_type = "String"
		_color = Color.WEB_GRAY
		
	elif typeof(DefaultData) == TYPE_BOOL:
		_type = "Boolean"
		_color = Color.DODGER_BLUE
		if DefaultData:
			_color_default = Color.SEA_GREEN
		else:
			_color_default = Color.INDIAN_RED
			
	elif typeof(DefaultData) == TYPE_ARRAY:
		_type = "Array"
		_color = Color.GREEN_YELLOW
	elif typeof(DefaultData) == TYPE_DICTIONARY:
		_type = "Dictionary"
		_color = Color.YELLOW
	elif typeof(DefaultData) == TYPE_INT:
		_type = "Integer"
		_color = Color.BLUE_VIOLET
	elif typeof(DefaultData) == TYPE_FLOAT:
		_type = "Float"
		_color = Color.WEB_PURPLE
	elif typeof(DefaultData) == TYPE_NIL:
		_type = "Null"
		_color = Color.RED
	else:
		_type = "?"
		_color = Color.FIREBRICK
	
	if _color is Color:
		_color = "#"+_color.to_html(false)
	
	if _color_default is Color:
		_color_default = "#"+_color_default.to_html(false)
	
	__type = "["+_color+"]"+_type
	__value = "["+_color_default+"]"+str(DefaultData)
	 
	
	if LocalizationAPI.has_text("ClassType."+Name+"_desc"):
		__description = "|ClassType."+Name+"_desc|"
	else:
		__description = "[UI.GRAY][center]No description"
	
	var _tooltip_text = "[emb][center][UI.YELLOW]|ClassType.tip_parametr|:[] {0}
[UI.YELLOW]|ClassType.tip_type|:[] {1} [UI.GRAY]︙ [UI.YELLOW]|ClassType.tip_default|:[] \"{2}[]\"
[left][]{3}".format([__parametr,__type,__value,__description])
	
	mindTooltip.tooltip_text = _tooltip_text



func _set_Name(value):
	Name = value
	
	if LocalizationAPI.has_text("ClassType."+Name):
		$NameLabel.real_text = "[emb]|ClassType."+Name+"|:"
	else:
		$NameLabel.real_text = "[emb]"+Name+":"

func _set_Type(value):
	Type = value
	
	_update()
	
func _set_Data(value):
	Data = value
	
	_update()

# Called when the node enters the scene tree for the first time.
func _ready():
	LocalizationAPI.global_language_changed.connect(func(): Name = Name)


func _on_actions_pressed():
	$/root/Main/Windows/ContentEditorKeyActions.edit(self)


func _on_name_label_mouse_entered() -> void:
	upd_tooltip()

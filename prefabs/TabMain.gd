extends PanelContainer

var controller: Node
@onready var tab = $Tab
signal close

var disabled = false:
	set = _set_disabled

func _set_disabled(v):
	disabled = v
	tab.disabled = v

var modClass: ModClass:
	set = _set_modClass

func _ready() -> void:
	reset()
	tab.show()

func _set_modClass(value):
	modClass = value
	
	if modClass == null:
		return
	
	var IconElement = tab.get_node_or_null("MarginContainer/HBoxContainer/Icon")
	
	if IconElement:
		IconElement.show()
		IconElement.texture = modClass.get_mod_icon()
	else:
		IconElement.hide()
	
	var LabelElement = tab.get_node_or_null("MarginContainer/HBoxContainer/Label")
	
	if LabelElement:
		if modClass.ModContentClass.FullData["displayName"] == "":
			LabelElement.real_text = "[emb]"+modClass.ModContentClass.FullData["name"]
		else:
			LabelElement.real_text = "[emb]"+modClass.ModContentClass.FullData["displayName"]
		
	modClass.ModContentClass.data_changed.connect(func():
		if modClass.ModContentClass.FullData["displayName"] == "":
			LabelElement.real_text = "[emb]"+modClass.ModContentClass.FullData["name"]
		else:
			LabelElement.real_text = "[emb]"+modClass.ModContentClass.FullData["displayName"]
		
		if IconElement:
			IconElement.show()
			IconElement.texture = modClass.get_mod_icon()
		else:
			IconElement.hide()
		)

func reset():
	modClass = null
	
	var IconElement = tab.get_node_or_null("MarginContainer/HBoxContainer/Icon")
	if IconElement:
		IconElement.hide()

	var LabelElement = tab.get_node_or_null("MarginContainer/HBoxContainer/Label")
	if LabelElement:
		LabelElement.real_text = "[emb][UI.YELLOW]|Explorer|"


func _on_tab_close() -> void:
	close.emit()


func _on_tab_pressed() -> void:
	controller.set_tab(self)

extends Panel


@onready var ErrorString = $Panel/MarginContainer/VBoxContainer/tip

@onready var ContentTypeOption = $Panel/MarginContainer/VBoxContainer/Type/OptionButton2

@onready var TypeOption = $Panel/MarginContainer/VBoxContainer/Type/OptionButton
@onready var TypeLine = $Panel/MarginContainer/VBoxContainer/Type/LineEdit
@onready var TypeCheck = $Panel/MarginContainer/VBoxContainer/Type/CheckCustom

@onready var PathLine = $Panel/MarginContainer/VBoxContainer/Path/LineEdit
@onready var NameString = $Panel/MarginContainer/VBoxContainer/Path/Name

@onready var NameLine = $Panel/MarginContainer/VBoxContainer/Name/LineEdit
@onready var ExtOption = $Panel/MarginContainer/VBoxContainer/Name/OptionButton

@onready var SelectFolder = $FileDialog


var modClass: ModClass


func open(_modClass):
	ContentTypeOption.clear()
	for i in ["Blocks", "Items", "Liquids"]:
		ContentTypeOption.add_item(i)
	ContentTypeOption.select(0)
	for i in ContentManager.ContentFile["CreateContent"]["Block"]:
		TypeOption.add_item(i)
	TypeOption.select(0)

	if _modClass != null:
		modClass = _modClass
		
		PathLine.text = ""
		
		NameLine.text = "name"
		ExtOption.select(0)
		
		$Panel/MarginContainer/VBoxContainer/DownPanel/Create.disabled = true
		
		show()
	
		update_data()



func update_data():
	NameString.real_text = "/"+NameLine.text+"."+ExtOption.text.to_lower()
	$Panel/MarginContainer/VBoxContainer/DownPanel/Create.disabled = true
	
	var new_text = NameLine.text
	
	if ContentTypeOption.selected == 0:
		if FileAccess.file_exists(modClass.Path.simplify_path().path_join("content/blocks").path_join(PathLine.text).path_join(new_text+"."+ExtOption.text.to_lower())):
			$Panel/MarginContainer/VBoxContainer/tip.real_text = "|PathBusy|"
			return
	elif ContentTypeOption.selected == 1:
		if FileAccess.file_exists(modClass.Path.simplify_path().path_join("content/items").path_join(PathLine.text).path_join(new_text+"."+ExtOption.text.to_lower())):
			$Panel/MarginContainer/VBoxContainer/tip.real_text = "|PathBusy|"
			return
	elif ContentTypeOption.selected == 2:
		if FileAccess.file_exists(modClass.Path.simplify_path().path_join("content/liquids").path_join(PathLine.text).path_join(new_text+"."+ExtOption.text.to_lower())):
			ErrorString.real_text = "|PathBusy|"
			return

	ErrorString.real_text = ""
	$Panel/MarginContainer/VBoxContainer/DownPanel/Create.disabled = false




func _on_back_pressed():
	hide()


func _on_create_pressed():
	var content_directories := ["blocks", "items", "liquids"]
	if ContentTypeOption.selected < 0 or ContentTypeOption.selected >= content_directories.size():
		Notifications.error("Cannot create content: invalid content category.")
		return

	var content_type := ""
	match ContentTypeOption.selected:
		0:
			content_type = TypeLine.text if TypeCheck.Checked else TypeOption.text
		1:
			content_type = "Items"
		2:
			content_type = "Liquids"

	var file_path := modClass.Path.path_join("content").path_join(
		content_directories[ContentTypeOption.selected]
	).path_join(PathLine.text).path_join(
		NameLine.text + "." + ExtOption.text.to_lower()
	)
	modClass.create_content(file_path, content_type)
	hide()

func _on_option_button_item_selected(index):
	if index == 0:
		$Panel/MarginContainer/VBoxContainer/Type.show()
		
		TypeOption.clear()
		
		for i in ContentManager.ContentFile["CreateContent"]["Block"]:
			TypeOption.add_item(i)
		TypeOption.select(0)
	else:
		$Panel/MarginContainer/VBoxContainer/Type.hide()
	
	update_data()


func _on_EXT_option_button_item_selected(index):
	update_data()


func _on_PathLine_edit_text_changed(new_text):
	update_data()


func _on_NameLine_edit_text_changed(new_text):
	update_data()


func _on_TypeLine_edit_text_changed(new_text):
	update_data()


func _on_check_custom_state_changed(v):
	if v != null:
		if TypeLine != null:
			TypeLine.visible = v
			TypeOption.visible = not v
			ContentTypeOption.visible = not v


func _on_1option_button_item_selected(index):
	update_data()


func _on_chose_path_pressed():
	if ContentTypeOption.selected == 0:
		SelectFolder.current_path = modClass.Path.simplify_path().path_join("content/blocks/")
	elif ContentTypeOption.selected == 1:
		SelectFolder.current_path = modClass.Path.simplify_path().path_join("content/items/")
	elif ContentTypeOption.selected == 2:
		SelectFolder.current_path = modClass.Path.simplify_path().path_join("content/liquids/")
	SelectFolder.show()




func _on_file_dialog_dir_selected(dir):
	if ContentTypeOption.selected == 0:
		if len(dir.simplify_path()) < len(modClass.Path.simplify_path().path_join("content/blocks")):
			Notifications.error("Error path root false")
			return
		PathLine.text = dir.simplify_path().substr(len(modClass.Path.simplify_path().path_join("content/blocks/")))
	elif ContentTypeOption.selected == 1:
		if len(dir.simplify_path()) < len(modClass.Path.simplify_path().path_join("content/items")):
			Notifications.error("Error path root false")
			return
		PathLine.text = dir.simplify_path().substr(len(modClass.Path.simplify_path().path_join("content/items/")))
	elif ContentTypeOption.selected == 2:
		if len(dir.simplify_path()) < len(modClass.Path.simplify_path().path_join("content/liquids")):
			Notifications.error("Error path root false")
			return
		PathLine.text = dir.simplify_path().substr(len(modClass.Path.simplify_path().path_join("content/liquids/")))

	update_data()

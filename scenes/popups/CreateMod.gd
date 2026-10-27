extends Panel



@onready var ErrorString = $Panel/MarginContainer/VBoxContainer/tip


@onready var PathLine = $Panel/MarginContainer/VBoxContainer/Path/LineEdit
@onready var NameString = $Panel/MarginContainer/VBoxContainer/Path/NameMod

@onready var NameLine = $Panel/MarginContainer/VBoxContainer/Name/LineEdit

@onready var SelectFolder = $FileDialog


var path = ""


func open(_path):
	path = _path
	
	PathLine.text = path
	NameLine.text = "name"
	
	NameString.real_text = "name"

	SelectFolder.hide()
		
	update_data()
	
	show()


func update_data():
	$Panel/MarginContainer/VBoxContainer/DownPanel/Create.disabled = true
	var full_path = PathLine.text.path_join(NameLine.text).simplify_path()
	
	NameString.real_text = "/"+NameLine.text
	
	if NameLine.text == "":
		ErrorString.real_text = "|ModNameInvalid|"
		return
	if DirAccess.dir_exists_absolute(full_path):
		ErrorString.real_text = "|PathBusy|"
		return

	$Panel/MarginContainer/VBoxContainer/DownPanel/Create.disabled = false
	ErrorString.real_text = ""



func _on_back_pressed():
	hide()


func _on_create_pressed():
	DirAccess.make_dir_absolute(PathLine.text.path_join(NameLine.text).simplify_path())
	
	var f = FileAccess.open(PathLine.text.path_join(NameLine.text).path_join("mod.json"), FileAccess.WRITE)
	
	f.store_string( str(ContentManager.get_content("mod")) )
	
	if ModManager.test_from_path(PathLine.text.path_join(NameLine.text).simplify_path()):
		var AllTabButtons = $/root/Main/V1/UpPanel/TabsPanel/MarginContainer/ScrollContainer/MarginContainer/HBoxContainer/Tabs
		for i in AllTabButtons.get_children():
			if i.tab.disabled:
				if i.ContentFrame == null:
					OpenMod.OpenFromPath(i, PathLine.text.path_join(NameLine.text).simplify_path())
					break
		$/root/Main/V1/ModManager.visible = false
		
		Notifications.info("Mod Created")
		hide()




func _on_line_edit_text_changed(new_text):
	update_data()


func _on_line_edit_text_changed1(new_text):
	update_data()


func _on_chose_path_pressed():
	SelectFolder.current_path = PathLine.text.simplify_path()+"/"
	SelectFolder.show()


func _on_file_dialog_dir_selected(dir):
	PathLine.text = SelectFolder.current_path.simplify_path()
	update_data()

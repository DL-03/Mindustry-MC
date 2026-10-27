extends Panel



var delete_process = 0
var delete_process_state = false
var final_delete_process = 0

var contentClass: ContentClass
var Type = 0

func get_only_filename(path):
	return path.get_file().substr(0, -1+path.get_file().length()-path.get_file().get_extension().length())



func update_data():
	var new_text = $Panel/MarginContainer/VBoxContainer/LineEdit.text
	
	print(FileAccess.file_exists(contentClass.Path.substr(0, len(contentClass.Path)-len(contentClass.Path.get_file()))+new_text+"."+contentClass.Path.get_extension()))
	
	if Type == 0:
		$Panel/MarginContainer/VBoxContainer/tip.real_text = "You can`t return content after deleting!!!"
		return
	
	if new_text == $Panel/MarginContainer/VBoxContainer/LineEdit.placeholder_text:
		$Panel/MarginContainer/VBoxContainer/tip.real_text = "Its Old Name!!!"
		#$Panel/MarginContainer/VBoxContainer/LineEdit.add_theme_color_override("font_color", COLORS.)
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/Rename.disabled = true
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/Duplicate.disabled = true
		return
	if FileAccess.file_exists(contentClass.Path.substr(0, len(contentClass.Path)-len(contentClass.Path.get_file()))+new_text+"."+contentClass.Path.get_extension()):
		$Panel/MarginContainer/VBoxContainer/tip.real_text = " A file with this name already exists!!!"
		#$Panel/MarginContainer/VBoxContainer/LineEdit.add_theme_color_override("font_color", Color.FIREBRICK)
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/Rename.disabled = true
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/Duplicate.disabled = true
		return
	else:
		$Panel/MarginContainer/VBoxContainer/tip.real_text = ""
		#$Panel/MarginContainer/VBoxContainer/LineEdit.add_theme_color_override("font_color", Color.SEA_GREEN)
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/Rename.disabled = false
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/Duplicate.disabled = false
		return


func open(_contentClass, _type):
	if _contentClass != null:
		contentClass = _contentClass
		Type = _type
		
		
		
		
		show()
		
		
		#$Panel/MarginContainer/VBoxContainer/LineEdit.add_theme_color_override("font_color", Color.GOLD)
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/Rename.disabled = true
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/Duplicate.disabled = true
		
		$Panel/MarginContainer/VBoxContainer/Label.font_color = COLORS.get_color("UI.YELLOW")
		if Type == 0:
			$Panel/MarginContainer/VBoxContainer/Label.real_text = "!  |Delete|  !"
			$Panel/MarginContainer/VBoxContainer/Label.font_color = COLORS.get_color("UI.RED")
			
			
			delete_process = 0
			delete_process_state = false
			final_delete_process = 0
			
			#if "MomentalDelete" in SaveDataAPI.data:
			#	SaveDataAPI.data["Settings.MomentalDelete"]
			if "Settings.TimeForDelete" in SaveDataAPI.data:
				if SaveDataAPI.data["Settings.TimeForDelete"] == 0:
					final_delete_process = 1
					delete_process = 0
			
			
			$Panel/MarginContainer/VBoxContainer/HBoxContainer/Delete.show()
			$Panel/MarginContainer/VBoxContainer/HBoxContainer/Rename.hide()
			$Panel/MarginContainer/VBoxContainer/HBoxContainer/Duplicate.hide()
			
			
			$Panel.get_theme_stylebox("panel").border_color = COLORS.get_color("UI.RED").to_html()
			
			$Panel/MarginContainer/VBoxContainer/HBoxContainer/Delete.real_text = "|Delete|"
			
			$Panel/MarginContainer/VBoxContainer/LineEdit.hide()
			
			var _name = contentClass.Path.get_file()
			
			if "name" in contentClass.FullData:
				if contentClass.FullData["name"] != "":
					_name = contentClass.FullData["name"]
			
			$Panel/MarginContainer/VBoxContainer/Label2.text = "You really want delete content\n - <"+_name+">?"
			#$Panel/MarginContainer/VBoxContainer/tip.real_text = "You can`t return content after deleting!!!"
		elif Type == 1:
			$Panel/MarginContainer/VBoxContainer/Label.real_text = " |Rename| "
			
			$Panel/MarginContainer/VBoxContainer/HBoxContainer/Delete.hide()
			$Panel/MarginContainer/VBoxContainer/HBoxContainer/Rename.show()
			$Panel/MarginContainer/VBoxContainer/HBoxContainer/Duplicate.hide()
			
			$Panel.get_theme_stylebox("panel").border_color = COLORS.get_color("UI.YELLOW").to_html()
			
			$Panel/MarginContainer/VBoxContainer/LineEdit.show()
			$Panel/MarginContainer/VBoxContainer/Label2.text = "Old file name: <"+str(get_only_filename(contentClass.Path))+">"
			
			$Panel/MarginContainer/VBoxContainer/LineEdit.text = get_only_filename(contentClass.Path)
			$Panel/MarginContainer/VBoxContainer/LineEdit.placeholder_text = get_only_filename(contentClass.Path)
		elif Type == 2:
			$Panel/MarginContainer/VBoxContainer/Label.real_text = " |Duplicate| "
			
			$Panel/MarginContainer/VBoxContainer/HBoxContainer/Delete.hide()
			$Panel/MarginContainer/VBoxContainer/HBoxContainer/Rename.hide()
			$Panel/MarginContainer/VBoxContainer/HBoxContainer/Duplicate.show()
			
			$Panel.get_theme_stylebox("panel").border_color = COLORS.get_color("UI.YELLOW").to_html()
			
			$Panel/MarginContainer/VBoxContainer/LineEdit.show()
			$Panel/MarginContainer/VBoxContainer/Label2.text = "Old file name: <"+str(get_only_filename(contentClass.Path))+">"
			
			$Panel/MarginContainer/VBoxContainer/LineEdit.text = get_only_filename(contentClass.Path)
			$Panel/MarginContainer/VBoxContainer/LineEdit.placeholder_text = get_only_filename(contentClass.Path)
			
		else:
			hide()
			return
		update_data()




# Called when the node enters the scene tree for the first time.
func _ready():
	await update_delete_procces()


func update_delete_procces():
	if final_delete_process == 0:
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/Delete/Panel.size.x = delete_process*($Panel/MarginContainer/VBoxContainer/HBoxContainer/Delete.size.x / 100)
		
		if delete_process_state:
			delete_process = min(100, delete_process + 1)
		if delete_process >= 100:
			final_delete_process = 1
			delete_process = 0
		
	else:
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/Delete/Panel.size.x = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Delete.size.x

	if "Settings.TimeForDelete" in SaveDataAPI.data:
		if SaveDataAPI.data["Settings.TimeForDelete"] == 0:
			await get_tree().create_timer(1/100).timeout.connect(update_delete_procces)
		else:
			await get_tree().create_timer(SaveDataAPI.data["Settings.TimeForDelete"]/100).timeout.connect(update_delete_procces)
			
	else:
		await get_tree().create_timer(5/100).timeout.connect(update_delete_procces)
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_cancel_pressed():
	hide()


func _on_delete_pressed():
	if final_delete_process > 0:
		if "Settings.MomentalDelete" in SaveDataAPI.data:
			if SaveDataAPI.data["Settings.MomentalDelete"]:
				contentClass.delete()
				hide()
		
		final_delete_process += 1
		if final_delete_process == 1:
			$Panel/MarginContainer/VBoxContainer/HBoxContainer/Delete.real_text = "|RDW.Delete.text|? - 5"
		if final_delete_process == 2:
			$Panel/MarginContainer/VBoxContainer/HBoxContainer/Delete.real_text = "Really? - 4"
		if final_delete_process == 3:
			$Panel/MarginContainer/VBoxContainer/HBoxContainer/Delete.real_text = "Danger!! - 3"
		if final_delete_process == 4:
			$Panel/MarginContainer/VBoxContainer/HBoxContainer/Delete.real_text = "YOU REALLY WANT?! - 2"
		if final_delete_process == 5:
			$Panel/MarginContainer/VBoxContainer/HBoxContainer/Delete.real_text = "LAST CHANCE!!! - 1"
		if final_delete_process == 6:
			$Panel/MarginContainer/VBoxContainer/HBoxContainer/Delete.real_text = "DELETE - 0"
		
		
		if final_delete_process >= 7:
			contentClass.delete()
			hide()
func _on_rename_pressed():
	contentClass.rename_filename($Panel/MarginContainer/VBoxContainer/LineEdit.text)
	hide()


func _on_duplicate_pressed():
	contentClass.duplicate_file($Panel/MarginContainer/VBoxContainer/LineEdit.text)
	hide()


func _on_line_edit_text_changed(new_text):
	update_data()


func _on_delete_button_down():
	if final_delete_process > 0:
		pass
	else:
		delete_process_state = true


func _on_delete_button_up():
	if final_delete_process > 0:
		pass
	else:
		delete_process = 0
		delete_process_state = false

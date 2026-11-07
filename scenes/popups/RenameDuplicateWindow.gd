extends PanelContainer


@export var TitleLabel: MindLabel
@export var ContentLabel: MindLabel
@export var TipLabel: MindLabel

@export var CLineEdit: LineEdit

@export var HSep: HSeparator

@export var CancelButton: MindIButton
@export var RenameButton: MindIButton
@export var DuplicateButton: MindIButton
@export var DeleteButton: MindIButton



var delete_process = 0
var delete_process_state = false
var final_delete_process = 0

var contentClass: ContentClass
var Type = 0

func get_only_filename(path):
	return path.get_file().substr(0, -1+path.get_file().length()-path.get_file().get_extension().length())



func update_data():
	var new_text = CLineEdit.text
	
	print(FileAccess.file_exists(contentClass.Path.substr(0, len(contentClass.Path)-len(contentClass.Path.get_file()))+new_text+"."+contentClass.Path.get_extension()))
	
	if Type == 0:
		TipLabel.real_text = "[emb]|YouCantReturnContentAfterDeleting|"
		return
	
	if new_text == CLineEdit.placeholder_text:
		TipLabel.real_text = "[emb]|ItsOldName|"
		RenameButton.disabled = true
		DuplicateButton.disabled = true
		return
	if FileAccess.file_exists(contentClass.Path.substr(0, len(contentClass.Path)-len(contentClass.Path.get_file()))+new_text+"."+contentClass.Path.get_extension()):
		TipLabel.real_text = "[emb]|FileWithThisNameAlreadyExists|"
		RenameButton.disabled = true
		DuplicateButton.disabled = true
		return
	else:
		TipLabel.real_text = ""
		RenameButton.disabled = false
		DuplicateButton.disabled = false
		return


func open(_contentClass, _type):
	if _contentClass != null:
		contentClass = _contentClass
		Type = _type
		
		show()
		
		#$Panel/MarginContainer/VBoxContainer/LineEdit.add_theme_color_override("font_color", Color.GOLD)
		RenameButton.disabled = true
		DuplicateButton.disabled = true
		
		if Type == 0:
			HSep.get_theme_stylebox("separator").border_color = COLORS.get_color("UI.RED").to_html()
			$Panel.get_theme_stylebox("panel").border_color = COLORS.get_color("UI.RED").to_html()
		else:
			HSep.get_theme_stylebox("separator").border_color = COLORS.get_color("UI.YELLOW").to_html()
			$Panel.get_theme_stylebox("panel").border_color = COLORS.get_color("UI.YELLOW").to_html()
			
		
		if Type == 0:
			TitleLabel.real_text = "[emb][UI.RED]!  |Delete|  !"
			
			delete_process = 0
			delete_process_state = false
			final_delete_process = 0
			
			#if "MomentalDelete" in SaveDataAPI.data:
			#	SaveDataAPI.data["Settings.MomentalDelete"]
			if "Settings.TimeForDelete" in SaveDataAPI.data:
				if SaveDataAPI.data["Settings.TimeForDelete"] == 0:
					final_delete_process = 1
					delete_process = 0
			
			DeleteButton.show()
			RenameButton.hide()
			DuplicateButton.hide()
			
			DeleteButton.real_text = "[emb]|Delete|"
			
			CLineEdit.hide()
			
			var _name = contentClass.Path.get_file()
			
			if "name" in contentClass.FullData:
				if contentClass.FullData["name"] != "":
					_name = contentClass.FullData["name"]
			
			ContentLabel.real_text = "[emb]|YouReallyWantDeleteContent|\n - <"+_name+">"
		elif Type == 1:
			TitleLabel.real_text = "[emb] |Rename| "
			
			DeleteButton.hide()
			RenameButton.show()
			DuplicateButton.hide()
			
			CLineEdit.show()
			ContentLabel.real_text = "[emb]|OldFileName|: <"+str(get_only_filename(contentClass.Path))+">"
			
			CLineEdit.text = get_only_filename(contentClass.Path)
			CLineEdit.placeholder_text = get_only_filename(contentClass.Path)
		elif Type == 2:
			TitleLabel.real_text = "[emb] |Duplicate| "
			
			DeleteButton.hide()
			RenameButton.hide()
			DuplicateButton.show()
			
			CLineEdit.show()
			ContentLabel.real_text = "[emb]|OldFileName|: <"+str(get_only_filename(contentClass.Path))+">"
			
			CLineEdit.text = get_only_filename(contentClass.Path)
			CLineEdit.placeholder_text = get_only_filename(contentClass.Path)
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
			DeleteButton.real_text = "[emb]|RDW.Delete.text|? - 5"
		if final_delete_process == 2:
			DeleteButton.real_text = "[emb]Really? - 4"
		if final_delete_process == 3:
			DeleteButton.real_text = "[emb]Danger!! - 3"
		if final_delete_process == 4:
			DeleteButton.real_text = "[emb]YOU REALLY WANT?! - 2"
		if final_delete_process == 5:
			DeleteButton.real_text = "[emb]LAST CHANCE!!! - 1"
		if final_delete_process == 6:
			DeleteButton.real_text = "[emb]DELETE - 0"
		
		
		if final_delete_process >= 7:
			contentClass.delete()
			hide()
func _on_rename_pressed():
	contentClass.rename_filename(CLineEdit.text)
	hide()


func _on_duplicate_pressed():
	contentClass.duplicate_file(CLineEdit.text)
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

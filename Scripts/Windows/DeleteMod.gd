extends Panel



var delete_process = 0
var delete_process_state = false
var final_delete_process = 0

var Path = ""
var Type = 0

func get_only_filename(path):
	return path.get_file().substr(0, -1+path.get_file().length()-path.get_file().get_extension().length())


func open(path):
	if path != null:
		Path = path

		delete_process = 0
		delete_process_state = false
		final_delete_process = 0

		show()

	
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/Delete.real_text = "|Delete|"

		$Panel/MarginContainer/VBoxContainer/Label2.text = "You really want delete mod\n - <"+str(Path)+">?\nYou can`t return mod after deleting!!!"

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

	await get_tree().create_timer(0.05).timeout.connect(update_delete_procces)


func _on_cancel_pressed():
	hide()


func _on_delete_pressed():
	if final_delete_process > 0:
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
			Notifications.info("WIP")
			#DirAccess.remove_absolute(Path)
			#$/root/Main/V1/ModManager/VBoxContainer/Mod_Explorer.current_path=$/root/Main/V1/ModManager/VBoxContainer/Mod_Explorer.current_path
			hide()

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

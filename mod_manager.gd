extends Control


func _on_create_modification_pressed():
	$/root/Main/Windows/CreateMod.open()


func _on_open_folder_pressed() -> void:
	OS.shell_show_in_file_manager($VBoxContainer/CustomExplorer.current_path)

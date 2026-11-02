extends VBoxContainer

func _on_open_folder_mmc_pressed():
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://"))

# Notifications Tests

@export var not_line: LineEdit
@export var not_optionButton: OptionButton

func _ready() -> void:
	for i in Notifications.Type.keys():
		not_optionButton.add_item(i)

func _on_topic_pressed() -> void:
	Notifications.toast(not_line.text, not_optionButton.selected)

func _on_line_edit_text_submitted(new_text: String) -> void:
	Notifications.toast(new_text, not_optionButton.selected)


# Debug Bank


var DebugBank = []

func ModBank_updated():
	var mb = $UpPanel/ModBank/VBoxContainer

	for i in mb.get_children():
		i.free()
	
	for c in ModManager.ModBank:
		var _Button = Button.new()
		_Button.text = c.Path.get_file()
		_Button.pressed.connect(func():
			var cb = $UpPanel/ContentBank/VBoxContainer
			
			for i in cb.get_children():
				i.free()
			
			var ___Button = Button.new()
			___Button.text = c.ModContentClass.Path.get_file()
			
			cb.add_child(___Button)
			
			
			for i in c.ContentBank:
				var __Button = Button.new()
				__Button.text = i.Path.get_file()
				
				cb.add_child(__Button)
			
			)
		mb.add_child(_Button)

		#DebugBank.append({"ModClass": _ModClass, "Button": _Button})

func _on_open_pressed() -> void:
	ModBank_updated()

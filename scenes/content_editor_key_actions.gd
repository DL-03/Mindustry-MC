extends Panel


var delete_process = 0
var delete_process_state = false
var final_delete_process = 0

@onready var TypeOptionButton: OptionButton = $Panel/MarginContainer/VBoxContainer/Type/OptionButton

var Types = [
	"String", 
	"Integer", 
	"Float", 
	"Boolean", 
	"List", 
	"Dictionary"
]
var DefaultValue = [
	"", 
	0, 
	0.0, 
	false, 
	[], 
	{}
]


var RootContentFrame = null

@export var NameLine: LineEdit
var s_name = ""
var s_type = ""

var contentClass: ContentClass
var CCW = null

func edit(object):
	$Panel/MarginContainer/VBoxContainer/tip.real_text = "No changes"
	NameLine.text = object.Name
	s_name = object.Name

	if object.Type in Types:
		s_type = Types.find(object.Type)
	else:
		s_type = 0
	TypeOptionButton.select(s_type)

	contentClass = object.RootContentFrame.contentClass
	CCW = object

	$Panel/MarginContainer/VBoxContainer/DownPanel/Delete.show()
	$Panel/MarginContainer/VBoxContainer/DownPanel/Create.hide()
	$Panel/MarginContainer/VBoxContainer/DownPanel/Save.show()
	$Panel/MarginContainer/VBoxContainer/DownPanel/Save.disabled = true
	show()


	delete_process = 0
	delete_process_state = false
	final_delete_process = 0

	$Panel/MarginContainer/VBoxContainer/DownPanel/Delete.real_text = "|RDW.Delete.text|"


func create(_RootContentFrame):
	$Panel/MarginContainer/VBoxContainer/tip.real_text = "No changes"
	$Panel/MarginContainer/VBoxContainer/Title.real_text = " Create Key "

	NameLine.text = ""
	s_name = ""

	TypeOptionButton.select(0)
	s_type = 0

	contentClass = _RootContentFrame.contentClass
	RootContentFrame = _RootContentFrame

	$Panel/MarginContainer/VBoxContainer/DownPanel/Delete.hide()
	$Panel/MarginContainer/VBoxContainer/DownPanel/Create.show()
	$Panel/MarginContainer/VBoxContainer/DownPanel/Save.hide()
	$Panel/MarginContainer/VBoxContainer/DownPanel/Create.disabled = true
	show()

func _on_back_pressed():
	hide()


func _on_save_pressed():
	hide()
	if CCW != null:
		CCW.Name = NameLine.text
		if s_type != TypeOptionButton.selected:
			CCW.Data = DefaultValue[TypeOptionButton.selected]
			CCW.Type = Types[TypeOptionButton.selected]

func _on_line_edit_text_changed(new_text):
	_update()



func _on_create_pressed():
	if TypeOptionButton.selected > -1:
		RootContentFrame.create_input(NameLine.text, DefaultValue[TypeOptionButton.selected])
	hide()





func _on_delete_pressed():
	if final_delete_process > 0:
		final_delete_process += 1
		if final_delete_process == 1:
			$Panel/MarginContainer/VBoxContainer/DownPanel/Delete.real_text = "|RDW.Delete.text|? - 5"
		if final_delete_process == 2:
			$Panel/MarginContainer/VBoxContainer/DownPanel/Delete.real_text = "Really? - 4"
		if final_delete_process == 3:
			$Panel/MarginContainer/VBoxContainer/DownPanel/Delete.real_text = "Danger!! - 3"
		if final_delete_process == 4:
			$Panel/MarginContainer/VBoxContainer/DownPanel/Delete.real_text = "YOU REALLY WANT?! - 2"
		if final_delete_process == 5:
			$Panel/MarginContainer/VBoxContainer/DownPanel/Delete.real_text = "LAST CHANCE!!! - 1"
		if final_delete_process == 6:
			$Panel/MarginContainer/VBoxContainer/DownPanel/Delete.real_text = "DELETE - 0"


		if final_delete_process >= 7:

			CCW.delete_data()



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





func _ready():
	for i in Types:
		TypeOptionButton.add_item(i)

	await update_delete_procces()


func update_delete_procces():
	if final_delete_process == 0:
		$Panel/MarginContainer/VBoxContainer/DownPanel/Delete/Panel.size.x = delete_process * ($Panel/MarginContainer/VBoxContainer/DownPanel/Delete.size.x / 100)

		if delete_process_state:
			delete_process = min(100, delete_process + 1)
		if delete_process >= 100:
			final_delete_process = 1
			delete_process = 0

	else:
		$Panel/MarginContainer/VBoxContainer/DownPanel/Delete/Panel.size.x = $Panel/MarginContainer/VBoxContainer/DownPanel/Delete.size.x

	await get_tree().create_timer(0.05).timeout.connect(update_delete_procces)



func _on_option_button_item_selected(index):
	_update()



func _update():
	var new_text = NameLine.text
	var index = TypeOptionButton.selected

	$Panel/MarginContainer/VBoxContainer/DownPanel/Save.disabled = true
	$Panel/MarginContainer/VBoxContainer/DownPanel/Create.disabled = true

	if new_text == "":
		$Panel/MarginContainer/VBoxContainer/tip.real_text = "The key name is incorrect"
	elif new_text == s_name:
		if s_type != index and $Panel/MarginContainer/VBoxContainer/DownPanel/Save.visible:
			$Panel/MarginContainer/VBoxContainer/tip.real_text = "[UI.YELLOW]Warning value key earse after change type!"
			$Panel/MarginContainer/VBoxContainer/DownPanel/Save.disabled = false
		else:
			$Panel/MarginContainer/VBoxContainer/tip.real_text = "No changes"

	elif contentClass.Data.has(new_text):
		$Panel/MarginContainer/VBoxContainer/tip.real_text = "Key exist!"
	else:
		$Panel/MarginContainer/VBoxContainer/ tip.real_text = ""
		$Panel/MarginContainer/VBoxContainer/DownPanel/Save.disabled = false
		$Panel/MarginContainer/VBoxContainer/DownPanel/Create.disabled = false

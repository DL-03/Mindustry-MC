@tool
extends HBoxContainer


@export var Line_Edit: Node
@export var ColorButton: Node

signal data_changed

@export var Data = Color.PURPLE:
	set = _set_Data
var current_data = Color.PURPLE

func _set_Data(value):
	Data = value
	current_data = value
	
	Line_Edit.text = "#"+value.to_html(true)
	ColorButton.color = value
	
	

# Called when the node enters the scene tree for the first time.
func _ready():
	Data = Data
	



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_line_edit_text_changed(new_text):
	current_data = Color.from_string(new_text, Color.PURPLE)
	ColorButton.color = current_data
	
	data_changed.emit(current_data)


func _on_color_picker_button_color_changed(color):
	current_data = color
	Line_Edit.text = "#"+color.to_html(true)
	
	data_changed.emit(current_data)

@tool
extends HBoxContainer


@export var Line_Edit: Node
@export var ColorButton: Node


@export var Data = Color.PURPLE:
	set = _set_Data
var current_data = Color.PURPLE

func _set_Data(value):
	Data = value
	current_data = value
	
	Line_Edit.text = "#"+value.to_html(true)
	update_color_button()

# Called when the node enters the scene tree for the first time.
func _ready():
	Data = Data
	


func update_color_button():
	var n = ColorButton.get_theme_stylebox("normal")
	n.bg_color = current_data
	ColorButton.add_theme_stylebox_override("normal", n)
	
	var h = ColorButton.get_theme_stylebox("hover")
	h.bg_color = current_data
	ColorButton.add_theme_stylebox_override("hover", h)

	var p = ColorButton.get_theme_stylebox("pressed")
	p.bg_color = current_data
	ColorButton.add_theme_stylebox_override("pressed", p)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_line_edit_text_changed(new_text):
	current_data = Color.from_string(new_text, Color.PURPLE)
	update_color_button()

@tool
extends Button



@export var Checked = false:
	set = _set_Checked

signal state_changed


func _set_Checked(value):
	Checked = value
	$MarginContainer/Panel/MarginContainer2.visible = Checked
	state_changed.emit(Checked)


# Called when the node enters the scene tree for the first time.
func _ready():
	Checked = Checked
	$MarginContainer/Panel/MarginContainer2/Panel.add_theme_stylebox_override("panel", $MarginContainer/Panel/MarginContainer2/Panel.get_theme_stylebox("panel").duplicate())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_pressed():
	Checked = not Checked


func _on_mouse_entered():
	
	var s = $MarginContainer/Panel/MarginContainer2/Panel.get_theme_stylebox("panel")
	if not button_pressed:
		s.bg_color = get_theme_stylebox("hover").bg_color
	else:
		s.bg_color = get_theme_stylebox("pressed").bg_color
	
func _on_mouse_exited():
	var s = $MarginContainer/Panel/MarginContainer2/Panel.get_theme_stylebox("panel")
	s.bg_color = get_theme_stylebox("normal").bg_color


func _on_button_down():
	var s = $MarginContainer/Panel/MarginContainer2/Panel.get_theme_stylebox("panel")
	s.bg_color = get_theme_stylebox("pressed").bg_color

func _on_button_up():
	
		var s = $MarginContainer/Panel/MarginContainer2/Panel.get_theme_stylebox("panel")
		if is_hovered():
			s.bg_color = get_theme_stylebox("hover").bg_color
		else:
			s.bg_color = get_theme_stylebox("normal").bg_color

extends Button
class_name FolderCard


var CLASS_NAME = "FolderCard"

var TypeButton = 0:
	set = _set_TypeButton
var RootExplorer = null
var self_path = "":
	set = _set_self_path


func _set_TypeButton(value: int):
	TypeButton = value

	$MarginContainer/HBoxContainer.vertical = TypeButton == 1
	$MarginContainer/HBoxContainer/Label2.horizontal_alignment = TypeButton


func _set_self_path(value: String):
	self_path = value
	$MarginContainer/HBoxContainer/Label2.text = value.substr(1+len(value.get_base_dir()))
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_pressed():
	print("[FolderCard]: " + self_path)
	if RootExplorer != null:
		RootExplorer.current_path = self_path

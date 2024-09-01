extends Control



@export var AllTabButtons: Node
@export var ContentPanel: Node
@export var modManager: Node

var list_images = []



# Called when the node enters the scene tree for the first time.



func _ready():
	pass



var TB_I_following = false
var TB_I_StartPos = Vector2.ZERO
func TitleBar_input(event):
	if event is InputEventMouseButton:
		print(event.get_button_index())
		if event.get_button_index() == 1:
			TB_I_following = not TB_I_following
			TB_I_StartPos = get_local_mouse_position()
func _process(_delta):

	if TB_I_following:
		get_viewport().position += Vector2i(get_global_mouse_position()-TB_I_StartPos)
		print(get_viewport().position)
	

func create_tab():
	var c = preload("res://Objects/TabButton_Main.tscn").instantiate()
	c.disabled = true
	c.reset()
	AllTabButtons.add_child(c)
	c.show()
	return c
	
func select_tab_from_index(index: int):
	if AllTabButtons.get_child_count() <= index and index >= 0:
		for i in AllTabButtons.get_children():
			if i.disabled:
				if i.ContentFrame != null:
					i.ContentFrame.hide()
				else:
					modManager.hide()
				i.disabled = false
		
		AllTabButtons.get_child(index).disabled = true
		if AllTabButtons.get_child(index).ContentFrame != null:
			AllTabButtons.get_child(index).ContentFrame.show()
		else:
			modManager.show()

func select_tab(tab):
	if tab != null:
		for i in AllTabButtons.get_children():
			if i.disabled:
				if i.ContentFrame != null:
					i.ContentFrame.hide()
				else:
					modManager.hide()
				i.disabled = false
		
		tab.disabled = true
		if tab.ContentFrame != null:
			tab.ContentFrame.show()
		else:
			modManager.show()

func close_tab_from_index(index: int):
	if AllTabButtons.get_child(index).ContentFrame != null:
		AllTabButtons.get_child(index).ContentFrame.queue_free()
	AllTabButtons.get_child(index).queue_free()
func close_tab(tab):
	if tab.ContentFrame != null:
		tab.ContentFrame.queue_free()
	tab.queue_free()


func _on_settings_pressed():
	$Windows/SettingsWindow.show()


func _on_close_pressed():
	if AllTabButtons.get_child_count() == 1:
		if AllTabButtons.get_child(0).ContentFrame == null:
			return
		else:
			pass

	for i in AllTabButtons.get_children():
		if i.disabled:
			if i.ContentFrame == null:
				
				
				i.free()
				AllTabButtons.get_children()[-1].pressed.emit()
			else:
				var err = i.ContentFrame.Close()
				if err == 1:
					pass
				else:
					pass
					
				
				if AllTabButtons.get_child_count() == 1:
					i.reset()
					modManager.show()
				else:
					i.free()
					AllTabButtons.get_children()[-1].pressed.emit()
					
					
				
			
			break


func _on_new_tab_pressed():
	select_tab(create_tab())


func _on_full_ready_ready():
	select_tab(create_tab())

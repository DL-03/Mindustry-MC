#@tool
class_name ModExplorer
extends Control



var FinderPanel = null

func WaitForChild(path, try_counter=50):
	if has_node(path):
		return get_node(path)
	else:
		if try_counter > 0:
			await get_tree().create_timer(0.1).timeout
			return await WaitForChild(path, try_counter-1)
		else:
			return null


var view_type = 6


var thread: Thread





var history = []


func _update_history():
	$VBoxContainer/HBoxContainer2/ARC_Return/Return.disabled = len(history) == 0
	#print(history)

@export var current_path = "":
	set = _set_current_path
var path = ""

func get_all_files(path: String, file_ext := "", files := [], _max_recursion=99):
	if _max_recursion <= 0:
		return files
	else:
		var dir = DirAccess.open(path)
		#print(dir)
		if dir != null:
			dir.list_dir_begin()

			var file_name = dir.get_next()

			while file_name != "":
				if dir.current_is_dir():
					dir.get_current_dir()
					files = get_all_files(dir.get_current_dir()+"/"+file_name, file_ext, files,_max_recursion-1)
					#print(file_name, " ", dir.get_current_dir()+"/"+file_name)
				else:
					if file_ext and file_name.get_extension() != file_ext:
						file_name = dir.get_next()
						continue

					files.append(file_name)

				file_name = dir.get_next()
		else:
			print("An error occurred when trying to access %s." % path)

	return files



func thred_fetching(value,_prev):
	if value != path:
		#print(DirAccess.dir_exists_absolute(value),DirAccess.open(value),value)
		if DirAccess.dir_exists_absolute(value):
			if 1==1:
				var DirA = DirAccess.open(value)
				path = value.simplify_path()+"/"
				$VBoxContainer/HBoxContainer2/LineEdit.text = path
				$VBoxContainer/HBoxContainer2/LineEdit.add_theme_color_override("font_color", Color.GREEN)
				
				var Box = $VBoxContainer/ScrollContainer/MarginContainer/Box
				
				for i in Box.get_children():
					i.queue_free()
				
				
				# --------
				var Folders = DirA.get_directories()
				DirA.list_dir_begin()
				var file_name = DirA.get_next()
				
				
				
				
				var Mods = []

				for i in Folders:
					if DirAccess.dir_exists_absolute((path+i).simplify_path()):
						var inst = preload("res://Objects/FolderCard.tscn").instantiate()
						inst.self_path = (path+i).simplify_path()
						inst.RootExplorer = self
						Box.add_child(inst)
			
				
				while file_name != "":
					#print("[ModExplorer]: ", value, " | ", file_name)
					var Data = null
					var Icon = null
					var TypeMod = ""
					var PathZip = path+file_name
					var PathLocal = null
					if DirA.current_is_dir():
						var reader = get_all_files(path+file_name, "", [], 3)
						
						
						for i in reader:
							#print(i.right(9), i)
							if i.right(9) == "/mod.json" or i == "mod.json":
								TypeMod = "Folder"
								PathLocal = i.left(-8)
								

								var s := FileAccess.open(path+file_name+"/"+i,FileAccess.READ)
								if s != null:
									Data = JSON.parse_string(FileAccess.open(path+file_name+"/"+i,FileAccess.READ).get_as_text())
									#print(reader.file_exists(i.left(-8)+"icon.png"))
									#print("AR: ",path+file_name+"/"+"icon.png")
									if FileAccess.file_exists(path+file_name+"/"+"icon.png"):
										var image = Image.new()
										image.load(path+file_name+"/"+"icon.png")
										var t = ImageTexture.new()
										
										Icon = t.create_from_image(image)
									s.close()
									#print(Icon)
								#print(i.left(-8)+"icon.png")
								break
							if i.right(10) == "/mod.hjson" or i == "mod.hjson":
								TypeMod = "Folder"
								PathLocal = i.left(-9)
								

								var s := FileAccess.open(path+file_name+"/"+i,FileAccess.READ)
								if s != null:
									Data = HJSON.parse_string(FileAccess.open(path+file_name+"/"+i,FileAccess.READ).get_as_text())
									#print(reader.file_exists(i.left(-8)+"icon.png"))
									if FileAccess.file_exists(path+file_name+"/"+"icon.png"):
										var image = Image.new()
										image.load(path+file_name+"/"+"icon.png")
										var t = ImageTexture.new()
										
										Icon = t.create_from_image(image)
									s.close()
									#print(Icon)
								#print(i.left(-8)+"icon.png")
								break
					else:
						var reader := ZIPReader.new()
						var err := reader.open(path+file_name)
						
						
						if err != OK:
							break
						else:
							for i in reader.get_files():
								#print(i.right(9), i)
								if i.right(9) == "/mod.json" or i == "mod.json":
									TypeMod = "Archive"
									PathLocal = i.left(-8)
									var s := reader.read_file(i)
									if s != null:
										Data = JSON.parse_string(s.get_string_from_utf8())
										#print(reader.file_exists(i.left(-8)+"icon.png"))
										if reader.file_exists(i.left(-8)+"icon.png"):
											var image = Image.new()
											image.load_png_from_buffer(reader.read_file(i.left(-8)+"icon.png"))
											var t = ImageTexture.new()
											
											Icon = t.create_from_image(image)
										#print(Icon)
									#print(i.left(-8)+"icon.png")
									break
								if i.right(10) == "/mod.hjson" or i == "mod.hjson":
									TypeMod = "Archive"
									PathLocal = i.left(-9)
									var s := reader.read_file(i)
									if s != null:
										Data = HJSON.parse_string(s.get_string_from_utf8())
										#print(reader.file_exists(i.left(-9)+"icon.png"))
										if reader.file_exists(i.left(-9)+"icon.png"):
											var image = Image.new()
											image.load_png_from_buffer(reader.read_file(i.left(-9)+"icon.png"))
											var t = ImageTexture.new()
											
											Icon = t.create_from_image(image)
										#print(Icon)
									#print(i.left(-9)+"icon.png")
									break
							reader.close()
									
									
					if Data != null:
						
						var _ModCard = preload("res://Objects/ModCard.tscn").instantiate()
						
						var st = _ModCard.get_node("MarginContainer/HBoxContainer/VBoxContainer")
						if "displayName" in Data:
							st.get_node("displayName").real_text = str(Data["displayName"])
						if "name" in Data:
							st.get_node("name").real_text = str(Data["name"])
						if "author" in Data:
							st.get_node("author").real_text = str(Data["author"])
						if "version" in Data:
							st.get_node("version").real_text = str(Data["version"])

						if Icon != null:
							_ModCard.get_node("MarginContainer/HBoxContainer/MarginContainer/TextureRect").texture = Icon
						
						if TypeMod == "Folder":
							_ModCard.get_node("MarginContainer/HBoxContainer/VFlowContainer/Type").real_text = ""
							_ModCard.get_node("MarginContainer/HBoxContainer/VFlowContainer/Type").real_tooltip_text = "[UI.YELLOW]|Text.Folder|"
						else:
							_ModCard.get_node("MarginContainer/HBoxContainer/VFlowContainer/Type").real_text = ""
							_ModCard.get_node("MarginContainer/HBoxContainer/VFlowContainer/Type").real_tooltip_text = "[UI.YELLOW]|Text.Archive|"
						st.get_node("HBoxContainer/Path").real_text = PathZip
						st.get_node("HBoxContainer/Path").real_tooltip_text = PathZip
						#_ModCard.get_node("MarginContainer/HBoxContainer/VFlowContainer/Type").tooltip_text = TypeMod
						_ModCard.Path = PathZip

						_ModCard.show_visible_button = false
						_ModCard.show_save_button = false
						
						Box.add_child(_ModCard)
					else:
						pass
					
							
						
					
					#print("Found file: " + file_name)
					#print(reader.get_files())
					
					file_name = DirA.get_next()
			if _prev != "":
				#if _prev != history[len(history)-1]:
					#print(_prev)
					history.append(_prev)
					_update_history()
		else:
			$VBoxContainer/HBoxContainer2/LineEdit.add_theme_color_override("font_color", Color.RED)
	update_list_view()
	
func _set_current_path(value):
	
	
	
	
	var _prev = current_path
	current_path = value
	
	
	$VBoxContainer/LabelLoading.show()
	$VBoxContainer/ScrollContainer.hide()
	
	
	#if thread != null:
	#	thread.queue_free()
	#	thread = null
	#thread = Thread.new()
	#var c = Callable.create(self, "thred_fetching")
	#c.bind([value,_prev])
	#thread.start(c,Thread.PRIORITY_NORMAL)
	await thred_fetching(value,_prev)
	
	#thread.wait_to_finish()
	
	
	
	#print("JJ")
	
@export var finder = true : 
	set = _set_finder
@export var view_folders = true


func _update_finder():
	if FinderPanel != null:
		FinderPanel.visible = finder
func _set_finder(value):
	finder = value
	_update_finder()




func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if has_node("VBoxContainer/HBoxContainer"):
		FinderPanel = get_node("VBoxContainer/HBoxContainer")
		_update_finder()


func _on_property_list_changed():
	#param_updated()
	pass

func update_list_view():
	var index = view_type
	var prev_box = $VBoxContainer/ScrollContainer/MarginContainer/Box
	var new_box = null
	if (index >= 0 and index <= 4) or index == 6:
		new_box = FlowContainer.new()
	else:
		new_box = BoxContainer.new()
	
	if new_box != null and prev_box != null:
		if prev_box.get_class() != new_box.get_class():
			for i in prev_box.get_property_list():
				if new_box.get(i["name"]) != null:
					new_box.set(i["name"], prev_box.get(i["name"]))
			for i in prev_box.get_children():
				prev_box.remove_child(i)
				new_box.add_child(i)
			prev_box.get_parent().add_child(new_box)
			prev_box.free()
			new_box.name = "Box"
		else:
			new_box.free()
			new_box=prev_box

		new_box.vertical = (index == 4 or index == 5 or index == 7)

		for i in new_box.get_children():
			var s = i.CLASS_NAME

			
			if s != null:
				if s == "ModCard":
					var n = (index==6 or index == 7)
					i.get_node("MarginContainer/HBoxContainer/VBoxContainer/author").visible = n
					i.get_node("MarginContainer/HBoxContainer/VBoxContainer/version").visible = n
					i.get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Path").visible = n
					
			
			if index >= 0 and index <= 3:
				i.TypeButton = 1
			else:
				i.TypeButton = 0
			
			
			match index:
				0: i.custom_minimum_size = Vector2(260,346)
				1: i.custom_minimum_size = Vector2(220,306)
				2: i.custom_minimum_size = Vector2(173,259)
				3: i.custom_minimum_size = Vector2(130,216)
				4: i.custom_minimum_size = Vector2(350,50)
				5: i.custom_minimum_size = Vector2(350,50)
				6: i.custom_minimum_size = Vector2(350,130)
				7: i.custom_minimum_size = Vector2(350,130)
				
			i.size.y = 0
			i.size.x = 0
			
			#print("CCC")
		
		
		#print("SUM")
	$VBoxContainer/LabelLoading.hide()
	$VBoxContainer/ScrollContainer.show()


			

func _on_option_button_item_selected(index):
	view_type = index
	update_list_view()
	
func _on_line_edit_text_submitted(new_text):
	current_path = new_text


func _on_reload_pressed():
	current_path = current_path


func _on_up_pressed():
	current_path = current_path.get_base_dir()


func _on_find_pressed():
	current_path = $VBoxContainer/HBoxContainer2/LineEdit.text


func _on_return_pressed():
	if len(history) > 0:
		current_path = history[len(history)-1]
		history.remove_at(len(history)-1)
	_update_history()
		

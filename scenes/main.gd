extends Control


@export var ContentPanel: Node
@export var modManager: Node

var list_images = []

@export var TabPlaceholder: PackedScene

@export_category("Tab System")
@export var tabsDict: Dictionary[Node, Node] = {}
@export var tabs_container: Node
@export var first_tab: Node
@export var margin_panel: MarginContainer

@export var menu_label: MindLabel
@export var menu_button: MindButton

@export var home_tab: Node
@export var settings_tab: Node

@export var tabs_panel: PanelContainer
@export var V1: SplitContainer
@export var V1_wrapp: BoxContainer
@export var V1_wrapp_vs: VSeparator
@export var V1_wrapp_vs2: VSeparator


var horizontal_tabs = false:
	set = _set_horizontal_tabs

var current_tab: Node

func _set_horizontal_tabs(v):
	horizontal_tabs = v
	V1.vertical = not v
	V1_wrapp.vertical = v
	tabs_container.vertical = v
	menu_button.visible = v
	V1_wrapp_vs2.visible = v
	
	V1_wrapp_vs.get_theme_stylebox("separator").vertical = not v
	var tpp = tabs_panel.get_theme_stylebox("panel")
	
	if v:
		tpp.border_width_right = 5
		tpp.border_width_bottom = 0
		
		margin_panel.add_theme_constant_override("margin_left", 0)
		margin_panel.add_theme_constant_override("margin_top", 10)
		margin_panel.add_theme_constant_override("margin_right", 0)
		margin_panel.add_theme_constant_override("margin_bottom", 10)
		
		home_tab.theme_type_variation = "HTab"
		settings_tab.theme_type_variation = "HTab"
	else:
		tpp.border_width_right = 0
		tpp.border_width_bottom = 5
		
		margin_panel.add_theme_constant_override("margin_left", 10)
		margin_panel.add_theme_constant_override("margin_top", 0)
		margin_panel.add_theme_constant_override("margin_right", 10)
		margin_panel.add_theme_constant_override("margin_bottom", 0)
		
		home_tab.theme_type_variation = "VTab"
		settings_tab.theme_type_variation = "VTab"
	
	for _tab in tabsDict.keys():
		update_tab(_tab)
		
	
	update_tabs()

func update_tab(_tab):
	if horizontal_tabs:
		_tab.theme_type_variation = "HTab"
	else:
		_tab.theme_type_variation = "VTab"

func update_tabs():
	menu_label.get_parent().visible = horizontal_tabs
	if horizontal_tabs:
		menu_label.visible = not tabs_minimized
		
		if tabs_minimized:
			tabs_panel.custom_minimum_size.x = 55
			home_tab.real_text = "[emb offset=3]"
			settings_tab.real_text = "[emb offset=3]"
			V1.collapsed = true
		else:
			tabs_panel.custom_minimum_size.x = 150
			home_tab.real_text = "[emb offset=3] |Home|"
			settings_tab.real_text = "[emb offset=3] |Settings|"
			V1.collapsed = false
	else:
		tabs_panel.custom_minimum_size = Vector2(55,55)
		home_tab.real_text = "[emb offset=3]"
		settings_tab.real_text = "[emb offset=3]"
		V1.collapsed = true

func on_data_changed():
	if "Settings.HorizontalTabsInMainWindow" in SaveDataAPI.data:
		horizontal_tabs = SaveDataAPI.data["Settings.HorizontalTabsInMainWindow"]

func on_loaded_settings():
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings.AutoOpenSettings" in SaveDataAPI.data:
			if SaveDataAPI.data["Settings.AutoOpenSettings"]:
				set_tab(settings_tab)
		

func _ready():
	$Windows.show()
	if first_tab:
		set_tab(first_tab)
	
	SaveDataAPI.data_loaded.connect(on_loaded_settings)
	SaveDataAPI.data_changed.connect(on_data_changed)
	on_loaded_settings()
	on_data_changed()


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
	var c = TabPlaceholder.instantiate()
	c.controller = self
	tabs_container.add_child(c)
	update_tab(c)
	return c

func set_tab(_tab: Node) -> void:
	if current_tab:
		current_tab.disabled = false
		if current_tab in tabsDict:
			if tabsDict[current_tab]:
				tabsDict[current_tab].hide()
	
	current_tab = _tab
	
	if current_tab:
		current_tab.disabled = true
		if current_tab in tabsDict:
			if tabsDict[current_tab]:
				tabsDict[current_tab].show()

func free_tab(tab):
	if tab in tabsDict:
		if tabsDict[tab]:
			tabsDict[tab].queue_free()
	
	tabsDict.erase(tab)
	tab.queue_free()
	
	if current_tab == tab:
		set_tab(home_tab)


func _on_home_pressed() -> void:
	set_tab(home_tab)

func _on_settings_pressed() -> void:
	set_tab(settings_tab)

var tabs_minimized = true

func _on_menu_pressed() -> void:
	tabs_minimized = not tabs_minimized
	update_tabs()
	
	

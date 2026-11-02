extends VBoxContainer

@export var LangContent: Node
@export var ElementPlaceholder: Button
@export var DescText: Node

var _language_list_dirty := true

func _ready() -> void:
	ElementPlaceholder.hide()
	LocalizationAPI.global_language_changed.connect(on_global_lc)
	LocalizationAPI.language_bank_updated.connect(_on_language_bank_updated)
	on_global_lc()
	_on_language_bank_updated()

func on_global_lc():
	DescSelect(LocalizationAPI.global_language)
	
	var pt = DescText.get_parent().get_parent().get_theme_stylebox("panel").duplicate()
	pt.border_color = COLORS.get_color("UI.GRAY")
	DescText.get_parent().get_parent().add_theme_stylebox_override("panel", pt)

func _on_language_bank_updated() -> void:
	_language_list_dirty = true
	if is_visible_in_tree():
		on_updated_lbu()


func on_updated_lbu():
	for i in LangContent.get_children():
		i.queue_free()
	#LangList.clear()
	
	var index = 0
	for i in LocalizationAPI.LanguageBank.keys():
		var s = ElementPlaceholder.duplicate()
		LangContent.add_child(s)
		s.disabled = false
		s.show()
		
		s.real_text_icon_left = "[emb offset=3]"+i
		s.real_text_icon_right = LocalizationAPI.translate_text("[emb offset=3]|version|", i)
		
		if LocalizationAPI.has_text("displayName", i):
			s.real_text = LocalizationAPI.translate_text("[emb]|displayName|", i)
		else:
			s.real_text = i
			
		s.pressed.connect(func(): 
			LangContent_select(index)
			
	
			if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
				if "Settings.Language" in SaveDataAPI.data:
					SaveDataAPI.data["Settings.Language"] = LocalizationAPI.LanguageBank.keys()[index]
					SaveDataAPI.save_data()
			)
		s.mouse_entered.connect(func():
			DescSelect(i)
			
			var pt = DescText.get_parent().get_parent().get_theme_stylebox("panel").duplicate()
			pt.border_color = COLORS.get_color("UI.YELLOW")
			DescText.get_parent().get_parent().add_theme_stylebox_override("panel", pt)
			)
		s.mouse_exited.connect(func():
			DescSelect(LocalizationAPI.global_language)
			
			var pt = DescText.get_parent().get_parent().get_theme_stylebox("panel").duplicate()
			pt.border_color = COLORS.get_color("UI.GRAY")
			DescText.get_parent().get_parent().add_theme_stylebox_override("panel", pt)
			)
		index += 1
	_language_list_dirty = false
	
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings.Language" in SaveDataAPI.data:
			#LangList.select(LocalizationAPI.LanguageBank.keys().find(SaveDataAPI.data["Settings.Language"]))
			#LangContent
			LangContent_select(LocalizationAPI.LanguageBank.keys().find(SaveDataAPI.data["Settings.Language"]))
			#LangList.select(LocalizationAPI.LanguageBank.keys().find(SaveDataAPI.data["Settings.Language"]))

func LangContent_select(index):
	if index != -1:
		if index < len(LocalizationAPI.LanguageBank.keys()):
			LocalizationAPI.set_global_language(LocalizationAPI.LanguageBank.keys()[index])
		
		for i in LangContent.get_children():
			i.disabled = false
		if index < LangContent.get_child_count():
			LangContent.get_child(index).disabled = true

func DescSelect(lang):
	DescText.real_text = LocalizationAPI.translate_text(
'''[emb]|Name|: |displayName|
|File|: '''+lang+'''.properties
|Version|: |version|
|MajorVersion|: |majorVersion|

|description|'''
, lang)


func _on_reload_pressed() -> void:
	LocalizationAPI.refresh_lang()


func _on_visibility_changed() -> void:
	if _language_list_dirty:
		on_updated_lbu()

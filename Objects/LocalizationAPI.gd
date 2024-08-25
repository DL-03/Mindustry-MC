@tool
extends Node


signal language_bank_updated
signal global_language_changed

var LanguageBank = {}




var global_language = ""
func set_global_language(language: String):
	if language == null:
		return
	
	language = str(language)
	global_language = language
	
	global_language_changed.emit()

func reload_language_bank():
	if DirAccess.dir_exists_absolute("user://Languages"):
		LanguageBank = {}
		for i in DirAccess.get_files_at("user://Languages"):
			if i.get_extension().to_lower() == "properties":
				var lang = i.get_file().split(".")[0]
				
				var file = FileAccess.open("user://Languages".path_join(i), FileAccess.READ)
				
				var res = PropertiesReader.parse(file.get_as_text())
				
				LanguageBank.merge({lang: res}, true)
		language_bank_updated.emit()
		set_global_language(global_language)
	#current_language = current_language
	#change_current_language.emit()


func _OnCreated(path: String):
	LocalizationAPI.reload_language_bank()
func _OnChanged(path: String):
	LocalizationAPI.reload_language_bank()
func _OnRenamed(path: String, path1: String):
	LocalizationAPI.reload_language_bank()
func _OnDeleted(path: String):
	LocalizationAPI.reload_language_bank()
# Called when the node enters the scene tree for the first time.



func recursive_find(text="", target = "",result=[]):
	result.erase(-1)
	if result.is_empty():
		result.append(text.find(target))
		if result[-1] == -1:
			return result
		else:
			recursive_find(text,target,result)
			return result
	else:
		result.append(text.find(target, result[-1]))
		if result[-1] == result[-2] or result[-1] == -1:
			return result
		else:
			recursive_find(text,target,result)
			return result


var RequestLanguages = HTTPRequest.new()

func RequestLanguages_completed(result, response_code, headers, body):
	print("[RequestLanguages][code]: ", result)
	print("[RequestLanguages][response_code]: ", response_code)
	#print("[RequestLanguages][headers]: ", headers)

	var parser = XMLParser.new()
	parser.open_buffer(body)
	
	
	var Result_Lang = []
	
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			var node_name = parser.get_node_name()
			var attributes_dict = {}
			for idx in range(parser.get_attribute_count()):
				attributes_dict[parser.get_attribute_name(idx)] = parser.get_attribute_value(idx)
			
			if node_name == "a":
				#print(attributes_dict)
				if "aria-label" in attributes_dict:
					#print("[JJJ]aria-label: ",attributes_dict["aria-label"].find(".properties, (File)"))
					if attributes_dict["aria-label"].find(".properties, (File)") != -1:
						print("[JJJ]PROP LANG: ",attributes_dict["title"])
						if not Result_Lang.has(attributes_dict["title"]):
							Result_Lang.append(attributes_dict["title"])

	
	for l in Result_Lang:
		var path_request = "https://raw.githubusercontent.com/DL-03/Mindustry-MC-Upgrade-Files/main/Languages/"+l
		
		var https_requests1 = HTTPRequest.new()
		add_child(https_requests1)
		
		https_requests1.request_completed.connect(func(result, response_code, headers, body):
			print("[DownloadLanguage][START]: ",l)
			print("[DownloadLanguage][code]: ", result)
			print("[DownloadLanguage][response_code]: ", response_code)
			#print("[DownloadLanguage][headers]: ", headers)
			
			#print("[DownloadLanguage][body]: ", body.get_string_from_utf8())
			if not DirAccess.dir_exists_absolute("user://Languages"):
				DirAccess.make_dir_recursive_absolute("user://Languages")
			
			
			#if PropertiesReader.parse(body.get_string_from_utf8())["version"] > LocalizationAPI.LanguageBank
			
			var file = FileAccess.open("user://Languages/"+l,FileAccess.WRITE)
			file.store_string(body.get_string_from_utf8())
			file.close()
			
			https_requests1.queue_free()
			)


		
		https_requests1.request(path_request)
	if Result_Lang.is_empty() and response_code == 200:
		RequestLanguages.request("https://github.com/DL-03/Mindustry-MC-Upgrade-Files/tree/main/Languages")
	


func _ready():
	add_child(RequestLanguages)
	RequestLanguages.request_completed.connect(RequestLanguages_completed)
	
	if not DirAccess.dir_exists_absolute("user://Languages"):
		DirAccess.make_dir_recursive_absolute("user://Languages")
	
	var sc = preload("res://Objects/CustomFileWathcer.cs")
	var customFileWathcer = sc.new()
	add_child(customFileWathcer)
	customFileWathcer.OnCreated.connect(_OnCreated)
	customFileWathcer.OnChanged.connect(_OnChanged)
	customFileWathcer.OnRenamed.connect(_OnRenamed)
	customFileWathcer.OnDeleted.connect(_OnDeleted)
	customFileWathcer.setPath(ProjectSettings.globalize_path("user://Languages/"))
	

	
	
	
	
	RequestLanguages.request("https://github.com/DL-03/Mindustry-MC-Upgrade-Files/tree/main/Languages")
	
	
	
	
	
	reload_language_bank()
	
	SaveDataAPI.data_loaded.connect(func():
		set_global_language(SaveDataAPI.data["Settings"]["Language"])
	)
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings" in SaveDataAPI.data:
			if "Language" in SaveDataAPI.data["Settings"]:
				set_global_language(SaveDataAPI.data["Settings"]["Language"])
	
	
	var timer = Timer.new()
	timer.wait_time = 180
	timer.timeout.connect(func():
		RequestLanguages.request("https://github.com/DL-03/Mindustry-MC-Upgrade-Files/tree/main/Languages")
		#timer.start()
		)
	timer.autostart = true
	
	add_child(timer)





func refresh_lang():
	RequestLanguages.request("https://github.com/DL-03/Mindustry-MC-Upgrade-Files/tree/main/Languages")


func has_text(text = "", language = null):
	if text == null:
		return ""
	text = str(text)
	
	
	
	var language_choise = global_language
	if language != null:
		language_choise = language
		
	
	if language_choise in LanguageBank:
		if text in LanguageBank[language_choise]:
			return true
	return false

func translate_text(text = "", language = null):
	if text == null:
		return ""
	text = str(text)
	
	var text_list = text.split("|")
	
	var result = ""
	
	var language_choise = global_language
	if language != null:
		language_choise = language
	
	for i in text_list:
		if language_choise in LanguageBank:
			if i in LanguageBank[language_choise]:
				result += translate_text(LanguageBank[language_choise][i])
			else:
				result += i
		else:
			result += i
	return result
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

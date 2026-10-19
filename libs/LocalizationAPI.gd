@tool
extends Node

signal language_bank_updated
signal global_language_changed

var LanguageBank: Dictionary = {}
var global_language: String = ""

const LANGUAGES_DIR: String = "user://Languages"
const GITHUB_API_URL: String = "https://api.github.com/repos/DL-03/Mindustry-MC-Upgrade-Files/contents/Languages"
const HTTP_HEADERS: PackedStringArray = [
	"User-Agent: GodotEngine/4.x",
	"Accept: application/vnd.github.v3+json"
]

var request_languages: HTTPRequest

func _ready() -> void:
	_ensure_directory_exists()
	_setup_file_watcher()
	_setup_http_request()
	
	# Первоначальная загрузка локальных файлов из user://Languages
	reload_language_bank()
	
	# Подключение к SaveDataAPI (если синглтон доступен в автозагрузке)
	if SaveDataAPI:
		if SaveDataAPI.has_signal("data_loaded"):
			SaveDataAPI.data_loaded.connect(_on_save_data_loaded)
		if "data" in SaveDataAPI and typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
			if "Settings.Language" in SaveDataAPI.data:
				set_global_language(SaveDataAPI.data["Settings.Language"])
	else:
		push_error("[LocalizationAPI] Отвал SaveDataAPI")

	# Запрос обновления файлов с GitHub API
	refresh_lang()

	# Автоматический запрос обновлений каждые 3 минуты (180 сек)
	var timer = Timer.new()
	timer.wait_time = 180.0
	timer.autostart = true
	timer.timeout.connect(refresh_lang)
	add_child(timer)

# --- Инициализация и системные методы ---

func _ensure_directory_exists() -> void:
	if not DirAccess.dir_exists_absolute(LANGUAGES_DIR):
		DirAccess.make_dir_recursive_absolute(LANGUAGES_DIR)

func _setup_http_request() -> void:
	request_languages = HTTPRequest.new()
	add_child(request_languages)
	request_languages.request_completed.connect(_on_request_languages_completed)

func _setup_file_watcher() -> void:
	if CustomFileWatcher:
		var custom_file_watcher = CustomFileWatcher.new()
		add_child(custom_file_watcher)
		
		custom_file_watcher.OnCreated.connect(_on_file_changed)
		custom_file_watcher.OnChanged.connect(_on_file_changed)
		custom_file_watcher.OnRenamed.connect(_on_file_renamed)
		custom_file_watcher.OnDeleted.connect(_on_file_changed)
			
		var global_path = ProjectSettings.globalize_path(LANGUAGES_DIR)
		custom_file_watcher.setPath(global_path)
	else:
		push_warning("[LocalizationAPI] C# класс CustomFileWatcher не найден или не скомпилирован.")

# --- Управление языком и банком локализации ---

func set_global_language(language: Variant) -> void:
	if language == null:
		return
	
	global_language = str(language)
	global_language_changed.emit()

func reload_language_bank() -> void:
	if not DirAccess.dir_exists_absolute(LANGUAGES_DIR):
		return
		
	LanguageBank.clear()
	var files = DirAccess.get_files_at(LANGUAGES_DIR)
	
	for file_name in files:
		if file_name.get_extension().to_lower() == "properties":
			var lang_key = file_name.get_basename()
			var full_path = LANGUAGES_DIR.path_join(file_name)
			
			var file = FileAccess.open(full_path, FileAccess.READ)
			if file:
				var content = file.get_as_text()
				file.close()
				
				var res = PropertiesReader.parse(content)
				LanguageBank[lang_key] = res
	
	language_bank_updated.emit()
	set_global_language(global_language)

# --- Загрузка обновлений через GitHub REST API ---

func refresh_lang() -> void:
	if request_languages and request_languages.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		request_languages.request(GITHUB_API_URL, HTTP_HEADERS)

func _on_request_languages_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_error("[LocalizationAPI] Ошибка запроса к GitHub API. Код ответа: %d" % response_code)
		return

	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	if parse_result != OK:
		push_error("[LocalizationAPI] Ошибка парсинга JSON от GitHub API.")
		return

	var data = json.data
	if typeof(data) != TYPE_ARRAY:
		return

	for item in data:
		if typeof(item) == TYPE_DICTIONARY and item.get("type") == "file":
			var file_name: String = item.get("name", "")
			var download_url: String = item.get("download_url", "")
			
			if file_name.get_extension().to_lower() == "properties" and not download_url.is_empty():
				_download_language_file(file_name, download_url)

func _download_language_file(file_name: String, download_url: String) -> void:
	var http_downloader = HTTPRequest.new()
	add_child(http_downloader)
	
	http_downloader.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var content_str = body.get_string_from_utf8()
			var parsed_props = PropertiesReader.parse(content_str)
			
			var server_version = parsed_props.get("version", null)
			var lang_key = file_name.get_basename()
			var client_version = null
			
			if lang_key in LanguageBank and typeof(LanguageBank[lang_key]) == TYPE_DICTIONARY:
				client_version = LanguageBank[lang_key].get("version", null)
				
			var should_update = false
			if server_version != null:
				if client_version == null:
					should_update = true
				elif float(server_version) > float(client_version):
					should_update = true
					
			if should_update:
				_ensure_directory_exists()
				var save_path = LANGUAGES_DIR.path_join(file_name)
				var file = FileAccess.open(save_path, FileAccess.WRITE)
				if file:
					file.store_string(content_str)
					file.close()
					print("[LocalizationAPI] Скачан/обновлен языковой файл: ", file_name)
					
		http_downloader.queue_free()
	)
	
	http_downloader.request(download_url, HTTP_HEADERS)

# --- Методы проверки и перевода текста ---

func has_text(text: Variant = "", language: Variant = null) -> bool:
	if text == null:
		return false
	var text_str = str(text)
	var lang_choice = global_language if language == null else str(language)
	
	if lang_choice in LanguageBank and typeof(LanguageBank[lang_choice]) == TYPE_DICTIONARY:
		return text_str in LanguageBank[lang_choice]
	return false

func translate_text(text: Variant = "", language: Variant = null) -> String:
	if text == null:
		return ""
	var text_str = str(text)
	var lang_choice = global_language if language == null else str(language)
	
	var text_list = text_str.split("|")
	var result = ""
	
	for key in text_list:
		if lang_choice in LanguageBank and typeof(LanguageBank[lang_choice]) == TYPE_DICTIONARY:
			if key in LanguageBank[lang_choice]:
				result += translate_text(LanguageBank[lang_choice][key], lang_choice)
			else:
				result += key
		else:
			result += key
			
	return result

# --- Обработчики сигналов ---

func _on_file_changed(_path: String) -> void:
	reload_language_bank()

func _on_file_renamed(_old_path: String, _new_path: String) -> void:
	reload_language_bank()

func _on_save_data_loaded() -> void:
	var save_data_node = get_node_or_null("/root/SaveDataAPI")
	if save_data_node and "data" in save_data_node:
		if typeof(save_data_node.data) == TYPE_DICTIONARY and "Settings.Language" in save_data_node.data:
			set_global_language(save_data_node.data["Settings.Language"])

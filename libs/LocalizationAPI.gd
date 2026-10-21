@tool
extends Node

signal language_bank_updated
signal global_language_changed

var LanguageBank: Dictionary = {}
var global_language: String = ""

const LANGUAGES_DIR: String = "user://Languages"
const BUNDLED_LANGUAGES_DIR := "res://languages"
const LANGUAGE_MAJOR_VERSION := 2
const GITHUB_API_URL: String = "https://api.github.com/repos/DL-03/Mindustry-MC-Upgrade-Files/contents/languages"
const APP_LATEST_RELEASE_URL: String = "https://api.github.com/repos/DL-03/Mindustry-MC/releases/latest"
const HTTP_HEADERS: PackedStringArray = [
	"User-Agent: GodotEngine/4.x",
	"Accept: application/vnd.github.v3+json"
]

var request_languages: HTTPRequest
var request_app_version: HTTPRequest
var _show_app_version_check_result := false
var _notified_update_tag := ""
var _last_app_version_check_error := ""

func _ready() -> void:
	_ensure_directory_exists()
	_setup_file_watcher()
	_setup_http_request()
	_setup_app_version_check()
	
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
	check_app_version()

	var language_timer := Timer.new()
	language_timer.wait_time = 180.0
	language_timer.autostart = true
	language_timer.timeout.connect(refresh_lang)
	add_child(language_timer)

	var app_update_timer := Timer.new()
	app_update_timer.wait_time = 300.0
	app_update_timer.autostart = true
	app_update_timer.timeout.connect(func(): check_app_version())
	add_child(app_update_timer)

# --- Инициализация и системные методы ---

func _ensure_directory_exists() -> void:
	if not DirAccess.dir_exists_absolute(LANGUAGES_DIR):
		DirAccess.make_dir_recursive_absolute(LANGUAGES_DIR)

func _setup_http_request() -> void:
	request_languages = HTTPRequest.new()
	add_child(request_languages)
	request_languages.request_completed.connect(_on_request_languages_completed)

func _setup_app_version_check() -> void:
	request_app_version = HTTPRequest.new()
	request_app_version.timeout = 10.0
	add_child(request_app_version)
	request_app_version.request_completed.connect(_on_app_version_check_completed)

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
	LanguageBank.clear()

	var bundled_directory := BUNDLED_LANGUAGES_DIR.path_join("v%d" % LANGUAGE_MAJOR_VERSION)
	var bundled_packs := _read_language_packs(bundled_directory)
	var user_packs := _read_language_packs(LANGUAGES_DIR)
	LanguageBank = _select_language_packs(bundled_packs, user_packs)
	
	language_bank_updated.emit()
	set_global_language(global_language)


func _select_language_packs(bundled_packs: Dictionary, user_packs: Dictionary) -> Dictionary:
	var selected_packs := bundled_packs.duplicate()
	for lang_key in user_packs:
		var user_pack: Dictionary = user_packs[lang_key]
		var bundled_pack: Dictionary = selected_packs.get(lang_key, {})
		if bundled_pack.is_empty() \
				or _compare_language_pack_versions(user_pack, bundled_pack) >= 0:
			selected_packs[lang_key] = user_pack
	return selected_packs


func _read_language_packs(directory_path: String) -> Dictionary:
	var packs: Dictionary = {}
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return packs

	for file_name in directory.get_files():
		if file_name.get_extension().to_lower() != "properties":
			continue
		var full_path := directory_path.path_join(file_name)
		var file := FileAccess.open(full_path, FileAccess.READ)
		if file == null:
			push_warning("[LocalizationAPI] Could not read language pack: %s" % full_path)
			continue
		var parsed: Dictionary = PropertiesReader.parse(file.get_as_text())
		file.close()
		if _is_supported_language_pack(parsed):
			packs[file_name.get_basename()] = parsed
	return packs


func _is_supported_language_pack(pack: Dictionary) -> bool:
	var major_version: Variant = pack.get("majorVersion", null)
	return major_version != null \
		and str(major_version).is_valid_int() \
		and int(major_version) == LANGUAGE_MAJOR_VERSION \
		and pack.has("version") \
		and str(pack["version"]).is_valid_float()


func _is_language_pack_newer(candidate: Dictionary, current: Dictionary) -> bool:
	return _compare_language_pack_versions(candidate, current) > 0


func _compare_language_pack_versions(candidate: Dictionary, current: Dictionary) -> int:
	var candidate_major := int(candidate.get("majorVersion", 0))
	var current_major := int(current.get("majorVersion", 0))
	if candidate_major != current_major:
		return 1 if candidate_major > current_major else -1

	var candidate_version := float(candidate.get("version", 0.0))
	var current_version := float(current.get("version", 0.0))
	if is_equal_approx(candidate_version, current_version):
		return 0
	return 1 if candidate_version > current_version else -1


# --- Загрузка обновлений через GitHub REST API ---

func check_app_version(show_result := false) -> void:
	_show_app_version_check_result = _show_app_version_check_result or show_result
	if request_app_version == null:
		_report_app_version_check_failure("version checker is not initialized")
		return
	if request_app_version.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var err := request_app_version.request(APP_LATEST_RELEASE_URL, HTTP_HEADERS)
	if err != OK:
		_report_app_version_check_failure(error_string(err))


func _on_app_version_check_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_report_app_version_check_failure(
			"request failed (result %d, HTTP %d)" % [result, response_code]
		)
		return
	_last_app_version_check_error = ""

	var json := JSON.new()
	var parse_error := json.parse(body.get_string_from_utf8())
	if parse_error != OK or typeof(json.data) != TYPE_DICTIONARY:
		_report_app_version_check_failure("GitHub returned an invalid release response")
		return

	var latest_version := str(json.data.get("tag_name", "")).strip_edges()
	var current_version := str(ProjectSettings.get_setting("application/config/version", "0.0.0"))
	if not _is_valid_app_version(latest_version):
		_report_app_version_check_failure("release has an invalid tag: %s" % latest_version)
		return
	if not _is_valid_app_version(current_version):
		_report_app_version_check_failure("project has an invalid version: %s" % current_version)
		return

	if _is_newer_app_version(latest_version, current_version):
		if _notified_update_tag != latest_version or _show_app_version_check_result:
			Notifications.warning("Update available: %s (installed: %s)" % [
				latest_version.trim_prefix("v"),
				current_version
			])
			_notified_update_tag = latest_version
	elif _show_app_version_check_result:
		Notifications.info("The application is up to date (%s)." % current_version)

	_show_app_version_check_result = false


func _report_app_version_check_failure(message: String) -> void:
	if _last_app_version_check_error != message:
		push_warning("[LocalizationAPI] Version check failed: %s" % message)
		_last_app_version_check_error = message
	if _show_app_version_check_result:
		Notifications.warning("Could not check for application updates.")
	_show_app_version_check_result = false


func _is_valid_app_version(version: String) -> bool:
	var components := version.trim_prefix("v").split(".")
	if components.size() != 3:
		return false
	for component in components:
		if not component.is_valid_int() or component.to_int() < 0:
			return false
	return true


func _is_newer_app_version(latest_version: String, current_version: String) -> bool:
	var latest := latest_version.trim_prefix("v").split(".")
	var current := current_version.trim_prefix("v").split(".")
	for index in range(3):
		var latest_component := latest[index].to_int()
		var current_component := current[index].to_int()
		if latest_component != current_component:
			return latest_component > current_component
	return false


func refresh_lang() -> void:
	if request_languages and request_languages.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		request_languages.request("%s/v%d" % [GITHUB_API_URL, LANGUAGE_MAJOR_VERSION], HTTP_HEADERS)

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
			var server_major: Variant = parsed_props.get("majorVersion", null)
			if not _is_supported_language_pack(parsed_props):
				push_warning("[LocalizationAPI] Language pack has no valid majorVersion: %s" % file_name)
				http_downloader.queue_free()
				return

			var lang_key = file_name.get_basename()
			var client_data: Dictionary = LanguageBank.get(lang_key, {})
			var should_update := client_data.is_empty() or _is_language_pack_newer(parsed_props, client_data)

			if should_update:
				var current_path := LANGUAGES_DIR.path_join(file_name)
				var local_data := _read_language_file(current_path) if FileAccess.file_exists(current_path) else {}
				var local_major: Variant = local_data.get("majorVersion", null)
				if not local_data.is_empty() and local_major != null \
						and str(local_major).is_valid_int() \
						and int(local_major) != int(server_major):
					if not _backup_language_pack(current_path, int(local_major), file_name):
						http_downloader.queue_free()
						return

				_ensure_directory_exists()
				var file := FileAccess.open(current_path, FileAccess.WRITE)
				if file == null:
					push_error("[LocalizationAPI] Could not write language pack: %s" % current_path)
				else:
					file.store_string(content_str)
					file.close()
					reload_language_bank()
					print("[LocalizationAPI] Скачан/обновлен языковой файл: ", file_name)
					
		http_downloader.queue_free()
	)
	
	http_downloader.request(download_url, HTTP_HEADERS)


func _read_language_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Dictionary = PropertiesReader.parse(file.get_as_text())
	file.close()
	return parsed


func _backup_language_pack(
	source_path: String,
	major_version: int,
	file_name: String,
	backup_root: String = ""
) -> bool:
	if backup_root.is_empty():
		backup_root = LANGUAGES_DIR.path_join("backups")
	var backup_directory: String = backup_root.path_join("v%d" % major_version)
	var err := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(backup_directory))
	if err != OK:
		push_error("[LocalizationAPI] Could not create language backup directory: %s" % backup_directory)
		return false

	var backup_path := backup_directory.path_join(file_name)
	if FileAccess.file_exists(backup_path):
		return true

	var source := FileAccess.open(source_path, FileAccess.READ)
	if source == null:
		push_error("[LocalizationAPI] Could not read language pack for backup: %s" % source_path)
		return false
	var backup := FileAccess.open(backup_path, FileAccess.WRITE)
	if backup == null:
		push_error("[LocalizationAPI] Could not write language backup: %s" % backup_path)
		source.close()
		return false

	backup.store_buffer(source.get_buffer(source.get_length()))
	source.close()
	backup.close()
	return true

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
	var lang_choice = global_language if language == null else str(language)
	return _translate_text(str(text), lang_choice, {})


func _translate_text(text: String, language: String, resolving_keys: Dictionary) -> String:
	var text_list := text.split("|")
	var result = ""
	
	for key in text_list:
		if language in LanguageBank and typeof(LanguageBank[language]) == TYPE_DICTIONARY:
			if key in LanguageBank[language]:
				if resolving_keys.has(key):
					result += key
					continue

				var nested_keys := resolving_keys.duplicate()
				nested_keys[key] = true
				result += _translate_text(str(LanguageBank[language][key]), language, nested_keys)
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

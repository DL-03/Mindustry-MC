extends Control

@export var notificationPrefab: PackedScene
@export var listElement: Node
@export var timer: Timer

var Messages = []

enum Type {
	DEFAULT,
	INFO,
	WARNING,
	ERROR,
	SUCCESS,
	DEBUG,
	CUSTOM
}

func info(_text=""):
	toast(_text, Type.INFO)
func warning(_text=""):
	toast(_text, Type.WARNING)
func error(_text=""):
	toast(_text, Type.ERROR)
func success(_text=""):
	toast(_text, Type.SUCCESS)
func debug(_text=""):
	toast(_text, Type.DEBUG)

func toast(_text="", _type = Type.DEFAULT):
	if _text=="":
		return

	var _message = _text
	var _message_for_console = _text
	
	match _type:
		Type.DEFAULT:
			_message = "[emb]"+_message
			_message_for_console = "[N]: "+_message_for_console
		Type.INFO:
			_message = "[emb offset=3][BLUE][/emb]  [][emb]"+_message
			_message_for_console = "[N][BLUE][INFO][]: "+_message_for_console
		Type.WARNING:
			_message = "[emb offset=3][UI.YELLOW]⚠[/emb]  [][emb]"+_message
			_message_for_console = "[N][UI.YELLOW][WARN][]: "+_message_for_console
		Type.ERROR:
			_message = "[emb offset=3][UI.RED][/emb]  [][emb]"+_message
			_message_for_console = "[N][UI.RED][ERROR][]: "+_message_for_console
		Type.SUCCESS:
			_message = "[emb offset=3][UI.GREEN][/emb]  [][emb]"+_message
			_message_for_console = "[N][UI.GREEN][SUCCESS][]: "+_message_for_console
		Type.DEBUG:
			_message = "[emb offset=3][PINK][/emb]  [][emb]"+_message
			_message_for_console = "[N][PINK][DEBUG][]: "+_message_for_console
		_:
			_message_for_console = "[N]: "+_message_for_console
	
	print_rich(COLORS.colorita(LocalizationAPI.translate_text(_message_for_console)))
	
	if _type == Type.DEBUG:
		if "Settings" in SaveDataAPI.data:
			if "Debug" in SaveDataAPI.data["Settings"]:
				if not SaveDataAPI.data["Settings"]["Debug"]:
					return
	
	if not notificationPrefab:
		print_rich(COLORS.colorita(LocalizationAPI.translate_text("[Notification][UI.RED][ERROR][]: Notification prefab not found!")))
	
	var s = notificationPrefab.instantiate()
	s.text = _message
	
	listElement.add_child(s)
	listElement.move_child(s,0)
	
	Messages.append(s)

func _ready() -> void:
	SaveDataAPI.data_changed.connect(on_updated_settings)
	on_updated_settings()
	
	upd()

func upd():
	move_to_front()
	visible = listElement.get_child_count() > 0

func _on_list_child_order_changed() -> void:
	upd()

func on_updated_settings():
	if typeof(SaveDataAPI.data) == TYPE_DICTIONARY:
		if "Settings" in SaveDataAPI.data:
			if "saveMessageFrequency" in SaveDataAPI.data["Settings"]:
				timer.wait_time = SaveDataAPI.data["Settings"]["saveMessageFrequency"]
				timer.stop()
				timer.start()

func _on_timer_timeout() -> void:
	info("|DontForgetSave|")

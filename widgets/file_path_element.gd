@tool
extends HBoxContainer

@export var path: String = "":
	set = _set_path

func _ready() -> void:
	upd()

func _set_path(_path)->void:
	path = _path
	upd()

func upd():
	var CopyButton = get_node_or_null("Copy")
	if not CopyButton:
		return
	if not CopyButton.is_node_ready():
		await CopyButton.ready
	
	var ext = path.get_extension()
	var basename = path.get_basename()
	var rpath = basename
	if ext != "":
		rpath = basename+"[UI.YELLOW]."+ext
	
	CopyButton.get_node("MarginContainer/Label").real_text = "[emb]"+rpath
	CopyButton.get_node("MindTooltip").tooltip_text = "[center][emb][UI.YELLOW]|CopyPath|!\n[]"+rpath
	
	var OpenButton = get_node_or_null("Open")
	if not OpenButton:
		return
	if not OpenButton.is_node_ready():
		await OpenButton.ready
		
	OpenButton.get_node("MindTooltip").tooltip_text = "[center][emb][UI.YELLOW]|OpenFolder|!\n[]"+rpath

func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set(path)
	Notifications.info("|PathCopied|!")

func _on_open_pressed() -> void:
	OS.shell_show_in_file_manager(path)

extends PanelContainer

var cr = ContentCore
var ctype = cr.ContentType

signal changed

var signals = [changed, content_type_changed]

func clear_connections():
	for s in signals:
		for i in s.get_connections():
			s.disconnect(i.callable)

var FContentType: Dictionary[ContentCore.ContentType, bool] = {}
@export var ContentTypeButtons: Dictionary[ContentCore.ContentType, Node] = {}
signal content_type_changed

func ctype_import(_ctype):
	for k in FContentType:
		FContentType[k] = _ctype[k]
	
	reload()

func reload() -> void:
	for k in ContentTypeButtons.keys():
		var v = ContentTypeButtons[k]
		if k in FContentType:
			v.button_pressed = FContentType[k]

func _on_ctype_toggled(toggled_on: bool, _ctype:ContentCore.ContentType):
	FContentType.set(_ctype, toggled_on)
	content_type_changed.emit()
	changed.emit()

func _ready() -> void:
	for i in ctype.values():
		FContentType.set(i, true)

	reload()
	
	for k in ContentTypeButtons:
		var v = ContentTypeButtons[k]
		if k in FContentType:
			v.button_pressed = FContentType[k]
		v.toggled.connect(_on_ctype_toggled.bind(k))

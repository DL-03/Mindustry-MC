extends Control

const MindIButtonScene = preload("res://widgets/mind_i_button.tscn")

var _workspace: Variant
var _groups_created := 2
var _tabs_created := 3
var _status_label: Label
var _tabs_vertical_toggle: CheckButton
var _compact_toggle: CheckButton
var _split_vertical_toggle: CheckButton
var _move_button: Button


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var outer_margin := MarginContainer.new()
	outer_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer_margin.add_theme_constant_override("margin_left", 12)
	outer_margin.add_theme_constant_override("margin_top", 10)
	outer_margin.add_theme_constant_override("margin_right", 12)
	outer_margin.add_theme_constant_override("margin_bottom", 10)
	add_child(outer_margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 8)
	outer_margin.add_child(page)

	var title := Label.new()
	title.text = "MMC — полигон интерфейса"
	title.add_theme_font_size_override("font_size", 22)
	page.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "F6 — запуск полигона. Перетаскивайте вкладки в полосы и области содержимого, заголовки групп — для перестановки панелей."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(subtitle)

	var toolbar_scroll := ScrollContainer.new()
	toolbar_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	toolbar_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	toolbar_scroll.custom_minimum_size.y = 42
	page.add_child(toolbar_scroll)

	var toolbar := HFlowContainer.new()
	toolbar.add_theme_constant_override("h_separation", 6)
	toolbar.add_theme_constant_override("v_separation", 5)
	toolbar_scroll.add_child(toolbar)

	_tabs_vertical_toggle = _add_toggle(toolbar, "Вкладки сбоку")
	_tabs_vertical_toggle.toggled.connect(_on_tabs_vertical_toggled)
	_compact_toggle = _add_toggle(toolbar, "Компактно")
	_compact_toggle.toggled.connect(_on_compact_toggled)
	_split_vertical_toggle = _add_toggle(toolbar, "Группы сверху/снизу")
	_split_vertical_toggle.toggled.connect(_on_split_vertical_toggled)

	_add_action(toolbar, "Новая вкладка", _on_add_content_tab)
	_add_action(toolbar, "Без содержимого", _on_add_empty_tab)
	_add_action(toolbar, "Новая группа", _on_add_group)
	_move_button = _add_action(toolbar, "Перенести вкладку", _on_move_selected_tab)
	_add_action(toolbar, "Переставить панель", _on_move_group)
	_add_action(toolbar, "Закрыть активную", _on_close_selected_tab)
	_add_action(toolbar, "Проверить", _on_run_live_checks)

	_workspace = get_node("TabWorkspace")
	remove_child(_workspace)
	_workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_workspace.custom_minimum_size = Vector2(280, 300)
	_workspace.tab_moved.connect(_on_tab_moved)
	_workspace.group_moved.connect(_on_group_moved)
	var tab_panel_style := StyleBoxFlat.new()
	tab_panel_style.bg_color = Color(0.13, 0.17, 0.18, 0.88)
	tab_panel_style.border_color = Color(0.34, 0.55, 0.48)
	tab_panel_style.set_border_width_all(1)
	tab_panel_style.set_content_margin_all(4)
	_workspace.tab_panel_stylebox = tab_panel_style
	var content_panel_style := StyleBoxFlat.new()
	content_panel_style.bg_color = Color(0.09, 0.12, 0.14, 0.95)
	content_panel_style.border_color = Color(0.38, 0.43, 0.5)
	content_panel_style.set_border_width_all(1)
	content_panel_style.set_content_margin_all(4)
	_workspace.content_panel_stylebox = content_panel_style
	page.add_child(_workspace)

	_status_label = Label.new()
	_status_label.text = "Готово. Выберите вкладку или измените раскладку."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(_status_label)

	var gallery_title := Label.new()
	gallery_title.text = "Галерея элементов Mindustry"
	gallery_title.add_theme_font_size_override("font_size", 18)
	page.add_child(gallery_title)

	var gallery_scroll := ScrollContainer.new()
	gallery_scroll.custom_minimum_size = Vector2(0, 155)
	gallery_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(gallery_scroll)

	var gallery := HFlowContainer.new()
	gallery.add_theme_constant_override("h_separation", 8)
	gallery.add_theme_constant_override("v_separation", 6)
	gallery.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gallery_scroll.add_child(gallery)
	_build_control_gallery(gallery)


func _make_page(heading_text: String, description: String) -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	var heading := Label.new()
	heading.text = heading_text
	heading.add_theme_font_size_override("font_size", 18)
	column.add_child(heading)

	var description_label := Label.new()
	description_label.text = description
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(description_label)

	var field := LineEdit.new()
	field.placeholder_text = "Текстовый ввод для проверки масштаба"
	column.add_child(field)

	var action := Button.new()
	action.theme_type_variation = "ButtonRect"
	action.text = "Демонстрационная кнопка"
	column.add_child(action)
	return margin


func _build_control_gallery(gallery: HFlowContainer) -> void:
	for variation: String in ["ButtonRect", "ButtonRectTiny", "ButtonUnborder", "ButtonUnborderTiny"]:
		var button := Button.new()
		button.theme_type_variation = variation
		button.text = variation
		button.custom_minimum_size = Vector2(138, 38)
		gallery.add_child(button)

	var checkbox := CheckButton.new()
	checkbox.text = "CheckButton"
	gallery.add_child(checkbox)

	var option := OptionButton.new()
	option.add_item("OptionButton")
	option.add_item("Вариант 2")
	gallery.add_child(option)

	var custom_button: MindIButton = MindIButtonScene.instantiate()
	custom_button.custom_minimum_size = Vector2(190, 48)
	custom_button.real_text_icon_left = "⌂"
	custom_button.real_text = "MindIButton"
	custom_button.real_text_icon_right = "›"
	gallery.add_child(custom_button)

func _add_toggle(parent: Control, caption: String) -> CheckButton:
	var toggle := CheckButton.new()
	toggle.text = caption
	parent.add_child(toggle)
	return toggle


func _add_action(parent: Control, caption: String, callback: Callable) -> Button:
	var button := Button.new()
	button.theme_type_variation = "ButtonRect"
	button.text = caption
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _on_tabs_vertical_toggled(value: bool) -> void:
	_workspace.set_tabs_vertical(value)


func _on_compact_toggled(value: bool) -> void:
	_workspace.set_compact_tabs(value)


func _on_split_vertical_toggled(value: bool) -> void:
	_workspace.set_split_vertical(value)


func _on_add_content_tab() -> void:
	_tabs_created += 1
	var tab_id := StringName("sample_%d" % _tabs_created)
	_workspace.add_tab(
		&"main",
		tab_id,
		"Документ %d" % _tabs_created,
		_make_page(
			"Документ %d" % _tabs_created,
			"Новая вкладка создана в основной группе."
		),
		"▤"
	)


func _on_add_empty_tab() -> void:
	_tabs_created += 1
	var tab_id := StringName("nav_%d" % _tabs_created)
	_workspace.add_tab(&"main", tab_id, "Навигация %d" % _tabs_created, null, "⌕")


func _on_add_group() -> void:
	_groups_created += 1
	var group_id := StringName("group_%d" % _groups_created)
	_workspace.add_group("Группа %d" % _groups_created, group_id)
	_status_label.text = "Добавлена группа. Перетащите в неё вкладку или перетащите заголовок группы для перестановки панелей."


func _on_move_selected_tab() -> void:
	var selected: StringName = _workspace.get_selected_tab_id(&"main")
	if selected.is_empty():
		_status_label.text = "В основной группе нет выбранной вкладки."
		return
	var target_id := _first_other_group(&"main")
	if target_id.is_empty():
		_groups_created += 1
		target_id = StringName("group_%d" % _groups_created)
		_workspace.add_group("Группа %d" % _groups_created, target_id)
	_workspace.move_tab(selected, target_id)


func _on_move_group() -> void:
	var group_ids: Array[StringName] = _workspace.get_group_ids()
	if group_ids.size() < 2:
		_status_label.text = "Для перестановки добавьте вторую группу."
		return
	var moved_group: StringName = group_ids[0]
	if _workspace.move_group(moved_group, group_ids.size() - 1):
		_status_label.text = "Панель %s перемещена в конец раскладки." % moved_group


func _on_close_selected_tab() -> void:
	var selected: StringName = _workspace.get_selected_tab_id(&"main")
	if selected.is_empty():
		_status_label.text = "В основной группе нет выбранной вкладки."
	elif not _workspace.close_tab(selected):
		_status_label.text = "Эту вкладку нельзя закрыть."


func _on_tab_moved(tab_id: StringName, source_group: StringName, target_group: StringName) -> void:
	_status_label.text = "Вкладка %s перемещена: %s → %s." % [tab_id, source_group, target_group]


func _on_group_moved(group_id: StringName, target_index: int) -> void:
	_status_label.text = "Панель %s переставлена на позицию %d." % [group_id, target_index + 1]


func _on_run_live_checks() -> void:
	var first_group: StringName = _workspace.get_group_ids()[0]
	var empty_tab_id := StringName("live_empty_%d" % Time.get_ticks_msec())
	var created: bool = _workspace.add_tab(first_group, empty_tab_id, "Проверка без страницы")
	var selectable: bool = created and _workspace.select_tab(first_group, empty_tab_id)
	var closeable: bool = selectable and _workspace.close_tab(empty_tab_id)
	if created and selectable and closeable:
		_status_label.text = "Проверка пройдена: пустая вкладка создаётся, выбирается и закрывается."
	else:
		_status_label.text = "Проверка не пройдена — смотрите ошибки в Output."
		push_error("TabWorkspace live check failed")


func _first_other_group(current_group: StringName) -> StringName:
	for group_id: StringName in _workspace.get_group_ids():
		if group_id != current_group:
			return group_id
	return &""

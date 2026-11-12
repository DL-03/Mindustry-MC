extends Node

var _failures := 0
var _checks := 0


func _ready() -> void:
	_run_tests.call_deferred()


func _run_tests() -> void:
	var mind_button_scene: PackedScene = load("res://widgets/mind_button.tscn")
	var mind_button: Variant = mind_button_scene.instantiate()
	mind_button.label.real_text = "Legacy child text"
	mind_button.get_node("MarginContainer").add_theme_constant_override("margin_left", 7)
	add_child(mind_button)
	await get_tree().process_frame
	_check(
		mind_button.label.real_text == "Legacy child text",
		"MindButton defaults preserve child-authored text"
	)
	_check(
		mind_button.get_node("MarginContainer").get_theme_constant("margin_left") == 7,
		"MindButton defaults preserve child-authored layout"
	)
	mind_button.real_text = "Inspector label"
	_check(
		mind_button.label.real_text == "Inspector label",
		"MindButton text updates its child label"
	)
	mind_button.real_text = ""
	_check(
		mind_button.label.real_text.is_empty()
		and mind_button.label.text.is_empty()
		and mind_button.text.is_empty(),
		"MindButton clears child and native text when real_text is empty"
	)
	mind_button.content_margins = Vector4i(1, 2, 3, 4)
	_check(
		mind_button.get_node("MarginContainer").get_theme_constant("margin_left") == 1,
		"MindButton parent layout settings update the internal margin"
	)
	mind_button.label.real_text = "Updated child"
	await get_tree().process_frame
	_check(
		mind_button.text == "Updated child",
		"MindButton follows child localization/text updates"
	)
	var typed_mind_button: Variant = load("res://widgets/mind_button.gd").new()
	add_child(typed_mind_button)
	await get_tree().process_frame
	_check(
		_native_button_text_is_hidden(typed_mind_button),
		"MindButton hides native text when added by script type"
	)
	_check(
		typed_mind_button.label
		== typed_mind_button.get_node("MarginContainer/Label")
		and typed_mind_button.label.real_text == "[emb]MindButton"
		and typed_mind_button.real_text == "[emb]MindButton"
		and typed_mind_button.label.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"MindButton exposes its type label by default and creates its internal layout"
	)
	typed_mind_button.label_alignment = 0
	typed_mind_button.content_margins = Vector4i(2, 3, 4, 5)
	typed_mind_button.font_size = 18
	_check(
		typed_mind_button.label.horizontal_alignment == HORIZONTAL_ALIGNMENT_LEFT
		and typed_mind_button.get_node("MarginContainer").get_theme_constant("margin_left") == 2
		and typed_mind_button.label.get_theme_font_size("font_size") == 18,
		"MindButton Inspector layout and appearance settings update typed-node preview"
	)

	var mind_label_scene: PackedScene = load("res://widgets/mind_label.tscn")
	var mind_label: Variant = mind_label_scene.instantiate()
	add_child(mind_label)
	await get_tree().process_frame
	mind_label.real_text = "Editor [emb]preview"
	_check(
		mind_label.text == "Editor preview",
		"MindLabel renders markup in the editor preview"
	)

	var mind_rtl_scene: PackedScene = load("res://widgets/mind_rtl.tscn")
	var mind_rtl: Variant = mind_rtl_scene.instantiate()
	add_child(mind_rtl)
	await get_tree().process_frame
	mind_rtl.real_text = "[emb]RTL preview"
	_check(
		mind_rtl.text == "RTL preview",
		"MindRTL renders markup in the editor preview"
	)

	var mind_i_button_scene: PackedScene = load("res://widgets/mind_i_button.tscn")
	var mind_i_button: Variant = mind_i_button_scene.instantiate()
	mind_i_button.label.real_text = "Legacy child label"
	mind_i_button.left_icon.real_text = "legacy icon"
	mind_i_button.get_node("MarginContainer").add_theme_constant_override("margin_left", 8)
	add_child(mind_i_button)
	await get_tree().process_frame
	_check(
		mind_i_button.label.real_text == "Legacy child label"
		and mind_i_button.left_icon.real_text == "legacy icon"
		and mind_i_button.get_node("MarginContainer").get_theme_constant("margin_left") == 8,
		"MindIButton defaults preserve child-authored content and layout"
	)
	mind_i_button.real_text = "Inspector action"
	mind_i_button.real_text_icon_left = "L"
	mind_i_button.real_text_icon_right = "R"
	_check(
		mind_i_button.label.real_text == "Inspector action",
		"MindIButton text updates its child label"
	)
	_check(
		mind_i_button.left_icon.visible and mind_i_button.right_icon.visible,
		"MindIButton shows configured icon labels"
	)
	mind_i_button.real_text = ""
	mind_i_button.real_text_icon_left = ""
	mind_i_button.real_text_icon_right = ""
	_check(
		mind_i_button.label.real_text.is_empty()
		and mind_i_button.label.text.is_empty()
		and mind_i_button.left_icon.real_text.is_empty()
		and mind_i_button.right_icon.real_text.is_empty()
		and mind_i_button.text.is_empty(),
		"MindIButton clears child labels and native text when real_text values are empty"
	)
	mind_i_button.show_left_icon = false
	mind_i_button.show_left_icon = true
	_check(
		mind_i_button.left_icon.visible,
		"MindIButton restores scene-authored icon visibility"
	)
	var typed_mind_i_button: Variant = load("res://widgets/mind_i_button.gd").new()
	add_child(typed_mind_i_button)
	await get_tree().process_frame
	_check(
		_native_button_text_is_hidden(typed_mind_i_button),
		"MindIButton hides native text when added by script type"
	)
	_check(
		typed_mind_i_button.left_icon
		== typed_mind_i_button.get_node("MarginContainer/HBoxContainer/LeftIcon")
		and typed_mind_i_button.label
		== typed_mind_i_button.get_node("MarginContainer/HBoxContainer/Label")
		and typed_mind_i_button.right_icon
		== typed_mind_i_button.get_node("MarginContainer/HBoxContainer/RightIcon")
		and typed_mind_i_button.real_text == "[emb]MindIButton"
		and typed_mind_i_button.real_text_icon_left == "[emb offset=3]0"
		and typed_mind_i_button.real_text_icon_right == "[emb offset=3]0"
		and typed_mind_i_button.get_node_or_null("_MindTooltip") != null,
		"MindIButton exposes type text and icon defaults and creates its full layout"
	)
	_check(
		typed_mind_i_button.get_node("MarginContainer").mouse_filter
		== Control.MOUSE_FILTER_IGNORE
		and typed_mind_i_button.label.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"MindIButton internal controls do not intercept button input"
	)
	typed_mind_i_button.real_text = "Type-created action"
	typed_mind_i_button.real_text_icon_left = "L"
	typed_mind_i_button.content_separation = 9
	typed_mind_i_button.content_margins = Vector4i(3, 4, 5, 6)
	typed_mind_i_button.font_size = 19
	_check(
		typed_mind_i_button.label.real_text == "Type-created action"
		and typed_mind_i_button.left_icon.real_text == "L"
		and typed_mind_i_button.get_node("MarginContainer/HBoxContainer").get_theme_constant(
			"separation"
		) == 9
		and typed_mind_i_button.get_node("MarginContainer").get_theme_constant("margin_left") == 3
		and typed_mind_i_button.label.get_theme_font_size("font_size") == 19,
		"MindIButton Inspector content and layout settings update typed-node preview"
	)

	var setting_row_scene: PackedScene = load("res://widgets/mind_setting_row.tscn")
	var setting_row: Variant = setting_row_scene.instantiate()
	setting_row.title_text = "Autosave"
	setting_row.description_text = "Save changes automatically"
	setting_row.control_scene = mind_i_button_scene
	add_child(setting_row)
	await get_tree().process_frame
	_check(
		setting_row.title_label.real_text == "Autosave"
		and setting_row.description_label.real_text == "Save changes automatically",
		"MindSettingRow previews Inspector-authored text"
	)
	_check(
		setting_row.setting_control is Button,
		"MindSettingRow instantiates a custom setting control scene"
	)
	_check(
		is_instance_valid(setting_row.setting_control.label)
		and setting_row.setting_control.label
		== setting_row.setting_control.get_node("MarginContainer/HBoxContainer/Label"),
		"instantiated control scene preserves references to its internal nodes"
	)

	var mind_button_rtl_scene: PackedScene = load("res://widgets/mind_button_rtl.tscn")
	var mind_button_rtl: Variant = mind_button_rtl_scene.instantiate()
	mind_button_rtl.label.real_text = "Legacy RTL child"
	mind_button_rtl.get_node("MarginContainer").add_theme_constant_override("margin_left", 9)
	add_child(mind_button_rtl)
	await get_tree().process_frame
	_check(
		mind_button_rtl.label.real_text == "Legacy RTL child"
		and mind_button_rtl.get_node("MarginContainer").get_theme_constant("margin_left") == 9,
		"MindButtonRTL defaults preserve child-authored text and layout"
	)
	mind_button_rtl.real_text = "[emb]RTL parent"
	_check(
		mind_button_rtl.label.real_text == "[emb]RTL parent",
		"MindButtonRTL parent text updates the child"
	)
	mind_button_rtl.real_text = ""
	_check(
		mind_button_rtl.label.real_text.is_empty()
		and mind_button_rtl.label.text.is_empty()
		and mind_button_rtl.text.is_empty(),
		"MindButtonRTL clears child and native text when real_text is empty"
	)
	var typed_mind_button_rtl: Variant = load("res://widgets/mind_button_rtl.gd").new()
	add_child(typed_mind_button_rtl)
	await get_tree().process_frame
	_check(
		_native_button_text_is_hidden(typed_mind_button_rtl),
		"MindButtonRTL hides native text when added by script type"
	)
	_check(
		typed_mind_button_rtl.label
		== typed_mind_button_rtl.get_node("MarginContainer/Label")
		and typed_mind_button_rtl.label.real_text == "[emb]MindButtonRTL"
		and typed_mind_button_rtl.real_text == "[emb]MindButtonRTL"
		and typed_mind_button_rtl.label.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"MindButtonRTL exposes its type label by default and creates its internal layout"
	)
	typed_mind_button_rtl.label_alignment = 0
	typed_mind_button_rtl.horizontal_margin = 4
	typed_mind_button_rtl.vertical_margin = 6
	typed_mind_button_rtl.label_font_size = 18
	_check(
		typed_mind_button_rtl.label.horizontal_alignment == HORIZONTAL_ALIGNMENT_LEFT
		and typed_mind_button_rtl.get_node("MarginContainer").get_theme_constant("margin_left") == 4
		and typed_mind_button_rtl.get_node("MarginContainer").get_theme_constant("margin_top") == 6
		and typed_mind_button_rtl.label.get_theme_font_size("normal_font_size") == 18,
		"MindButtonRTL Inspector layout settings update typed-node preview"
	)

	var mind_i_button_rtl_scene: PackedScene = load("res://widgets/mind_i_button_rtl.tscn")
	var mind_i_button_rtl: Variant = mind_i_button_rtl_scene.instantiate()
	mind_i_button_rtl.label.real_text = "Legacy RTL label"
	mind_i_button_rtl.left_icon.real_text = "legacy RTL icon"
	mind_i_button_rtl.get_node("MarginContainer").add_theme_constant_override("margin_left", 10)
	add_child(mind_i_button_rtl)
	await get_tree().process_frame
	_check(
		mind_i_button_rtl.label.real_text == "Legacy RTL label"
		and mind_i_button_rtl.left_icon.real_text == "legacy RTL icon"
		and mind_i_button_rtl.get_node("MarginContainer").get_theme_constant("margin_left") == 10,
		"MindIButtonRTL defaults preserve child-authored content and layout"
	)
	mind_i_button_rtl.real_text = "[emb]RTL parent label"
	_check(
		mind_i_button_rtl.label.real_text == "[emb]RTL parent label",
		"MindIButtonRTL parent text updates the child"
	)
	mind_i_button_rtl.real_text = ""
	mind_i_button_rtl.real_text_icon_left = ""
	mind_i_button_rtl.real_text_icon_right = ""
	_check(
		mind_i_button_rtl.label.real_text.is_empty()
		and mind_i_button_rtl.label.text.is_empty()
		and mind_i_button_rtl.left_icon.real_text.is_empty()
		and mind_i_button_rtl.right_icon.real_text.is_empty()
		and mind_i_button_rtl.text.is_empty(),
		"MindIButtonRTL clears child labels and native text when real_text values are empty"
	)
	_check(
		mind_i_button_rtl.get_node("MarginContainer/HBoxContainer/Label").mouse_filter
		== Control.MOUSE_FILTER_IGNORE
		and mind_i_button_rtl.get_node("MarginContainer").get_theme_constant("margin_left")
		== 10,
		"MindIButtonRTL prefab keeps its layout while allowing button input"
	)

	var mind_i_button_rtl_script: Script = load("res://widgets/mind_i_button_rtl.gd")
	var typed_mind_i_button_rtl: Variant = mind_i_button_rtl_script.new()
	add_child(typed_mind_i_button_rtl)
	await get_tree().process_frame
	_check(
		typed_mind_i_button_rtl.get_node_or_null("MarginContainer/HBoxContainer") != null,
		"MindIButtonRTL added by script type creates its internal layout"
	)
	_check(
		typed_mind_i_button_rtl.left_icon
		== typed_mind_i_button_rtl.get_node("MarginContainer/HBoxContainer/LeftIcon")
		and typed_mind_i_button_rtl.label
		== typed_mind_i_button_rtl.get_node("MarginContainer/HBoxContainer/Label")
		and typed_mind_i_button_rtl.right_icon
		== typed_mind_i_button_rtl.get_node("MarginContainer/HBoxContainer/RightIcon"),
		"MindIButtonRTL added by script type resolves all child exports"
	)
	_check(
		typed_mind_i_button_rtl.real_text == "[emb]MindIButtonRTL"
		and typed_mind_i_button_rtl.real_text_icon_left == "[emb offset=3]0"
		and typed_mind_i_button_rtl.real_text_icon_right == "[emb offset=3]0",
		"MindIButtonRTL exposes its type text and icon defaults"
	)
	_check(
		typed_mind_i_button_rtl.get_node("MarginContainer").mouse_filter
		== Control.MOUSE_FILTER_IGNORE
		and typed_mind_i_button_rtl.get_node("MarginContainer/HBoxContainer").mouse_filter
		== Control.MOUSE_FILTER_IGNORE
		and typed_mind_i_button_rtl.label.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"MindIButtonRTL internal controls do not intercept button input"
	)
	_check(
		typed_mind_i_button_rtl.get_node("MarginContainer").get_theme_constant(
			"margin_left"
		) == 15
		and typed_mind_i_button_rtl.label.get_theme_font_size("normal_font_size") == 16,
		"MindIButtonRTL script-created layout keeps the prefab's default appearance"
	)
	_check(
		_native_button_text_is_hidden(typed_mind_i_button_rtl)
		and not typed_mind_i_button_rtl.label.text.is_empty(),
		"MindIButtonRTL hides the native Button text while keeping the custom label visible"
	)
	var checkbox_scene: PackedScene = load("res://widgets/mind_check_box.tscn")
	var checkbox: Variant = checkbox_scene.instantiate()
	add_child(checkbox)
	await get_tree().process_frame
	checkbox.Checked = true
	_check(
		checkbox.get_node("MarginContainer/Panel/MarginContainer2").visible,
		"MindCheckBox preview follows the exported Checked property"
	)
	checkbox._on_pressed()
	_check(not checkbox.Checked, "MindCheckBox updates state on press")

	var color_editor_scene: PackedScene = load("res://widgets/mind_color_edit.tscn")
	var color_editor: Variant = color_editor_scene.instantiate()
	add_child(color_editor)
	await get_tree().process_frame
	color_editor.Data = Color.CORAL
	_check(
		color_editor.ColorButton.color.is_equal_approx(Color.CORAL),
		"MindColorEdit color picker follows Data"
	)
	_check(
		color_editor.Line_Edit.text == "#" + Color.CORAL.to_html(true),
		"MindColorEdit text field follows Data"
	)

	var category_scene: PackedScene = load("res://widgets/mind_category.tscn")
	var category: Variant = category_scene.instantiate()
	add_child(category)
	await get_tree().process_frame
	category.Data = "liquid"
	_check(
		category.get_node("HFlowContainer/liquid").disabled,
		"MindCategory Inspector selection updates the selected button"
	)
	_check(
		category.get_node("Panel/HBoxContainer/Text").real_text == "liquid",
		"MindCategory Inspector selection updates its preview"
	)

	var tab_scene: PackedScene = load("res://widgets/mind_tab.tscn")
	var tab: Variant = tab_scene.instantiate()
	add_child(tab)
	await get_tree().process_frame
	tab.direction = 3
	_check(
		tab.theme_type_variation == "HTabR",
		"MindTab direction updates its theme variation"
	)

	var closable_tab_scene: PackedScene = load("res://widgets/mind_utab.tscn")
	var closable_tab: Variant = closable_tab_scene.instantiate()
	add_child(closable_tab)
	await get_tree().process_frame
	closable_tab.tab_title = "Editor preview"
	closable_tab.has_changes = false
	_check(
		closable_tab.get_node("MarginContainer/HBoxContainer/Label").real_text
		== "[emb]Editor preview",
		"MindUTab title property updates its preview"
	)
	_check(
		not closable_tab.get_node("MarginContainer/HBoxContainer/Changes").visible,
		"MindUTab change indicator follows has_changes"
	)

	print("Widget tests: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: %s" % description)
	else:
		_failures += 1
		push_error("FAIL: %s" % description)


func _native_button_text_is_hidden(button: Button) -> bool:
	for color_name: StringName in [
		&"font_color",
		&"font_focus_color",
		&"font_pressed_color",
		&"font_hover_color",
		&"font_hover_pressed_color",
		&"font_disabled_color",
		&"font_outline_color",
	]:
		if not is_zero_approx(button.get_theme_color(color_name).a):
			return false
	return true

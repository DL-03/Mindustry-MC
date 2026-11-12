extends SceneTree

const CUSTOM_TAB_SCRIPT: Script = preload("res://widgets/tab_workspace_tab.gd")

var _workspace: Variant
var _failures := 0
var _checks := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var workspace_script: Script = load("res://widgets/tab_workspace.gd")
	_workspace = workspace_script.new()
	root.add_child(_workspace)
	await process_frame

	_check(_workspace.get_group_ids() == [&"main"], "creates a default group")
	_check(_workspace.add_group("Second", &"second") == &"second", "adds a group")
	_check(
		_workspace.move_group(&"second", 0)
		and _workspace.get_group_ids() == [&"second", &"main"]
		and _workspace._groups_container.get_child(0) == _workspace._groups[&"second"]["panel"],
		"reorders an independently draggable group panel"
	)
	_workspace.move_group(&"main", 0)
	_check(
		_workspace.get_group_ids() == [&"main", &"second"],
		"keeps group model order synchronized with the visible layout"
	)
	_check(_workspace.add_group("Duplicate", &"second").is_empty(), "rejects duplicate group id")
	var main_tab_panel: Control = _workspace.get_tab_panel(&"main")
	var main_content_panel: Control = _workspace.get_content_panel(&"main")
	_check(
		main_tab_panel != main_content_panel
		and main_tab_panel.get_parent() == _workspace._groups[&"main"]["body"]
		and main_content_panel.get_parent() == _workspace._groups[&"main"]["body"]
		and _workspace.get_bound_group_id(main_tab_panel) == &"main"
		and _workspace.get_bound_group_id(main_content_panel) == &"main",
		"keeps tab and content panels separate but bound to the same group"
	)
	var tab_panel_style := StyleBoxFlat.new()
	tab_panel_style.bg_color = Color.DARK_BLUE
	_workspace.tab_panel_stylebox = tab_panel_style
	var content_panel_style := StyleBoxFlat.new()
	content_panel_style.bg_color = Color.DARK_GREEN
	_workspace.content_panel_stylebox = content_panel_style
	_check(
		main_tab_panel.get_theme_stylebox("panel").bg_color == Color.DARK_BLUE
		and main_content_panel.get_theme_stylebox("panel").bg_color == Color.DARK_GREEN,
		"styles tab and content panels independently"
	)
	_workspace.add_group("Later", &"later")
	_check(
		_workspace.get_tab_panel(&"later").get_theme_stylebox("panel").bg_color == Color.DARK_BLUE
		and _workspace.get_content_panel(&"later").get_theme_stylebox("panel").bg_color == Color.DARK_GREEN,
		"applies independent panel styles to groups created later"
	)
	_workspace.remove_group(&"later")

	var first_content := Control.new()
	_check(
		_workspace.add_tab(&"main", &"first", "First", first_content),
		"adds tab with content"
	)
	var original_content_parent: Node = first_content.get_parent()
	_check(
		not _workspace.add_tab(&"main", &"duplicate_content", "Duplicate", first_content),
		"rejects content shared by multiple tabs"
	)
	_check(
		_workspace.get_selected_tab_id(&"main") == &"first",
		"selects the most recently added tab"
	)
	_check(first_content.get_parent() != null, "parents tab content into its group")

	_check(
		_workspace.add_tab(&"main", &"empty", "Empty"),
		"adds a tab without content"
	)
	_check(
		_workspace.get_selected_tab_id(&"main") == &"empty",
		"selects a tab without content"
	)
	_check(_workspace.get_tab_content(&"empty") == null, "preserves missing content")
	_check(not _workspace.add_tab(&"missing", &"bad", "Bad"), "rejects unknown group")
	_check(not _workspace.add_tab(&"main", &"first", "Duplicate"), "rejects duplicate tab id")

	_workspace.add_tab(&"main", &"third", "Third")
	_check(
		_workspace.move_tab(&"third", &"main", 0),
		"reorders a tab within its group"
	)
	_check(
		_workspace.get_tab_ids(&"main") == [&"third", &"first", &"empty"],
		"stores the requested tab order"
	)
	_workspace.add_tab(&"main", &"pinned", "Pinned", null, "", false)
	_check(not _workspace.close_tab(&"pinned"), "preserves non-closable tabs")
	_workspace.select_tab(&"main", &"first")

	_check(
		_workspace.move_tab(&"first", &"second"),
		"moves a tab between groups"
	)
	_check(
		_workspace.get_tab_ids(&"second") == [&"first"],
		"adds moved tab to destination group"
	)
	_check(
		_workspace.get_tab_group(&"first") == &"second",
		"updates the moved tab's owning group"
	)
	_check(
		first_content.get_parent() != original_content_parent,
		"moves tab content with its tab"
	)
	_check(
		_workspace.get_selected_tab_id(&"main") == &"empty",
		"selects a neighbor after moving the selected tab"
	)
	_check(_workspace.move_tab(&"empty", &"second"), "moves an empty tab between groups")
	_check(
		_workspace.get_tab_content(&"empty") == null,
		"keeps empty tab content absent after moving"
	)

	_workspace.set_tab_modified(&"first", true)
	_check(_workspace.is_tab_modified(&"first"), "stores the modified state")
	_workspace.set_tabs_vertical(true)
	_workspace.set_compact_tabs(true)
	_workspace.set_split_vertical(true)
	var layout: Dictionary = _workspace.serialize_layout()
	_check(layout["version"] == 1, "serializes a versioned layout")
	_check(layout["tabs_vertical"], "serializes vertical tab orientation")
	_check(layout["compact_tabs"], "serializes compact tab mode")
	_check(layout["split_vertical"], "serializes group split orientation")
	_check(layout["groups"].size() == 2, "serializes all groups")

	_check(not _workspace.remove_group(&"second"), "does not remove a non-empty group")
	_check(_workspace.close_tab(&"first"), "closes a closable tab")
	_check(_workspace.get_tab_group(&"first").is_empty(), "removes closed tab from registry")
	_check(_workspace.close_tab(&"empty"), "closes a moved empty tab")
	_check(_workspace.remove_group(&"second"), "removes an empty non-primary group")
	_check(not _workspace.remove_group(&"main"), "keeps at least one group")

	var page_workspace: Variant = workspace_script.new()
	var home_page := TabWorkspacePage.new()
	home_page.tab_id = &"home"
	home_page.title = "Home"
	home_page.group_id = &"main"
	home_page.group_title = "Main"
	home_page.selected_on_start = true
	home_page.tab_scene = load("res://tests/tab_content/custom_tab.tscn")
	home_page.content_scene = load("res://widgets/mind_button.tscn")
	var blank_page := TabWorkspacePage.new()
	blank_page.tab_id = &"blank"
	blank_page.title = "No content"
	blank_page.group_id = &"main"
	var tools_page := TabWorkspacePage.new()
	tools_page.tab_id = &"tools"
	tools_page.title = "Tools"
	tools_page.group_id = &"tools"
	tools_page.group_title = "Tools"
	var page_descriptors: Array[TabWorkspacePage] = [home_page, blank_page, tools_page]
	page_workspace.pages = page_descriptors
	root.add_child(page_workspace)
	await process_frame
	_check(
		page_workspace.get_tab_ids(&"main") == [&"home", &"blank"],
		"creates scene-authored tabs from Inspector resources"
	)
	_check(
		page_workspace.get_group_ids() == [&"main", &"tools"],
		"creates tab groups from Inspector resources"
	)
	_check(
		page_workspace.get_selected_tab_id(&"main") == &"home",
		"uses the configured initial selection"
	)
	_check(
		page_workspace.get_tab_content(&"home") is Button,
		"instantiates the selected page content scene"
	)
	var custom_tab: Control = page_workspace.get_tab_visual(&"home")
	_check(
		custom_tab.get_script() == CUSTOM_TAB_SCRIPT,
		"instantiates the Inspector-assigned custom tab scene"
	)
	var custom_tab_button: Button = custom_tab.get_parent()
	_check(
		not custom_tab_button.disabled and custom_tab_button.button_pressed,
		"keeps the selected custom tab draggable and visually selected"
	)
	if custom_tab.get_script() == CUSTOM_TAB_SCRIPT:
		var custom_tab_widget: Variant = custom_tab
		_check(
			custom_tab_widget.tab_title == "Home"
			and custom_tab_widget.tab_icon == ""
			and custom_tab_widget.tab_selected,
			"passes tab title and selection state into a custom tab scene"
		)
	page_workspace.set_tab_modified(&"home", true)
	custom_tab = page_workspace.get_tab_visual(&"home")
	if custom_tab.get_script() == CUSTOM_TAB_SCRIPT:
		_check(custom_tab.tab_modified, "refreshes custom tab visual state when the tab changes")
	_check(
		page_workspace.get_tab_content(&"blank") == null,
		"supports an Inspector-authored page without content"
	)
	var drop_strip: Control = page_workspace._groups[&"main"]["tab_strip"]
	_check(
		drop_strip._can_drop_data(Vector2.ZERO, {
			"source": "tab_workspace",
			"tab_id": "blank",
		}),
		"accepts tab drops on a supported tab strip"
	)
	_check(
		page_workspace._drop_target_group == &"main"
		and page_workspace._drop_target_in_strip,
		"shows an insertion preview for a tab-strip drop"
	)
	var marker_row_index: int = mini(
		page_workspace._drop_target_index,
		drop_strip.get_child_count() - 1
	)
	var drop_row: Control = drop_strip.get_child(marker_row_index)
	var drop_button: Variant = drop_row.get_child(0)
	_check(
		is_instance_valid(drop_button.drop_marker),
		"draws the insertion marker above the tab visual"
	)
	page_workspace._clear_drop_target()
	var drop_panel: Control = page_workspace._groups[&"tools"]["panel"]
	_check(
		drop_panel._can_drop_data(Vector2.ZERO, {
			"source": "tab_workspace",
			"tab_id": "blank",
		}),
		"accepts tab drops on a supported group panel"
	)
	_check(
		page_workspace._drop_target_group == &"tools"
		and not page_workspace._drop_target_in_strip,
		"shows a panel docking preview while hovering"
	)
	page_workspace._clear_drop_target()
	var main_group_panel: Control = page_workspace._groups[&"main"]["panel"]
	_check(
		main_group_panel._can_drop_data(
			Vector2.ZERO,
			{"source": "tab_workspace_group", "group_id": "tools"}
		),
		"accepts group-panel drag data for layout rearrangement"
	)
	_check(
		page_workspace._group_drop_target == &"main",
		"shows a target highlight when docking a group panel"
	)
	main_group_panel._drop_data(Vector2.ZERO, {
		"source": "tab_workspace_group",
		"group_id": "tools",
	})
	_check(
		page_workspace.get_group_ids() == [&"tools", &"main"]
		and page_workspace._groups_container.get_child(0) == page_workspace._groups[&"tools"]["panel"],
		"docks the dragged group panel into the selected layout position"
	)

	print("TabWorkspace tests: %d checks, %d failures" % [_checks, _failures])
	_workspace.queue_free()
	await process_frame
	quit(1 if _failures > 0 else 0)


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: %s" % description)
	else:
		_failures += 1
		push_error("FAIL: %s" % description)

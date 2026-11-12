# Mindustry Mod Construct

Mindustry Mod Construct (MMC) is a desktop application for creating and editing
mods for [Mindustry](https://github.com/Anuken/Mindustry). It can open multiple
mods and edit their content files.

> **Project status:** actively developed. Interfaces and project data formats
> may change between releases.

## Features

- Browse mod folders and ZIP/JAR archives.
- Open and work with multiple mods.
- Edit JSON/HJSON mod metadata and content files.
- Browse and edit content from several categories.
- Use the interface in different languages.

## Project structure

```text
libs/
  classes/          ModClass and ContentClass data models
  tooltip/          Tooltip manager
  *.gd, *.cs        Autoloads and platform helpers
scenes/
  Main.tscn         Main window and tab bar
  mod_manager/      Mod folder browser
  mod_editor/       Opened-mod editor
  content_editor/   Content file editor and its widgets
  explorer/         File system explorer
  popups/           Settings, creation, rename and delete dialogs
prefabs/            Reusable mod/content cards and icons
widgets/            Custom Mindustry-styled controls
resources/          Content type schema, icons and sounds
themes/             Mindustry UI theme
languages/v2/       Translation packs
```

Autoloads are registered in `project.godot`. Content type definitions live in
`resources/ContentType.json` and drive the generated property editors.

## Supported platforms

| Platform | Status |
| --- | --- |
| Windows | Supported |
| Linux | Supported |

Build and run the project on the target operating system using the matching
Godot .NET editor and .NET SDK. Other platforms are not currently supported.

## Requirements

- [Godot 4.7.2 .NET](https://godotengine.org/download/archive/4.7.2-stable/) —
  the .NET/Mono edition is required; the standard Godot editor cannot build the
  C# scripts.
- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0).
- Git, to clone the repository.

The project uses `Godot.NET.Sdk/4.7.2` and targets `net8.0`.

## Build and run from the editor

1. Install Godot 4.7.2 .NET and the .NET 8 SDK.
2. Clone the repository:

   ```sh
   git clone https://github.com/DL-03/Mindustry-MC.git
   cd Mindustry-MC
   ```

3. Open `project.godot` with Godot 4.7.2 .NET.
4. Wait for Godot to import the project and restore the .NET dependencies.
5. Build the C# project with the editor's **Build** button (hammer icon).
6. Press **F6** to run the current scene, or **F5** to run the project.

### UI and tab workspace test scene

Open `scenes/test_ui.tscn` and press **F6** to launch the UI test polygon. It
includes independently styled tab and content panels, empty and content-backed
tabs, draggable/reorderable groups, orientation and compactness controls, plus
a gallery of the existing Mindustry-styled controls. Drag a tab over another
group's tab strip to insert it there, or over its content area to dock it. Drag
a group header over another group to reorder the panels; the target highlights
while dragging. The test toolbar also has a panel-reorder action.

Run the tab workspace behavior checks headlessly from the project root:

```sh
godot-mono --headless --path . -s res://tests/test_tab_workspace.gd
```

Use the Godot .NET executable for your platform (named `godot-mono` in some
Linux distributions).

Run the widget preview/property checks in the project scene tree, so the
project autoloads used by localization and theme colors are available:

```sh
godot-mono --headless --path . res://tests/test_widgets.tscn
```

### Editing custom widgets

MMC widgets are built from native Godot `Control` nodes and `@tool` GDScript.
Their exported values are grouped in the Inspector, and supported properties
update the scene preview as they change. Prefer native Controls, exported
resources/node references, and property setters for reusable UI. An
`EditorPlugin`/`EditorInspectorPlugin` is appropriate when a widget needs a
custom inspector, creation workflow, or dock; a compiled Godot engine module
is a separate engine-fork/build decision and is not required for editor-ready
MMC controls.

To author tabs in a `TabWorkspace`, select it in the scene tree and add entries
to its **Tab Pages** array in the Inspector. Increase the array size, create a
`TabWorkspacePage` resource for each entry, set its ID/title/group, and assign
optional `PackedScene` scenes for page content and tab appearance. Page content
must have a `Control` root. A custom tab scene also has a `Control` root; use
`TabWorkspaceTab` as its root script to receive `tab_title`, `tab_icon`,
`tab_selected`, `tab_modified`, and `compact_mode` state. Custom tab scenes are
visual-only during dragging; selection, dragging, and closing are handled by the
workspace. The `scenes/test_ui.tscn` polygon demonstrates a custom tab and
multiple groups. Changes to page resources rebuild the editor preview.

`MindSettingRow` is the reusable settings-row widget. Set its title and optional
description in the Inspector, then assign a `PackedScene` for the right-side
control. The control can be a checkbox, selector, slider, or another custom
Control; the settings page remains responsible for binding its value and
signals. For a composite control with internal child nodes, assign its scene
(`PackedScene`) unless the control explicitly builds its internal layout when
created from its script type. `MindButton`, `MindButtonRTL`, `MindIButton`, and
`MindIButtonRTL` support both workflows: adding any of them as a node type
creates its internal layout and fills the child references. Generated internal
controls are locked in the editor canvas so they do not obstruct selecting or
moving the parent button; at runtime they ignore mouse input so the parent
button receives it.

Each workspace group has a separate tab panel and content panel with shared
group identity, exposed through `get_tab_panel()`, `get_content_panel()`, and
`get_bound_group_id()`. Assign `tab_panel_stylebox` and
`content_panel_stylebox` independently in the Inspector to style them, while
keeping them bound to the same group. Groups can be reordered through
`move_group()` or by dragging their headers over another group. Dragging a tab
over another tab strip shows an insertion marker. Hovering over a group's
content area highlights the panel; dropping there appends the tab to that
group. Common button text, spacing, margins, alignment, and icon settings are
exposed on the parent button.

Unassigned parent text fields preserve text authored on the internal labels.
Assigning a value overrides it, including an empty string to clear the label.
Layout properties enable the parent layout override when edited, while leaving
child-authored margins and alignment intact by default.

## Build from the command line

From the repository root, run:

```sh
dotnet build
```

This builds the C# assembly used by the Godot project. To run the application,
open the project with the Godot 4.7.2 .NET editor.

## Releases and update checks

The application version is set in `project.godot`. At startup and every five
minutes, MMC checks the latest published GitHub Release for this repository and
compares its tag (for example, `v0.3.0`) with the installed version. The check
only notifies about a newer version; it does not download or install updates.

The update check can also be triggered from GDScript with:

```gdscript
LocalizationAPI.check_app_version(true)
```

The optional `true` asks the application to report when it is already up to
date as well as when a newer release is available. GitHub Releases must be
published with semantic version tags in `vMAJOR.MINOR.PATCH` form.

## Language packs

Keep language packs in the `languages` branch of this same repository. The
branch root contains a directory for each incompatible language-pack format:

```text
languages branch
└── v2/
    ├── en.properties
    ├── ru.properties
    └── ua.properties
```

The `languages` branch is not a separate repository. Its contents can be
projected into the `main` checkout under `languages/` with Git subtree for
convenient editing. `main` then contains `languages/v2/*.properties`.
`LANGUAGE_MAJOR_VERSION` in
`libs/LocalizationAPI.gd` selects the compatible pack directory. Keep older
major-version directories in the `languages` branch when introducing an
incompatible format; increment the constant when the application adopts the new
format.

Each pack must declare its format and translation revision:

```properties
majorVersion = 2
version = 0.5
displayName = English
```

At startup, MMC compares compatible packs from the bundled
`res://languages/vN/` directory and `user://Languages/`. It uses the pack with
the higher numeric `version`; ties favor the user copy. Only packs matching the
application's `LANGUAGE_MAJOR_VERSION` are loaded, so packs for an unsupported
incompatible format are ignored.

The application checks the `vN/` directory on the same repository's remote
`languages` branch. A remote pack replaces the user copy only when its version
is newer than the best compatible pack already available locally or in the
bundle. Before replacing a pack from a different major version, MMC saves the
old file under
`user://Languages/backups/vN/<language>.properties`.

The Linux export preset explicitly includes `languages/**/*.properties`, so
the bundled fallback packs are available in exported builds as well as when
running from the editor.

### Create and publish the `languages` branch in this repository

First commit or stash changes in the `main` checkout. Create the branch in the
existing clone (this does not create another repository):

```sh
git switch --orphan languages
git rm -rf -- .
mkdir -p v2
```

The `git rm` command clears the tracked `main` files from this orphan branch's
working tree; it does not delete them from `main`. Copy the language files from
their existing source into `v2/` (for example, `en.properties`,
`ru.properties`, and `ua.properties`). Check that each file has the correct
`majorVersion` and a `version`, then commit and push the branch:

```sh
git add v2
git commit -m "Add version 2 language packs"
git push -u origin languages
```

### Show the branch contents under `languages/` in `main`

Switch back to `main` and add the branch contents as the `languages/`
directory. Both branches are in the same repository and use the same `origin`:

```sh
git switch main
git fetch origin languages
git subtree add --prefix=languages origin languages --squash
```

After making translation changes in `main/languages/`, publish those changes
back to the `languages` branch with:

```sh
git subtree push --prefix=languages origin languages
```

To bring changes made directly on the `languages` branch into `main`, run:

```sh
git fetch origin languages
git subtree pull --prefix=languages origin languages --squash
```

### Keep language packs available offline

Commit the language files into the `languages` branch and project that branch
into `main` with the subtree commands above. Once `languages/vN/*.properties`
are present, Godot can include them in exports and MMC can load them without a
network connection. The `languages` branch remains the online update source
for newer translations; bundled files provide the offline fallback and are not
modified by downloads.

## Contributing

Bug reports, fixes, and translation improvements are welcome. When reporting a
bug, include the operating system, MMC version, Godot version, and steps to
reproduce it. Keep changes focused and test the project with Godot 4.7.2 .NET.

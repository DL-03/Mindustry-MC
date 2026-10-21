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

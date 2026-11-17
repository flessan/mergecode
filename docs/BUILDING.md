# Building

Stack: Godot **4.7.2 Stable**, GDScript, Compatibility renderer (`gl_compatibility` for desktop and mobile), 1280×720 canvas-items stretch. One shared project for all platforms; no platform-specific code paths except hiding Quit on web.

## Run in editor
Import `project.godot` in Godot 4.7.2 and press Play. Main scene: `scenes/main_menu.tscn`.

## Exports
`export_presets.cfg` includes starter presets for **Web**, **Windows Desktop**, **Linux/X11** and **macOS** (output under `builds/`, git-ignored). Before exporting:
1. Install the matching Godot 4.7.2 export templates (Editor → Manage Export Templates).
2. Web: the project already uses the Compatibility renderer and avoids threads-only features; serve the output folder over HTTP(S) with the usual Godot web headers (COOP/COEP only needed if threads are enabled — they are not by default here).
3. Android/iOS: add presets via Project → Export (Android needs the Android SDK/JDK configured in Editor Settings; iOS needs macOS + Xcode). Touch input works through standard Control drag-and-drop; orientation is set to landscape.

Saves use `user://`, which maps to browser IndexedDB on web and per-platform app data directories elsewhere — no extra code needed.

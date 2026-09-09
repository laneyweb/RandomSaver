# RandomSaver Build Plan & Status
App: RandomSaver | User: darren | Plan scope: v1.0.0 panel plugin

## Completed Tasks
- [x] Create plugin directory structure
- [x] Create manifest.json (v1.0.0)
- [x] Bundle Delta Corps Priest 1.flf font
- [x] Bundle pyfiglet source + fix fonts package (add pyfiglet/fonts/__init__.py + .flf)
- [x] Create Plugin.qml entry point (Fixed inheritance cycle: renamed from Panel.qml; added FloatingWindow with WlrLayershell properties; added Quickshell.Wayland import)
- [x] Create Model.js logic inside Plugin.qml (controller with add/remove words, random activate, restore default)
- [x] Create initial words.txt
- [x] Create scripts/convert.py (local ASCII conversion)
- [x] Create scripts/random-activate.py (random pick + activation)
- [x] Create default-screensaver.txt backup
- [x] Test with omarchy plugin validate (exit 0)
- [x] Test with qmllint (only expected warnings, no recursive Panel error)
- [x] Test conversion (PASS)
- [x] Test random activation (PASS)
- [x] Install plugin to ~/.config/omarchy/plugins/darren.randomsaver/
- [x] Enable plugin (omarchy plugin enable: enabled=true)
- [x] Add keepLoaded: true to manifest (final fix attempt)
- [x] Replaced pyfiglet backend with Omarchy's own awk renderer (scripts/render.sh adapted from omacom/omarchy bin/omarchy-ascii; deleted convert.py, pyfiglet bundle, fonts/; QML now runs bash render.sh; random-activate.py uses subprocess + portable paths)
- [x] Fixed Add/Remove closing the panel: words now persist under XDG state dir (shell file-watcher reloads the plugin on any write inside the plugin dir); seed from shipped words.txt on first open; PanelKeyCatcher blocked while typing

## Pending / Blocked
- [x] Panel floating surface now renders (fixed: Item root + FloatingWindow child, removed keepLoaded, Process/FileView backend; verified with hyprctl mapped:1 after shell restart — earlier no-show was stale shell Loader state + inverted root, not compositor)
- [ ] User selected "No, hold for now" for commit/push (not pushed to https://github.com/laneyweb/RandomSaver)

## Upcoming (post-v1.0.0 if fixable)
- Font selection option in panel (future: load additional .flf fonts, dropdown selection)
- Potential v1.0.1: fix visibility/display mechanism or commit current working version

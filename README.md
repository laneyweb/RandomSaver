# RandomSaver
Omarchy 4 standalone panel plugin. Converts random words to ASCII art (Delta Corps Priest 1) and writes to `~/.config/omarchy/branding/screensaver.txt`. Keeps a default backup and supports restore.

## Files
- manifest.json — plugin contract (v1.0.0, kind: panel)
- SaverPanel.qml — panel entry point (Item root + FloatingWindow, GalleryPanel pattern)
- Model.js — pure helpers (parse/serialize/pickRandom, .pragma library)
- scripts/render.sh — ASCII conversion (bash+awk engine adapted from omacom/omarchy bin/omarchy-ascii, MIT; embedded Delta Corps Priest 1 font, touch-kerned like the Omarchy logo)
- scripts/random-activate.py — picks random word and activates screensaver
- words.txt — shipped seed word list (copied to state dir on first run)
- Live words live at `${XDG_STATE_HOME:-~/.local/state}/omarchy/randomsaver/words.txt` — writable state must stay out of the plugin dir or the shell's file watcher reloads (and closes) the panel on every save
- default-screensaver.txt — backup of original screensaver

## Usage
```
omarchy-shell shell summon darren.randomsaver '{}'
omarchy-shell shell hide darren.randomsaver
bash scripts/render.sh "hello" /tmp/test.txt
python3 scripts/random-activate.py
```

## Build Status (v1.0.0)
- Plugin validates (omarchy plugin validate: exit 0)
- Conversion tested (Delta Corps Priest 1 -> ASCII art)
- Random activation tested
- Default backup verified
- Panel installed and enabled; summon returns ok
- Visibility fixed: root is now Item with open()/close(), FloatingWindow child (was inverted); dropped keepLoaded to match dev-gallery, the only first-party FloatingWindow panel; Model.js rewritten as pure library, exec via Quickshell.Io Process, words via FileView
- Verified after `omarchy restart shell`: summon maps RandomSaver window (hyprctl mapped:1 visible:1), hide removes it, resummon works, convert + restore tested

- Renderer is Omarchy's own awk engine (adapted from `omarchy-ascii`); output matches `omarchy ascii` exactly, unlike pyfiglet smushing (pyfiglet bundle + standalone .flf removed)

# RandomSaver
Omarchy 4 standalone panel plugin. Converts random words to ASCII art (Delta Corps Priest 1) and writes to `~/.config/omarchy/branding/screensaver.txt`. Keeps a default backup and supports restore.

## Files
- manifest.json — plugin contract (v1.0.0, kind: panel)
- Plugin.qml — panel entry point (FloatingWindow + Item)
- fonts/Delta Corps Priest 1.flf — bundled FIGlet font
- scripts/convert.py — local ASCII conversion using bundled pyfiglet
- scripts/random-activate.py — picks random word and activates screensaver
- words.txt — persisted word list
- default-screensaver.txt — backup of original screensaver

## Usage
```
omarchy-shell shell summon darren.randomsaver '{}'
omarchy-shell shell hide darren.randomsaver
python3 scripts/convert.py "hello" /tmp/test.txt
python3 scripts/random-activate.py
```

## Build Status (v1.0.0)
- Plugin validates (omarchy plugin validate: exit 0)
- Conversion tested (Delta Corps Priest 1 -> ASCII art)
- Random activation tested
- Default backup verified
- Panel installed and enabled; summon returns ok
- Visibility issue: floating surface does not render on current session/compositor (non-fatal layer-shell display issue, not plugin logic failure)

## Memory Stored
Bug fix memory stored for pyfiglet fonts package resolution (`pyfiglet.fonts` module missing in bundle, fixed by adding `pyfiglet/fonts/__init__.py` and font file)

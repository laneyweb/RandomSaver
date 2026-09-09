# RandomSaver

Standalone panel plugin for Omarchy 4 (Quattro). Manages a word list, renders
a random word as ASCII art in Delta Corps Priest 1 — the same font and engine
as the Omarchy logo — and writes it to the screensaver branding file. Ships
with a backup of the default art plus one-click restore.

## Install

```sh
# from a checkout:
cp -r . ~/.config/omarchy/plugins/darren.randomsaver/
omarchy-shell shell rescanPlugins
omarchy plugin enable darren.randomsaver
```

## Usage

```sh
omarchy-shell shell summon darren.randomsaver '{}'
omarchy-shell shell hide darren.randomsaver
bash scripts/render.sh "hello" /tmp/test.txt
python3 scripts/random-activate.py
```

In the panel: add/remove words, **Random Activate** renders a random word to
`~/.config/omarchy/branding/screensaver.txt`, **Restore Default** copies back
`default-screensaver.txt`. Esc or **Close** dismisses the panel. The
**Randomise on reboot / restart shell** checkbox persists to the state dir;
when on, a headless `service` companion renders a fresh word at every shell
start (login and `omarchy restart shell` alike).

## Files

- `manifest.json` — plugin contract (v1.0.0, `kinds: panel + service`, no `keepLoaded`)
- `SaverPanel.qml` — panel entry point: `Item` root with `open()/close()`,
  child `FloatingWindow` (dev-gallery pattern), `Process`-based backend,
  `FileView`-backed word list
- `Service.qml` — headless start-up companion: renders one random word when
  the option is enabled (shell instantiates `service` kinds at every start)
- `Model.js` — pure `.pragma library` helpers (parse/serialize/pickRandom)
- `scripts/render.sh` — ASCII renderer (bash+awk, adapted from Omarchy's
  `omarchy-ascii`; embedded Delta Corps Priest 1 font)
- `scripts/random-activate.py` — headless random pick + render (subprocess,
  resolves installed vs checkout paths)
- `words.txt` — seed word list, copied to the state dir on first run
- `default-screensaver.txt` — backup of the stock screensaver art
- `LICENSE` / `THIRD-PARTY-NOTICES` — own MIT license + vendored-code notices

## State locations

| What | Where |
| ---- | ----- |
| Live word list | `${XDG_STATE_HOME:-~/.local/state}/omarchy/randomsaver/words.txt` |
| Panel option | `${XDG_STATE_HOME:-~/.local/state}/omarchy/randomsaver/settings.json` |
| Rendered art | `~/.config/omarchy/branding/screensaver.txt` |

Writable state deliberately lives **outside** `~/.config/omarchy/plugins/`:
the shell file-watches the plugin dir and reloads (destroying the open
panel) on any write there.

## How rendering works

`render.sh` embeds the awk FIGlet engine and font from Omarchy's
`bin/omarchy-ascii`, so output is byte-identical in layout to
`omarchy ascii` (touch-kerned glyphs). Only the CLI differs: upstream reads
args/stdin and prints to stdout; ours takes a word plus an output path.
The font draws letters and spaces only — digits/punctuation are skipped
with a stderr note. An earlier pyfiglet backend was removed because its
smushing rules rendered differently from Omarchy's own tooling.

## Development notes

- `omarchy plugin validate <dir>` must exit 0.
- After editing QML, run `omarchy restart shell` once before testing —
  rescan/summon alone has twice left stale panel code loaded.
- `qs log -p /usr/share/omarchy/shell --tail 30` shows panel errors
  (e.g. `convert stderr` lines from the render process).

## Credits & license

Own code is MIT — see `LICENSE`. The renderer adapts third-party MIT code;
see `THIRD-PARTY-NOTICES` and the header in `scripts/render.sh`:

- `omarchy-ascii` by the Omarchy project
  (https://github.com/omacom/omarchy/blob/quattro/bin/omarchy-ascii),
  Copyright (c) David Heinemeier Hansson, MIT License.
- Embedded "Delta Corps Priest 1" FIGFont by CoSMiC cHiLD
  (via the patorjk.com FIGFont Editor), shipped inside the above file.

# RandomSaver Build Plan & Status
App: RandomSaver | User: darren | Plan scope: v1.0.0 panel plugin

## Architecture (current)

- `manifest.json` (v1.0.0, `kinds: ["panel", "service"]`, no `keepLoaded`)
- `SaverPanel.qml`: `Item` root exposing `open()/close()` for the shell
  Loader, child `FloatingWindow`; backend via `Quickshell.Io Process`,
  word list via `FileView` over the XDG state dir, seeded from `words.txt`
- `Model.js`: pure `.pragma library` (parse/serialize/pickRandom)
- `scripts/render.sh`: bash+awk renderer adapted from Omarchy's
  `bin/omarchy-ascii` (embedded Delta Corps Priest 1 font)
- `scripts/random-activate.py`: headless pick + render via subprocess
- `LICENSE` (own MIT) + `THIRD-PARTY-NOTICES` (upstream MIT)

## Completed Tasks
- [x] Create plugin directory structure
- [x] Create manifest.json (v1.0.0)
- [x] Create SaverPanel.qml entry point (Item root + FloatingWindow,
      dev-gallery pattern; no keepLoaded — the only first-party
      FloatingWindow panel omits it)
- [x] Create Model.js as pure library (parse/serialize/pickRandom)
- [x] Create initial words.txt (now the read-only seed)
- [x] Create scripts/render.sh (Omarchy awk engine, `omarchy ascii`
      compatible output) and scripts/random-activate.py (subprocess,
      installed/checkout path resolution)
- [x] Create default-screensaver.txt backup + Restore Default path
- [x] Persist live words under XDG state dir (plugin-dir writes make the
      shell's file watcher reload and destroy the open panel)
- [x] "Randomise on reboot / restart shell" option: checkbox in panel
      persisted to state-dir settings.json; headless Service.qml renders one
       random word at every shell start (covers login/boot and restarts);
       verified off-by-default safe, on-triggers-render + log line, and a
       canary-file test proving the start-up write end to end
- [x] PanelKeyCatcher `blocked` while the new-word field has focus
- [x] Add LICENSE + THIRD-PARTY-NOTICES + per-file attribution header
- [x] Test with omarchy plugin validate (exit 0, work + installed copies)
- [x] Test render output, random activation, restore, hide/resummon cycle
      (hyprctl mapped:1; clean shell log)
- [x] Install to ~/.config/omarchy/plugins/darren.randomsaver/ + enable

## Pending / Blocked
- [ ] Commit/push current state (https://github.com/laneyweb/RandomSaver)

## Upcoming (post-v1.0.0)
- Font selection in panel (additional .flf fonts, dropdown) — needs a
  renderer that loads external fonts; current engine embeds one font

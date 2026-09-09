import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

// Headless companion to SaverPanel.qml. The shell instantiates every enabled
// `service` kind at startup (shell.qml _syncServices, first- and third-party
// alike), so this runs on each login/boot AND each shell restart. When the
// user enabled "Randomise on reboot / restart shell" in the panel, render one
// random word so the screensaver art is fresh.
Item {
    id: root
    visible: false

    // ---- host injections (set by shell.qml ensureService if present) ----
    property var shell: null
    property var manifest: null
    property string omarchyPath: Quickshell.env("OMARCHY_PATH") || ""
    property var pluginRegistry: null
    property var barWidgetRegistry: null

    readonly property string pluginId: "darren.randomsaver"
    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string pluginDir: home + "/.config/omarchy/plugins/darren.randomsaver"
    readonly property string renderScript: pluginDir + "/scripts/render.sh"
    readonly property string stateBase: Quickshell.env("XDG_STATE_HOME") || home + "/.local/state"
    readonly property string stateDir: stateBase + "/omarchy/randomsaver"
    readonly property string wordsPath: stateDir + "/words.txt"
    readonly property string settingsPath: stateDir + "/settings.json"
    readonly property string screensaverOut: home + "/.config/omarchy/branding/screensaver.txt"

    property bool settingsReady: false
    property bool wordsReady: false
    property bool startRandomize: false
    property var words: []
    property bool done: false

    FileView {
        id: settingsFile
        path: root.settingsPath
        watchChanges: false
        printErrors: false
        onLoaded: {
            try {
                var parsed = JSON.parse(text() || "{}")
                root.startRandomize = parsed && parsed.randomizeOnStart === true
            } catch (e) {
                root.startRandomize = false
            }
            root.settingsReady = true
            root.maybeRun()
        }
        onLoadFailed: {
            root.startRandomize = false
            root.settingsReady = true
            root.maybeRun()
        }
    }

    FileView {
        id: wordsFile
        path: root.wordsPath
        watchChanges: false
        printErrors: false
        onLoaded: {
            root.words = Model.parseWords(text())
            root.wordsReady = true
            root.maybeRun()
        }
        onLoadFailed: {
            root.words = Model.defaultWords()
            root.wordsReady = true
            root.maybeRun()
        }
    }

    Process {
        id: renderProc
        running: false
        onExited: function(exitCode) {
            if (exitCode === 0)
                console.log(root.pluginId, "start-up render done")
            else
                console.warn(root.pluginId, "start-up render failed (exit " + exitCode + ")")
        }
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (text.trim() !== "")
                    console.warn(root.pluginId, "start-up render stderr:", text.trim())
            }
        }
    }

    function maybeRun() {
        if (root.done || !root.settingsReady || !root.wordsReady)
            return
        root.done = true
        if (!root.startRandomize || renderProc.running)
            return
        var chosen = Model.pickRandom(root.words)
        renderProc.command = ["bash", root.renderScript, chosen, root.screensaverOut]
        renderProc.running = true
    }
}

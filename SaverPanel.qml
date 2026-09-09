import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Ui
import "Model.js" as Model

// Standalone panel entry point. Root MUST be an Item with
// open(payloadJson)/close() — the shell calls those on Loader.item
// (see shell.qml deliverIfLoaded/invokeIfLoaded). The FloatingWindow
// is a child, following GalleryPanel.qml / Osd.qml.
Item {
    id: root

    // ---- host injections (shell.qml sets these if present) ----
    property var shell: null
    property var manifest: null
    property string omarchyPath: Quickshell.env("OMARCHY_PATH") || ""
    property var pluginRegistry: null
    property var barWidgetRegistry: null
    property var service: null

    // ---- lifecycle (GalleryPanel pattern: no keepLoaded, no opened
    // property, no visible binding — Loader creates us on summon with the
    // window default-visible; close hides and the host destroys us) ----
    property bool closingFromHost: false

    readonly property string pluginId: "darren.randomsaver"
    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string pluginDir: home + "/.config/omarchy/plugins/darren.randomsaver"
    readonly property string convertScript: pluginDir + "/scripts/convert.py"
    readonly property string wordsPath: pluginDir + "/words.txt"
    readonly property string defaultArt: pluginDir + "/default-screensaver.txt"
    readonly property string screensaverOut: home + "/.config/omarchy/branding/screensaver.txt"

    property var words: ["hello", "world", "omarchy", "random", "screensaver"]
    property string statusMessage: ""
    property string lastActivated: ""

    function open(payloadJson) {
        closingFromHost = false
        window.visible = true
        Qt.callLater(function() {
            if (keyCatcher) keyCatcher.forceActiveFocus()
        })
    }

    function close() {
        closingFromHost = true
        window.visible = false
        closingFromHost = false
    }

    function toggle() {
        if (window.visible) root.close()
        else root.open("{}")
    }

    // User-initiated close (Esc / window button): notify host so
    // openPanelIds stays consistent and toggle() works next time.
    function requestClose() {
        if (shell && typeof shell.hide === "function")
            shell.hide(root.pluginId)
        else
            root.close()
    }

    // ---- persisted word list ----
    FileView {
        id: wordsFile
        path: root.wordsPath
        watchChanges: true
        atomicWrites: true
        printErrors: false
        onLoaded: root.words = Model.parseWords(text())
        onFileChanged: reload()
        onLoadFailed: root.words = Model.defaultWords()
    }

    function saveWords() {
        wordsFile.setText(Model.serializeWords(root.words))
    }

    function addWord(w) {
        var clean = String(w || "").trim()
        if (clean === "")
            return
        root.words = root.words.concat([clean])
        saveWords()
        root.statusMessage = "Added: " + clean
    }

    function removeWord(idx) {
        if (idx < 0 || idx >= root.words.length)
            return
        var removed = root.words[idx]
        var next = root.words.slice()
        next.splice(idx, 1)
        if (next.length === 0)
            next = Model.defaultWords()
        root.words = next
        saveWords()
        root.statusMessage = "Removed: " + removed
    }

    // ---- backend processes (replaces invalid root.run()) ----
    Process {
        id: convertProc
        running: false
        onExited: function(exitCode) {
            if (exitCode === 0)
                root.statusMessage = "Activated: " + root.lastActivated
            else
                root.statusMessage = "Convert failed (exit " + exitCode + ")"
        }
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (text.trim() !== "")
                    console.warn(root.pluginId, "convert stderr:", text.trim())
            }
        }
    }

    Process {
        id: restoreProc
        running: false
        onExited: function(exitCode) {
            root.statusMessage = exitCode === 0 ? "Restored default" : "Restore failed (exit " + exitCode + ")"
        }
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (text.trim() !== "")
                    console.warn(root.pluginId, "restore stderr:", text.trim())
            }
        }
    }

    function randomActivate() {
        if (root.words.length === 0) {
            root.statusMessage = "Word list is empty"
            return
        }
        if (convertProc.running) {
            root.statusMessage = "Convert already running…"
            return
        }
        var chosen = Model.pickRandom(root.words)
        root.lastActivated = chosen
        root.statusMessage = "Activating: " + chosen + "…"
        convertProc.command = ["python3", root.convertScript, chosen, root.screensaverOut]
        convertProc.running = true
    }

    function restoreDefault() {
        if (restoreProc.running)
            return
        root.statusMessage = "Restoring default…"
        restoreProc.command = ["cp", root.defaultArt, root.screensaverOut]
        restoreProc.running = true
    }

    // ---- floating surface ----
    FloatingWindow {
        id: window
        title: "RandomSaver"
        color: "#1a1a2e"
        implicitWidth: 600
        implicitHeight: 500
        minimumSize: Qt.size(400, 300)

        onVisibleChanged: {
            if (!visible && !root.closingFromHost && root.shell && typeof root.shell.hide === "function")
                root.shell.hide(root.pluginId)
        }

        PanelKeyCatcher {
            id: keyCatcher
            anchors.fill: parent
            onCloseRequested: root.requestClose()

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10

                Label {
                    text: "RandomSaver v1.0.0"
                    font.bold: true
                    font.pixelSize: 16
                    color: "#ffffff"
                }

                Label {
                    text: "Words: " + root.words.length
                    font.pixelSize: 12
                    color: "#cccccc"
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: root.words
                            delegate: RowLayout {
                                spacing: 8
                                Layout.fillWidth: true
                                Label {
                                    text: modelData
                                    color: "#ffffff"
                                    Layout.fillWidth: true
                                }
                                Button {
                                    text: "Remove"
                                    onClicked: root.removeWord(index)
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    spacing: 10
                    Layout.fillWidth: true
                    TextField {
                        id: newWordField
                        placeholderText: "New word"
                        Layout.fillWidth: true
                        onAccepted: {
                            root.addWord(text)
                            text = ""
                        }
                    }
                    Button {
                        text: "Add"
                        onClicked: {
                            root.addWord(newWordField.text)
                            newWordField.text = ""
                        }
                    }
                }

                RowLayout {
                    spacing: 10
                    Button {
                        text: "Random Activate"
                        enabled: !convertProc.running
                        onClicked: root.randomActivate()
                    }
                    Button {
                        text: "Restore Default"
                        enabled: !restoreProc.running
                        onClicked: root.restoreDefault()
                    }
                    Button {
                        text: "Close"
                        onClicked: root.requestClose()
                    }
                }

                Label {
                    text: root.statusMessage
                    font.pixelSize: 12
                    color: "#aaaaaa"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}

import QtQuick
import Quickshell
import qs.Ui
import QtQuick.Controls
import QtQuick.Layouts

pragma ComponentBehavior: Bound

FloatingWindow {
    id: window
    title: "RandomSaver"
    color: "#1a1a2e"
    implicitWidth: 600
    implicitHeight: 500
    minimumSize: Qt.size(400, 300)
    visible: root.opened

    onVisibleChanged: {
        if (!visible && !root.closingFromHost && root.shell && typeof root.shell.hide === "function")
            root.shell.hide("darren.randomsaver")
    }

    Item {
        id: root
        moduleName: "darren.randomsaver"
        manageIpc: false
        anchors.fill: parent

        property bool opened: false
        property bool closingFromHost: false
        property var anchorItem: null
        property var hostWidget: null
        property var shell: null

        function open(payloadJson) {
            closingFromHost = false
            root.opened = true
            window.visible = true
        }

        function close() {
            closingFromHost = true
            root.opened = false
            window.visible = false
            closingFromHost = false
        }

        QtObject {
            id: controller
            property var words: ["hello", "world", "omarchy", "random", "screensaver"]
            property int wordCount: words.length

            function addWord(w) {
                words.push(w)
                wordCount = words.length
            }

            function removeWord(idx) {
                words.splice(idx, 1)
                wordCount = words.length
            }

            function randomActivate() {
                var chosen = words[Math.floor(Math.random() * words.length)] || words[0]
                var cmd = "python3 /home/darren/Work/RandomSaver/scripts/convert.py \"" + chosen + "\" /home/darren/.config/omarchy/branding/screensaver.txt"
                root.run(cmd)
            }

            function restoreDefault() {
                var cmd = "cp /home/darren/Work/RandomSaver/default-screensaver.txt /home/darren/.config/omarchy/branding/screensaver.txt"
                root.run(cmd)
            }
        }

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
                text: "Words: " + controller.wordCount
                font.pixelSize: 12
                color: "#cccccc"
            }

            Repeater {
                model: controller.words
                delegate: RowLayout {
                    spacing: 8
                    Label { text: modelData; color: "#ffffff"; Layout.fillWidth: true }
                    Button {
                        text: "Remove"
                        onClicked: controller.removeWord(index)
                    }
                }
            }

            RowLayout {
                spacing: 10
                TextField {
                    id: newWordField
                    placeholderText: "New word"
                    Layout.fillWidth: true
                }
                Button {
                    text: "Add"
                    onClicked: {
                        if (newWordField.text.trim() !== "") {
                            controller.addWord(newWordField.text.trim())
                            newWordField.text = ""
                        }
                    }
                }
            }

            Button {
                text: "Random Activate"
                onClicked: controller.randomActivate()
            }

            Button {
                text: "Restore Default"
                onClicked: controller.restoreDefault()
            }
        }
    }
}

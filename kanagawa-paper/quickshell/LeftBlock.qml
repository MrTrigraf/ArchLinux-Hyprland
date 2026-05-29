import QtQuick
import Quickshell.Io

Item {
    id: root
    property bool powerMenuOpen: false
    property alias powerButton: powerBtn

    Process {
        id: termProc
        command: ["sh", "-c", "kitty --class kitty-dropdown &"]
    }

    Process {
        id: filesProc
        command: ["sh", "-c", "nautilus --new-window &"]
    }

    // Кнопки — фиксированно над полоской
    Row {
        id: buttonRow
        anchors.top: parent.top
        anchors.bottom: indicator.top
        anchors.bottomMargin: 3
        anchors.left: parent.left
        anchors.leftMargin: 10
        spacing: 3

        // Power
        Rectangle {
            id: powerBtn
            width: 28
            height: parent.height
            radius: 6
            color: powerMa.containsMouse ? Colors.bgLight : "transparent"

            Text {
                anchors.centerIn: parent
                text: "\uf011"
                color: Colors.red
                font.pixelSize: 20
                font.family: "JetBrainsMono Nerd Font"
            }

            MouseArea {
                id: powerMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.powerMenuOpen = !root.powerMenuOpen
            }
        }

        // Терминал
        Rectangle {
            width: 28
            height: parent.height
            radius: 6
            color: termMa.containsMouse ? Colors.bgLight : "transparent"

            Text {
                anchors.centerIn: parent
                text: "\uf120"
                color: Colors.text
                font.pixelSize: 20
                font.family: "JetBrainsMono Nerd Font"
            }

            MouseArea {
                id: termMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: termProc.running = true
            }
        }

        // Файлы
        Rectangle {
            width: 28
            height: parent.height
            radius: 6
            color: filesMa.containsMouse ? Colors.bgLight : "transparent"

            Text {
                anchors.centerIn: parent
                text: "\uf07b"
                color: Colors.text
                font.pixelSize: 20
                font.family: "JetBrainsMono Nerd Font"
            }

            MouseArea {
                id: filesMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: filesProc.running = true
            }
        }

        // Обои
        Rectangle {
            width: 28
            height: parent.height
            radius: 6
            color: wallMa.containsMouse ? Colors.bgLight : "transparent"

            Text {
                anchors.centerIn: parent
                text: "\uf03e"
                color: Colors.text
                font.pixelSize: 20
                font.family: "JetBrainsMono Nerd Font"
            }

            MouseArea {
                id: wallMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: console.log("Wallpaper picker — TODO")
            }
        }
    }

    // Полоска-индикатор
    Rectangle {
        id: indicator
        anchors.bottom: parent.bottom
        anchors.left: buttonRow.left
        width: buttonRow.width
        height: 2
        radius: 1.5
        antialiasing: true
        color: Colors.indicator
    }
}

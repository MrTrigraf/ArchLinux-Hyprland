import QtQuick
import Quickshell.Io

Item {
    id: root
    signal actionTriggered()

    Process {
        id: shutdownProc
        command: ["systemctl", "poweroff"]
    }

    Process {
        id: rebootProc
        command: ["systemctl", "reboot"]
    }

    Process {
        id: suspendProc
        command: ["systemctl", "suspend"]
    }

    Process {
        id: lockProc
        command: ["sh", "-c", "pidof hyprlock || hyprlock --config ~/.config/hypr/kanagawa-paper/hyprlock/hyprlock.conf"]
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Colors.bgSurface
        border.width: 1
        border.color: Colors.accent

        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Rectangle {
                width: parent.width
                height: 42
                radius: 8
                color: shutMa.containsMouse ? Colors.bgLight : "transparent"

                Row {
					anchors.left: parent.left
					anchors.leftMargin: 16
					anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    Text {
                        text: "\uf011"
                        color: Colors.red
                        font.pixelSize: 16
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Text {
                        text: "Выключить"
                        color: Colors.text
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                MouseArea {
                    id: shutMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.actionTriggered()
                        shutdownProc.running = true
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 42
                radius: 8
                color: rebootMa.containsMouse ? Colors.bgLight : "transparent"

                Row {
                    anchors.left: parent.left
					anchors.leftMargin: 16
					anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    Text {
                        text: "\uf01e"
                        color: Colors.orange
                        font.pixelSize: 16
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Text {
                        text: "Перезагрузка"
                        color: Colors.text
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                MouseArea {
                    id: rebootMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.actionTriggered()
                        rebootProc.running = true
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 42
                radius: 8
                color: sleepMa.containsMouse ? Colors.bgLight : "transparent"

                Row {
                    anchors.left: parent.left
					anchors.leftMargin: 16
					anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    Text {
                        text: "\uf186"
                        color: Colors.brightYellow
                        font.pixelSize: 16
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Text {
                        text: "Сон"
                        color: Colors.text
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"
                    }
				}

				MouseArea {
                    id: sleepMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.actionTriggered()
                        suspendProc.running = true
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 42
                radius: 8
                color: lockMa.containsMouse ? Colors.bgLight : "transparent"

                Row {
                     anchors.left: parent.left
					anchors.leftMargin: 16
					anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    Text {
                        text: "\uf023"
                        color: Colors.accent
                        font.pixelSize: 16
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Text {
                        text: "Блокировка"
                        color: Colors.text
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                MouseArea {
                    id: lockMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.actionTriggered()
                        lockProc.running = true
                    }
                }
            }
        }
    }
}

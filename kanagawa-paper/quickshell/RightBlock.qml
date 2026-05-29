import QtQuick

Item {
    id: root

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.8
        height: 2
        radius: 1
        color: Colors.indicator
    }

    Text {
        anchors.centerIn: parent
        text: "RIGHT"
        color: Colors.textMuted
        font.pixelSize: 12
        font.family: "JetBrainsMono Nerd Font"
    }
}

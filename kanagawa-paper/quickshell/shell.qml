import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property var modelData
            screen: modelData

            anchors {
                left: true
                bottom: true
                right: true
            }

            implicitHeight: 38
            color: "transparent"
            exclusionMode: ExclusionMode.Auto

            Item {
                id: barContainer
                width: bar.width * 0.60
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                clip: true

                Rectangle {
                    id: barBg
                    anchors.fill: parent
                    radius: 12
                    color: Colors.bgSurface
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: barBg.radius
                    color: Colors.bgSurface
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    spacing: 8

                    LeftBlock {
                        id: leftBlock
                        Layout.fillHeight: true
                        Layout.preferredWidth: barContainer.width * 0.25
                    }

                    CenterBlock {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }

                    RightBlock {
                        Layout.fillHeight: true
                        Layout.preferredWidth: barContainer.width * 0.35
                    }
                }
            }

            // === Попапы ===
			PopupWindow {
                id: powerMenu
                anchor.item: leftBlock.powerButton
                anchor.edges: Edges.Top
				anchor.gravity: Edges.Top
				anchor.rect.y: -10
                width: 180
                height: 210
                visible: leftBlock.powerMenuOpen
                color: "transparent"
                grabFocus: true

                onVisibleChanged: {
                    if (!visible) leftBlock.powerMenuOpen = false
                }

                PowerMenuContent {
                    anchors.fill: parent
                    onActionTriggered: leftBlock.powerMenuOpen = false
                }
            }
        }
    }
}

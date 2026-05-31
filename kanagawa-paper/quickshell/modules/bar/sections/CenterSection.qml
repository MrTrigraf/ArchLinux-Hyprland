import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Widgets
import "../components"
import "../../../theme"

// CenterSection - индикаторы воркспейсов 1..5 внутри плашки-капсулы.
//
// Источник данных - Quickshell.Hyprland.Hyprland (реактивный).
//
// Состояния пилюли:
//   empty    -> Theme.inactive  (#393836), размер 20x14
//   occupied -> Theme.occupied  (#54546D), размер 20x14
//   active   -> Theme.accent    (#b4a7b5), размер 32x14 (шире остальных)
//
// Визуально: ряд пилюль обёрнут в WrapperRectangle (Theme.sectionBg)
// с большим radius. Плашка плотно по содержимому.

WrapperRectangle {
    id: root

    resizeChild: false
    leftMargin:   Theme.sectionPillPaddingH
    rightMargin:  Theme.sectionPillPaddingH
    topMargin:    Theme.sectionPillPaddingV
    bottomMargin: Theme.sectionPillPaddingV

    color: Theme.sectionBg
    radius: Theme.sectionPillRadius

    RowLayout {
        spacing: -5   // минимальный зазор между слотами (пилюли вплотную)

        Repeater {
            model: 5

            Item {
                id: pillSlot
                required property int index
                readonly property int wsId: index + 1

                readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId)
                readonly property bool isActive: Hyprland.focusedWorkspace?.id === wsId
                readonly property bool isOccupied: ws !== undefined && ws.toplevels.values.length > 0

                implicitWidth: 34
                implicitHeight: 20

                Rectangle {
                    id: pill
                    anchors.centerIn: parent

                    width: pillSlot.isActive ? 32 : 20
                    height: 14
                    radius: 5

                    color: pillSlot.isActive
                        ? Theme.accent
                        : (pillSlot.isOccupied ? Theme.occupied : Theme.inactive)

                    Behavior on width {
                        NumberAnimation {
                            duration: Theme.animMed
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on color {
                        ColorAnimation { duration: Theme.animFast }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Hyprland.dispatch('hl.dsp.exec_raw("workspace, ' + pillSlot.wsId + '")')
                    }
                }
            }
        }
    }
}


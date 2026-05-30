import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../components"
import "../../../theme"

// ─────────────────────────────────────────────────────────────────────────────
// CenterSection — индикаторы воркспейсов 1..5 (пилюли).
//
// Источник данных — Quickshell.Hyprland.Hyprland (реактивный, обновляется
// автоматически при смене ws и появлении/закрытии окон).
//
// Состояния пилюли (для каждого ws):
//   active   → ширина 32px, заливка accent
//   occupied → ширина 18px, фон inactive, точка accent в центре
//   empty    → ширина 18px, фон inactive, без точки
//
// Клик по пилюле → Hyprland.dispatch("workspace N") → переключение ws.
// ─────────────────────────────────────────────────────────────────────────────
ColumnLayout {
    spacing: 5

    // ─── Ряд пилюль ──────────────────────────────────────────────────────
    RowLayout {
        spacing: 8
        Layout.alignment: Qt.AlignHCenter

        Repeater {
            model: 5  // 5 persistent-воркспейсов из hyprland.lua темы

            Rectangle {
                id: pill
                required property int index
                readonly property int wsId: index + 1

                // ищем этот ws среди известных Hyprland-у (может быть undefined,
                // если ws ещё не открывался — это нормально)
                readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId)
                readonly property bool isActive: Hyprland.focusedWorkspace?.id === wsId
                readonly property bool isOccupied: ws !== undefined && ws.toplevels.values.length > 0

                width: isActive ? 32 : 18
                height: 14
                radius: 5
                color: isActive ? Theme.accent : Theme.inactive

                // ─── Точка-маркер «в ws есть окна, но он не активен» ────
                Rectangle {
                    visible: pill.isOccupied && !pill.isActive
                    anchors.centerIn: parent
                    width: 3.5
                    height: 3.5
                    radius: 1.75
                    color: Theme.accent
                }

                // ─── Анимации ───────────────────────────────────────────
                Behavior on width {
                    NumberAnimation {
                        duration: Theme.animMed
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }

                // ─── Клик → переключение воркспейса ─────────────────────
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + pill.wsId)
                }
            }
        }
    }

    // ─── Подчёркивание секции ────────────────────────────────────────────
    SectionUnderline {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.sectionPaddingH
        Layout.rightMargin: Theme.sectionPaddingH
    }
}

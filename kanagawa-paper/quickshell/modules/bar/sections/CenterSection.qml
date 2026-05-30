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
// Состояния пилюли:
//   empty    → Theme.inactive  (#393836), размер 20×14
//   occupied → Theme.occupied  (#54546D), размер 20×14
//   active   → Theme.accent    (#b4a7b5), размер 32×14 (шире остальных)
// ─────────────────────────────────────────────────────────────────────────────
ColumnLayout {
    spacing: 5

    // ─── Ряд пилюль ──────────────────────────────────────────────────────
    RowLayout {
        spacing: -5  // минимальный зазор между слотами (≈ пилюли вплотную)
        Layout.alignment: Qt.AlignHCenter

        Repeater {
            model: 5  // 5 persistent-воркспейсов из hyprland.lua темы

            Item {
                id: pillSlot
                required property int index
                readonly property int wsId: index + 1

                // ищем этот ws среди известных Hyprland-у (может быть undefined)
                readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId)
                readonly property bool isActive: Hyprland.focusedWorkspace?.id === wsId
                readonly property bool isOccupied: ws !== undefined && ws.toplevels.values.length > 0

                // Слот фиксированной ширины 34px вмещает и узкую (20),
                // и широкую активную (32) пилюлю без сдвига соседей.
                implicitWidth: 34
                implicitHeight: 20

                // ─── Сама пилюля ────────────────────────────────────────
                Rectangle {
                    id: pill
                    anchors.centerIn: parent

                    // Ширина анимируется при смене активности (узкая ↔️ широкая)
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

                // ─── Хитбокс на весь слот (34×20) ───────────────────────
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

    // ─── Подчёркивание секции ────────────────────────────────────────────
    SectionUnderline {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.sectionPaddingH
        Layout.rightMargin: Theme.sectionPaddingH
    }
}

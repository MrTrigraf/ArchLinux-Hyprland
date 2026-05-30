import QtQuick
import QtQuick.Layouts
import "../components"
import "../../../theme"

// ─────────────────────────────────────────────────────────────────────────────
// RightSection — системный блок (всегда виден, прибит к правому краю бара).
//
// В чате A содержит только часы HH:MM.
// В чате C сюда придут: layout-indicator (EN/RU) + volume (% + popup-слайдер).
// В чате D: Wi-Fi, Bluetooth, notification-trigger.
// На ноуте также: battery (модуль появляется только при наличии аккумулятора).
//
// Tray вынесен в отдельный блок TraySection (см. Bar.qml).
// ─────────────────────────────────────────────────────────────────────────────
ColumnLayout {
    spacing: 5

    // ─── Ряд содержимого ─────────────────────────────────────────────────
    RowLayout {
        spacing: Theme.iconGap
        Layout.alignment: Qt.AlignHCenter

        // Часы: HH:MM (без секунд, без AM/PM)
        Text {
            id: clock
            text: Qt.formatDateTime(new Date(), "HH:mm")
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeBar

            // Тик раз в секунду гарантирует точный переход через минуту.
            // Перерисовка происходит только когда text реально меняется.
            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clock.text = Qt.formatDateTime(new Date(), "HH:mm")
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

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../components"
import "../../../theme"

// RightSection - системный блок (часы) внутри плашки-капсулы.
//
// В чате A содержит только часы HH:MM.
// В чате C сюда придут: layout-indicator (EN/RU) + volume (% + popup-слайдер).
// В чате D: Wi-Fi, Bluetooth, notification-trigger.
// На ноуте также: battery (модуль появляется только при наличии аккумулятора).
//
// Tray вынесен в отдельный блок TraySection (см. Bar.qml).

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
        spacing: Theme.iconGap

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
}

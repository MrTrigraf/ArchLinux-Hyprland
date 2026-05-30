import QtQuick
import QtQuick.Layouts
import "../components"
import "../../../components"
import "../../../theme"

// ─────────────────────────────────────────────────────────────────────────────
// LeftSection — заглушка для левого блока.
//
// В чате B сюда придут:
//   power_settings_new → popup с PowerOff / Reboot / Sleep / Lock
//   terminal           → плавающее окно kitty
//   folder             → плавающее окно nautilus
//   wallpaper          → меню обоев awww
// Сейчас иконки без MouseArea — только вёрстка для проверки геометрии.
//
// Каждая иконка обёрнута в Item фиксированной высоты Theme.iconSizeBar
// и центрирована внутри. Это нужно, чтобы строка иконок в Left имела
// ту же высоту, что и в TraySection/RightSection, — иначе bounding box
// Text-элемента у Material Symbols добавляет невидимый padding ~6-8px,
// и подчёркивание Left уезжает выше остальных секций.
// ─────────────────────────────────────────────────────────────────────────────
ColumnLayout {
    spacing: 5

    // ─── Ряд иконок ─────────────────────────────────────────────────────
    RowLayout {
        spacing: Theme.iconGap
        Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom

        // Каждая иконка в обёртке-Item для контроля высоты строки.
        // BarIcon центрируется внутри обёртки, что обрезает «лишние» отступы
        // шрифта Material Symbols вокруг глифа.
        Repeater {
            model: ["power_settings_new", "terminal", "folder", "wallpaper"]

            Item {
                required property string modelData
                implicitWidth: Theme.iconSizeBar
                implicitHeight: Theme.iconSizeBar

                BarIcon {
                    anchors.centerIn: parent
                    name: parent.modelData
                }
            }
        }
    }

    // ─── Подчёркивание секции ───────────────────────────────────────────
    SectionUnderline {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.sectionPaddingH
        Layout.rightMargin: Theme.sectionPaddingH
    }
}

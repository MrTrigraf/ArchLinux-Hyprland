import QtQuick
import QtQuick.Layouts
import "../components"
import "../../../components"
import "../../../theme"

// ─────────────────────────────────────────────────────────────────────────────
// LeftSection — заглушка для левого блока.
// В чате B сюда придут:
//   power_settings_new → popup с PowerOff / Reboot / Sleep / Lock
//   terminal           → плавающее окно kitty
//   folder             → плавающее окно nautilus
//   wallpaper          → меню обоев awww
// Сейчас иконки без MouseArea — только вёрстка для проверки геометрии.
// ─────────────────────────────────────────────────────────────────────────────
ColumnLayout {
    spacing: 5

    // ─── Ряд иконок ─────────────────────────────────────────────────────
    RowLayout {
        spacing: Theme.iconGap
        Layout.alignment: Qt.AlignHCenter

        BarIcon { name: "power_settings_new" }
        BarIcon { name: "terminal" }
        BarIcon { name: "folder" }
        BarIcon { name: "wallpaper" }
    }

    // ─── Подчёркивание секции ───────────────────────────────────────────
    SectionUnderline {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.sectionPaddingH
        Layout.rightMargin: Theme.sectionPaddingH
    }
}

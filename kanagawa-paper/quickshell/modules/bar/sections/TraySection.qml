import QtQuick
import QtQuick.Layouts
import "../components"
import "../../../theme"

// ─────────────────────────────────────────────────────────────────────────────
// TraySection — отдельный блок между центром и правой секцией.
//
// Размещение в Bar.qml: anchors.right = rightSection.left, т.е. блок прижат
// к правому соседу и растёт ВЛЕВО при добавлении иконок.
//
// layoutDirection: Qt.RightToLeft заставляет RowLayout укладывать дочерние
// элементы справа налево, что совпадает с направлением роста блока.
//
// В чате A — заглушка из 3 точек (Repeater{model:3}), нужна для проверки
// геометрии и видимости подчёркивания.
// В чате C заменим Repeater на:
//     Repeater { model: SystemTray.items; delegate: TrayIcon { ... } }
// и добавим к корневому ColumnLayout:
//     visible: SystemTray.items.values.length > 0
// чтобы блок исчезал, когда трей пуст.
// ─────────────────────────────────────────────────────────────────────────────
ColumnLayout {
    id: root
    spacing: 5

    // ─── Ряд иконок (растёт справа налево) ──────────────────────────────
    RowLayout {
        layoutDirection: Qt.RightToLeft
        spacing: Theme.iconGap
        Layout.alignment: Qt.AlignRight

        // заглушка: 3 точки. Реальные tray-иконки придут в чате C.
        Repeater {
            model: 3
            Rectangle {
                width: 4
                height: 4
                radius: 2
                color: Theme.fgMuted
                opacity: 0.5
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

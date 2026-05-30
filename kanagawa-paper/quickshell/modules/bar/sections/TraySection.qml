import QtQuick
import QtQuick.Layouts
import "../components"
import "../../../theme"

// ─────────────────────────────────────────────────────────────────────────────
// TraySection — отдельный блок между центром и правой секцией.
//
// Размещение в Bar.qml: anchors.right = rightSection.left, т.е. блок прижат
// к правой секции и растёт ВЛЕВО при добавлении иконок.
//
// layoutDirection: Qt.RightToLeft в RowLayout заставляет элементы укладываться
// справа налево, что совпадает с направлением роста блока.
//
// Layout.alignment: Qt.AlignRight | Qt.AlignBottom прижимает иконки к низу
// секции — на уровне подчёркивания, а не в центре. Это синхронизирует
// визуальный нижний край всех 4 секций.
//
// В чате A — заглушка из 3 точек (нужна, чтобы было видно блок и проверить
// геометрию). После проверки этот файл будет переписан в чате C:
//   - Repeater { model: 3 } → Repeater { model: SystemTray.items.values }
//   - в delegate: реальная иконка приложения через IconImage
//   - на root: visible: SystemTray.items.values.length > 0
//     (блок исчезнет, когда нет ни одной tray-иконки)
// ─────────────────────────────────────────────────────────────────────────────
ColumnLayout {
    id: root
    spacing: 5

    // ─── Ряд иконок (растёт справа налево) ──────────────────────────────
    RowLayout {
        layoutDirection: Qt.RightToLeft
        spacing: Theme.iconGap
        Layout.alignment: Qt.AlignRight | Qt.AlignBottom

        // заглушка: 3 точки. Реальные tray-иконки придут в чате C.
        // Внешний Item фиксированной высоты выравнивает строку с другими
        // секциями, чтобы подчёркивание не «прыгало» относительно иконок.
        Repeater {
            model: 3
            Item {
                implicitWidth: 6
                implicitHeight: 18  // совпадает с высотой строки пилюль и иконок

                Rectangle {
                    anchors.centerIn: parent
                    width: 6
                    height: 6
                    radius: 3
                    color: Theme.fgMuted
                    opacity: 0.7
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

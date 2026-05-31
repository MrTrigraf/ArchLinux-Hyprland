import QtQuick
import QtQuick.Layouts
import "../components"
import "../../../components"
import "../../../theme"

// LeftSection - левый блок бара: 4 иконки + подчёркивание.
//
// Иконки:
//   power_settings_new -> сигнал powerClicked  -> PowerMenu
//   terminal           -> сигнал terminalClicked  -> плавающий kitty
//   folder             -> сигнал filesClicked     -> плавающий nautilus
//   wallpaper          -> сигнал wallpaperClicked -> WallpaperPicker

ColumnLayout {
    id: root
    spacing: 5

    // Ссылка на корневое окно бара. Выставляется из Bar.qml.
    // Нужна для mapToItem - чтобы получить X иконки в координатах окна бара.
    property var barWindow: null

    // Сигналы наружу секции. Параметр - локальный X иконки внутри бара.
    signal powerClicked(int iconLocalX)
    signal terminalClicked(int iconLocalX)
    signal filesClicked(int iconLocalX)
    signal wallpaperClicked(int iconLocalX)

    // ─── Ряд иконок ─────────────────────────────────────────────────────
    RowLayout {
        id: iconRow
        spacing: Theme.iconGap
        Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom

        Repeater {
            model: [
                { name: "power_settings_new", signal: "power"     },
                { name: "terminal",           signal: "terminal"  },
                { name: "folder",             signal: "files"     },
                { name: "wallpaper",          signal: "wallpaper" }
            ]

            Item {
                id: iconWrap
                required property var modelData
                implicitWidth: Theme.iconSizeBar
                implicitHeight: Theme.iconSizeBar

                BarIcon {
                    anchors.centerIn: parent
                    name: iconWrap.modelData.name
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: {
                        var localX = 0
                        if (root.barWindow !== null && root.barWindow !== undefined) {
                            var p = iconWrap.mapToItem(root.barWindow.contentItem, 0, 0)
                            localX = Math.round(p.x)
                        }

                        switch (iconWrap.modelData.signal) {
                            case "power":     root.powerClicked(localX);     break
                            case "terminal":  root.terminalClicked(localX);  break
                            case "files":     root.filesClicked(localX);     break
                            case "wallpaper": root.wallpaperClicked(localX); break
                        }
                    }
                }

                // HoverHandler для cursor shape - TapHandler сам не меняет
                // курсор. Это отдельный лёгкий PointerHandler, без логики.
                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
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

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../components"
import "../../../components"
import "../../../theme"

// LeftSection - левый блок бара: 4 иконки внутри плашки-капсулы.
//
// Иконки:
//   power_settings_new -> сигнал powerClicked  -> PowerMenu
//   terminal           -> сигнал terminalClicked  -> плавающий kitty
//   folder             -> сигнал filesClicked     -> плавающий nautilus
//   wallpaper          -> сигнал wallpaperClicked -> WallpaperPicker
//
// Визуально: ряд иконок обёрнут в WrapperRectangle (Theme.sectionBg =
// #363646) с большим radius (Theme.sectionPillRadius). Плашка
// автоматически подгоняется под содержимое + padding'и из Theme.

WrapperRectangle {
    id: root

    // ─── Геометрия плашки ───────────────────────────────────────────────
    // resizeChild=false: плашка плотно по implicit-размеру содержимого,
    // не растягивается даже если родитель больше. Это даёт "капсулу
    // по иконкам", а не плашку во всю ширину секции.
    resizeChild: false
    leftMargin:   Theme.sectionPillPaddingH
    rightMargin:  Theme.sectionPillPaddingH
    topMargin:    Theme.sectionPillPaddingV
    bottomMargin: Theme.sectionPillPaddingV

    color: Theme.sectionBg
    radius: Theme.sectionPillRadius

    // Ссылка на корневое окно бара. Выставляется из Bar.qml.
    // Нужна для mapToItem - чтобы получить X иконки в координатах окна бара.
    property var barWindow: null

    // Сигналы наружу секции. Параметр - локальный X иконки внутри бара.
    signal powerClicked(int iconLocalX)
    signal terminalClicked(int iconLocalX)
    signal filesClicked(int iconLocalX)
    signal wallpaperClicked(int iconLocalX)

    // ─── Ряд иконок (child WrapperRectangle) ────────────────────────────
    // WrapperRectangle оборачивает ОДИН child Item, его размер становится
    // размером плашки + margins. Поэтому RowLayout - единственный потомок.
    RowLayout {
        spacing: Theme.iconGap

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

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }
}

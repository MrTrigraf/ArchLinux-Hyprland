import QtQuick
import Quickshell.Io
import "../../theme"

// WallpaperPicker - попап для выбора обоев.
// Источник данных: WallpaperModel (Singleton). Список перечитывается
// при каждом открытии (reload в Connections onIsOpenChanged).
PopupBase {
    id: root

    // ─── Геометрия попапа ───────────────────────────────────────────────
    // contentWidth выставляется из shell.qml = width бара (60% screen.width).
    // contentHeight - суммарная высота строк + padding'и.
    // Формула (на текущих токенах Theme):
    //   2*popupContentPadding (8*2 = 16)
    //   + wallpaperPreviewH (96)
    //   + wallpaperRowGap (12)
    //   + wallpaperLabelHeight (22)
    //   + wallpaperRowGap (12)
    //   + wallpaperArrowSize (28)
    //   = 186px
    contentHeight: 2 * Theme.popupContentPadding
                 + Theme.wallpaperPreviewH
                 + Theme.wallpaperRowGap
                 + Theme.wallpaperLabelHeight
                 + Theme.wallpaperRowGap
                 + Theme.wallpaperArrowSize

    // Индекс selected картинки (с подсветкой).
    property int focusedIndex: 0

    // Перезагрузка списка при открытии и сброс фокуса на 0.
    Connections {
        target: root
        function onIsOpenChanged() {
            if (root.isOpen) {
                WallpaperModel.reload()
                root.focusedIndex = 0
            }
        }
    }

    // Процесс для применения обоев. Создаём один экземпляр, меняем
    // command перед каждым запуском (path меняется в зависимости от выбора).
    Process {
        id: applyProc
        // command выставляется в applyWallpaper() перед startDetached
    }

    // ─── Действия ───────────────────────────────────────────────────────
    function moveFocus(delta) {
        var n = WallpaperModel.count
        if (n === 0) return
        root.focusedIndex = (root.focusedIndex + delta + n) % n
        // прокручиваем ListView к новому индексу, чтобы был виден
        previewList.positionViewAtIndex(root.focusedIndex, ListView.Contain)
    }

    function applyWallpaper(index) {
        if (index < 0 || index >= WallpaperModel.count) return
        var path = WallpaperModel.items[index]
        applyProc.command = ["awww", "img", path]
        applyProc.startDetached()
        root.close()
    }

    // selectOrApply: если index == focusedIndex (то есть нажатие на уже
    // выбранную) - применить. Иначе - просто переместить фокус.
    function selectOrApply(index) {
        if (index === root.focusedIndex) {
            applyWallpaper(index)
        } else {
            root.focusedIndex = index
            previewList.positionViewAtIndex(index, ListView.Contain)
        }
    }

    // ─── Содержимое попапа ──────────────────────────────────────────────
    Column {
        anchors.fill: parent
        spacing: Theme.wallpaperRowGap

        // ── Ряд 1: горизонтальный ListView превьюшек ───────────────────
        ListView {
            id: previewList
            width: parent.width
            height: Theme.wallpaperPreviewH
            orientation: ListView.Horizontal
            spacing: Theme.wallpaperPreviewGap
            clip: true                  // обрезать содержимое в пределах ListView
            boundsBehavior: Flickable.StopAtBounds
            focus: true                 // получить keyboard focus от contentHolder
			// Скрытый скроллбар. Flickable работает,
            // навигация стрелками через positionViewAtIndex.

            model: WallpaperModel.items

            // Обработка клавиатуры. ←/→ - moveFocus, Enter - apply selected.
            Keys.onLeftPressed:    root.moveFocus(-1)
            Keys.onRightPressed:   root.moveFocus(+1)
            Keys.onReturnPressed:  root.applyWallpaper(root.focusedIndex)
            Keys.onEnterPressed:   root.applyWallpaper(root.focusedIndex)

            delegate: Item {
                id: previewItem
                required property int index
                required property var modelData   // путь к файлу (string)

                width: Theme.wallpaperPreviewW
                height: Theme.wallpaperPreviewH

                readonly property bool isSelected: root.focusedIndex === previewItem.index

                // Контейнер с радиусом и опциональной рамкой accent.
                // Rectangle с border поверх Image обрезает картинку
                // через clip + radius на самом Image-rect.
                Rectangle {
                    id: tile
                    anchors.fill: parent
                    radius: Theme.wallpaperPreviewRadius
                    color: "transparent"
                    border.width: previewItem.isSelected ? Theme.wallpaperSelectedBorderW : 0
                    border.color: Theme.accent

                    // Сама картинка. fillMode: PreserveAspectCrop - заполнить
                    // все 170x96 px, обрезая то, что не помещается.
                    // sourceSize кэширует уменьшенную копию (превью), чтобы
                    // не грузить полноразмерное изображение 2160x1440 в память.
                    Image {
                        anchors.fill: parent
                        anchors.margins: previewItem.isSelected
                            ? Theme.wallpaperSelectedBorderW
                            : 0
                        source: "file://" + previewItem.modelData
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: Theme.wallpaperPreviewW * 2
                        sourceSize.height: Theme.wallpaperPreviewH * 2
                        // smooth: true даёт билинейную фильтрацию при downscale.
                        smooth: true
                        // Радиус через MultiEffect/маску слишком тяжело;
                        // обходимся container'ом-Rectangle с clip.
                    }

                    // Clip контейнер - чтобы Image округлился по radius.
                    clip: true

                    Behavior on border.width {
                        NumberAnimation { duration: Theme.animFast }
                    }
                }

                // Клик мышью: select-or-apply.
                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: root.selectOrApply(previewItem.index)
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }

        // ── Ряд 2: имя selected картинки ───────────────────────────────
        Text {
            width: parent.width
            height: Theme.wallpaperLabelHeight
            text: WallpaperModel.count > 0
                ? WallpaperModel.basename(WallpaperModel.items[root.focusedIndex])
                : "—"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizePopupItem
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideMiddle  // длинные имена обрезаются по центру с "..."
        }

        // ── Ряд 3: стрелки по центру ───────────────────────────────────
       Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 32
            height: Theme.wallpaperArrowSize

            // Левая стрелка (chevron_right, повёрнутый на 180°).
            Item {
                width: Theme.wallpaperArrowSize
                height: Theme.wallpaperArrowSize

                Text {
                    anchors.centerIn: parent
                    text: "chevron_right"
                    rotation: 180
                    font.family: Theme.iconFamily
                    font.pixelSize: Theme.wallpaperArrowSize
                    color: Theme.fg
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: root.moveFocus(-1)
                }
                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
            }

            // Правая стрелка (chevron_right без поворота).
            Item {
                width: Theme.wallpaperArrowSize
                height: Theme.wallpaperArrowSize

                Text {
                    anchors.centerIn: parent
                    text: "chevron_right"
                    font.family: Theme.iconFamily
                    font.pixelSize: Theme.wallpaperArrowSize
                    color: Theme.fg
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: root.moveFocus(+1)
                }
                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }    }
}

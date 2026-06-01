import QtQuick
import "../../../theme"

Item {
    id: root

    // ─── Публичные свойства ─────────────────────────────────────────────
    property string label: ""
    property real value: 0        // 0..1
    property bool muted: false

    // Сигнал «пользователь подвинул слайдер». Родитель ловит и пишет
    // в источник (sink.audio.volume / stream.audio.volume).
    signal userChanged(real newValue)

    // ─── Размеры ────────────────────────────────────────────────────────
    implicitWidth: 200
    // Высота = подпись + gap + рельс с кругляшком. Кругляшек выше рельса,
    // поэтому в высоту считаем handle, а не track.
    implicitHeight: Theme.volumeSliderLabelSize
                  + Theme.volumeSliderLabelGap
                  + Theme.volumeSliderHandleSize

    // ─── Ряд "подпись + значение" ───────────────────────────────────────
    Item {
        id: labelRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Theme.volumeSliderLabelSize

        // Подпись слева. elide — если приложение с длинным именем.
        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            // Оставляем место справа для значения "100%".
            anchors.right: valueText.left
            anchors.rightMargin: 8

            text: root.label
            color: Theme.volumeSliderLabelFg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.volumeSliderLabelSize
            elide: Text.ElideRight
        }

        // Значение справа в процентах.
        Text {
            id: valueText
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            text: Math.round(root.value * 100) + "%"
            color: Theme.volumeSliderValueFg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.volumeSliderLabelSize
        }
    }

    // ─── Рельс с заполнением и handle ───────────────────────────────────
    Item {
        id: trackArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: labelRow.bottom
        anchors.topMargin: Theme.volumeSliderLabelGap
        // Высота = handle, чтобы он не клипался.
        height: Theme.volumeSliderHandleSize

        // Внутренний слой: track. Тонкая полоса по центру trackArea.
        Rectangle {
            id: track
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: Theme.volumeSliderTrackHeight
            radius: height / 2
            color: Theme.volumeSliderTrackBg

            // Заполненная часть. Слева, шириной = value * track.width.
            Rectangle {
                id: filled
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * root.value
                radius: parent.radius
                color: root.muted
                    ? Theme.volumeSliderTrackFgMuted
                    : Theme.volumeSliderTrackFg

                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }
            }
        }

        // Handle — кругляшек, центр по value на track.
        // X handle = track.x + value * track.width - handle.width / 2.
        // Поскольку track.anchors.fill совпадает с trackArea по горизонтали,
        // считаем относительно trackArea.
        Rectangle {
            id: handle
            width: Theme.volumeSliderHandleSize
            height: Theme.volumeSliderHandleSize
            radius: width / 2
            x: track.width * root.value - width / 2
            anchors.verticalCenter: parent.verticalCenter

            color: root.muted
                ? Theme.volumeSliderHandleBgMuted
                : Theme.volumeSliderHandleBg

            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }
        }

		// ─── Обработка кликов и перетаскивания ──────────────────────────
        // Используем MouseArea, а не TapHandler+DragHandler — слайдер
        // должен реагировать и на одиночный клик в произвольную точку
        // (мгновенно прыгнуть на значение), и на удержание+drag.
        // С MouseArea это одной логикой через onPositionChanged.
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            // Удерживаем кнопку — pressed = true, реагируем на каждое
            // движение мыши. При обычном клике onPressed срабатывает
            // один раз и устанавливает позицию.
            onPressed: (mouse) => updateFromMouse(mouse.x)
            onPositionChanged: (mouse) => {
                if (pressed) updateFromMouse(mouse.x)
            }

            function updateFromMouse(mx) {
                // mx может выйти за пределы [0, track.width] при drag
                // за край — clamp в [0, 1].
                var v = Math.max(0, Math.min(1, mx / track.width))
                root.userChanged(v)
            }
        }
    }
}

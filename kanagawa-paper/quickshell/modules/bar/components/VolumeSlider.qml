import QtQuick
import "../../../theme"

Item {
    id: root

    // ─── Публичные свойства ─────────────────────────────────────────────
    property string label: ""
    property real value: 0        // 0..1
	property bool muted: false

	property bool muteIcon: false

    // Сигнал «пользователь подвинул слайдер». Родитель ловит и пишет
    // в источник (sink.audio.volume / stream.audio.volume).
	signal userChanged(real newValue)
	signal muteToggled()

    // ─── Размеры ────────────────────────────────────────────────────────
    implicitWidth: 200
    // Высота = подпись + gap + рельс с кругляшком. Кругляшек выше рельса,
    // поэтому в высоту считаем handle, а не track.
    implicitHeight: Theme.volumeSliderLabelSize
                  + Theme.volumeSliderLabelGap
                  + Theme.volumeSliderHandleSize

	// ─── Ряд "[mute?] подпись ↔️ значение" ────────────────────────────────
    // Высота ряда — max(textSize, muteIconSize), потому что иконка mute
    // выше шрифта label. Без max'а иконка клипалась бы.
    Item {
        id: labelRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Math.max(Theme.volumeSliderLabelSize,
                         root.muteIcon ? Theme.volumeSliderMuteIconSize : 0)

        // Mute-кнопка слева. Видна только при muteIcon: true.
        // Глиф меняется по root.muted (входящий проп от родителя).
        Text {
            id: muteBtn
            visible: root.muteIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width:  visible ? Theme.volumeSliderMuteIconSize : 0
            height: Theme.volumeSliderMuteIconSize

            text: root.muted ? "volume_off" : "volume_up"
            font.family: Theme.iconFamily
            font.pixelSize: Theme.volumeSliderMuteIconSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            // Цвет: при mute — fgMuted, при hover — accent, иначе fg.
            // muteHover.hovered — реактивный signal от HoverHandler ниже.
            color: muteHover.hovered
                ? Theme.volumeSliderMuteFgHover
                : (root.muted
                    ? Theme.volumeSliderMuteFgMuted
                    : Theme.volumeSliderMuteFg)

            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }

            HoverHandler {
                id: muteHover
                cursorShape: Qt.PointingHandCursor
            }

            // TapHandler даёт нам тап без конфликта с MouseArea трека
            // ниже (track-MouseArea не пересекается с этой зоной по
            // координатам). Сигналим наружу, состояние не меняем сами.
            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: root.muteToggled()
            }
        }

        // Подпись. Левый край — после mute-кнопки (с gap), правый —
        // до valueText. Если muteIcon выключен, muteBtn.width == 0 и
        // леворазмещение совпадает с прежним поведением.
        Text {
            anchors.left: muteBtn.right
            anchors.leftMargin: root.muteIcon ? Theme.volumeSliderMuteGap : 0
            anchors.verticalCenter: parent.verticalCenter
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

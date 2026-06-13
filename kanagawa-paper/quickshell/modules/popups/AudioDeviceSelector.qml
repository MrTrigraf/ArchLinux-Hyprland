import QtQuick
import "../services"
import "../../theme"

Item {
    id: root

    // ─── Публичное состояние ────────────────────────────────────────────
    // expanded: true — список развёрнут. Контролируется кликом по pill'у.
    property bool expanded: false

    // ─── Геометрия ──────────────────────────────────────────────────────
    // Закрытый: только ряд. Открытый: ряд + gap + список.
    // Список высотой = min(N, max) * itemHeight, где N — кол-во sinks.
    readonly property int _listVisibleCount:
        Math.min(AudioOutputModel.sinks.length, Theme.audioSelectorMaxVisible)
    readonly property int _listHeight:
        _listVisibleCount * Theme.audioSelectorItemHeight

    implicitHeight: Theme.audioDeviceRowHeight
                  + (expanded ? Theme.audioOutputRowGap + _listHeight : 0)

    Behavior on implicitHeight {
        NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuad }
    }

    // ─── Helper: PwNode → отображаемое имя ──────────────────────────────
    // Приоритет (по доке PwNode v0.3.0):
    //   nickname > description > name. nickname/description могут быть
    //   пустыми строками (а не null) — отсюда проверка != "".
    function deviceLabel(node) {
        if (!node) return "—"
        if (node.nickname && node.nickname !== "") return node.nickname
        if (node.description && node.description !== "") return node.description
        return node.name || "Без имени"
    }

    // ─── Ряд "текущее устройство" (pill) ────────────────────────────────
    Rectangle {
        id: pill
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Theme.audioDeviceRowHeight
        radius: Theme.audioDeviceRowRadius
        color: pillHover.hovered
            ? Qt.darker(Theme.audioDeviceRowBg, 1.1)
            : Theme.audioDeviceRowBg

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }

        // Иконка speaker слева.
        Text {
            id: pillIcon
            anchors.left: parent.left
            anchors.leftMargin: Theme.audioDeviceRowPaddingH
            anchors.verticalCenter: parent.verticalCenter
            text: "speaker"
            font.family: Theme.iconFamily
            font.pixelSize: Theme.audioDeviceRowIconSize
            color: Theme.fgSubtle
        }

        // Имя текущего default-sink'а посередине.
        Text {
            id: pillName
            anchors.left: pillIcon.right
            anchors.leftMargin: Theme.audioDeviceRowGap
            anchors.right: pillChevron.left
            anchors.rightMargin: Theme.audioDeviceRowGap
            anchors.verticalCenter: parent.verticalCenter

            text: root.deviceLabel(AudioOutputModel.sink)
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.audioDeviceRowFontSize
            elide: Text.ElideRight
        }

        // Chevron справа. Поворачивается при expanded.
        Text {
            id: pillChevron
            anchors.right: parent.right
            anchors.rightMargin: Theme.audioDeviceRowPaddingH
            anchors.verticalCenter: parent.verticalCenter
            text: "expand_more"
            font.family: Theme.iconFamily
            font.pixelSize: Theme.audioDeviceRowChevronSize
            color: Theme.fgSubtle
            rotation: root.expanded ? 180 : 0

            Behavior on rotation {
                NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuad }
            }
        }

        HoverHandler {
            id: pillHover
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: root.expanded = !root.expanded
        }
    }

    // ─── Раскрывающийся список sinks ────────────────────────────────────
    // ListView вместо Column+Repeater: получаем бесплатно скролл при
    // длинном списке (>audioSelectorMaxVisible). clip: true обрезает
    // содержимое по границам — без него скролл не "режется" по краю.
    ListView {
        id: sinksList
        anchors.top: pill.bottom
        anchors.topMargin: Theme.audioOutputRowGap
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.expanded ? root._listHeight : 0
        clip: true
        visible: root.expanded || height > 0     // скрываем, когда высота=0,
                                                  // чтобы не ловить hover.
        opacity: root.expanded ? 1 : 0

        Behavior on height {
            NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuad }
        }
        Behavior on opacity {
            NumberAnimation { duration: Theme.animFast }
        }

        model: AudioOutputModel.sinks
        spacing: 0

        delegate: Rectangle {
            id: item
            required property var modelData    // PwNode
            required property int index

            width: ListView.view.width
            height: Theme.audioSelectorItemHeight
            radius: Theme.audioSelectorItemRadius

            readonly property bool isCurrent:
                AudioOutputModel.sink && item.modelData
                && AudioOutputModel.sink.id === item.modelData.id

            color: itemHover.hovered
                ? Theme.accent
                : (item.isCurrent
                    ? Qt.rgba(0xb4/255, 0xa7/255, 0xb5/255, 0.10)
                    : "transparent")

            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }

            // Чекмарк слева, виден только у текущего устройства.
            // Width фиксирован — даже если чекмарка нет, заголовок не "прыгает"
            // при переключении.
            Text {
                id: itemCheck
                anchors.left: parent.left
                anchors.leftMargin: Theme.audioSelectorItemPaddingH
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.audioSelectorItemFontSize + 4
                text: item.isCurrent ? "check" : ""
                font.family: Theme.iconFamily
                font.pixelSize: Theme.audioSelectorItemFontSize
                color: itemHover.hovered
                    ? Theme.popupItemHoverFg
                    : Theme.accent
            }

            Text {
                anchors.left: itemCheck.right
                anchors.leftMargin: 4
                anchors.right: parent.right
                anchors.rightMargin: Theme.audioSelectorItemPaddingH
                anchors.verticalCenter: parent.verticalCenter
                text: root.deviceLabel(item.modelData)
                color: itemHover.hovered ? Theme.popupItemHoverFg : Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.audioSelectorItemFontSize
                elide: Text.ElideRight

                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }
            }

            HoverHandler {
                id: itemHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: {
                    AudioOutputModel.setDefaultSink(item.modelData)
                    // После выбора схлопываем список — лучший UX для
                    // фиксированной высоты попапа.
                    root.expanded = false
                }
            }
        }

        // Скроллбар появляется автоматически при overflow ListView'а:
        // используем встроенный механизм через ScrollIndicator из QtQuick.
        // Если ScrollIndicator не подключён в проекте — в крайнем случае
        // оставляем без явного индикатора, ListView сам обрабатывает drag.
    }
}

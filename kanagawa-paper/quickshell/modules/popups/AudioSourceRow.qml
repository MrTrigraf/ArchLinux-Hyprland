import QtQuick
import Quickshell.Services.Pipewire
import "../services"
import "../bar/components"
import "../../theme"

// ─────────────────────────────────────────────────────────────────────────
// AudioSourceRow.qml — карточка одного микрофона в Input-вкладке попапа.
// Вариант C дизайна (card+pill).
//
// Раскладка:
//   ┌─────────────────────────────────────────────────────────┐
//   │ 🎤  ALC256 Analog                            [DEFAULT]  │  ← header
//   │ ▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░                     │  ← meter
//   │ 🔊 (mute) ━━━━━━●━━━━━━━━━━  62%                        │  ← VolumeSlider
//   └─────────────────────────────────────────────────────────┘
//
// Особенности варианта C:
//   - Слева в header — иконка mic (FILL=1 у default, FILL=0 у остальных).
//   - Справа — pill "DEFAULT" (заполненная капсула) или "SET DEFAULT"
//     (контур). Это явное словесное обозначение состояния, лучше
//     читается, чем галочка в квадрате.
//   - Selected-card подсвечена рамкой accent + фоном accent ~12%.
//   - PeakMonitor включается только когда строка visible (вкладка Input
//     активна и попап открыт) — экономия CPU.
//
// Источники: AudioInputModel.{isDefault, setDefaultSource, setSourceVolume,
//            toggleSourceMute}, PwNodePeakMonitor.peak.
// ─────────────────────────────────────────────────────────────────────────

Rectangle {
    id: root

    // ─── Вход от родителя (Repeater/ListView delegate) ─────────────────
    required property var modelData    // PwNode (source-устройство)

    // ─── Геометрия ─────────────────────────────────────────────────────
    width: parent ? parent.width : 0
    height: Theme.audioSourceRowHeight
    radius: Theme.audioSourceRowRadius

    // ─── Реактивный признак "это текущий default-source" ──────────────
    // AudioInputModel.isDefault сравнивает по id через
    // Pipewire.defaultAudioSource (реактивно). Любое внешнее переключение
    // (wpctl, pavucontrol, наш checkmark) — карточка перекрасится.
    readonly property bool isDefault:
        AudioInputModel.isDefault(modelData)

    // Card-стиль: рамка + фон при selected.
    color: isDefault
        ? Theme.audioSourceRowSelectedBg
        : "transparent"
    border.color: isDefault
        ? Theme.audioSourceCardBorderActive
        : "transparent"
    border.width: Theme.audioSourceCardBorderWidth

    Behavior on color {
        ColorAnimation { duration: Theme.animFast }
    }
    Behavior on border.color {
        ColorAnimation { duration: Theme.animFast }
    }

    // ─── Имя устройства → отображаемая подпись ─────────────────────────
    // Приоритет nickname > description > name, как в AudioDeviceSelector.
    function deviceLabel(node) {
        if (!node) return "—"
        if (node.nickname && node.nickname !== "") return node.nickname
        if (node.description && node.description !== "") return node.description
        return node.name || "Без имени"
    }

    // ─── PwNodePeakMonitor: capture только когда строка visible ────────
    // Когда вкладка Input невидима (активна Output) или попап закрыт —
    // visible: false каскадно → enabled: false → capture останавливается.
    PwNodePeakMonitor {
        id: peakMonitor
        node: root.modelData
        enabled: root.visible
    }

    // ─── 1. Header: 🎤 + имя + [DEFAULT pill] ──────────────────────────
    Item {
        id: header
        anchors.top: parent.top
        anchors.topMargin: Theme.audioSourceRowPaddingV
        anchors.left: parent.left
        anchors.leftMargin: Theme.audioSourceRowPaddingH
        anchors.right: parent.right
        anchors.rightMargin: Theme.audioSourceRowPaddingH
        height: Theme.audioDefaultPillHeight   // = 18, доминирующая высота

        // Иконка mic слева. FILL=1 у default-source (визуально "светится").
        Text {
            id: micIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "mic"
            font.family: Theme.iconFamily
            font.pixelSize: Theme.audioSourceMicIconSize
            color: root.isDefault ? Theme.accent : Theme.fgMuted
            font.variableAxes: ({ FILL: root.isDefault ? 1 : 0 })

            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }
        }

        // Имя устройства посередине.
        Text {
            id: nameLabel
            anchors.left: micIcon.right
            anchors.leftMargin: Theme.audioSourceHeaderGap
            anchors.right: defaultPill.left
            anchors.rightMargin: Theme.audioSourceHeaderGap
            anchors.verticalCenter: parent.verticalCenter

            text: root.deviceLabel(root.modelData)
            color: root.isDefault ? Theme.accent : Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.audioSourceLabelFontSize
            font.weight: root.isDefault ? Font.Medium : Font.Normal
            elide: Text.ElideRight

            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }
        }

        // Pill "DEFAULT" / "SET DEFAULT" справа.
        Rectangle {
            id: defaultPill
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: Theme.audioDefaultPillHeight
            radius: Theme.audioDefaultPillRadius
            // Width растягивается по содержимому + horizontal padding.
            width: pillLabel.implicitWidth + 2 * Theme.audioDefaultPillPaddingH

            color: root.isDefault
                ? Theme.audioDefaultPillActiveBg
                : "transparent"
            border.color: root.isDefault
                ? Theme.audioDefaultPillActiveBg
                : Theme.audioDefaultPillInactiveBorder
            border.width: 1
            opacity: root.isDefault ? 1.0 : (pillHover.hovered ? 1.0 : 0.7)

            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }
            Behavior on border.color {
                ColorAnimation { duration: Theme.animFast }
            }
            Behavior on opacity {
                NumberAnimation { duration: Theme.animFast }
            }

            Text {
                id: pillLabel
                anchors.centerIn: parent
                text: root.isDefault ? "DEFAULT" : "SET DEFAULT"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.audioDefaultPillFontSize
                font.weight: Font.Bold
                color: root.isDefault
                    ? Theme.audioDefaultPillActiveFg
                    : Theme.audioDefaultPillInactiveFg

                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }
            }

            HoverHandler {
                id: pillHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: {
                    // Идемпотентность: повторный клик по DEFAULT-pill
                    // не дёргает Pipewire (избегаем лишних метадата-set'ов).
                    if (!root.isDefault) {
                        AudioInputModel.setDefaultSource(root.modelData)
                    }
                }
            }
        }
    }

	// ─── 2. Peak meter ─────────────────────────────────────────────────
    // height задан явно: при anchors top+left+right (без bottom) QtQuick
    // не всегда подхватывает implicitHeight компонента, и полоска
    // схлопывается в 0 px. Дублируем из Theme — гарантированно видно.
    PeakMeter {
        id: meter
        anchors.top: header.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.leftMargin: Theme.audioSourceRowPaddingH
        anchors.right: parent.right
        anchors.rightMargin: Theme.audioSourceRowPaddingH
        height: Theme.audioPeakMeterHeight
        value: peakMonitor.peak
        active: root.isDefault
    }

    // ─── 3. VolumeSlider (с mute-кнопкой) ──────────────────────────────
    VolumeSlider {
        id: slider
        anchors.top: meter.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.leftMargin: Theme.audioSourceRowPaddingH
        anchors.right: parent.right
        anchors.rightMargin: Theme.audioSourceRowPaddingH

        // Label пустой: имя устройства уже в header'е.
        label: ""

        value: root.modelData?.audio?.volume ?? 0
        muted: root.modelData?.audio?.muted ?? false
        muteIcon: true        // mute-кнопка слева, как договорились в этапе 4

        onUserChanged: (newValue) => {
            if (!root.modelData?.audio) return
            // Drag = "хочу слышать/говорить" → авто-снятие mute.
            if (root.modelData.audio.muted) {
                AudioInputModel.toggleSourceMute(root.modelData)
            }
            AudioInputModel.setSourceVolume(root.modelData, newValue)
        }

        onMuteToggled: {
            AudioInputModel.toggleSourceMute(root.modelData)
        }
    }
}

import QtQuick
import Quickshell
import "../bar/components"
import "../services"
import "../../theme"

// ─────────────────────────────────────────────────────────────────────────
// AudioPopup.qml — главный попап звука. Заменил старый VolumePopup.
//
// Структура:
//   ┌───────────────────────────────────────────────────────┐
//   │  [ 🎤 Ввод ]      [ 🔊 Вывод (active) ]               │  ← шапка-табы
//   │                                                       │
//   │  <содержимое активной вкладки>                        │  ← body
//   │                                                       │
//   └───────────────────────────────────────────────────────┘
//
// Дефолтная вкладка при открытии — Output (по требованию ТЗ).
// При повторном открытии после закрытия — снова Output, даже если в
// прошлый раз закрыли на Input. Это сбрасывается в onVisibleChanged.
//
// Высота попапа ФИКСИРОВАНА: обе вкладки (_outputBodyHeight и
// _inputBodyHeight) считаются по максимуму резервируемых слотов
// (audioMaxVisibleApps / audioMaxVisibleSources), независимо от
// реального числа streams/sources. Это закрывает регресс ghost-rendering
// из чата 12, который вылез повторно при апдейте звукового стека.
//
// Tabs visual: активный — заливка accent 16% + рамка accent, неактивный —
// opacity 0.55 (тот же приём, что в NetworkPopup из чата 11–12).
// ─────────────────────────────────────────────────────────────────────────

PopupBase {
    id: root

    // ─── Состояние ──────────────────────────────────────────────────────
    // 0 = Output (по умолчанию, по ТЗ), 1 = Input.
    // Int вместо enum — в QML enum'ы требуют отдельных файлов через qmldir,
    // что для двух значений overkill.
    property int currentTab: 0

    // Удобные читалки для делегатов и body-Loader'а.
    readonly property bool isOutput: currentTab === 0
    readonly property bool isInput:  currentTab === 1

    // ─── Сброс на Output при каждом открытии попапа ───────────────────
    onVisibleChanged: {
        if (visible) currentTab = 0
    }

    // ─── Размеры ────────────────────────────────────────────────────────
    contentWidth: Theme.audioPopupWidth

    // Высота вкладки Output: фикс. независимо от числа streams.
    // Раскладка:
    //   selector(36) + gap(6) + system-slider(32) + gap(6) +
    //   + sep(1) + gap(6) + apps-area(audioMaxVisibleApps × 36) + bottom-pad(3)
    readonly property int _outputBodyHeight: {
        var sliderH = Theme.volumeSliderLabelSize
                    + Theme.volumeSliderLabelGap
                    + Theme.volumeSliderHandleSize
        var appsItemH = sliderH + 4
        return Theme.audioDeviceRowHeight
             + Theme.audioOutputRowGap
             + sliderH
             + Theme.audioOutputRowGap + Theme.audioSeparatorHeight
             + Theme.audioOutputRowGap
             + Theme.audioMaxVisibleApps * appsItemH
             + Theme.audioBodyBottomPadding
    }

    // Высота вкладки Input: фикс. независимо от числа sources.
    // Резервируем audioMaxVisibleSources × audioSourceRowHeight плюс
    // gap'ы между ними плюс отступ снизу.
    readonly property int _inputBodyHeight: {
        var n = Theme.audioMaxVisibleSources
        return n * Theme.audioSourceRowHeight
             + (n - 1) * Theme.audioSourceRowGap
             + Theme.audioBodyBottomPadding
    }

    // Высота тела попапа = max двух фиксированных вкладок. Обе уже
    // фиксированы → max тоже фиксирован → попап не "прыгает" никогда.
    readonly property int _bodyHeight:
        Math.max(_outputBodyHeight, _inputBodyHeight)

    contentHeight: 2 * Theme.audioPopupContentPadding
                 + Theme.audioTabsRowHeight
                 + Theme.audioPopupTabsGap
                 + _bodyHeight

    // ─── Содержимое: шапка-табы + body ─────────────────────────────────
    Column {
        anchors.fill: parent
        anchors.margins: Theme.audioPopupContentPadding
        spacing: Theme.audioPopupTabsGap

        // ── Шапка-селектор Input | Output ─────────────────────────────
        Row {
            id: tabs
            width: parent.width
            height: Theme.audioTabsRowHeight
            spacing: Theme.audioTabHGap

            // Левый таб — Ввод (mic)
            Rectangle {
                id: inputTab
                width: (parent.width - Theme.audioTabHGap) / 2
                height: parent.height
                radius: Theme.audioTabRadius

                color: root.isInput
                    ? Theme.audioTabActiveBg
                    : "transparent"
                border.color: root.isInput
                    ? Theme.audioTabActiveBorder
                    : "transparent"
                border.width: 1
                opacity: root.isInput ? 1.0 : Theme.audioTabDimOpacity

                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }
                Behavior on border.color {
                    ColorAnimation { duration: Theme.animFast }
                }
                Behavior on opacity {
                    NumberAnimation { duration: Theme.animFast }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.audioTabIconGap

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "mic"
                        font.family: Theme.iconFamily
                        font.pixelSize: Theme.audioTabIconSize
                        color: Theme.audioTabFg
                        // FILL=1 у активной иконки, FILL=0 у неактивной —
                        // согласовано с приёмом из NotificationsPopup.
                        font.variableAxes: ({ FILL: root.isInput ? 1 : 0 })
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Ввод"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.audioTabFontSize
                        color: Theme.audioTabFg
                    }
                }

                HoverHandler {
                    id: inputTabHover
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: root.currentTab = 1
                }
            }

            // Правый таб — Вывод (volume_up)
            Rectangle {
                id: outputTab
                width: (parent.width - Theme.audioTabHGap) / 2
                height: parent.height
                radius: Theme.audioTabRadius

                color: root.isOutput
                    ? Theme.audioTabActiveBg
                    : "transparent"
                border.color: root.isOutput
                    ? Theme.audioTabActiveBorder
                    : "transparent"
                border.width: 1
                opacity: root.isOutput ? 1.0 : Theme.audioTabDimOpacity

                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }
                Behavior on border.color {
                    ColorAnimation { duration: Theme.animFast }
                }
                Behavior on opacity {
                    NumberAnimation { duration: Theme.animFast }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.audioTabIconGap

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "volume_up"
                        font.family: Theme.iconFamily
                        font.pixelSize: Theme.audioTabIconSize
                        color: Theme.audioTabFg
                        font.variableAxes: ({ FILL: root.isOutput ? 1 : 0 })
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Вывод"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.audioTabFontSize
                        color: Theme.audioTabFg
                    }
                }

                HoverHandler {
                    id: outputTabHover
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: root.currentTab = 0
                }
            }
        }

        // ── Body: содержимое активной вкладки ─────────────────────────
        // Обе вкладки СОЗДАНЫ всегда, не пересоздаются при переключении —
        // visible управляет отображением. Это даёт два важных свойства:
        //   1) PeakMonitor'ы внутри AudioInputTab.AudioSourceRow получают
        //      visible: false когда активна Output → capture останавливается
        //      и CPU свободен. Это работает каскадно через QtQuick.
        //   2) AudioDeviceSelector сохраняет своё expanded-состояние при
        //      переключении вкладок — если открыли список sinks, переключились
        //      на Input и обратно, список всё ещё развёрнут.
        Item {
            id: body
            width: parent.width
            height: root._bodyHeight

            AudioOutputTab {
                anchors.fill: parent
                visible: root.isOutput
            }

            AudioInputTab {
                anchors.fill: parent
                visible: root.isInput
            }
        }
    }
}
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../components"
import "../../../theme"
import "../../services"

WrapperRectangle {
    id: root

    resizeChild: false
    leftMargin:   Theme.sectionPillPaddingH
    rightMargin:  Theme.sectionPillPaddingH
    topMargin:    Theme.sectionPillPaddingV
    bottomMargin: Theme.sectionPillPaddingV

    color: Theme.sectionBg
    radius: Theme.sectionPillRadius

    property var barWindow: null

    signal clockClicked(int clockLocalX)
	signal volumeClicked(int volumeLocalX)
	signal batteryClicked(int batteryLocalX)
	signal networkClicked(int networkLocalX)

    // ─── Системные часы (реактивно по минуте) ─────────────────────────────
    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    RowLayout {
        spacing: Theme.iconGap

        // ─── 1. Layout-индикатор EN/RU ────────────────────────────────────
        Item {
            id: layoutSlot
            implicitWidth:  Theme.layoutIndicatorWidth
            implicitHeight: Theme.fontSizeBar

            readonly property bool isHovered: layoutHover.hovered

            Text {
                anchors.fill: parent
                text: KeyboardLayoutModel.currentShortName
                color: layoutSlot.isHovered
                    ? Theme.layoutIndicatorFgHover
                    : Theme.layoutIndicatorFg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.layoutIndicatorFontSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: KeyboardLayoutModel.toggleLayout()
            }

            HoverHandler {
                id: layoutHover
                cursorShape: Qt.PointingHandCursor
            }
        }

        // ─── 2. Network-иконка ────────────────────────────────────────────
        // Приоритет глифа: Wi-Fi (с градацией по сигналу) → Ethernet → off.
        // Цвет — два состояния: Theme.fg (есть коннект) / Theme.statusError
        // (нет связи). При hover — Theme.accent, как у других слотов.
        Item {
            id: networkSlot
            implicitWidth:  Theme.volumeIconSize
            implicitHeight: Theme.volumeIconSize

            readonly property bool isHovered: networkHover.hovered

            readonly property string iconGlyph: {
                if (NetworkModel.wifiConnected) {
                    var s = NetworkModel.activeSignal || 0
                    if (s >= 0.75) return "signal_wifi_4_bar"
                    if (s >= 0.50) return "network_wifi_3_bar"
                    if (s >= 0.25) return "network_wifi_2_bar"
                    return "network_wifi_1_bar"
                }
                if (NetworkModel.wiredConnected) return "settings_ethernet"
                return "signal_wifi_off"
            }

            Text {
                anchors.fill: parent
                text: networkSlot.iconGlyph
                color: networkSlot.isHovered
                    ? Theme.accent
                    : (NetworkModel.anyConnected ? Theme.fg : Theme.statusError)
                font.family: Theme.iconFamily
                font.pixelSize: Theme.volumeIconSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: {
                    var localX = 0
                    if (root.barWindow !== null && root.barWindow !== undefined) {
                        var p = networkSlot.mapToItem(root.barWindow.contentItem, 0, 0)
                        localX = Math.round(p.x)
                    }
                    root.networkClicked(localX)
                }
            }

            HoverHandler {
                id: networkHover
                cursorShape: Qt.PointingHandCursor
            }
        }

        // ─── 3. Volume-иконка ─────────────────────────────────────────────
        Item {
            id: volumeSlot
            implicitWidth:  Theme.volumeIconSize
            implicitHeight: Theme.volumeIconSize

            readonly property bool isHovered: volumeHover.hovered

            // Выбор глифа Material Symbols по уровню громкости и mute.
            // Hyprland Material Symbols входят в iconFamily.
            readonly property string iconGlyph: {
                if (VolumeModel.muted) return "volume_off"
                var v = VolumeModel.volume
                if (v <= 0.33) return "volume_mute"
                if (v <= 0.66) return "volume_down"
                return "volume_up"
            }

            Text {
                anchors.fill: parent
                text: volumeSlot.iconGlyph
                color: volumeSlot.isHovered ? Theme.accent : Theme.fg
                font.family: Theme.iconFamily
                font.pixelSize: Theme.volumeIconSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: {
                    var localX = 0
                    if (root.barWindow !== null && root.barWindow !== undefined) {
                        var p = volumeSlot.mapToItem(root.barWindow.contentItem, 0, 0)
                        localX = Math.round(p.x)
                    }
                    root.volumeClicked(localX)
                }
            }

            HoverHandler {
                id: volumeHover
                cursorShape: Qt.PointingHandCursor
			}

			// Скролл по иконке — меняет системную громкость.
            // delta > 0 — колесо вверх → громче.
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: (event) => {
                    var step = event.angleDelta.y > 0
                        ? Theme.volumeScrollStep
                        : -Theme.volumeScrollStep
                    // Если sink в mute и юзер крутит вверх — снимаем mute.
                    // Если крутит вниз при mute — оставляем mute (логично:
                    // выкручиваешь "до тишины", повторная попытка не нужна).
                    if (VolumeModel.muted && step > 0) {
                        VolumeModel.toggleMute()
                    }
                    VolumeModel.changeVolume(step)
                }
            }
        }

        // ─── 4. Часы HH:MM (кликабельные → CalendarPopup) ─────────────────
        Item {
            id: clockSlot
            implicitWidth:  Theme.clockSlotWidth
            implicitHeight: Theme.fontSizeBar

            readonly property bool isHovered: clockHover.hovered

            Text {
                id: clockText
                anchors.fill: parent
                text: Qt.formatDateTime(sysClock.date, "HH:mm")
                color: clockSlot.isHovered ? Theme.accent : Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBar
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: {
                    var localX = 0
                    if (root.barWindow !== null && root.barWindow !== undefined) {
                        var p = clockSlot.mapToItem(root.barWindow.contentItem, 0, 0)
                        localX = Math.round(p.x)
                    }
                    root.clockClicked(localX)
                }
            }

            HoverHandler {
                id: clockHover
                cursorShape: Qt.PointingHandCursor
            }
        }

		// ─── 5. Battery icon (правее часов, только ноут) ──────────────────
        // --- desktop: comment out the battery block (no battery) ---
        Item {
            id: batterySlot
            implicitWidth:  Theme.batteryIconSize
            implicitHeight: Theme.batteryIconSize

            readonly property bool isHovered: batteryHover.hovered

            // Локальные animated properties для variable axes Material Symbols.
            // Behavior on real/int работает; на dict font.variableAxes напрямую —
            // нет, поэтому держим оси в отдельных свойствах с биндингом на
            // BatteryModel и анимируем их переходы здесь.
            property real animFill:   BatteryModel.iconFill
            property int  animWeight: BatteryModel.iconWeight

            Behavior on animFill {
                NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic }
            }
            Behavior on animWeight {
                NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic }
            }

            Text {
                anchors.fill: parent
                text: BatteryModel.iconGlyph
                color: batterySlot.isHovered ? Theme.accent : BatteryModel.iconColor
                font.family: Theme.iconFamily
                font.pixelSize: Theme.batteryIconSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                font.variableAxes: ({
                    FILL: batterySlot.animFill,
                    wght: batterySlot.animWeight,
                    opsz: 24,
                    GRAD: 0
                })

                Behavior on color {
                    ColorAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic }
                }
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: {
                    var localX = 0
                    if (root.barWindow !== null && root.barWindow !== undefined) {
                        var p = batterySlot.mapToItem(root.barWindow.contentItem, 0, 0)
                        localX = Math.round(p.x)
                    }
                    root.batteryClicked(localX)
                }
            }

            HoverHandler {
                id: batteryHover
                cursorShape: Qt.PointingHandCursor
            }
        }
        // --- end of battery block ---
    }
}

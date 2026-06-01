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
        // ─── 2. Volume-иконка ─────────────────────────────────────────────
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

        // ─── 3. Часы HH:MM (кликабельные → CalendarPopup) ─────────────────
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
    }
}

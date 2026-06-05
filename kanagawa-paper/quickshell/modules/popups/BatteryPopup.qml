import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../services"
import "../../theme"

PopupBase {
    id: root

    contentWidth: Theme.batteryPopupWidth

    readonly property int sectionHeight: Theme.volumeSliderLabelSize
                                       + Theme.volumeSliderLabelGap
                                       + Theme.volumeSliderHandleSize

    contentHeight: 3 * sectionHeight
                 + 2 * Theme.batteryPopupRowGap
                 + 2 * Theme.popupContentPadding

	// ── Refresh UPower при открытом попапе ─────────────────────────────
	Timer {
        interval: 5000                  // каждые 5 секунд
        running: root.isOpen            // активен только при открытом попапе
        repeat: true
        triggeredOnStart: true          // дёрнуть сразу при открытии
        onTriggered: Quickshell.execDetached([
            "busctl", "--system", "call",
            "org.freedesktop.UPower",
            "/org/freedesktop/UPower/devices/DisplayDevice",
            "org.freedesktop.UPower.Device",
            "Refresh"
        ])
    }

    Column {
        anchors.fill: parent
        spacing: Theme.batteryPopupRowGap

        Column {
            id: profileSection
            width: parent.width
            spacing: Theme.volumeSliderLabelGap

            readonly property int profileIndex: {
                if (PowerProfiles.profile === PowerProfile.PowerSaver)   return 0
                if (PowerProfiles.profile === PowerProfile.Balanced)     return 1
                if (PowerProfiles.profile === PowerProfile.Performance)  return 2
                return 1
            }

            readonly property var profileNames: ["Power saver", "Balanced", "Boost"]
            readonly property var profileEnums: [
                PowerProfile.PowerSaver,
                PowerProfile.Balanced,
                PowerProfile.Performance
            ]

            function setProfile(idx) {
                var target = profileEnums[idx]
                if (target === PowerProfile.Performance
                    && !PowerProfiles.hasPerformanceProfile) return
                PowerProfiles.profile = target
            }

            Item {
                width: parent.width
                height: Theme.volumeSliderLabelSize

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Profile"
                    color: Theme.volumeSliderLabelFg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.volumeSliderLabelSize
                }
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: profileSection.profileNames[profileSection.profileIndex]
                    color: Theme.volumeSliderValueFg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.volumeSliderLabelSize
                }
            }

            Item {
                id: profileBody
                width: parent.width
                height: Theme.volumeSliderHandleSize

                readonly property real handleR: Theme.volumeSliderHandleSize / 2
                readonly property real trackX:  handleR
                readonly property real trackW:  width - 2 * handleR

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: profileBody.trackX
                    width: profileBody.trackW
                    height: Theme.volumeSliderTrackHeight
                    radius: height / 2
                    color: Theme.volumeSliderTrackBg
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: profileBody.trackX
                    width: profileBody.trackW * profileSection.profileIndex / 2
                    height: Theme.volumeSliderTrackHeight
                    radius: height / 2
                    color: Theme.volumeSliderTrackFg

                    Behavior on width {
                        NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic }
                    }
                }

                Repeater {
                    model: 3
                    Rectangle {
                        required property int index
                        width: 5; height: 5
                        radius: 2.5
                        color: Theme.background
                        border.width: 1.2
                        border.color: Theme.volumeSliderTrackFg
                        x: profileBody.trackX + index * profileBody.trackW / 2 - width / 2
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    width: Theme.volumeSliderHandleSize
                    height: Theme.volumeSliderHandleSize
                    radius: width / 2
                    color: Theme.volumeSliderHandleBg
                    x: profileBody.trackX + profileBody.trackW * profileSection.profileIndex / 2 - width / 2
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on x {
                        NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    function pickIndex(mouseX) {
                        var rel = (mouseX - profileBody.trackX) / profileBody.trackW
                        var clamped = Math.max(0, Math.min(1, rel))
                        return Math.round(clamped * 2)
                    }

                    onPressed: (mouse) => profileSection.setProfile(pickIndex(mouse.x))
                    onPositionChanged: (mouse) => {
                        if (pressed) profileSection.setProfile(pickIndex(mouse.x))
                    }
                }
            }
        }

        Column {
            id: chargeSection
            width: parent.width
            spacing: Theme.volumeSliderLabelGap

            Item {
                width: parent.width
                height: Theme.volumeSliderLabelSize

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Charge"
                    color: Theme.volumeSliderLabelFg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.volumeSliderLabelSize
                }
               Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(BatteryModel.percentage) + "%"
                        + (BatteryModel.timeLabel ? " · " + BatteryModel.timeLabel : "")
                    color: Theme.volumeSliderValueFg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.volumeSliderLabelSize
                }
            }

            Item {
                id: chargeBody
                width: parent.width
                height: Theme.volumeSliderHandleSize

                readonly property real handleR: Theme.volumeSliderHandleSize / 2
                readonly property real trackX:  handleR
                readonly property real trackW:  width - 2 * handleR

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: chargeBody.trackX
                    width: chargeBody.trackW
                    height: Theme.volumeSliderTrackHeight
                    radius: height / 2
                    color: Theme.volumeSliderTrackBg
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: chargeBody.trackX
                    width: chargeBody.trackW * BatteryModel.percentage / 100
                    height: Theme.volumeSliderTrackHeight
                    radius: height / 2
                    color: BatteryModel.fillColor

                    Behavior on width {
                        NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic }
                    }
                    Behavior on color {
                        ColorAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic }
                    }
                }
            }
        }

        Column {
            id: brightnessSection
            width: parent.width
            spacing: Theme.volumeSliderLabelGap

            Item {
                width: parent.width
                height: Theme.volumeSliderLabelSize

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Brightness"
                    color: Theme.volumeSliderLabelFg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.volumeSliderLabelSize
                }
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(BrightnessModel.value * 100) + "%"
                    color: Theme.volumeSliderValueFg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.volumeSliderLabelSize
                }
            }

            Item {
                id: brightnessBody
                width: parent.width
                height: Theme.volumeSliderHandleSize

                readonly property real iconZone: Theme.brightnessIconSize + 6
                readonly property real handleR:  Theme.volumeSliderHandleSize / 2
                readonly property real trackX:   iconZone + handleR
                readonly property real trackW:   width - 2 * trackX

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "brightness_low"
                    color: Theme.fgSubtle
                    font.family: Theme.iconFamily
                    font.pixelSize: Theme.brightnessIconSize
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "brightness_high"
                    color: Theme.fgSubtle
                    font.family: Theme.iconFamily
                    font.pixelSize: Theme.brightnessIconSize
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: brightnessBody.trackX
                    width: brightnessBody.trackW
                    height: Theme.volumeSliderTrackHeight
                    radius: height / 2
                    color: Theme.volumeSliderTrackBg
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: brightnessBody.trackX
                    width: brightnessBody.trackW * BrightnessModel.value
                    height: Theme.volumeSliderTrackHeight
                    radius: height / 2
                    color: Theme.volumeSliderTrackFg
                }

                Rectangle {
                    width: Theme.volumeSliderHandleSize
                    height: Theme.volumeSliderHandleSize
                    radius: width / 2
                    color: Theme.volumeSliderHandleBg
                    x: brightnessBody.trackX + brightnessBody.trackW * BrightnessModel.value - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    function valueFromX(mx) {
                        var rel = (mx - brightnessBody.trackX) / brightnessBody.trackW
                        return Math.max(0, Math.min(1, rel))
                    }

                    onPressed: (mouse) => BrightnessModel.setValue(valueFromX(mouse.x))
                    onPositionChanged: (mouse) => {
                        if (pressed) BrightnessModel.setValue(valueFromX(mouse.x))
                    }
                }
            }
        }
    }
}

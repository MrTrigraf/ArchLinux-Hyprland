pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../../theme"

Singleton {
    id: root

    // ── Источник данных ────────────────────────────────────────────────
    readonly property var device: UPower.displayDevice
    readonly property bool ready: device.ready && device.isLaptopBattery

    // ── Сырые значения от UPower ───────────────────────────────────────
    readonly property real percentage: ready ? device.percentage : 0
    readonly property int  state:      ready ? device.state : UPowerDeviceState.Unknown

    // ── Производные булевы для UI ──────────────────────────────────────
    readonly property bool charging: state === UPowerDeviceState.Charging
                                   || state === UPowerDeviceState.PendingCharge

    readonly property bool pluggedIn: charging
                                   || state === UPowerDeviceState.FullyCharged

    // ── Глиф иконки в баре ─────────────────────────────────────────────
    readonly property string iconGlyph: {
        if (charging) {
            if (percentage >= 87.5) return "battery_full"
            if (percentage >= 62.5) return "battery_charging_90"
            if (percentage >= 37.5) return "battery_charging_50"
            return "battery_charging_20"
        }
        // Разрядка или FullyCharged без активной зарядки
        if (percentage >= 87.5) return "battery_full"
        if (percentage >= 62.5) return "battery_6_bar"
        if (percentage >= 37.5) return "battery_4_bar"
        if (percentage >= 17.5) return "battery_2_bar"
        return "battery_alert"
    }

    // ── Цвет иконки в баре ─────────────────────────────────────────────
    readonly property color iconColor: {
        if (pluggedIn) return Theme.statusOk
        if (percentage >= 87.5) return Theme.statusOk
        if (percentage >= 62.5) return Theme.statusCaution
        if (percentage >= 37.5) return Theme.statusWarn
        return Theme.statusError
    }

    // ── Variable axes для Material Symbols Rounded ─────────────────────
    // FILL ось (0..1): outline / filled.
    readonly property real iconFill: (pluggedIn || percentage < 17.5) ? 1.0 : 0.0

    // wght ось (100..700): толщина штриха.
    readonly property int iconWeight: (!pluggedIn && percentage < 17.5) ? 700 : 500

    // ── Цвет fill для прогресс-бара заряда в попапе ────────────────────
    readonly property color fillColor: {
        if (percentage >= 87.5) return Theme.statusOk
        if (percentage >= 62.5) return Theme.statusCaution
        if (percentage >= 37.5) return Theme.statusWarn
        return Theme.statusError
    }
}

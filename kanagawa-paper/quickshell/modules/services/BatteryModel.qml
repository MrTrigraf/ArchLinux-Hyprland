pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Io
import "../../theme"

Singleton {
    id: root

    // ── Источник данных ────────────────────────────────────────────────
    readonly property var device: UPower.displayDevice
    readonly property bool ready: device.ready && device.isLaptopBattery
	readonly property bool hasBattery: device.isLaptopBattery

    // ── Сырые значения от UPower ───────────────────────────────────────
    readonly property real percentage: ready ? device.percentage * 100 : 0
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

	// ── Оставшееся время в минутах ─────────────────────────────────────
    readonly property int minutesRemaining: {
        if (!ready) return 0
        if (state === UPowerDeviceState.FullyCharged) return 0
        if (charging) return Math.round(device.timeToFull / 60)
        if (state === UPowerDeviceState.Discharging) return Math.round(device.timeToEmpty / 60)
        return 0
    }

    // ── Форматированная строка времени ─────────────────────────────────
    readonly property string timeLabel: {
        if (!ready) return ""
        if (state === UPowerDeviceState.FullyCharged) return "полный"
        const m = minutesRemaining
        if (m <= 0) return ""              // changeRate ещё не стабилизировался
        const hours = Math.floor(m / 60)
        const mins  = m % 60
        if (hours >= 24) return hours + "ч"   // очень большое время — без минут
        if (hours === 0) return mins + "м"
        return hours + "ч " + mins + "м"
    }

    // ───Уведомления о низком заряде ────────────────────────────────────────
    // Последний порог, по которому уже отправили уведомление.
    // 100 = ни одного, всё впереди. После 5% станет 5.
    property int lastNotifiedThreshold: 100

    // Декларативный список порогов: от высокого к низкому.
    // Все три — обычные системные уведомления (urgency=normal → tier=system).
    readonly property var batteryThresholds: [
        { pct: 30, icon: "battery-low",     summary: "Заряд батареи 30%" },
        { pct: 15, icon: "battery-caution", summary: "Заряд батареи 15%" },
        { pct:  5, icon: "battery-empty",   summary: "Заряд батареи 5%"  }
    ]

    // Реакция на изменение процента: ищем самый низкий из не-отправленных порогов.
    onPercentageChanged: {
        if (!ready || pluggedIn) return
        var triggered = null
        for (var i = 0; i < batteryThresholds.length; ++i) {
            var t = batteryThresholds[i]
            if (percentage <= t.pct && lastNotifiedThreshold > t.pct) {
                triggered = t   // перезаписываем — нужен самый низкий
            }
        }
        if (triggered) {
            sendLowBatteryNotification(triggered)
            lastNotifiedThreshold = triggered.pct
        }
    }

    // Подключили зарядку — сбрасываем счётчик. Следующая разрядка
    // снова покажет все три уведомления при пересечении порогов.
    onPluggedInChanged: {
        if (pluggedIn) lastNotifiedThreshold = 100
    }

    // Отправка уведомления через notify-send (внешний процесс).
    function sendLowBatteryNotification(t) {
        notifyProc.command = [
            "notify-send",
            "-a", "Battery",
            "-u", "normal",
            "-i", t.icon,
            "-h", "string:category:device.battery",
            t.summary
        ]
        notifyProc.startDetached()
    }

    // Process для запуска notify-send. Команда подменяется перед каждым вызовом.
    Process { id: notifyProc; command: [] }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ── Публичное состояние ────────────────────────────────────────────
    // value: 0..1. Локальный source of truth — мы не поллим внешние
    // изменения. При setValue() обновляется оптимистично (без ожидания
    // exit-кода brightnessctl).
    property real value: 0.5

    // available: true когда brightnessctl при старте вернул валидный
    // вывод с устройством backlight. На десктопе будет false.
    property bool available: false

    // ── Чтение текущей яркости при старте ──────────────────────────────
    // brightnessctl -m — machine-readable формат через запятые:
    //   device,class,current,percent_with_sign,max
    // Пример:  intel_backlight,backlight,28235,24%,120000
    // Берём 4-е поле (индекс 3), убираем "%", делим на 100.
    Process {
        id: readProc
        command: ["brightnessctl", "-m"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = root._parse(this.text)
                if (parsed !== null) {
                    root.value = parsed
                    root.available = true
                } else {
                    root.available = false
                }
            }
        }
    }

    // ── Парсер вывода `brightnessctl -m` ───────────────────────────────
    // Возвращает значение 0..1 либо null при невалидном/пустом вводе.
    // Префикс _ — внутренняя функция, не для использования снаружи.
    function _parse(text) {
        const trimmed = (text || "").trim()
        if (!trimmed) return null
        const parts = trimmed.split(",")
        if (parts.length < 4) return null
        const percentStr = parts[3].replace("%", "")
        const percent = parseInt(percentStr, 10)
        if (isNaN(percent)) return null
        return percent / 100.0
    }

    // ── Публичный метод записи ─────────────────────────────────────────
	readonly property real minValue: 0.05

    function setValue(v) {
        const clamped = Math.max(minValue, Math.min(1, v))
        const percent = Math.round(clamped * 100)
        Quickshell.execDetached(["brightnessctl", "set", percent + "%"])
        root.value = clamped
    }
}

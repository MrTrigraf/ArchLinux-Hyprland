pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    // ─── Состояние ──────────────────────────────────────────────────────
    // Длинное имя из Hyprland ("English (US)", "Russian", ...).
    property string currentLayoutLong: ""

    // Короткое имя для UI. Вычисляется реактивно из currentLayoutLong.
    readonly property string currentShortName: shortNameOf(currentLayoutLong)

    // ─── Маппинг длинных имён в двухбуквенные коды ──────────────────────
    // Если в будущем добавятся другие раскладки — добавляй строки сюда.
    function shortNameOf(longName) {
        if (!longName || longName.length === 0) return "??"
        var s = longName.toLowerCase()
        if (s.indexOf("english") !== -1) return "EN"
        if (s.indexOf("russian") !== -1) return "RU"
        // Фоллбэк: первые 2 символа длинного имени в верхнем регистре.
        // Лучше, чем "??", если в системе раскладка, которую мы не учли.
        return longName.substring(0, 2).toUpperCase()
    }

    // ─── Переключение раскладки ─────────────────────────────────────────
    function toggleLayout() {
        Hyprland.dispatch('hl.dsp.exec_raw("switchxkblayout, all, next")')
    }

    // ─── Источник 1: начальное состояние через hyprctl ──────────────────
    // running: true стартует процесс при загрузке Singleton'а.
    // Парсим JSON, ищем клавиатуру с main:true, читаем active_keymap.
    //
    // В случае многих клавиатур (внешняя на ноуте) Hyprland помечает одну
    // как main. Если main по какой-то причине не найдена — берём первую
    // подходящую как fallback.
    Process {
        id: initialQuery
        command: ["hyprctl", "-j", "devices"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text)
                    var keyboards = data.keyboards || []
                    var mainKb = null
                    for (var i = 0; i < keyboards.length; i++) {
                        if (keyboards[i].main) {
                            mainKb = keyboards[i]
                            break
                        }
                    }
                    // Fallback: первая клавиатура, если main не помечена.
                    if (!mainKb && keyboards.length > 0) mainKb = keyboards[0]

                    if (mainKb && mainKb.active_keymap) {
                        root.currentLayoutLong = mainKb.active_keymap
                    }
                } catch (e) {
                    console.warn("KeyboardLayoutModel: failed to parse hyprctl output:", e)
                }
            }
        }
    }

    // ─── Источник 2: live-обновления через Hyprland event socket ────────
    // event.name === "activelayout" → event.data = "KEYBOARDNAME,LAYOUTNAME".
    // event.parse(2) аккуратно разбивает по запятой с известным числом
    // полей (лучше split — Hyprland гарантирует ровно 2 поля для этого
    // события, но в имени раскладки могут быть запятые внутри скобок).
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activelayout") return
            var parts = event.parse(2)
            if (parts && parts.length >= 2) {
                root.currentLayoutLong = parts[1]
            }
        }
    }
}

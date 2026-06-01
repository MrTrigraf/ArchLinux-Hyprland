pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    // ─── Системный sink ─────────────────────────────────────────────────
    readonly property PwNode sink: Pipewire.defaultAudioSink

    // Optional chain (?.) — если sink null, выражение вернёт undefined,
    // которое QML обработает как fallback к 0/false.
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    // ─── Список приложений-стримов ──────────────────────────────────────
    // Pipewire.nodes содержит ВСЕ ноды (sinks, sources, streams).
    // Фильтруем:
    //   - isStream: true        — это приложение, а не железо
    //   - audio !== null        — это аудио-нода (не видео)
    //   - type === AudioOutStream — именно playback (не запись)
    readonly property var streams: {
        var result = []
        var allNodes = Pipewire.nodes.values
        for (var i = 0; i < allNodes.length; i++) {
            var n = allNodes[i]
            if (n.isStream && n.audio && n.type === PwNodeType.AudioOutStream) {
                result.push(n)
            }
        }
        return result
    }

    // ─── PwObjectTracker — удерживает ноды bound ────────────────────────
    // Без трекера .audio.volume / .muted у sink и streams возвращают
    // невалидные значения. objects: [...] динамически обновляется
    // через биндинг от streams.
    //
    // Спред-оператор недоступен в QML, поэтому строим массив вручную.
    PwObjectTracker {
        objects: {
            var list = []
            if (root.sink) list.push(root.sink)
            for (var i = 0; i < root.streams.length; i++) {
                list.push(root.streams[i])
            }
            return list
        }
    }

    // ─── Методы управления системным sink ───────────────────────────────
    // Все методы — no-op, если sink или sink.audio отсутствуют.
    // Math.max/min — clamp в [0..1].
    function setVolume(v) {
        if (!sink || !sink.ready || !sink.audio) return
        var clamped = Math.max(0, Math.min(1, v))
        sink.audio.volume = clamped
    }

    function toggleMute() {
        if (!sink || !sink.ready || !sink.audio) return
        sink.audio.muted = !sink.audio.muted
    }

    // Относительное изменение громкости. Используется в скролле по иконке.
    // d — дельта в долях единицы (например, 0.01 = +1%).
    function changeVolume(d) {
        setVolume(volume + d)
    }

    // ─── Методы для приложений ──────────────────────────────────────────
    // Передаём сам PwNode (из streams) — он гарантированно bound, потому
    // что мы держим его в PwObjectTracker. Из QML вызываем напрямую через
    // stream.audio.volume = ..., этот метод тут для симметрии с sink.
    function setStreamVolume(stream, v) {
        if (!stream || !stream.audio) return
        var clamped = Math.max(0, Math.min(1, v))
        stream.audio.volume = clamped
    }
}

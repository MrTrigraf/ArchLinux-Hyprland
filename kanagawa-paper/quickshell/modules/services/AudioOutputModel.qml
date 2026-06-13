pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// ─────────────────────────────────────────────────────────────────────────
// AudioOutputModel.qml — всё, что связано с ВЫВОДОМ звука.
//
// Источники данных:
//   - Pipewire.defaultAudioSink            — текущий sink (readonly).
//   - Pipewire.preferredDefaultAudioSink   — наша хотелка (writable);
//                                            WirePlumber запоминает её.
//   - Pipewire.nodes                       — все ноды; фильтруем sinks
//                                            и playback streams.
//
// Сущности:
//   - sink        — текущий default-sink (PwNode, иногда null).
//   - sinks       — список ВСЕХ sinks (для dropdown в Output-вкладке).
//   - streams     — все playback streams (PwNode'ы) — техническая выборка.
//   - streamGroups — то же, что streams, но СГРУППИРОВАНО по
//                   properties["application.name"]. UI использует
//                   ИМЕННО это: одна строка попапа = одно приложение,
//                   даже если у него N открытых вкладок.
//
// Группировка:
//   В Pipewire каждая вкладка Firefox / каждый звонок Discord — это
//   отдельный PwNode со своим audio.volume. Pavucontrol их показывает
//   по-отдельности, но в desktop-стилях (KDE/GNOME/Win) принято
//   группировать по приложению.
//
//   Группа = { name, nodes[] }
//     - name  : имя для UI (берётся из первого node, см. _groupName).
//     - nodes : массив PwNode, относящихся к одному приложению.
//
//   Громкость группы = громкость ПЕРВОГО узла группы. Когда юзер крутит
//   слайдер — пишем во ВСЕ узлы группы одно и то же значение (старые
//   относительные пропорции теряются). Mute группы = "хоть один muted";
//   toggleMute приводит всю группу к новому единому состоянию.
// ─────────────────────────────────────────────────────────────────────────

Singleton {
    id: root

    // ─── Текущий default-sink (используемое сейчас устройство вывода) ──
    readonly property PwNode sink: Pipewire.defaultAudioSink

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    // ─── Список всех доступных sinks (для dropdown в Output-вкладке) ───
    readonly property var sinks: {
        var result = []
        var allNodes = Pipewire.nodes.values
        for (var i = 0; i < allNodes.length; i++) {
            var n = allNodes[i]
            if (n.audio && n.isSink && !n.isStream) {
                result.push(n)
            }
        }
        return result
    }

    // ─── Список playback-стримов (плоский, технический) ────────────────
    // Не используется напрямую в UI: UI работает с streamGroups.
    // Оставлен, потому что:
    //   1) PwObjectTracker должен удерживать ВСЕ ноды, на которые мы пишем
    //      volume (не только первую в группе) — массив `streams` это
    //      самое прямое описание этого множества.
    //   2) groupBy реактивно зависит от streams.
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

    // ─── Группировка стримов по application.name ──────────────────────
    // Возвращает массив объектов:
    //   [ { name: "Firefox", nodes: [pwNode, pwNode, ...] }, ... ]
    //
    // Ключ группировки — то же выражение, что использовалось для лейбла
    // отдельного стрима в старой версии AudioOutputTab: application.name
    // с fallback на description / name / "Без имени". Если у двух стримов
    // получился одинаковый _groupKey — они в одной группе.
    readonly property var streamGroups: {
        var groups = {}            // map: key → { name, nodes[] }
        var order = []             // массив key'ев в порядке появления
                                    // (чтобы порядок групп был стабильным
                                    //  и не "прыгал" при rebuild'е)
        var list = streams
        for (var i = 0; i < list.length; i++) {
            var node = list[i]
            var key = _groupKey(node)
            if (!groups[key]) {
                groups[key] = {
                    name: _groupName(node),
                    nodes: []
                }
                order.push(key)
            }
            groups[key].nodes.push(node)
        }
        // Возвращаем массив в порядке появления.
        var result = []
        for (var j = 0; j < order.length; j++) {
            result.push(groups[order[j]])
        }
        return result
    }

    // ─── Helpers для группировки ───────────────────────────────────────
    // Ключ группировки. application.name всегда есть у "настоящих"
    // pulse/pipewire-приложений (Firefox, Discord, Spotify, OBS).
    // Если его нет — возвращаемся к description/name, как делал старый
    // VolumePopup для лейбла; пустых ключей в практике не встречал.
    function _groupKey(node) {
        if (!node) return "__null"
        var p = node.properties || {}
        return p["application.name"]
            || node.description
            || node.name
            || "__unnamed"
    }

    // Отображаемое имя группы. По смыслу совпадает с _groupKey, но
    // выделено в отдельную функцию — на случай если когда-нибудь захотим
    // показывать другое имя, а группировать по другому ключу (например,
    // группировать по application.process.id, а имя брать application.name).
    function _groupName(node) {
        return _groupKey(node)
    }

    // ─── PwObjectTracker — удерживает все ноды bound ───────────────────
    // Все streams нужны: мы пишем volume/muted каждой ноде группы,
    // не только первой. Без трекера записи молча провалятся.
    PwObjectTracker {
        objects: {
            var list = []
            if (root.sink) list.push(root.sink)
            for (var i = 0; i < root.sinks.length; i++) {
                list.push(root.sinks[i])
            }
            for (var j = 0; j < root.streams.length; j++) {
                list.push(root.streams[j])
            }
            return list
        }
    }

    // ─── Управление системным sink ─────────────────────────────────────
    function setVolume(v) {
        if (!sink || !sink.ready || !sink.audio) return
        var clamped = Math.max(0, Math.min(1, v))
        sink.audio.volume = clamped
    }

    function toggleMute() {
        if (!sink || !sink.ready || !sink.audio) return
        sink.audio.muted = !sink.audio.muted
    }

    function changeVolume(d) {
        setVolume(volume + d)
    }

    // ─── Управление отдельным стримом ──────────────────────────────────
    // Эти методы оставлены для обратной совместимости (если когда-нибудь
    // понадобится отдельный UI типа pavucontrol). UI попапа использует
    // group-методы ниже.
    function setStreamVolume(stream, v) {
        if (!stream || !stream.audio) return
        var clamped = Math.max(0, Math.min(1, v))
        stream.audio.volume = clamped
    }

    function toggleStreamMute(stream) {
        if (!stream || !stream.audio) return
        stream.audio.muted = !stream.audio.muted
    }

    // ─── Управление ГРУППОЙ стримов ────────────────────────────────────
    // Принимаем массив nodes (group.nodes), пишем volume/muted КАЖДОМУ
    // узлу одно и то же значение. Это и есть "один слайдер = одно
    // приложение" из требований.
    function setGroupVolume(nodes, v) {
        if (!nodes || nodes.length === 0) return
        var clamped = Math.max(0, Math.min(1, v))
        for (var i = 0; i < nodes.length; i++) {
            var n = nodes[i]
            if (n && n.audio) n.audio.volume = clamped
        }
    }

    // Toggle mute группы: считаем, что группа muted если ХОТЯ БЫ ОДИН
    // node muted (см. groupMuted). При toggle всем нодам пишем НЕ-текущее
    // состояние (т.е. инвертируем "групповой" muted, приводя группу
    // к единому состоянию).
    function toggleGroupMute(nodes) {
        if (!nodes || nodes.length === 0) return
        var newMuted = !groupMuted(nodes)
        for (var i = 0; i < nodes.length; i++) {
            var n = nodes[i]
            if (n && n.audio) n.audio.muted = newMuted
        }
    }

    // Громкость группы = громкость ПЕРВОГО узла. Это то, что UI
    // показывает в слайдере. Если в группе разные volume у нод —
    // показываем первый, остальные "подравниваются" при первом drag.
    function groupVolume(nodes) {
        if (!nodes || nodes.length === 0) return 0
        var first = nodes[0]
        return first?.audio?.volume ?? 0
    }

    // Группа считается muted, если хоть один её node muted.
    // Иконка mute в слайдере будет показывать volume_off, как только
    // одна вкладка Firefox замьючена. После toggleGroupMute группа
    // приходит к единому состоянию.
    function groupMuted(nodes) {
        if (!nodes || nodes.length === 0) return false
        for (var i = 0; i < nodes.length; i++) {
            var n = nodes[i]
            if (n && n.audio && n.audio.muted) return true
        }
        return false
    }

    // ─── Смена default-sink (выбор из dropdown) ────────────────────────
    function setDefaultSink(node) {
        if (!node) return
        Pipewire.preferredDefaultAudioSink = node
    }
}
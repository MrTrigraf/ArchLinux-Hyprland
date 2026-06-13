pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    // ─── Текущий default-source ────────────────────────────────────────
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property real volume: source?.audio?.volume ?? 0
    readonly property bool muted: source?.audio?.muted ?? false

    // ─── Список всех source-устройств (микрофонов) ─────────────────────
    // Фильтр:
    //   - audio !== null   — аудио-нода
    //   - isSink === false — это источник, а не выход
    //   - isStream === false — железо/виртуальное устройство, не приложение
    //
    // Bluetooth-наушники в HSP/HFP-профиле появятся здесь автоматически как
    // отдельный source — pavucontrol показывает их так же.
    readonly property var sources: {
        var result = []
        var allNodes = Pipewire.nodes.values
        for (var i = 0; i < allNodes.length; i++) {
            var n = allNodes[i]
            if (n.audio && !n.isSink && !n.isStream) {
                result.push(n)
            }
        }
        return result
    }

    // ─── PwObjectTracker — для записи volume/muted в source-устройства ─
    // Без этого .audio.volume = ... молча провалится. Держим default-source
    // плюс все известные sources (чтобы можно было читать их имена и менять
    // volume у НЕ-дефолтного source — pavucontrol позволяет это делать).
    PwObjectTracker {
        objects: {
            var list = []
            if (root.source) list.push(root.source)
            for (var i = 0; i < root.sources.length; i++) {
                list.push(root.sources[i])
            }
            return list
        }
    }

    // ─── Управление громкостью/mute любого source ──────────────────────
    // Принимаем сам PwNode (из sources), а не id — bound он через трекер
    // выше. Симметрично методам AudioOutputModel для streams.
    function setSourceVolume(src, v) {
        if (!src || !src.audio) return
        var clamped = Math.max(0, Math.min(1, v))
        src.audio.volume = clamped
    }

    function toggleSourceMute(src) {
        if (!src || !src.audio) return
        src.audio.muted = !src.audio.muted
    }

    // Удобный сеттер для текущего default-source (для скролла по иконке
    // в баре, если когда-нибудь понадобится; не используется в попапе).
    function setVolume(v) {
        setSourceVolume(source, v)
    }

    function toggleMute() {
        toggleSourceMute(source)
    }

    // ─── Смена default-source (галочка в Input-вкладке) ───────────────
    // Pipewire.preferredDefaultAudioSource — hint для pipewire/WirePlumber.
    // defaultAudioSource может отличаться кратковременно или если выбранное
    // устройство отвалилось (отключили USB-микрофон). WirePlumber запоминает
    // preferredDefault'ы между перезагрузками — это persistence из ТЗ.
    function setDefaultSource(node) {
        if (!node) return
        Pipewire.preferredDefaultAudioSource = node
    }

    // Удобная проверка "является ли node текущим default-source".
    // Сравниваем по id — это стабильный pipewire-идентификатор объекта.
    function isDefault(node) {
        if (!node || !root.source) return false
        return node.id === root.source.id
    }
}
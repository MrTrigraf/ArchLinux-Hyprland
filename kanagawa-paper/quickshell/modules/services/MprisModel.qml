pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// ─────────────────────────────────────────────────────────────────────────────
// MprisModel — обёртка над Quickshell.Services.Mpris для одного-единственного
// плеера cmus (`org.mpris.MediaPlayer2.cmus`). По проектному решению другие
// MPRIS-источники игнорируются: секция MediaSection в баре реагирует ТОЛЬКО
// на cmus, никаких «приоритетов» или «последний-играющий».
//
// Экспонирует:
//   cmusPlayer  — MprisPlayer | null. Нужен MediaSection'у для Connections
//                 (подписка на trackChanged для рестарта marquee).
//   available   — bool. true если cmus подключён И есть непустое название.
//                 Управляет видимостью MediaSection.
//   playing     — bool. true если playbackState == Playing. Управляет
//                 выбором глифа play_arrow ↔️ pause.
//   trackTitle  — string. Название текущего трека или "".
// ─────────────────────────────────────────────────────────────────────────────
QtObject {
	id: root

    // ─── Поиск cmus среди зарегистрированных MPRIS-плееров ────────────────
    readonly property MprisPlayer cmusPlayer: {
        var ps = Mpris.players.values
        for (var i = 0; i < ps.length; ++i) {
            if (ps[i].dbusName === "org.mpris.MediaPlayer2.cmus") return ps[i]
        }
        return null
    }

    // ─── Производные свойства для биндингов в баре ────────────────────────
    readonly property string trackTitle: cmusPlayer ? (cmusPlayer.trackTitle || "") : ""
    readonly property bool   playing:    cmusPlayer ? cmusPlayer.isPlaying         : false
    readonly property bool   available:  cmusPlayer !== null && trackTitle !== ""

    // ─── Методы управления (с capability-гардами по спецификации MPRIS) ───
    function playPause() {
        if (cmusPlayer && cmusPlayer.canTogglePlaying) cmusPlayer.togglePlaying()
    }
    function next() {
        if (cmusPlayer && cmusPlayer.canGoNext) cmusPlayer.next()
    }
    function previous() {
        if (cmusPlayer && cmusPlayer.canGoPrevious) cmusPlayer.previous()
    }
}

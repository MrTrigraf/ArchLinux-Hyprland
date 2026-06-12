pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Io
import "../../theme"

// ─────────────────────────────────────────────────────────────────────────────
// NotificationService.qml — центральный singleton уведомлений.
//
// Архитектура:
//   server.trackedNotifications  — ObjectModel<Notification>, source of truth.
//   toastIds                     — массив id уведомлений, которые сейчас в очереди
//                                  на показ как toast. UI (ToastsWindow) делает
//                                  ScriptModel поверх него + trackedNotifications,
//                                  получая список живых Notification напрямую.
//
// Когда notification закрывается извне (n.dismiss(), CloseNotification),
// он автоматически уходит из trackedNotifications. ScriptModel пересчитается
// и стейл id просто отфильтруется (find вернёт undefined → filter уберёт).
// ─────────────────────────────────────────────────────────────────────────────
QtObject {
	id: root

	readonly property NotificationServer server: NotificationServer {
		actionsSupported:        true
		actionIconsSupported:    false
		bodySupported:           true
		bodyMarkupSupported:     true
		bodyHyperlinksSupported: false
		bodyImagesSupported:     false
		imageSupported:          true
		persistenceSupported:    true
		inlineReplySupported:    false
		keepOnReload:            true

		onNotification: (n) => root.handleIncoming(n)
	}

	readonly property int unreadCount: server.trackedNotifications.values.length

	property bool soundMuted: false
	property bool dndEnabled: false

	// Карта "id → timestamp получения" (для "5 мин назад").
	property var receivedAt: ({})

	// Очередь id для тостов — новые в начале.
	property var toastIds: []

	function handleIncoming(n) {
		if (!n) return

		var tier = NotificationRules.classify(n)

		// Помечаем для сохранения в trackedNotifications — попадёт в попап
		// центра уведомлений всегда, независимо от DnD.
		n.tracked = true

		var map = Object.assign({}, root.receivedAt)
		map[n.id] = Date.now()
		root.receivedAt = map

		// DnD: для tier="normal" подавляем ЗВУК и ТОСТ, но в центр (попап)
		// уведомление приходит как обычно. System и Critical всегда проходят.
		var dndSilenced = root.dndEnabled && tier === "normal"

		// lastGeneration (после qs reload) тоже не озвучивает и не пушит тост.
		var skipToast = dndSilenced || n.lastGeneration

		if (!root.soundMuted && !skipToast) root.playSound()
		if (!skipToast) root.pushToast(n)

		console.log("[notif] +", tier, "·", n.appName || "?", "·",
			        (n.summary || "").substring(0, 40),
				    dndSilenced ? "[DnD: no toast/sound]" : "")
	}

	function pushToast(notif) {
		if (!notif) return
		var ids = root.toastIds.slice()
		ids.unshift(notif.id)
		while (ids.length > Theme.notifToastMaxVisible) ids.pop()
		root.toastIds = ids
		console.log("[notif] pushToast: id=" + notif.id + " queue=" + ids.length)
	}

	function expireToast(id) {
		root.toastIds = root.toastIds.filter(function (x) { return x !== id })
	}

	function dismiss(notif) {
		if (!notif) return
		var id = notif.id
		notif.dismiss()
		root.expireToast(id)
		if (id !== undefined) {
			var map = Object.assign({}, root.receivedAt)
			delete map[id]
			root.receivedAt = map
		}
	}

	function clearAll() {
		var items = root.server.trackedNotifications.values.slice()
		for (var i = 0; i < items.length; ++i) {
			if (items[i]) items[i].dismiss()
		}
		root.toastIds = []
		root.receivedAt = ({})
	}

	function toggleSound() { root.soundMuted = !root.soundMuted }
	function toggleDnd()   { root.dndEnabled = !root.dndEnabled }

	function tierOf(notif) {
		return notif ? NotificationRules.classify(notif) : "normal"
	}

	function timeAgo(notif) {
		if (!notif) return ""
		var t = root.receivedAt[notif.id]
		if (!t) return "сейчас"
		var diffSec = Math.round((Date.now() - t) / 1000)
		if (diffSec < 10)   return "сейчас"
		if (diffSec < 60)   return diffSec + " с назад"
		var diffMin = Math.round(diffSec / 60)
		if (diffMin < 60)   return diffMin + " мин назад"
		var diffHr = Math.round(diffMin / 60)
		if (diffHr < 24)    return diffHr + " ч назад"
		var diffDay = Math.round(diffHr / 24)
		return diffDay + " д назад"
	}

	function iconFor(notif) {
		if (!notif) return ""
		if (notif.image && notif.image !== "") return notif.image
		if (notif.appIcon && notif.appIcon !== "") return Quickshell.iconPath(notif.appIcon, true)
		return ""
	}

	property Process soundProc: Process {
		command: ["paplay", "/usr/share/sounds/freedesktop/stereo/bell.oga"]
	}
	function playSound() { soundProc.startDetached() }

	// ─── TODO: persistence для Critical (шаг 8) ──────────────────────────
}

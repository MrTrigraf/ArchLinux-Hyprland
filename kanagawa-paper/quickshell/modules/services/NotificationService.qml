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
//
// Persistence Critical-уведомлений (чат 20):
//   - Каждое уведомление с tier="critical" сохраняется в JSON-файл
//     ~/.local/state/quickshell/<shellId>/notif-critical.json.
//   - При старте (cold start) запись восстанавливается через re-emit:
//     notify-send -u critical -h boolean:x-restored:true ...
//     Хинт x-restored=true говорит handleIncoming не играть звук
//     и не пушить toast, но добавить уведомление в trackedNotifications
//     (попап «центра уведомлений» снова покажет).
//   - Идемпотентность против keepOnReload: при restore сверяемся
//     с trackedNotifications.values по ключу — что уже живо, не дублируем.
//   - Удаление из JSON: dismiss отдельной карточки, clearAll, TTL 24ч.
//   - TTL anchor — firstSeenAt (момент первого появления, не обновляется
//     при дедупе). pruneTimer раз в 10 минут чистит истёкшее.
//   - Дедуп-ключ: appName + "|" + summary + "|" + body.
//     Если failed-units watcher шлёт ту же critical каждые 5 минут —
//     обновляется lastSeenAt, новая запись не создаётся.
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

	// ─── Persistence: состояние в памяти ─────────────────────────────────
	// Массив записей. Каждая запись:
	//   { key, appName, summary, body, firstSeenAt, lastSeenAt }
	// firstSeenAt — anchor для TTL (24 часа от первого появления).
	// lastSeenAt — обновляется при дедупе, для информации.
	property var persistedEntries: []

	// Карта key → firstSeenAt на короткое время между re-emit при старте
	// и приходом восстановленного уведомления через DBus в handleIncoming.
	// Нужна, чтобы receivedAt[n.id] получил оригинальный firstSeenAt
	// (тогда timeAgo покажет "5 ч назад", а не "сейчас").
	property var pendingRestores: ({})

	// TTL: 24 часа в миллисекундах.
	readonly property int ttlMs: 24 * 60 * 60 * 1000

	// ─── FileView для notif-critical.json ────────────────────────────────
	// blockLoading: true — синхронная загрузка при установке path.
	// К моменту, когда сработает restoreTimer (через 500мс), persistedEntries
	// гарантированно проинициализирован: либо из файла, либо пустым массивом.
	// atomicWrites: true (дефолт) — запись через временный файл + rename,
	// частичная запись на диске невозможна.
	readonly property FileView stateFile: FileView {
		path: Quickshell.statePath("notif-critical.json")
		blockLoading: true

		onLoaded: root._onStateLoaded()
		onLoadFailed: root._onStateLoadFailed()
	}

	// ─── Таймеры: restore при старте и периодическая чистка TTL ──────────
	// Отложенный restore: 500мс дают keepOnReload вернуть свои
	// trackedNotifications (если это был hot reload), и тогда restoreCriticals
	// пропустит уже живые записи по ключу — дубля не будет.
	property Timer restoreTimer: Timer {
		interval: 500
		repeat: false
		running: true
		onTriggered: root.restoreCriticals()
	}

	// Раз в 10 минут — чистка истёкших записей из JSON.
	property Timer pruneTimer: Timer {
		interval: 10 * 60 * 1000
		repeat: true
		running: true
		onTriggered: root.pruneExpired()
	}

	// ─── handleIncoming: обработка приходящего уведомления ───────────────
	function handleIncoming(n) {
		if (!n) return

		var tier = NotificationRules.classify(n)

		// x-restored=true — флаг, что уведомление пришло из restoreCriticals,
		// не от приложения. notify-send умеет ставить boolean-хинты:
		// notify-send -h boolean:x-restored:true ...
		var isRestored = !!(n.hints && n.hints["x-restored"])

		// Помечаем для сохранения в trackedNotifications — попадёт в попап
		// центра уведомлений всегда, независимо от DnD.
		n.tracked = true

		var key = root.makeKey(n)

		// Время "получения" для индикатора "N мин назад":
		// - для свежих — Date.now()
		// - для восстановленных — firstSeenAt из pendingRestores
		//   (тогда timeAgo покажет реальный возраст уведомления).
		var receivedTime = Date.now()
		if (isRestored && root.pendingRestores[key] !== undefined) {
			receivedTime = root.pendingRestores[key]
			var pr = Object.assign({}, root.pendingRestores)
			delete pr[key]
			root.pendingRestores = pr
		}
		var map = Object.assign({}, root.receivedAt)
		map[n.id] = receivedTime
		root.receivedAt = map

		// Сохранение в JSON — только для свежих Critical.
		// Восстановленные уже в JSON (не плодим дубль).
		if (tier === "critical" && !isRestored) {
			root._upsertEntry(n, key)
		}

		// DnD: для tier="normal" подавляем ЗВУК и ТОСТ, но в центр (попап)
		// уведомление приходит как обычно. System и Critical всегда проходят.
		var dndSilenced = root.dndEnabled && tier === "normal"

		// Восстановленные не должны звенеть/всплывать как toast — иначе
		// после каждой перезагрузки была бы лавина старых тостов.
		var skipToast = dndSilenced || n.lastGeneration || isRestored

		if (!root.soundMuted && !skipToast) root.playSound()
		if (!skipToast) root.pushToast(n)

		console.log("[notif] +", tier, "·", n.appName || "?", "·",
			        (n.summary || "").substring(0, 40),
				    dndSilenced ? "[DnD: no toast/sound]" : "",
				    isRestored ? "[restored]" : "")
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

	// dismiss: убираем уведомление из trackedNotifications,
	// дочищаем receivedAt и удаляем запись из JSON по ключу
	// (если она там была — для не-Critical _removeEntry no-op).
	function dismiss(notif) {
		if (!notif) return
		var id = notif.id
		var key = root.makeKey(notif)
		notif.dismiss()
		root.expireToast(id)
		if (id !== undefined) {
			var map = Object.assign({}, root.receivedAt)
			delete map[id]
			root.receivedAt = map
		}
		root._removeEntry(key)
	}

	// clearAll: пользователь явно сказал "забудьте всё" — чистим и JSON.
	function clearAll() {
		var items = root.server.trackedNotifications.values.slice()
		for (var i = 0; i < items.length; ++i) {
			if (items[i]) items[i].dismiss()
		}
		root.toastIds = []
		root.receivedAt = ({})

		if (root.persistedEntries.length > 0) {
			root.persistedEntries = []
			root._saveState()
		}
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

	// ═════════════════════════════════════════════════════════════════════
	// Persistence helpers
	// ═════════════════════════════════════════════════════════════════════

	// Дедуп-ключ: appName + "|" + summary + "|" + body.
	// Тело входит в ключ намеренно — если failed-units watcher меняет body
	// ("3 failed units" → "4 failed units"), это новое событие,
	// старая запись остаётся до dismiss/TTL.
	function makeKey(n) {
		if (!n) return ""
		return (n.appName || "") + "|" + (n.summary || "") + "|" + (n.body || "")
	}

	// Добавить новую запись или обновить lastSeenAt существующей.
	function _upsertEntry(n, key) {
		var now = Date.now()
		var entries = root.persistedEntries.slice()
		var found = -1
		for (var i = 0; i < entries.length; ++i) {
			if (entries[i].key === key) { found = i; break }
		}
		if (found >= 0) {
			// Дедуп: только обновляем lastSeenAt, firstSeenAt не трогаем
			// (TTL отсчитывается от firstSeenAt).
			entries[found].lastSeenAt = now
		} else {
			entries.push({
				key: key,
				appName: n.appName || "",
				summary: n.summary || "",
				body: n.body || "",
				firstSeenAt: now,
				lastSeenAt: now
			})
		}
		root.persistedEntries = root._filterExpired(entries)
		root._saveState()
	}

	function _removeEntry(key) {
		if (!key) return
		var filtered = root.persistedEntries.filter(function (e) { return e.key !== key })
		if (filtered.length !== root.persistedEntries.length) {
			root.persistedEntries = filtered
			root._saveState()
		}
	}

	// Отфильтровать массив, оставив только не-истёкшие записи.
	// TTL anchor — firstSeenAt (вариант α из плана чата 20).
	function _filterExpired(entries) {
		var cutoff = Date.now() - root.ttlMs
		return entries.filter(function (e) {
			return (e.firstSeenAt || 0) > cutoff
		})
	}

	// Периодическая чистка истёкших — раз в 10 минут.
	function pruneExpired() {
		var before = root.persistedEntries.length
		var filtered = root._filterExpired(root.persistedEntries)
		if (filtered.length !== before) {
			root.persistedEntries = filtered
			root._saveState()
			console.log("[notif] persistence: pruned",
			            before - filtered.length, "expired critical(s)")
		}
	}

	// Запись на диск. Атомарно (default), не блокирующая поток UI.
	function _saveState() {
		try {
			var json = JSON.stringify({ entries: root.persistedEntries }, null, 2)
			root.stateFile.setText(json)
		} catch (e) {
			console.warn("[notif] persistence: save error:", e)
		}
	}

	// Файл успешно прочитан — парсим и фильтруем истёкшее.
	function _onStateLoaded() {
		try {
			var t = root.stateFile.text()
			if (!t || t.length === 0) {
				root.persistedEntries = []
				return
			}
			var parsed = JSON.parse(t)
			var raw = (parsed && parsed.entries) ? parsed.entries : []
			root.persistedEntries = root._filterExpired(raw)
			console.log("[notif] persistence: loaded",
			            root.persistedEntries.length, "entry/ies")
		} catch (e) {
			console.warn("[notif] persistence: parse error:", e)
			root.persistedEntries = []
		}
	}

	// Файл не существует или нечитаем — первый запуск или ручное удаление.
	// Это штатная ситуация, не ошибка.
	function _onStateLoadFailed() {
		root.persistedEntries = []
		console.log("[notif] persistence: state file absent, starting empty")
	}

	// Restore при cold start.
	// Идемпотентность: для каждой записи проверяем, есть ли в живой
	// trackedNotifications уведомление с таким же ключом. Если есть
	// (keepOnReload спас при hot reload) — пропускаем. Если нет —
	// re-emit через notify-send с хинтом x-restored=true.
	function restoreCriticals() {
		if (!root.persistedEntries || root.persistedEntries.length === 0) return

		var existing = {}
		var live = root.server.trackedNotifications.values
		for (var i = 0; i < live.length; ++i) {
			existing[root.makeKey(live[i])] = true
		}

		var emitted = 0
		for (var j = 0; j < root.persistedEntries.length; ++j) {
			var e = root.persistedEntries[j]
			if (existing[e.key]) continue

			// Запоминаем firstSeenAt, чтобы handleIncoming поставил
			// корректный receivedAt для timeAgo("5 ч назад").
			var pr = Object.assign({}, root.pendingRestores)
			pr[e.key] = e.firstSeenAt
			root.pendingRestores = pr

			// Re-emit через DBus. execDetached — fire-and-forget,
			// не блокирует, не требует общего Process-объекта.
			Quickshell.execDetached([
				"notify-send",
				"-u", "critical",
				"-a", e.appName,
				"-h", "boolean:x-restored:true",
				e.summary,
				e.body
			])
			emitted++
		}

		if (emitted > 0) {
			console.log("[notif] persistence: restored",
			            emitted, "critical(s) via notify-send")
		}
	}

	// При первой загрузке singleton-а — гарантировать, что parent dir
	// для state-файла существует. Quickshell.statePath() возвращает путь
	// под ~/.local/state/quickshell/<shellId>/, и сам каталог может
	// отсутствовать на свежей машине. mkdir -p идемпотентен.
	Component.onCompleted: {
		var p = root.stateFile.path
		var lastSlash = p.lastIndexOf("/")
		if (lastSlash > 0) {
			var parent = p.substring(0, lastSlash)
			Quickshell.execDetached(["mkdir", "-p", parent])
		}
	}
}

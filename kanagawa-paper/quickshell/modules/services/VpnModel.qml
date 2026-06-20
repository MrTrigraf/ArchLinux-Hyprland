pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
	id: root

	// ── Публичная модель: список VPN-профилей ──────────────────────────
	// Элемент: { name, uuid, type ("vpn" | "wireguard" | ...), active: bool,
	//            device: "tun0" | "" }.
	property var profiles: []
	readonly property var activeProfiles: profiles.filter(p => p.active)
	readonly property bool anyActive: activeProfiles.length > 0

	// ── Парсер вывода `nmcli connection show` ──────────────────────────
	function parseConnections(stdout) {
		var lines = stdout.split("\n").filter(s => s.length > 0)
		var allowedTypes = ["vpn", "wireguard"]
		var result = []
		for (var i = 0; i < lines.length; i++) {
			var safe = lines[i].replace(/\\:/g, "\x00")
			var fields = safe.split(":").map(function(p) {
				return p.replace(/\x00/g, ":")
			})
			if (fields.length < 4) continue
			var name   = fields[0]
			var uuid   = fields[1]
			var type   = fields[2]
			var device = fields[3]   // пустая строка, если профиль не активен
			if (allowedTypes.indexOf(type) < 0) continue
			result.push({
				name:   name,
				uuid:   uuid,
				type:   type,
				active: device.length > 0,
				device: device
			})
		}
		return result
	}

	// ── Чтение списка профилей ─────────────────────────────────────────
	Process {
		id: listProc
		command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,DEVICE", "connection", "show"]
		stdout: StdioCollector {
			onStreamFinished: {
				root.profiles = root.parseConnections(text)
			}
		}
		onExited: (code) => {
			if (code !== 0) console.warn("[VpnModel] nmcli connection show exit=" + code)
		}
	}

	function refresh() {
		listProc.running = true
	}

	// Первичная загрузка при запуске.
	Component.onCompleted: refresh()

	// ── Live-обновления через `nmcli monitor` ──────────────────────────
	Process {
		id: monitorProc
		running: true
		command: ["nmcli", "monitor"]
		stdout: SplitParser {
			splitMarker: "\n"
			onRead: root.refresh()
		}
	}

	// ── Действия над профилями ─────────────────────────────────────────
	// Все запускаются через execDetached: процесс отрабатывает и завершается,
	function connectProfile(uuid) {
		if (!uuid) return
		Quickshell.execDetached(["nmcli", "connection", "up", "uuid", uuid])
	}

	function disconnectProfile(uuid) {
		if (!uuid) return
		Quickshell.execDetached(["nmcli", "connection", "down", "uuid", uuid])
	}

	function removeProfile(uuid) {
		// Безвозвратно удаляет .nmconnection файл. Подтверждение спрашиваем
		// в UI до вызова, тут — просто исполнение.
		if (!uuid) return
		Quickshell.execDetached(["nmcli", "connection", "delete", "uuid", uuid])
	}

	function openEditor(uuid) {
		// nm-connection-editor — GTK-редактор профилей. Без аргументов
		// открывает список со всеми коннектами + кнопку "+" для нового;
		// с --edit=<uuid> сразу открывает форму нужного профиля.
		var inner = uuid && uuid.length > 0
			? ["nm-connection-editor", "--edit=" + uuid]
			: ["nm-connection-editor"]
		Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exec_cmd(\"" + inner + "\")"])
	}

	// ─────────────────────────────────────────────────────────────────────
	// Уведомления о подключении / отключении VPN.
	//
	// Логика:
	//   - При старте Quickshell activeProfiles может быть непустым (VPN
	//     уже поднят). Это НЕ событие — текущее состояние, уведомления
	//     слать не надо. Init-таймер 3с подавляет уведомления, потом
	//     фиксирует текущий список активных как базовый.
	//   - На каждое изменение activeProfiles сравниваем текущее множество
	//     uuid с предыдущим (lastActive):
	//       - есть в current, не было в lastActive → "VPN подключён"
	//       - было в lastActive, нет в current   → "VPN отключён"
	//   - В lastActive храним {uuid, name}, потому что при отключении
	//     объекта в activeProfiles уже нет — имя нужно достать из памяти.
	//   - appName="NetworkManager" → tier=system через NotificationRules.
	// ─────────────────────────────────────────────────────────────────────

	property bool vpnNotifInitDone: false
	property var  lastActive:        []   // [{uuid, name}, ...]

	Timer {
		id: vpnNotifInitTimer
		interval: 3000
		repeat: false
		running: true
		onTriggered: {
			root.lastActive = root.activeProfiles.map(function(p) {
				return { uuid: p.uuid, name: p.name }
			})
			root.vpnNotifInitDone = true
		}
	}

	onActiveProfilesChanged: {
		if (!vpnNotifInitDone) return

		var current = activeProfiles.map(function(p) {
			return { uuid: p.uuid, name: p.name }
		})

		// Новые подключения: есть в current, не было в lastActive.
		for (var i = 0; i < current.length; i++) {
			var c = current[i]
			var wasActive = lastActive.some(function(l) { return l.uuid === c.uuid })
			if (!wasActive) {
				sendVpnNotification("network-vpn", "VPN подключён: " + c.name)
			}
		}

		// Отключения: было в lastActive, нет в current.
		for (var j = 0; j < lastActive.length; j++) {
			var l2 = lastActive[j]
			var stillActive = current.some(function(c2) { return c2.uuid === l2.uuid })
			if (!stillActive) {
				sendVpnNotification("network-vpn-disconnected", "VPN отключён: " + l2.name)
			}
		}

		lastActive = current
	}

	function sendVpnNotification(icon, summary) {
		notifyProc.command = [
			"notify-send",
			"-a", "NetworkManager",
			"-u", "normal",
			"-i", icon,
			"-h", "string:category:network",
			summary
		]
		notifyProc.startDetached()
	}

	Process { id: notifyProc; command: [] }
}

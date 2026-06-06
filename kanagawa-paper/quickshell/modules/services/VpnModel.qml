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
			var parts = lines[i].match(/(?:\\:|[^:])+/g) || []
			if (parts.length < 4) continue
			var name   = parts[0].replace(/\\:/g, ":")
			var uuid   = parts[1]
			var type   = parts[2]
			var device = parts[3]   // пусто, если профиль не активен
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
		var cmd = uuid && uuid.length > 0
			? ["nm-connection-editor", "--edit=" + uuid]
			: ["nm-connection-editor"]
		Quickshell.execDetached(cmd)
	}

	// ── Диагностический блок ───────────────────────────────────────────
//	onProfilesChanged: {
//		console.log("[VpnModel] profiles.length:", profiles.length,
//			"active:", activeProfiles.length)
//		for (var i = 0; i < profiles.length; i++) {
//			var p = profiles[i]
//			console.log("  profile[" + i + "] name='" + p.name + "'",
//				"type=" + p.type, "active=" + p.active,
//				"device='" + p.device + "'")
//		}
//	}
}

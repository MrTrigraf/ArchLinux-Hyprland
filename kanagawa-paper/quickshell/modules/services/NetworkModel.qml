pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Io
import "../../theme"

Singleton {
	id: root

	// ── Базовая доступность сервиса ────────────────────────────────────
	readonly property bool backendReady: Networking.backend !== NetworkBackendType.NoBackend

	// ── Все устройства, разложенные по типам ───────────────────────────
	// Networking.devices — ObjectModel; .values отдаёт массив устройств.
	readonly property var allDevices:   backendReady ? Networking.devices.values : []
	readonly property var wifiDevices:  allDevices.filter(d => d.type === DeviceType.Wifi)
	readonly property var wiredDevices: allDevices.filter(d => d.type === DeviceType.Wired)

	readonly property var wifiDevice:  wifiDevices.length  > 0 ? wifiDevices[0]  : null
	readonly property var wiredDevice: wiredDevices.length > 0 ? wiredDevices[0] : null

	readonly property bool hasWifi:  wifiDevice  !== null
	readonly property bool hasWired: wiredDevice !== null

	// ── Состояния коннекта ─────────────────────────────────────────────
	// NetworkDevice.connected — простой булев (есть/нет соединения).
	readonly property bool wifiConnected:  hasWifi  && wifiDevice.connected
	readonly property bool wiredConnected: hasWired && wiredDevice.connected
	readonly property bool anyConnected:   wifiConnected || wiredConnected

	// ── Wi-Fi toggle (rfkill SW-блок) ──────────────────────────────────
	readonly property bool wifiEnabled:   backendReady && Networking.wifiEnabled
	readonly property bool wifiHwEnabled: backendReady && Networking.wifiHardwareEnabled

	function toggleWifi() {
		if (backendReady) Networking.wifiEnabled = !Networking.wifiEnabled
	}

	// ── Сканер Wi-Fi ───────────────────────────────────────────────────
	function setScanning(on) {
		if (hasWifi) wifiDevice.scannerEnabled = on
	}

	// ── Активная Wi-Fi сеть ────────────────────────────────────────────
	readonly property var activeWifiNetwork: {
		if (!hasWifi) return null
		var nets = wifiDevice.networks.values
		for (var i = 0; i < nets.length; i++) {
			if (nets[i].connected) return nets[i]
		}
		return null
	}

	// Имя активной сети. У Network свойство называется `name` (для Wi-Fi = SSID).
	readonly property string activeSsid:   activeWifiNetwork ? (activeWifiNetwork.name           || "") : ""
	readonly property real   activeSignal: activeWifiNetwork ? (activeWifiNetwork.signalStrength || 0)  : 0

	// ── Список доступных Wi-Fi сетей ───────────────────────────────────
	readonly property var wifiNetworks: hasWifi ? wifiDevice.networks.values : []

	// Активная сверху, остальные — по убыванию signalStrength.
	readonly property var sortedWifiNetworks: {
		var arr = wifiNetworks.slice()
		var active = activeWifiNetwork
		arr.sort(function(a, b) {
			if (a === active) return -1
			if (b === active) return 1
		return (b.signalStrength || 0) - (a.signalStrength || 0)
	})
	return arr
}

	// ── Глиф иконки в баре (Material Symbols Rounded) ──────────────────
	readonly property string iconGlyph: {
		if (wifiConnected) {
			var s = activeSignal
			if (s >= 0.75) return "signal_wifi_4_bar"
			if (s >= 0.50) return "network_wifi_3_bar"
			if (s >= 0.25) return "network_wifi_2_bar"
			return "network_wifi_1_bar"
		}
		if (wiredConnected) return "settings_ethernet"
		return "signal_wifi_off"
	}

	// ── Цвет иконки в баре ─────────────────────────────────────────────
	// fg — обычный (есть связь), statusError — красный (нет связи).
	readonly property color iconColor: anyConnected ? Theme.fg : Theme.statusError

	// ── Подключение / отключение / удаление ────────────────────────────
	function connectKnown(network) {
		if (network) network.connect()
	}

	function connectWithPsk(network, psk) {
		if (network && network.connectWithPsk) network.connectWithPsk(psk)
	}

	function disconnectActive() {
		// Отключает активное устройство; Wi-Fi приоритетнее Ethernet.
		if (wifiConnected) {
			wifiDevice.disconnect()
		} else if (wiredConnected) {
			wiredDevice.disconnect()
		}
	}

	function forgetNetwork(net) {
		if (net) net.forget()
	}

	// ─────────────────────────────────────────────────────────────────────
	// Уведомления о смене состояния Wi-Fi / Ethernet.
	//
	// Логика:
	//   - При старте Quickshell wifiConnected / wiredConnected могут уже быть
	//     true (Wi-Fi подключён в момент старта). Это НЕ событие — это
	//     текущее состояние, уведомления слать не надо.
	//   - Поэтому первые 3 секунды после старта уведомления подавлены
	//     (notifInitDone=false). По истечении init-таймера фиксируем
	//     "базовое" состояние и начинаем реагировать только на ИЗМЕНЕНИЯ.
	//   - При отключении Wi-Fi activeSsid уже становится "" (биндинг
	//     обновляется реактивно). Чтобы показать "Wi-Fi отключён: <SSID>",
	//     запоминаем имя последней активной сети в lastActiveSsid.
	//   - appName="NetworkManager" совпадает с правилом в NotificationRules
	//     → tier=system, urgency=normal.
	// ─────────────────────────────────────────────────────────────────────

	property bool   notifInitDone:     false
	property bool   wasWifiConnected:  false
	property bool   wasWiredConnected: false
	property string lastActiveSsid:    ""

	// Init-таймер: подавляет уведомления первые 3 секунды после старта,
	// затем фиксирует текущее состояние как базовое.
	Timer {
		id: notifInitTimer
		interval: 3000
		repeat: false
		running: true
		onTriggered: {
			root.wasWifiConnected  = root.wifiConnected
			root.wasWiredConnected = root.wiredConnected
			if (root.wifiConnected) root.lastActiveSsid = root.activeSsid
			root.notifInitDone = true
		}
	}

	// Реакция на смену Wi-Fi состояния.
	onWifiConnectedChanged: {
		if (!notifInitDone) return
		if (wifiConnected && !wasWifiConnected) {
			// SSID может ещё не успеть подтянуться — берём из activeSsid
			// или из lastActiveSsid как fallback.
			var ssid = activeSsid || lastActiveSsid || ""
			sendNetworkNotification("network-wireless",
				ssid.length > 0 ? "Wi-Fi подключён: " + ssid : "Wi-Fi подключён")
		} else if (!wifiConnected && wasWifiConnected) {
			var ssid2 = lastActiveSsid || ""
			sendNetworkNotification("network-wireless-disconnected",
				ssid2.length > 0 ? "Wi-Fi отключён: " + ssid2 : "Wi-Fi отключён")
		}
		wasWifiConnected = wifiConnected
	}

	// При подключении к Wi-Fi запоминаем SSID, чтобы показать его при отключении.
	onActiveSsidChanged: {
		if (notifInitDone && activeSsid.length > 0) lastActiveSsid = activeSsid
	}

	// Реакция на смену Ethernet состояния.
	onWiredConnectedChanged: {
		if (!notifInitDone) return
		if (wiredConnected && !wasWiredConnected) {
			sendNetworkNotification("network-wired", "Ethernet подключён")
		} else if (!wiredConnected && wasWiredConnected) {
			sendNetworkNotification("network-wired-disconnected", "Ethernet отключён")
		}
		wasWiredConnected = wiredConnected
	}

	// Отправка уведомления через notify-send. Все Network-уведомления
	// идут как System (через appName="NetworkManager").
	function sendNetworkNotification(icon, summary) {
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

	// Process для notify-send. Команда подменяется перед каждым вызовом.
	Process { id: notifyProc; command: [] }
}

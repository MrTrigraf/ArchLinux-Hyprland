pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking
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

	// ── Подключение / отключение ───────────────────────────────────────
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

	// ── Диагностический блок (срабатывает реактивно при изменении devices) ──
	// Quickshell.Networking.devices наполняется асинхронно через DBus, поэтому
	// Component.onCompleted увидит пустой список. onAllDevicesChanged тригернётся,
	// когда NetworkManager пришлёт первый ответ — и на каждом последующем
	// изменении (подключение/отключение устройств).
	//Component.onCompleted: console.log("[NetworkModel] backend:", Networking.backend)

	//onAllDevicesChanged: {
		//console.log("[NetworkModel] devices.length:", allDevices.length)
		//for (var i = 0; i < allDevices.length; i++) {
			//var d = allDevices[i]
			//console.log("  device[" + i + "] type=" + d.type,
				//"name=" + d.name,
                //"connected=" + d.connected,
                //"state=" + d.state)
		//}
	//}
}

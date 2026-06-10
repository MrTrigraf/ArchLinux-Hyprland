pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../../theme"

// ════════════════════════════════════════════════════════════════════
//  BluetoothModel — singleton-фасад над Quickshell.Bluetooth (BlueZ).
//
//  Предоставляет попапу и бару удобные «причёсанные» свойства:
//   • available     — есть ли вообще BT-адаптер (на десктопе — false);
//   • enabled       — питание адаптера (rfkill / BlueZ Powered);
//   • discovering   — идёт ли поиск новых устройств;
//   • activeDevice  — первое подключённое устройство (или null);
//   • sortedDevices — отсортированный список (connected → paired → ост.);
//   • iconGlyph     — глиф Material Symbols для бара (только при активном
//                     коннекте; в остальных случаях — пустая строка,
//                     RightSection прячет элемент через visible).
//
//  Все действия идут через нативные методы BlueZ-обёртки Quickshell:
//  connect/disconnect/pair/forget — никаких bluetoothctl-обёрток.
//  Помощник сопряжения (blueman-manager) запускается через
//  Quickshell.execDetached() — без создания Process-объекта.
// ════════════════════════════════════════════════════════════════════

Singleton {
	id: root

	// ── Базовая доступность ────────────────────────────────────────────
	// На десктопе без BT-чипа defaultAdapter === null — попап и иконка
	// в баре прячутся целиком (по visible: BluetoothModel.available).
	readonly property var adapter: Bluetooth.defaultAdapter
	readonly property bool available: adapter !== null

	// ── Состояние адаптера ─────────────────────────────────────────────
	// enabled === BlueZ Powered; discovering === идущий scan on.
	// Оба свойства writable у Quickshell.BluetoothAdapter, поэтому
	// тогл = простое присваивание (см. функции ниже).
	readonly property bool enabled: available && adapter.enabled
	readonly property bool discovering: available && adapter.discovering

	// ── Все устройства, известные адаптеру ─────────────────────────────
	// devices — ObjectModel; .values отдаёт обычный массив.
	// На пустом adapter возвращаем [], чтобы фильтры/сортировки
	// не падали с null.
	readonly property var allDevices: available ? adapter.devices.values : []

	// ── Активный коннект ───────────────────────────────────────────────
	// Берём первое устройство со connected=true. У нас не бывает
	// «более активного» среди подключённых, поэтому первое — ок.
	readonly property var activeDevice: {
		for (var i = 0; i < allDevices.length; i++) {
			if (allDevices[i].connected) return allDevices[i]
		}
		return null
	}
	readonly property bool hasActiveConnection: activeDevice !== null

	// ── Подгруппы для попапа ───────────────────────────────────────────
	// Сопряжённые (видны в секции «знакомые») и обнаруженные при скане
	// (видны только когда discovering=true и они ещё не paired).
	readonly property var pairedDevices: allDevices.filter(function(d) { return d.paired })
	readonly property var discoveredDevices: allDevices.filter(function(d) { return !d.paired })

	// ── Единый сортированный список для попапа ────────────────────────
	// Порядок: подключённые → спаренные → обнаруженные → по имени.
	// activeDevice оказывается на самом верху естественно
	// (connected ⇒ true, paired ⇒ true).
	readonly property var sortedDevices: {
		var arr = allDevices.slice()
		arr.sort(function(a, b) {
			if (a.connected !== b.connected) return a.connected ? -1 : 1
			if (a.paired    !== b.paired)    return a.paired    ? -1 : 1
			var nameA = (a.name || a.deviceName || "")
			var nameB = (b.name || b.deviceName || "")
			return nameA.localeCompare(nameB)
		})
		return arr
	}

	// ── Действия над адаптером ─────────────────────────────────────────
	// Питание адаптера. Идём не через adapter.enabled (BlueZ API), а
	// через rfkill: BlueZ-property Powered=true завязан на rfkill soft-block
	// (если адаптер заблокирован — Powered не поднимется, ошибка
	// «Cannot enable adapter because it is blocked by rfkill»). rfkill
	// работает напрямую с ядром, и BlueZ автоматически реагирует на смену
	// его состояния: unblock → Powered=true, block → Powered=false
	// (при условии AutoEnable=true в /etc/bluetooth/main.conf, что дефолт).
	function togglePower() {
		if (!available) return
		var action = adapter.enabled ? "block" : "unblock"
		Quickshell.execDetached(["rfkill", action, "bluetooth"])
	}

	// Сканирование: вкл/выкл. Стартует только если адаптер включён —
	// иначе BlueZ всё равно откажет.
	function toggleDiscovery() {
		if (available && enabled) adapter.discovering = !adapter.discovering
	}

	// ── Действия над устройством ───────────────────────────────────────
	// Тонкие обёртки для попапа: единая точка для логирования/перехвата
	// ошибок, плюс защита от null (попап может позвать в момент,
	// когда устройство только что удалилось из коллекции).
	function connectDevice(dev)    { if (dev) dev.connect() }
	function disconnectDevice(dev) { if (dev) dev.disconnect() }
	function pairDevice(dev)       { if (dev) dev.pair() }
	function cancelPair(dev)       { if (dev) dev.cancelPair() }
	function forgetDevice(dev)     { if (dev) dev.forget() }

	// ── Помощник сопряжения (blueman-manager) ──────────────────────────
	// Открывается из кнопки «+» в шапке BT-секции попапа.
	// execDetached спавнит отдельный процесс без Process-объекта;
	// если blueman не установлен — silently завершится с ошибкой
	// (это нормально, попап не падает).
	function openPairingHelper() {
		Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exec_cmd(\"blueman-manager\")"])
	}

	// ── Маппинг типа устройства на Material Symbols Rounded ────────────
	// dev.icon приходит из BlueZ как XDG-имя иконки (audio-headphones,
	// input-mouse, input-keyboard, input-gaming, phone, …). Это
	// надёжнее, чем угадывать по name. Неизвестный тип → дженерик
	// bluetooth-глиф.
	function deviceGlyph(dev) {
		if (!dev) return "bluetooth"
		var ic = (dev.icon || "").toLowerCase()
		if (ic.indexOf("headphones") !== -1 || ic.indexOf("headset") !== -1) return "headphones"
		if (ic.indexOf("speaker")    !== -1) return "speaker"
		if (ic.indexOf("audio")      !== -1) return "headphones"
		if (ic.indexOf("mouse")      !== -1) return "mouse"
		if (ic.indexOf("keyboard")   !== -1) return "keyboard"
		if (ic.indexOf("gaming")     !== -1 || ic.indexOf("gamepad") !== -1) return "sports_esports"
		if (ic.indexOf("phone")      !== -1) return "smartphone"
		if (ic.indexOf("computer")   !== -1 || ic.indexOf("laptop")  !== -1) return "computer"
		if (ic.indexOf("watch")      !== -1) return "watch"
		if (ic.indexOf("printer")    !== -1) return "print"
		return "bluetooth"
	}

	// ── Глиф для бара (вариант C — только при активном коннекте) ──────
	// Когда нет подключённого устройства — пустая строка. RightSection
	// скрывает индикатор по visible: BluetoothModel.iconGlyph !== "".
	readonly property string iconGlyph: hasActiveConnection ? deviceGlyph(activeDevice) : ""
	// Цвет берётся из Theme — лаванда-акцент (как в попапе для строки BT).
	readonly property color iconColor: Theme.accent

	// ── Диагностика (раскомментировать при отладке) ────────────────────
	//Component.onCompleted: console.log("[BluetoothModel] available:", available, "adapter:", adapter ? adapter.adapterId : "none")

	//onAllDevicesChanged: {
	//	console.log("[BluetoothModel] devices.length:", allDevices.length)
	//	for (var i = 0; i < allDevices.length; i++) {
	//		var d = allDevices[i]
	//		console.log("  device[" + i + "]",
	//			"name=" + d.name,
	//			"icon=" + d.icon,
	//			"paired=" + d.paired,
	//			"connected=" + d.connected,
	//			"battery=" + (d.batteryAvailable ? d.battery : "n/a"))
	//	}
	//}
}

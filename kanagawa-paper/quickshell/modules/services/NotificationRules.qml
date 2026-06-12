pragma Singleton
import QtQuick
import Quickshell.Services.Notifications

// ─────────────────────────────────────────────────────────────────────────────
// NotificationRules.qml — классификатор уведомлений на 3 класса:
//   - "normal"    от приложений (соцсети, браузер, мессенджеры)
//   - "system"    системные события (Network, Battery, BT, USB, VPN, ...)
//   - "critical"  urgency=Critical ИЛИ явный override через tier="critical"
//
// Алгоритм classify(n):
//   1. Совпадение в overrideRules с заданным tier → возвращаем его сразу
//      (override побеждает даже urgency=Critical).
//   2. urgency=Critical → "critical".
//   3. Совпадение в systemRules → "system" (или tier правила, если задан).
//   4. Иначе → "normal".
//
// Hot-reload работает: правка этого файла применяется без рестарта Quickshell.
// ─────────────────────────────────────────────────────────────────────────────
QtObject {
	id: root

	// ─── Правила, попадающие в System ─────────────────────────────────────
	// Поля одного правила (можно комбинировать):
	//   appName          строгое совпадение с notification.appName (case-insensitive)
	//   desktopEntry     совпадение с hints["desktop-entry"] (или n.desktopEntry)
	//   category         совпадение с hints["category"] (XDG-категории)
	//   appNamePattern   регулярка по appName (case-insensitive)
	//   tier             явный override; если опущен — правило ведёт в "system"
	readonly property var systemRules: [
		// ── Network: Wi-Fi / Ethernet / VPN ──────────────────────────────
		{ appName: "NetworkManager" },
		{ appName: "nm-applet" },
		{ appName: "networkmanager" },
		{ desktopEntry: "nm-applet" },
		{ appNamePattern: "^(network|nm-).*" },
		{ category: "network" },
		{ category: "network.connected" },
		{ category: "network.disconnected" },

		// VPN-инструменты, если шлют через notify-send напрямую
		{ appName: "WireGuard" },
		{ appName: "wg-quick" },
		{ appName: "openvpn" },
		{ appName: "Tailscale" },
		{ appName: "Mullvad VPN" },
		{ appNamePattern: "^vpn.*" },

		// ── Power / Battery / Thermal ────────────────────────────────────
		{ appName: "Power" },
		{ appName: "UPower" },
		{ appName: "Battery" },
		{ appName: "tlp" },
		{ appName: "auto-cpufreq" },
		{ desktopEntry: "tlp-ui" },
		{ category: "device.battery" },

		// ── Bluetooth ────────────────────────────────────────────────────
		{ appName: "BlueZ" },
		{ appName: "bluez" },
		{ appName: "bluetoothd" },
		{ appName: "blueman" },
		{ desktopEntry: "blueman" },
		{ desktopEntry: "bluedevil" },
		{ appNamePattern: "^bluetooth.*" },

		// ── USB / storage / external devices ─────────────────────────────
		{ appName: "UDisks2" },
		{ appName: "udisks2" },
		{ appName: "udisksd" },
		{ desktopEntry: "udisks2" },
		{ category: "device" },
		{ category: "device.added" },
		{ category: "device.removed" },
		{ appNamePattern: "^(udisk|usb).*" },

		// ── File managers (шлют уведомления о монтировании/размонтировании) ──
	    { appName: "org.gnome.Nautilus" },
		{ appName: "nautilus" },
	    { appName: "Nautilus" },
		{ appName: "org.kde.dolphin" },
	    { appName: "dolphin" },
		{ appName: "nemo" },
	    { appName: "caja" },
		{ appName: "thunar" },
	    { appName: "Files" },
		{ appNamePattern: "^(org\\.(gnome|kde|xfce|mate)\\.)?(nautilus|dolphin|nemo|caja|thunar|files)$" },

	    // ── GVFS / KIO (бекенды монтирования, шлют свои события) ──────────
	    { appName: "gvfs" },
	    { appName: "gvfsd" },
	    { appNamePattern: "^gvfs.*" },

		// ── Системные обновления Arch ────────────────────────────────────
		{ appName: "pacman" },
		{ appName: "informant" },
		{ appName: "paru" },
		{ appName: "yay" },
		{ appName: "flatpak" },
		{ appNamePattern: "^(arch|pacman|aur)-.*" },

		// ── systemd / journald ───────────────────────────────────────────
		// Примечание: уведомления от systemd с urgency=Critical (failed service)
		// автоматически попадут в Critical через шаг 2 алгоритма — урgency
		// побеждает совпадение в systemRules.
		{ appName: "systemd" },
		{ appName: "journald" },

		// ── Hyprland / Wayland session ───────────────────────────────────
		{ appName: "Hyprland" },
		{ appName: "hyprctl" },
		{ appName: "hypridle" },
		{ appName: "hyprlock" }
	]

	// ─── Правила-override с явным tier ────────────────────────────────────
	// Принудительно зафиксировать класс для конкретного приложения.
	// Примеры (закомментированы):
	//   { appName: "Backup",  tier: "critical" }  — даже без urgency=2
	//   { appName: "Slack",   tier: "normal"   }  — даже если есть category=device
	readonly property var overrideRules: [
		// твои правила-override здесь
	]

	// ─── classify(notification) → "normal" | "system" | "critical" ────────
	function classify(n) {
		if (!n) return "normal"

		// 1. Override-правило с заданным tier — побеждает всё.
		var ovr = matchInList(n, overrideRules)
		if (ovr && ovr.tier) return ovr.tier

		// 2. Critical urgency — выше системных правил.
		if (n.urgency === NotificationUrgency.Critical) return "critical"

		// 3. System-правило.
		var sys = matchInList(n, systemRules)
		if (sys) return sys.tier ? sys.tier : "system"

		// 4. По умолчанию — Normal.
		return "normal"
	}

	// ─── Хелпер: первое совпадение правила с данными уведомления ──────────
	function matchInList(n, rules) {
		if (!rules || !n) return null

		var appName = (n.appName || "").toString().toLowerCase()
		var deName  = ""
		if (n.hints && n.hints["desktop-entry"]) deName = n.hints["desktop-entry"].toString().toLowerCase()
		if (!deName && n.desktopEntry) deName = n.desktopEntry.toString().toLowerCase()
		var cat = (n.hints && n.hints["category"]) ? n.hints["category"].toString().toLowerCase() : ""

		for (var i = 0; i < rules.length; ++i) {
			var r = rules[i]
			if (r.appName && r.appName.toLowerCase() === appName) return r
			if (r.desktopEntry && deName && r.desktopEntry.toLowerCase() === deName) return r
			if (r.category && cat && r.category.toLowerCase() === cat) return r
			if (r.appNamePattern) {
				try {
					var re = new RegExp(r.appNamePattern, "i")
					if (re.test(appName)) return r
				} catch (e) { /* кривая регулярка — пропускаем тихо */ }
			}
		}
		return null
	}
}

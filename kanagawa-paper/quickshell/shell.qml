//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import "./modules/bar"
import "./modules/popups"
import "./modules/services/"
import "./modules/notifications"
import "./theme"

// shell.qml - точка входа Quickshell.

Variants {
	model: Quickshell.screens

	Component.onCompleted: {
		NotificationService.server
		MprisModel.cmusPlayer
	}

    delegate: QtObject {
        id: perScreen
		required property var modelData
		Component.onCompleted: console.log("[shell] delegate created for screen:", modelData.name, "id:", modelData.serialNumber)
		Component.onDestruction: console.log("[shell] delegate DESTROYED for screen:", modelData ? modelData.name : "?")

        // ─── Сам бар ─────────────────────────────────────────────────────
        property Bar bar: Bar {
            screen: perScreen.modelData

            // ─── Левые иконки -> попапы ─────────────────────────────────
            // iconLocalX - X-координата левого края иконки в координатах
            // окна бара (см. LeftSection.qml -> mapToItem).
            onLeftPowerClicked: (iconLocalX) => {
                powerMenu.parentBar = bar
                powerMenu.anchorX = iconLocalX - 22
                PopupManager.toggle(powerMenu)
			}

			onLeftTerminalClicked: (iconLocalX) => {
				terminakProc.startDetached()
			}

			onLeftFilesClicked: (iconLocalX) => {
				fileProc.startDetached()
			}

			onLeftWallpaperClicked: (iconLocalX) => {
				wallpaperPicker.parentBar = bar
				wallpaperPicker.contentWidth = bar.width
				wallpaperPicker.anchorX = 0
				PopupManager.toggle(wallpaperPicker)
			}

			onRightClockClicked: (clockLocalX) => {
				calendarPopup.parentBar = bar
				calendarPopup.anchorX = bar.width - 0 - calendarPopup.contentWidth
				PopupManager.toggle(calendarPopup)
			}

			onRightVolumeClicked: (volumeLocalX) => {
				audioPopup.parentBar = bar
				audioPopup.anchorX = bar.width - 0 - audioPopup.contentWidth
				PopupManager.toggle(audioPopup)
			}

			onRightNetworkClicked: (networkLocalX) => {
				networkPopup.parentBar = bar
				networkPopup.anchorX = bar.width - networkPopup.contentWidth - Theme.popupSideMargin
				PopupManager.toggle(networkPopup)
			}

			onRightBatteryClicked: (batteryLocalX) => {
				batteryPopup.parentBar = bar
				batteryPopup.anchorX = bar.width - 0 - batteryPopup.contentWidth
				PopupManager.toggle(batteryPopup)
			}

			onRightNotificationsClicked: (x) => {
			notificationsPopup.parentBar = bar
			notificationsPopup.anchorX = bar.width - 0 - notificationsPopup.contentWidth
			PopupManager.toggle(notificationsPopup)
			}
        }

        // ─── Попапы ─────────────────────────────────────────────────────
        // Стартуют невидимыми. parentBar и anchorX выставляются в
        // соответствующих обработчиках перед toggle().
		property PowerMenu powerMenu: PowerMenu {}
		property WallpaperPicker wallpaperPicker: WallpaperPicker {}
		property CalendarPopup calendarPopup: CalendarPopup {}
		property AudioPopup audioPopup: AudioPopup {}
		property BatteryPopup batteryPopup: BatteryPopup {}
		property NetworkPopup networkPopup: NetworkPopup {}
		property NotificationsPopup notificationsPopup: NotificationsPopup {}
		property var toasts: ToastsWindow { screen: perScreen.modelData }

		property Process terminakProc: Process {
			command: ["hyprctl", "dispatch", "hl.dsp.exec_cmd(\"kitty --class floating-kitty\")"]
		}
		property Process fileProc: Process {
			command: ["hyprctl", "dispatch", "hl.dsp.exec_cmd(\"nautilus\")"]
		}
    }
}

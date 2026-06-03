//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import "./modules/bar"
import "./modules/popups"
import "./theme"

// shell.qml - точка входа Quickshell.
//
// Variants по Quickshell.screens создаёт по одной копии делегата на каждый
// подключённый монитор. Делегат - QtObject-контейнер, внутри которого живут:
//   - Bar (PanelWindow с layer-shell - отдельное окно)
//   - PowerMenu (PopupWindow - тоже отдельное окно)
//
// PowerMenu позиционируется относительно своего Bar через anchor.window,
// поэтому каждый монитор имеет свой набор Bar+PowerMenu. Иначе на
// multi-monitor клик с одного экрана открывал бы попап на другом.
//
// modelData в делегате - это ShellScreen текущего монитора. Передаётся
// в Bar.screen, чтобы layer-shell поверхность создалась именно на этом
// дисплее. PowerMenu берёт screen из своего parentBar автоматически.
Variants {
    model: Quickshell.screens

    delegate: QtObject {
        id: perScreen
        required property var modelData

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
				volumePopup.parentBar = bar
				volumePopup.anchorX = bar.width - 0 - volumePopup.contentWidth
				PopupManager.toggle(volumePopup)
			}

			onRightBatteryClicked: (batteryLocalX) => {
				batteryPopup.parentBar = bar
				batteryPopup.anchorX = bar.width - 0 - batteryPopup.contentWidth
				PopupManager.toggle(batteryPopup)
			}
        }

        // ─── Попап питания ──────────────────────────────────────────────
        // Стартует невидимым. parentBar и anchorX выставляются в обработчике
        // onLeftPowerClicked перед toggle().
		property PowerMenu powerMenu: PowerMenu {}
		property WallpaperPicker wallpaperPicker: WallpaperPicker {}
		property CalendarPopup calendarPopup: CalendarPopup {}
		property VolumePopup volumePopup: VolumePopup {}
		property BatteryPopup batteryPopup: BatteryPopup{}
		property Process terminakProc: Process {
			command: ["kitty", "--class", "floating-kitty"]
		}
		property Process fileProc: Process {
			command: ["nautilus"]
		}
    }
}

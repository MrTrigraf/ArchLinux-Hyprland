import QtQuick
import Quickshell
import Quickshell.Wayland
import "./sections"
import "../../theme"

// ─────────────────────────────────────────────────────────────────────────────
// Bar — главная полоса. Layer-shell поверх Wayland, прилипает к нижнему краю
// по центру.
//
// Геометрия:
//   - 3 якоря (left+right+bottom) → ширина окна = Screen.width
//   - margins.left/right = (1 - barWidthRatio)/2 * screen.width
//     → визуальная ширина 52% от экрана
//   - implicitHeight = 38, margins.bottom = 0 (бар прилипает к низу)
//
// Раскладка содержимого через якоря (НЕ RowLayout):
//   - LeftSection   → прибит к левому краю
//   - CenterSection → прибит к horizontalCenter бара (строго посередине)
//   - RightSection  → прибит к правому краю
//   - TraySection   → прибит к ЛЕВОЙ грани RightSection и растёт влево
//                     по мере появления tray-иконок
// Namespace "qs-bar" — для Hyprland layer-rule с blur (см. layerrules.lua).
// ─────────────────────────────────────────────────────────────────────────────
PanelWindow {
    id: bar
	// ─── Сигналы наружу делегата ─────────────────────────────────────────
    // Bar — это PanelWindow. Прокидывает клики по иконкам
    // наверх в shell.qml, который превращает их в открытие попапов.
    signal leftPowerClicked(int iconLeftX)
    signal leftTerminalClicked(int iconLeftX)
    signal leftFilesClicked(int iconLeftX)
	signal leftWallpaperClicked(int iconLeftX)

	signal rightClockClicked(int iconLeftX)
	signal rightVolumeClicked(int iconLeftX)
	signal rightBatteryClicked(int iconLeftX)

    // ─── Layer-shell параметры ───────────────────────────────────────────
    WlrLayershell.namespace: "qs-bar"
    WlrLayershell.layer: WlrLayer.Top
	WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // ─── Якоря layer-shell поверхности к экрану ──────────────────────────
    anchors {
        left: true
        right: true
        bottom: true
    }

    // ─── Боковые отступы для визуальной ширины 52% от экрана ─────────────
    margins {
        left:   Math.round(screen.width * (1 - Theme.barWidthRatio) / 2)
        right:  Math.round(screen.width * (1 - Theme.barWidthRatio) / 2)
        bottom: 0
    }

    implicitHeight: Theme.barHeight

    // Фон самой панели прозрачный — реальный фон рисует Rectangle ниже.
    // Прозрачность нужна, чтобы Hyprland blur мог увидеть «дырки» в alpha-канале.
    color: "transparent"

    // ─── Фон бара ────────────────────────────────────────────────────────
    // Полупрозрачный фон из палитры (alpha задаётся в Theme.background).
    // Блюр под ним накладывает Hyprland через layer-rule. Верхние углы
    // округлены, нижние — нет (бар прилипает к нижнему краю экрана).
    Rectangle {
        anchors.fill: parent
        color: Theme.background
        topLeftRadius:  Theme.barRadiusTop
        topRightRadius: Theme.barRadiusTop
        bottomLeftRadius:  0
        bottomRightRadius: 0
        border.width: 1.2
        border.color: Theme.edge
    }

    // ─── Контейнер содержимого с боковым padding'ом 22px ─────────────────
    // Все секции прижаты к НИЖНЕМУ краю с одинаковым отступом
    // Theme.sectionBottomMargin → подчёркивания всех 4 блоков
    // на одной горизонтальной линии у самого низа бара.
    Item {
        anchors.fill: parent
        anchors.leftMargin: 22
        anchors.rightMargin: 22

        // ─── Левая секция: прибита к левому краю ─────────────────────────
        LeftSection {
            id: leftSection
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.sectionBottomMargin

			barWindow: bar

            // Реэмитим клики наружу делегата — в shell.qml.
            onPowerClicked:     (x) => bar.leftPowerClicked(x)
            onTerminalClicked:  (x) => bar.leftTerminalClicked(x)
            onFilesClicked:     (x) => bar.leftFilesClicked(x)
            onWallpaperClicked: (x) => bar.leftWallpaperClicked(x)
        }

        // ─── Центральная секция: строго по центру бара ───────────────────
        CenterSection {
            id: centerSection
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.sectionBottomMargin
        }

        // ─── Правая секция: прибита к правому краю ───────────────────────
        RightSection {
            id: rightSection
            anchors.right: parent.right
            anchors.bottom: parent.bottom
			anchors.bottomMargin: Theme.sectionBottomMargin

			barWindow: bar

			onClockClicked: (x) => bar.rightClockClicked(x)
			onVolumeClicked: (x) => bar.rightVolumeClicked(x)
			onBatteryClicked: (x) => bar.rightBatteryClicked(x)
        }
		// ─── Tray-секция: прибита к ЛЕВОЙ грани правой секции ────────────
        // Растёт справа налево по мере добавления tray-иконок.
        // В чате A — заглушка из 3 точек; в чате C — реальный SystemTray.
        TraySection {
            id: traySection
            anchors.right: rightSection.left
            anchors.rightMargin: Theme.sectionGap
            anchors.bottom: parent.bottom
			anchors.bottomMargin: Theme.sectionBottomMargin

			barWindow: bar
        }
    }
}

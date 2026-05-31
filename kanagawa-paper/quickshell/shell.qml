import QtQuick
import Quickshell
import "./modules/bar"
import "./modules/popups"

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

            // terminal/folder/wallpaper подключим в следующих шагах чата B.
        }

        // ─── Попап питания ──────────────────────────────────────────────
        // Стартует невидимым. parentBar и anchorX выставляются в обработчике
        // onLeftPowerClicked перед toggle().
        property PowerMenu powerMenu: PowerMenu {}
    }
}

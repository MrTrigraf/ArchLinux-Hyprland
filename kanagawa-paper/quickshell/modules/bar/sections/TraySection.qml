import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../components"
import "../../../theme"

// ─────────────────────────────────────────────────────────────────────────────
// TraySection — реальный System Tray (StatusNotifierItem).

// ─────────────────────────────────────────────────────────────────────────────
ColumnLayout {
    id: root
    spacing: 5

    // Виден только если есть хотя бы одна tray-иконка.
    visible: SystemTray.items.values.length > 0

    // Корневое окно бара — выставляется из Bar.qml. Нужно для anchor.window
    // у QsMenuAnchor: без window-родителя платформенное меню не открывается.
    property var barWindow: null

    // ─── Один QsMenuAnchor на всю секцию ──────────────────────────────────
    // Используется и для правого клика, и для onlyMenu-приложений на левом
    // клике. Перед каждым open():
    //   1. anchor.item   — иконка, от которой меню должно «расти»
    //   2. menu          — handle на DBus-меню конкретного приложения
    //   3. open()        — без аргументов
    QsMenuAnchor {
        id: trayMenu
        anchor.window: root.barWindow
    }

    // ─── Ряд иконок (растёт справа налево) ────────────────────────────────
    RowLayout {
        layoutDirection: Qt.RightToLeft
        spacing: Theme.trayIconGap
        Layout.alignment: Qt.AlignRight | Qt.AlignBottom

        Repeater {
            model: SystemTray.items.values

            // Один tray-элемент.
            Item {
                id: trayItem
                required property var modelData   // SystemTrayItem

                // Внешний размер слота — фиксирован, чтобы layout не «прыгал»
                // при появлении иконки (scale 0.8 → 1.0 не должен двигать
                // соседние иконки).
                implicitWidth:  Theme.trayIconSize
                implicitHeight: Theme.trayIconSize

                // Начальные значения для fade+scale-in анимации появления.
                opacity: 0
                scale: Theme.trayAppearScaleFrom

                // Запускаем анимацию появления сразу после создания delegate.
                Component.onCompleted: {
                    opacity = 1
                    scale = 1.0
                }
				Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.trayAppearDuration
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.trayAppearDuration
                        easing.type: Easing.OutBack
                        // OutBack даёт лёгкий «overshoot» в конце — иконка
                        // чуть «вылетает» за 1.0 и возвращается. Чувствуется
                        // живее, чем OutCubic. Не злоупотреблять — только
                        // здесь, для маленького элемента.
                    }
                }

                // ─── Сама иконка ──────────────────────────────────────────
                // IconImage из Quickshell.Widgets умеет резолвить
                // freedesktop icon names ("telegram", "nm-applet") через
                // icon-theme. Обычный Image такие имена не поймёт.
                IconImage {
                    anchors.fill: parent
                    source: trayItem.modelData.icon
                }

                // ─── Обработка кликов ─────────────────────────────────────
                // Отдельный TapHandler на каждую кнопку — один TapHandler
                // не различает кнопки в обработчике onTapped.
                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: {
                        // Если приложение умеет ТОЛЬКО меню (некоторые
                        // индикаторы не имеют primary-действия),
                        // ЛКМ открывает меню. Иначе — primary activate.
                        var item = trayItem.modelData
                        if (item.onlyMenu) {
                            if (item.hasMenu) {
                                trayMenu.anchor.item = trayItem
                                trayMenu.menu = item.menu
                                trayMenu.open()
                            }
                        } else {
                            item.activate()
                        }
                    }
                }

                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: {
                        var item = trayItem.modelData
                        if (item.hasMenu) {
                            trayMenu.anchor.item = trayItem
                            trayMenu.menu = item.menu
                            trayMenu.open()
                        }
                    }
                }

                TapHandler {
                    acceptedButtons: Qt.MiddleButton
                    onTapped: trayItem.modelData.secondaryActivate()
                }

                // ─── Скролл по иконке ─────────────────────────────────────
                // SystemTrayItem.scroll(delta, horizontal) — стандартный
                // путь для регулировок: громкость у pavucontrol-tray,
                // яркость у некоторых индикаторов и т.п.
                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: (event) => {
                        // event.angleDelta в 1/8 градуса; стандартный «щелчок»
                        // колеса = 120 единиц. Передаём «попугаев», как
                        // ожидает StatusNotifierItem.Scroll DBus-метод
                        // (целое число с произвольной шкалой).
                        var delta = event.angleDelta.y !== 0
                            ? event.angleDelta.y
                            : event.angleDelta.x
                        var horizontal = event.angleDelta.y === 0
                        trayItem.modelData.scroll(delta, horizontal)
                    }
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }
	// ─── Подчёркивание секции ─────────────────────────────────────────────
    // Оставлено по решению пользователя — Tray визуально «выделяется»
    // отдельным языком от плашек-капсул Left/Center/Right.
    SectionUnderline {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.sectionPaddingH
        Layout.rightMargin: Theme.sectionPaddingH
    }
}



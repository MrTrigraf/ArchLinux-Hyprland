import QtQuick
import Quickshell.Io
import "../../theme"

// ─────────────────────────────────────────────────────────────────────────────
// PowerMenu — попап питания над кнопкой power_settings_new в LeftSection.
//
// Структура: PopupBase + вертикальный Column из 4 пунктов.
// Каждый пункт — Item с иконкой (Material Symbols Rounded) и лейблом.
// Hover/focus подсвечивает плашку пункта цветом Theme.accent, текст темнеет.
//
// Управление:
//   - Мышь: hover подсвечивает, click выполняет действие и закрывает попап.
//   - Клавиатура: ↑/↓ перемещает focusedIndex, Enter выполняет действие
//     текущего сфокусированного пункта.
//   - ESC: закрывает попап (логика в PopupBase).
//
// Позиционирование задаёт владелец (shell.qml) через anchorX. Для кнопки
// power_settings_new это margins.left бара + 22 (внутренний padding бара).
// ─────────────────────────────────────────────────────────────────────────────
PopupBase {
    id: root

    // Геометрия попапа — компактный вертикальный список.
    contentWidth:  220
    contentHeight: items.length * Theme.popupItemHeight + 2 * Theme.popupContentPadding

    // ─── Модель пунктов меню ─────────────────────────────────────────────
    // Порядок сверху вниз: Lock → Suspend → Reboot → PowerOFF.
    // Первый пункт (Lock) безопасный — на нём стартует фокус, чтобы
    // случайный Enter после открытия не вызвал выключение.
    readonly property var items: [
        { icon: "lock",                 label: "Lock",     action: "lock"     },
        { icon: "bedtime",              label: "Suspend",  action: "suspend"  },
        { icon: "restart_alt",          label: "Reboot",   action: "reboot"   },
        { icon: "power_settings_new",   label: "PowerOFF", action: "poweroff" }
    ]

    // Индекс сфокусированного пункта (для подсветки и Enter).
    property int focusedIndex: 0

    // При открытии — сбрасываем фокус на первый пункт.
	Connections {
		target: root
		function onIsOpenChanged() {
			if (root.isOpen) root.focusedIndex = 0
		}
	}

    // ─── Процессы для выполнения действий ────────────────────────────────
    // Quickshell.Io.Process — асинхронный запуск команд. Lock дёргаем через
    // loginctl (тот же путь, что в hypridle и SUPER+SHIFT+L), остальные —
    // systemctl.
    Process { id: procLock;     command: ["loginctl", "lock-session"] }
    Process { id: procSuspend;  command: ["systemctl", "suspend"]     }
    Process { id: procReboot;   command: ["systemctl", "reboot"]      }
    Process { id: procPoweroff; command: ["systemctl", "poweroff"]    }

    // ─── Диспетчер действий ──────────────────────────────────────────────
    function execAction(action) {
		root.closeImmediate()
        switch (action) {
            case "lock":     procLock.startDetached();     break
            case "suspend":  procSuspend.startDetached();  break
            case "reboot":   procReboot.startDetached();   break
            case "poweroff": procPoweroff.startDetached(); break
        }
    }

    // ─── Содержимое: список пунктов ──────────────────────────────────────
    Column {
        id: menu
        anchors.fill: parent
        spacing: 0
        focus: true   // получает focus от contentHolder в PopupBase

        // Обработка ↑/↓ и Enter на уровне всего меню.
        Keys.onUpPressed: {
            focusedIndex = (focusedIndex - 1 + items.length) % items.length
        }
        Keys.onDownPressed: {
            focusedIndex = (focusedIndex + 1) % items.length
        }
        Keys.onReturnPressed:  execAction(items[focusedIndex].action)
        Keys.onEnterPressed:   execAction(items[focusedIndex].action)

        Repeater {
            model: root.items

            // Один пункт меню.
            Item {
                id: itemRoot
                required property int index
                required property var modelData

                width: parent.width
                height: Theme.popupItemHeight
				// Подсветка активна, если индекс совпадает с focusedIndex
                // (фокус с клавиатуры) ИЛИ если мышь над пунктом.
                readonly property bool isActive:
                    root.focusedIndex === index || hoverArea.containsMouse

                // ─── Фон-плашка (accent при hover/focus) ─────────────────
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.popupItemRadius
                    color: itemRoot.isActive ? Theme.accent : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Theme.animFast }
                    }
                }

                // ─── Иконка + лейбл ──────────────────────────────────────
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.popupItemPaddingH
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.popupIconGap

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: itemRoot.modelData.icon
                        font.family: Theme.iconFamily
                        font.pixelSize: Theme.iconSizePopupItem
                        color: itemRoot.isActive ? Theme.popupItemHoverFg : Theme.fg

                        Behavior on color {
                            ColorAnimation { duration: Theme.animFast }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: itemRoot.modelData.label
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizePopupItem
                        color: itemRoot.isActive ? Theme.popupItemHoverFg : Theme.fg

                        Behavior on color {
                            ColorAnimation { duration: Theme.animFast }
                        }
                    }
                }

                // ─── Обработка мыши ──────────────────────────────────────
                // hoverEnabled: true — для containsMouse.
                // При наведении синхронизируем focusedIndex, чтобы
                // подсветка от клавиатуры и от мыши были согласованы.
                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onEntered: root.focusedIndex = itemRoot.index
                    onClicked: root.execAction(itemRoot.modelData.action)
                }
            }
        }
    }
}
